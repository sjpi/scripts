#!/bin/bash

# Initialize log file
LOG_FILE="logging_setup.log"
echo "Logging Configuration Setup - $(date)" > $LOG_FILE
echo "================================" >> $LOG_FILE

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

# Install logrotate if not present
echo "Installing logrotate..." | tee -a $LOG_FILE
run_command sudo apt-get install -y logrotate

# Configure Apache/Nginx log rotation
echo "Configuring web server log rotation..." | tee -a $LOG_FILE
sudo cat > /etc/logrotate.d/wordpress-web <<EOF
/var/log/apache2/*.log
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \$(cat /var/run/nginx.pid)
        fi
        if [ -f /var/run/apache2/apache2.pid ]; then
            /etc/init.d/apache2 reload > /dev/null
        fi
    endscript
}
EOF

# Configure PHP-FPM log rotation
echo "Configuring PHP-FPM log rotation..." | tee -a $LOG_FILE
sudo cat > /etc/logrotate.d/php-fpm <<EOF
/var/log/php*-fpm.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /etc/init.d/php*-fpm reload > /dev/null
    endscript
}
EOF

# Configure MariaDB log rotation
echo "Configuring MariaDB log rotation..." | tee -a $LOG_FILE
sudo cat > /etc/logrotate.d/mysql-server <<EOF
/var/log/mysql/*.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        if [ -f /var/run/mysqld/mysqld.pid ]; then
            kill -HUP \$(cat /var/run/mysqld/mysqld.pid)
        fi
    endscript
    create 640 mysql adm
}
EOF

# Create log directories if they don't exist
echo "Creating log directories..." | tee -a $LOG_FILE
run_command sudo mkdir -p /var/log/wordpress
run_command sudo chown www-data:adm /var/log/wordpress
run_command sudo chmod 755 /var/log/wordpress

# Configure WordPress specific log rotation
echo "Configuring WordPress log rotation..." | tee -a $LOG_FILE
sudo cat > /etc/logrotate.d/wordpress <<EOF
/var/log/wordpress/*.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    create 640 www-data adm
}
EOF

# Force log rotation to verify configuration
echo "Testing log rotation configuration..." | tee -a $LOG_FILE
run_command sudo logrotate -f /etc/logrotate.conf

echo "Logging configuration complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE