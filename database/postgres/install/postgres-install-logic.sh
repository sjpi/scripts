#!/bin/bash

# Prompt the user to enter the IP address and port to test
read -p "Enter the IP address: " ip_address
read -p "Enter the port: " port

# Test the port connectivity
echo "Testing port $port on $ip_address..."
nc -zv $ip_address $port

if [ $? -eq 0 ]; then
    echo "Port $port on $ip_address is open. Proceeding with the script."
    # Continue with the rest of the script here
else
    echo "Port $port on $ip_address is not open. Exiting the script."
    exit 1
fi


# Prompt the user to enter the Postgres version
read -p "Enter the Postgres version you want to install (e.g., 9.6, 10, 11, etc.): " version

# Install PostgreSQL
sudo apt-get update
sudo apt-get install postgresql-$version postgresql-contrib-$version

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
sudo systemctl restart postgresql-$version

# Check if PostgreSQL is running
if sudo systemctl is-active --quiet postgresql-$version; then
    echo "PostgreSQL version $version is now set up and running."
else
    echo "Failed to start PostgreSQL. Please check the service status."
fi

# Prompt the user to enter the database user and password
read -p "Enter the database user: " replicatordbuser
read -p "Enter the database password: " replicatordbpass

# Prompt the user to specify if the server is master or read-only
read -p "Is this server a master (M) or read-only (R)? " server_type

if [ "$server_type" = "M" ]; then
    # This is the master server

    # Prompt the user to specify the listen address for streaming replication
    read -p "Enter the listen address for streaming replication (e.g., 0.0.0.0): " sr_listen_address

    # Configure PostgreSQL for streaming replication
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/$version/main/postgresql.conf
    sudo sed -i "s/#wal_level = replica/wal_level = replica/g" /etc/postgresql/$version/main/postgresql.conf
    sudo sed -i "s/#max_wal_senders = 10/max_wal_senders = 10/g" /etc/postgresql/$version/main/postgresql.conf
    sudo sed -i "s/#wal_keep_segments = 0/wal_keep_segments = 32/g" /etc/postgresql/$version/main/postgresql.conf
    echo "host replication all $sr_listen_address/32 md5" | sudo tee -a /etc/postgresql/$version/main/pg_hba.conf
    sudo systemctl restart postgresql-$version
    echo "PostgreSQL version $version is now configured for streaming replication."

    # Prompt the user to specify the read-only server's IP address
    read -p "Enter the IP address of the read-only server: " ro_server_ip

    # Prompt the user to specify the database name for streaming replication
    read -p "Enter the database name to be replicated: " repl_dbname

    # Create the replication user on the master server
    sudo -u postgres psql -c "CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '$replicatordbpass';"

    # Add the replication settings to pg_hba.conf on the master server
    echo "host replication replicator $ro_server_ip/32 md5" | sudo tee -a /etc/postgresql/$version/main/pg_hba.conf

    # Create a replication slot on the master server
    sudo -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('replication_slot_1');"

    echo "Streaming replication has been configured. Follow the documentation to set up the read-only server."
else
    # This is the read-only server

    # Prompt the user to specify the master server's IP address and database name
    read -p "Enter the IP address of the master server: " master_server_ip
    read -p "Enter the database name to be replicated: " repl_dbname

    # Stop PostgreSQL
    sudo systemctl stop postgresql-$version
