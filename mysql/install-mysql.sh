#!/bin/bash

# Updates to package list / config package manager
sudo apt-get update
sudo apt-get install -y software-properties-common

# Add MySQL APT repo
wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.24-1_all.deb

# Update package DB with packages
sudo apt-get update

# Install the MySQL server / packages
sudo apt-get install -y mysql-server

# Run the MySQL install util
sudo mysql_secure_installation

# MySQL service to start on boot
sudo systemctl enable mysql

# Start the MySQL service
sudo systemctl start mysql

echo "MySQL installation is completed!"

