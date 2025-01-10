#!/bin/bash

# Initialize log file
LOG_FILE="mariadb_install.log"
echo "MariaDB Installation Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# Function to log and execute commands
run_command() {
    echo "Executing: $@" | tee -a $LOG_FILE
    if "$@" >> $LOG_FILE 2>&1; then
        echo "Success: $@" | tee -a $LOG_FILE
    else
        echo "Error: $@" | tee -a $LOG_FILE
        exit 1
    fi
}

# Function to get database configuration
get_database_config() {
    # Force output to terminal
    exec 3>&1

    echo
    echo "=== Database Configuration ==="
    echo "Please provide the following information:"
    echo

    while true; do
        echo -n "Is this a remote database? (y/n): " >&3
        read -r IS_REMOTE </dev/tty
        
        if [[ "$IS_REMOTE" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Please enter 'y' or 'n'" >&3
        fi
    done
    
    if [[ "$IS_REMOTE" =~ ^[Yy]$ ]]; then
        echo -n "Enter database hostname: " >&3
        read -r DB_HOST </dev/tty
        
        echo -n "Enter database port (default 3306): " >&3
        read -r DB_PORT </dev/tty
        DB_PORT=${DB_PORT:-3306}
        
        echo -n "Enter database root username: " >&3
        read -r DB_ROOT_USER </dev/tty
        
        echo -n "Enter database root password: " >&3
        read -rs DB_ROOT_PASS </dev/tty
        echo >&3
    else
        DB_HOST="localhost"
        DB_PORT="3306"
        DB_ROOT_USER="root"
        
        echo -n "Enter new MariaDB root password: " >&3
        read -rs DB_ROOT_PASS </dev/tty
        echo >&3
    fi

    echo
    echo "=== WordPress Database Details ==="
    echo

    echo -n "Enter WordPress database name: " >&3
    read -r WP_DB_NAME </dev/tty
    
    echo -n "Enter WordPress database user: " >&3
    read -r WP_DB_USER </dev/tty
    
    echo -n "Enter WordPress database password: " >&3
    read -rs WP_DB_PASS </dev/tty
    echo >&3

    # Close terminal output
    exec 3>&-

    # Log configuration (without passwords)
    echo "Database Configuration:" >> $LOG_FILE
    echo "Host: $DB_HOST" >> $LOG_FILE
    echo "Port: $DB_PORT" >> $LOG_FILE
    echo "WordPress DB: $WP_DB_NAME" >> $LOG_FILE
    echo "WordPress User: $WP_DB_USER" >> $LOG_FILE
}

# Get database configuration
get_database_config

if [[ "$IS_REMOTE" =~ ^[Nn]$ ]]; then
    # Install MariaDB locally
    echo "Installing MariaDB..." | tee -a $LOG_FILE
    run_command sudo apt-get update
    run_command sudo apt-get install -y mariadb-server mariadb-client

    # Start MariaDB without password
    echo "Starting MariaDB service..." | tee -a $LOG_FILE
    run_command sudo systemctl enable mariadb
    run_command sudo systemctl start mariadb

    # Set root password
    echo "Setting root password..." | tee -a $LOG_FILE
    sudo mysqladmin -u root password "$DB_ROOT_PASS"
    
    # Secure the installation
    echo "Securing MariaDB installation..." | tee -a $LOG_FILE
    mysql -u root -p"$DB_ROOT_PASS" <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    # Configure MariaDB
    echo "Configuring MariaDB..." | tee -a $LOG_FILE
    MYSQL_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
    run_command sudo sed -i "s/^bind-address.*/bind-address = 127.0.0.1/" $MYSQL_CONF
    run_command sudo sed -i "s/^max_connections.*/max_connections = 200/" $MYSQL_CONF
    run_command sudo sed -i "s/^innodb_buffer_pool_size.*/innodb_buffer_pool_size = 256M/" $MYSQL_CONF
    run_command sudo sed -i "s/^query_cache_size.*/query_cache_size = 64M/" $MYSQL_CONF

    # Restart MariaDB to apply changes
    echo "Restarting MariaDB service..." | tee -a $LOG_FILE
    run_command sudo systemctl restart mariadb

    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to be ready..." | tee -a $LOG_FILE
    sleep 5
fi

# Test database connection
echo "Testing database connection..." | tee -a $LOG_FILE
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e "SELECT 1;" > /dev/null 2>&1; then
        echo "Database connection successful!" | tee -a $LOG_FILE
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "Failed to connect to database after $MAX_RETRIES attempts. Please check credentials." | tee -a $LOG_FILE
            exit 1
        fi
        echo "Connection attempt $RETRY_COUNT failed, retrying in 5 seconds..." | tee -a $LOG_FILE
        sleep 5
    fi
done

# Create WordPress database and user
echo "Creating WordPress database and user..." | tee -a $LOG_FILE
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $WP_DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER IF NOT EXISTS '$WP_DB_USER'@'%' IDENTIFIED BY '$WP_DB_PASS';
GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "MariaDB setup complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE

# Save database configuration for WordPress
echo "Saving database configuration..." | tee -a $LOG_FILE
cat > wordpress_db.conf <<EOF
DB_NAME=$WP_DB_NAME
DB_USER=$WP_DB_USER
DB_PASS=$WP_DB_PASS
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
EOF