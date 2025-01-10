#!/bin/bash

# Initialize log file
LOG_FILE="php_optimization.log"
echo "PHP Optimization Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# Get PHP version
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1-2)
PHP_INI="/etc/php/$PHP_VERSION/fpm/php.ini"

# Backup current php.ini
echo "Backing up php.ini..." | tee -a $LOG_FILE
sudo cp $PHP_INI "$PHP_INI.bak" >> $LOG_FILE 2>&1

# Optimize PHP settings
echo "Optimizing PHP settings..." | tee -a $LOG_FILE
sudo sed -i "s/^max_execution_time = .*/max_execution_time = 180/" $PHP_INI
sudo sed -i "s/^max_input_time = .*/max_input_time = 600/" $PHP_INI
sudo sed -i "s/^memory_limit = .*/memory_limit = 512M/" $PHP_INI
sudo sed -i "s/^post_max_size = .*/post_max_size = 60M/" $PHP_INI
sudo sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 60M/" $PHP_INI
sudo sed -i "s/^max_file_uploads = .*/max_file_uploads = 20/" $PHP_INI
sudo sed -i "s/^;realpath_cache_size = .*/realpath_cache_size = 256k/" $PHP_INI
sudo sed -i "s/^;realpath_cache_ttl = .*/realpath_cache_ttl = 3600/" $PHP_INI

# Restart PHP-FPM
echo "Restarting PHP-FPM..." | tee -a $LOG_FILE
sudo systemctl restart php$PHP_VERSION-fpm >> $LOG_FILE 2>&1

# Verify changes
echo "Verifying PHP settings..." | tee -a $LOG_FILE
php -i | grep -E 'max_execution_time|max_input_time|memory_limit|post_max_size|upload_max_filesize|max_file_uploads|realpath_cache' >> $LOG_FILE 2>&1

echo "PHP optimization complete!" | tee -a $LOG_FILE