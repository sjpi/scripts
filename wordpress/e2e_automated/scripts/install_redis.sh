#!/bin/bash

# Initialize log file
LOG_FILE="redis_install.log"
echo "Redis Installation Log - $(date)" > $LOG_FILE
echo "========================" >> $LOG_FILE

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

# Check if WordPress is installed
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress is not installed. Please install WordPress first." | tee -a $LOG_FILE
    exit 1
fi

# Ensure unzip is installed
echo "Checking for unzip..." | tee -a $LOG_FILE
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..." | tee -a $LOG_FILE
    run_command sudo apt-get update
    run_command sudo apt-get install -y unzip
fi

# Function to get Redis configuration
get_redis_config() {
    # Force output to terminal
    exec 3>&1

    echo
    echo "=== Redis Configuration ==="
    echo "Please provide the following information:"
    echo

    while true; do
        echo -n "Is Redis hosted remotely? (y/n): " >&3
        read -r IS_REMOTE </dev/tty
        
        if [[ "$IS_REMOTE" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Please enter 'y' or 'n'" >&3
        fi
    done
    
    if [[ "$IS_REMOTE" =~ ^[Yy]$ ]]; then
        echo -n "Enter Redis hostname: " >&3
        read -r REDIS_HOST </dev/tty
        
        echo -n "Enter Redis port (default 6379): " >&3
        read -r REDIS_PORT </dev/tty
        REDIS_PORT=${REDIS_PORT:-6379}
        
        echo -n "Enter Redis password (if any): " >&3
        read -rs REDIS_PASS </dev/tty
        echo >&3
    else
        REDIS_HOST="127.0.0.1"
        REDIS_PORT="6379"
        echo -n "Set Redis password: " >&3
        read -rs REDIS_PASS </dev/tty
        echo >&3
    fi

    # Close terminal output
    exec 3>&-
}

# Get Redis configuration
get_redis_config

if [[ "$IS_REMOTE" =~ ^[Nn]$ ]]; then
    # Install Redis locally
    echo "Installing Redis..." | tee -a $LOG_FILE
    run_command sudo apt-get update
    run_command sudo apt-get install -y redis-server

    # Configure Redis
    echo "Configuring Redis..." | tee -a $LOG_FILE
    sudo sed -i "s/^# requirepass.*/requirepass $REDIS_PASS/" /etc/redis/redis.conf
    sudo sed -i "s/^bind.*/bind 127.0.0.1/" /etc/redis/redis.conf
    sudo sed -i "s/^port.*/port $REDIS_PORT/" /etc/redis/redis.conf

    # Enable and start Redis
    echo "Starting Redis service..." | tee -a $LOG_FILE
    run_command sudo systemctl enable redis-server
    run_command sudo systemctl restart redis-server

    # Wait for Redis to be ready
    echo "Waiting for Redis to be ready..." | tee -a $LOG_FILE
    sleep 5
fi

# Install Redis PHP extension
echo "Installing Redis PHP extension..." | tee -a $LOG_FILE
run_command sudo apt-get install -y php-redis

# Test Redis connection
echo "Testing Redis connection..." | tee -a $LOG_FILE
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if [ -n "$REDIS_PASS" ]; then
        REDIS_TEST=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" ping 2>/dev/null)
    else
        REDIS_TEST=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null)
    fi

    if [ "$REDIS_TEST" = "PONG" ]; then
        echo "Redis connection successful!" | tee -a $LOG_FILE
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "Failed to connect to Redis after $MAX_RETRIES attempts." | tee -a $LOG_FILE
            exit 1
        fi
        echo "Connection attempt $RETRY_COUNT failed, retrying in 5 seconds..." | tee -a $LOG_FILE
        sleep 5
    fi
done

# Configure WordPress to use Redis
echo "Configuring WordPress to use Redis..." | tee -a $LOG_FILE

# Prepare WordPress directories with proper permissions
echo "Preparing WordPress directories..." | tee -a $LOG_FILE
run_command sudo mkdir -p /var/www/html/wp-content/plugins
run_command sudo chown -R www-data:www-data /var/www/html/wp-content
run_command sudo chmod -R 755 /var/www/html/wp-content

# Create temporary directory for plugin extraction
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR" | tee -a $LOG_FILE

# Install Redis Object Cache plugin
echo "Installing Redis Object Cache plugin..." | tee -a $LOG_FILE

# Clean up any previous downloads
rm -f /tmp/redis-cache.zip

# Download plugin
run_command wget https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip -O /tmp/redis-cache.zip

# Verify download
if [ ! -f "/tmp/redis-cache.zip" ]; then
    echo "Failed to download Redis Cache plugin" | tee -a $LOG_FILE
    exit 1
fi

# Check if file is a valid zip
if ! unzip -t /tmp/redis-cache.zip >/dev/null 2>&1; then
    echo "Downloaded file is not a valid zip archive" | tee -a $LOG_FILE
    exit 1
fi

# Extract plugin to temporary directory first
echo "Extracting Redis Cache plugin..." | tee -a $LOG_FILE
run_command unzip -o /tmp/redis-cache.zip -d "$TEMP_DIR"

# Move plugin to WordPress plugins directory
echo "Moving plugin to WordPress directory..." | tee -a $LOG_FILE
run_command sudo cp -r "$TEMP_DIR/redis-cache" /var/www/html/wp-content/plugins/

# Set proper permissions
echo "Setting permissions..." | tee -a $LOG_FILE
run_command sudo chown -R www-data:www-data /var/www/html/wp-content/plugins/redis-cache
run_command sudo chmod -R 755 /var/www/html/wp-content/plugins/redis-cache

# Clean up
echo "Cleaning up..." | tee -a $LOG_FILE
run_command rm -f /tmp/redis-cache.zip
run_command rm -rf "$TEMP_DIR"

# Add Redis configuration to wp-config.php
echo "Adding Redis configuration to wp-config.php..." | tee -a $LOG_FILE
WP_CONFIG="/var/www/html/wp-config.php"

# Add Redis configuration before "/* That's all, stop editing! */"
sudo sed -i "/.*That's all, stop editing.*/i \
/* Redis configuration */\n\
define('WP_REDIS_HOST', '$REDIS_HOST');\n\
define('WP_REDIS_PORT', $REDIS_PORT);" $WP_CONFIG

if [ -n "$REDIS_PASS" ]; then
    sudo sed -i "/.*That's all, stop editing.*/i \
define('WP_REDIS_PASSWORD', '$REDIS_PASS');" $WP_CONFIG
fi

echo "Redis installation and configuration complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE

# Save Redis configuration
echo "Saving Redis configuration..." | tee -a $LOG_FILE
cat > redis.conf <<EOF
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
EOF