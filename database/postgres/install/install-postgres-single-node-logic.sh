#!/bin/bash

# Prompt the user to enter the Postgres version
read -p "Enter the Postgres version you want to install (e.g., 9.6, 10, 11, etc.): " version

# Install PostgreSQL
sudo apt-get update
sudo apt-get install postgresql-$version postgresql-contrib-$version -y

# Prompt the user to enter the database user and password
read -p "Enter the database user: " dbuser
read -p "Enter the database password: " dbpass

# Create the user with the specified password
sudo -u postgres psql -c "CREATE USER $dbuser WITH ENCRYPTED PASSWORD '$dbpass';"

# Prompt the user to enter the database names and create the databases
while true
do
    read -p "Enter a database name (or 'q' to quit): " dbname
    if [ "$dbname" = "q" ]; then
        break
    fi
    sudo -u postgres psql -c "CREATE DATABASE $dbname;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $dbname TO $dbuser;"
    echo "Database '$dbname' has been created."
done

# Prompt the user to specify the listen address
read -p "Enter the listen address for Postgres (e.g., 0.0.0.0): " listen_address

# Configure PostgreSQL to allow remote connections
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '$listen_address'/g" /etc/postgresql/$version/main/postgresql.conf
echo "PostgreSQL version $version is now configured to accept remote connections from $listen_address."
echo "To connect to the databases, use the following command:"
echo "psql -h $listen_address -U $dbuser -d <database>"
echo "(replace <database> with your actual database name)"
echo "Don't forget to open the necessary ports in your firewall!"
echo "See the PostgreSQL documentation for more information."

# Restart PostgreSQL
sudo systemctl restart postgresql@$version

echo "PostgreSQL version $version is now set up and running."