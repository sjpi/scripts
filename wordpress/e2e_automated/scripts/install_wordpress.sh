#!/bin/bash

# Initialize log file
LOG_FILE="wordpress_install.log"
echo "WordPress Installation Log - $(date)" > $LOG_FILE
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

# Check for database configuration
if [ ! -f "wordpress_db.conf" ]; then
    echo "Database configuration not found. Please run install_mariadb.sh first." | tee -a $LOG_FILE
    exit 1
fi

# Load database configuration
source wordpress_db.conf

# Verify database configuration
echo "Verifying database connection..." | tee -a $LOG_FILE
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" 2>/dev/null; then
    echo "Failed to connect to database. Please check configuration." | tee -a $LOG_FILE
    exit 1
fi

# Step 1: Clean up existing WordPress installation
echo "Cleaning up existing WordPress installation..." | tee -a $LOG_FILE
run_command sudo rm -rf /var/www/html/*
run_command sudo rm -rf /tmp/wordpress.tar.gz

# Step 2: Create WordPress directory
echo "Creating WordPress directory..." | tee -a $LOG_FILE
run_command sudo mkdir -p /var/www/html
run_command sudo chown -R www-data:www-data /var/www/html

# Step 3: Download WordPress
echo "Downloading WordPress..." | tee -a $LOG_FILE
run_command sudo wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz

# Step 4: Extract WordPress
echo "Extracting WordPress..." | tee -a $LOG_FILE
run_command sudo tar -xzf /tmp/wordpress.tar.gz -C /tmp/
run_command sudo mv /tmp/wordpress/* /var/www/html/
run_command sudo rm -rf /tmp/wordpress

# Step 5: Set permissions
echo "Setting permissions..." | tee -a $LOG_FILE
run_command sudo chown -R www-data:www-data /var/www/html
run_command sudo chmod -R 755 /var/www/html

# Step 6: Configure wp-config.php
echo "Configuring wp-config.php..." | tee -a $LOG_FILE
run_command sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
run_command sudo sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
run_command sudo sed -i "s/username_here/$DB_USER/" /var/www/html/wp-config.php
run_command sudo sed -i "s/password_here/$DB_PASS/" /var/www/html/wp-config.php
run_command sudo sed -i "s/localhost/$DB_HOST/" /var/www/html/wp-config.php

if [ "$DB_PORT" != "3306" ]; then
    echo "Configuring custom database port..." | tee -a $LOG_FILE
    sudo sed -i "/DB_HOST/a define('DB_PORT', '$DB_PORT');" /var/www/html/wp-config.php
fi

# Add unique keys and salts
echo "Adding security keys..." | tee -a $LOG_FILE
KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sudo sed -i "/define('AUTH_KEY'/,/define('NONCE_SALT'/c\\$KEYS" /var/www/html/wp-config.php

# Step 7: Verify installation
echo "Verifying WordPress installation..." | tee -a $LOG_FILE
if [ -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress installation successful!" | tee -a $LOG_FILE
else
    echo "WordPress installation failed - wp-config.php not found" | tee -a $LOG_FILE
    exit 1
fi

echo "WordPress installation complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE