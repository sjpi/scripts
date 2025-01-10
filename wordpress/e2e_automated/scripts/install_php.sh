#!/bin/bash

# Initialize log file
LOG_FILE="php_install.log"
echo "PHP Installation Log - $(date)" > $LOG_FILE
echo "======================" >> $LOG_FILE

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

# Get number of CPU cores
CPU_CORES=$(nproc)
echo "Detected $CPU_CORES CPU cores" | tee -a $LOG_FILE

# Calculate PHP-FPM settings based on CPU cores
MAX_CHILDREN=$((CPU_CORES * 4))
START_SERVERS=$((CPU_CORES * 2))
MIN_SPARE_SERVERS=$CPU_CORES
MAX_SPARE_SERVERS=$((CPU_CORES * 3))

# Install PHP and required extensions
echo "Installing PHP and extensions..." | tee -a $LOG_FILE
run_command sudo apt-get update
run_command sudo apt-get install -y \
    php \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    php-json \
    php-bcmath \
    php-imagick \
    php-intl \
    php-soap \
    php-opcache

# Get PHP version
PHP_VERSION=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1-2)
PHP_FPM_POOL="/etc/php/$PHP_VERSION/fpm/pool.d/www.conf"
PHP_INI="/etc/php/$PHP_VERSION/fpm/php.ini"

# Configure PHP-FPM
echo "Configuring PHP-FPM..." | tee -a $LOG_FILE
sudo sed -i "s/^pm.max_children =.*/pm.max_children = $MAX_CHILDREN/" $PHP_FPM_POOL
sudo sed -i "s/^pm.start_servers =.*/pm.start_servers = $START_SERVERS/" $PHP_FPM_POOL
sudo sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = $MIN_SPARE_SERVERS/" $PHP_FPM_POOL
sudo sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = $MAX_SPARE_SERVERS/" $PHP_FPM_POOL

# Configure PHP settings
echo "Configuring PHP settings..." | tee -a $LOG_FILE
sudo sed -i "s/^memory_limit =.*/memory_limit = 512M/" $PHP_INI
sudo sed -i "s/^max_execution_time =.*/max_execution_time = 180/" $PHP_INI
sudo sed -i "s/^max_input_time =.*/max_input_time = 600/" $PHP_INI
sudo sed -i "s/^post_max_size =.*/post_max_size = 60M/" $PHP_INI
sudo sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 60M/" $PHP_INI

# Configure OpCache
echo "Configuring OpCache..." | tee -a $LOG_FILE
sudo cat > /etc/php/$PHP_VERSION/mods-available/opcache.ini <<EOF
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF

# Enable OpCache
run_command sudo phpenmod opcache

# Restart PHP-FPM
echo "Restarting PHP-FPM..." | tee -a $LOG_FILE
run_command sudo systemctl restart php$PHP_VERSION-fpm

# Verify PHP installation
echo "Verifying PHP installation..." | tee -a $LOG_FILE
php -v | tee -a $LOG_FILE
php -m | tee -a $LOG_FILE

echo "PHP installation and configuration complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE