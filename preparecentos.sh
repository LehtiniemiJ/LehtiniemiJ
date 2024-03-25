#!/bin/bash

# Function to check if ping is successful
check_ping() {
    ping -c 1 8.8.8.8 >/dev/null 2>&1
}

# Function to set up network adapter if ping fails
setup_network() {
    echo "Setting up network adapter..."
    # Find out the network adapter name
    network_adapter=$(ip a | grep '^[0-9]' | grep -v 'lo' | awk '{print $2}' | sed 's/://')
    echo "Detected network adapter: $network_adapter"
    cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$network_adapter
DEVICE=$network_adapter
BOOTPROTO=dhcp
ONBOOT=yes
DNS1=8.8.8.8
DNS2=8.8.4.4
EOF
    systemctl restart network
}

# Add sslverify=false to /etc/yum.conf
echo "Adding sslverify=false to /etc/yum.conf..."
echo "sslverify=false" | sudo tee -a /etc/yum.conf >/dev/null

# Check ping
echo "Pinging 8.8.8.8..."
if ! check_ping; then
    echo "Ping failed. Setting up network adapter..."
    setup_network
else
    echo "Ping successful."
fi

# Install required packages
echo "Installing audit..."
sudo yum install -y audit yum-utils > /dev/null

echo "Updating curl..."
sudo yum update -y curl

echo "Starting auditd service..."
sudo systemctl start auditd
sudo systemctl enable auditd
sudo systemctl status auditd

echo "Adding Microsoft repository..."
sudo yum-config-manager --add-repo=https://packages.microsoft.com/config/rhel/7/prod.repo

echo "install mdapt"
yum install mdatp -y

# Remove sslverify=false from /etc/yum.conf after script execution
echo "Removing sslverify=false from /etc/yum.conf..."
sudo sed -i '/sslverify=false/d' /etc/yum.conf

echo "Script execution complete."
