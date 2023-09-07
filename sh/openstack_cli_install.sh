#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or with sudo privileges."
    exit 1
fi

# Update and install required packages
apt update -y
apt install -y python3 python3-pip

# Install the OpenStack client using pip
pip3 install python-openstackclient

# Verify the installation
openstack --version

echo "OpenStack CLI installed successfully!"

# Prompt user for Glance CLI installation
read -p "Do you want to install the Glance CLI? (Y/n) " answer

case $answer in
    [Yy]* )
        pip3 install python-glanceclient
        glance --version
        echo "Glance CLI installed successfully!"
        ;;
    * ) 
        echo "Skipping Glance CLI installation."
        ;;
esac
