#!/bin/bash

# Script to install the latest MariaDB version
# Ensure the script is run as root or with sudo privileges

echo "Starting MariaDB installation..."

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "Installing required packages..."
apt install -y software-properties-common gnupg curl

# Add MariaDB repository
echo "Adding MariaDB repository..."
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

# Install MariaDB server
echo "Installing MariaDB server..."
apt update && apt install -y mariadb-server

# Start and enable MariaDB service
echo "Starting and enabling MariaDB service..."
systemctl start mariadb
systemctl enable mariadb

# Run MariaDB secure installation
echo "Running MariaDB secure installation..."
mysql_secure_installation

# Display MariaDB version
echo "MariaDB installation complete. Version installed:"
mysql -V

