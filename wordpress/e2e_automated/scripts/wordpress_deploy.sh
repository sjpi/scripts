#!/bin/bash

# Function to prompt for input with default value
prompt_with_default() {
  local prompt=$1
  local default=$2
  read -p "$prompt [$default]: " input
  echo ${input:-$default}
}

# Function to prompt for yes/no with default value
prompt_yes_no() {
  local prompt=$1
  local default=$2
  while true; do
    read -p "$prompt [$default]: " yn
    case ${yn:-$default} in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

# Initialize log file
LOG_FILE="wordpress_deploy.log"
echo "WordPress Deployment Log - $(date)" > $LOG_FILE
echo "================================" >> $LOG_FILE

# Section 1: System Updates
echo "Updating system packages..."
sudo apt-get update -y >> $LOG_FILE 2>&1
sudo apt-get upgrade -y >> $LOG_FILE 2>&1
sudo apt-get dist-upgrade -y >> $LOG_FILE 2>&1

echo "Installing essential utilities..."
sudo apt-get install -y \
  curl wget git unzip nano glances htop \
  build-essential software-properties-common >> $LOG_FILE 2>&1

# Section 2: WordPress Installation
INSTALL_DIR=$(prompt_with_default "Enter WordPress installation directory" "/var/www/html/")
echo "Creating installation directory: $INSTALL_DIR" | tee -a $LOG_FILE
sudo mkdir -p $INSTALL_DIR
sudo chown -R $USER:$USER $INSTALL_DIR
sudo chmod 755 $INSTALL_DIR

echo "Downloading and extracting WordPress..." | tee -a $LOG_FILE
wget -q https://wordpress.org/latest.tar.gz -P /tmp >> $LOG_FILE 2>&1
sudo tar -xzf /tmp/latest.tar.gz -C $INSTALL_DIR --strip-components=1 >> $LOG_FILE 2>&1
sudo chown -R $USER:$USER $INSTALL_DIR
rm -f /tmp/latest.tar.gz

# Section 3: Database Configuration
DB_NAME=$(prompt_with_default "Enter database name" "wordpress")
DB_USER=$(prompt_with_default "Enter database user" "wpuser")
DB_PASS=$(prompt_with_default "Enter database password" "")
DB_HOST=$(prompt_with_default "Enter database host" "localhost")
DB_PREFIX=$(prompt_with_default "Enter table prefix" "wp_")

# Create wp-config.php
echo "Creating wp-config.php..." | tee -a $LOG_FILE
if [ -f "$INSTALL_DIR/wp-config-sample.php" ]; then
  # Ensure directory permissions
  sudo chmod 755 "$INSTALL_DIR"
  
  # Create and modify wp-config.php with sudo
  sudo cp "$INSTALL_DIR/wp-config-sample.php" "$INSTALL_DIR/wp-config.php"
  sudo chown $USER:$USER "$INSTALL_DIR/wp-config.php"
  
  # Update wp-config.php with database details using sudo
  sudo sed -i "s/database_name_here/$DB_NAME/" "$INSTALL_DIR/wp-config.php"
  sudo sed -i "s/username_here/$DB_USER/" "$INSTALL_DIR/wp-config.php"
  sudo sed -i "s/password_here/$DB_PASS/" "$INSTALL_DIR/wp-config.php"
  sudo sed -i "s/localhost/$DB_HOST/" "$INSTALL_DIR/wp-config.php"
  sudo sed -i "s/wp_/$DB_PREFIX/" "$INSTALL_DIR/wp-config.php"

  # Generate security keys
  echo "Generating security keys..." | tee -a $LOG_FILE
  SECURE_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
  sudo sed -i "/define('AUTH_KEY'/,$ d" "$INSTALL_DIR/wp-config.php"
  echo "$SECURE_KEYS" | sudo tee -a "$INSTALL_DIR/wp-config.php" > /dev/null
else
  echo "Error: wp-config-sample.php not found in $INSTALL_DIR" | tee -a $LOG_FILE
  exit 1
fi

# Set file permissions
echo "Setting file permissions..." | tee -a $LOG_FILE
sudo chown -R www-data:www-data $INSTALL_DIR
sudo find $INSTALL_DIR -type d -exec chmod 755 {} \;
sudo find $INSTALL_DIR -type f -exec chmod 644 {} \;

# Section 4: PHP Installation and Configuration
echo "Installing PHP and required extensions..." | tee -a $LOG_FILE
sudo apt-get install -y \
  php php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip \
  php-opcache php-intl php-soap php-imagick >> $LOG_FILE 2>&1

# Configure PHP settings
echo "Configuring PHP settings..." | tee -a $LOG_FILE
PHP_INI=$(php --ini | grep "Loaded Configuration File" | awk '{print $4}')
sudo sed -i "s/^memory_limit = .*/memory_limit = 512M/" $PHP_INI
sudo sed -i "s/^max_execution_time = .*/max_execution_time = 180/" $PHP_INI
sudo sed -i "s/^max_input_time = .*/max_input_time = 600/" $PHP_INI
sudo sed -i "s/^post_max_size = .*/post_max_size = 60M/" $PHP_INI
sudo sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 60M/" $PHP_INI

# Section 5: Security Configuration
echo "Installing and configuring fail2ban..." | tee -a $LOG_FILE
sudo apt-get install -y fail2ban >> $LOG_FILE 2>&1
sudo systemctl enable fail2ban >> $LOG_FILE 2>&1
sudo systemctl start fail2ban >> $LOG_FILE 2>&1

# Section 6: SSL Configuration
echo "Configuring SSL..." | tee -a $LOG_FILE
SSL_CHOICE=$(prompt_with_default "Choose SSL option (none/certbot/cloudflare)" "certbot")

case $SSL_CHOICE in
  certbot)
    sudo apt-get install -y certbot python3-certbot-nginx >> $LOG_FILE 2>&1
    sudo certbot --nginx -d $(hostname -f) >> $LOG_FILE 2>&1
    ;;
  cloudflare)
    echo "Please configure Cloudflare origin certificates manually." | tee -a $LOG_FILE
    ;;
  *)
    echo "Skipping SSL configuration." | tee -a $LOG_FILE
    ;;
esac

# Section 7: Redis Installation
if prompt_yes_no "Install Redis for caching?" "Y"; then
  echo "Installing Redis..." | tee -a $LOG_FILE
  sudo apt-get install -y redis-server >> $LOG_FILE 2>&1
  sudo systemctl enable redis-server >> $LOG_FILE 2>&1
  sudo systemctl start redis-server >> $LOG_FILE 2>&1
  
  # Configure WordPress to use Redis
  echo "Configuring WordPress to use Redis..." | tee -a $LOG_FILE
  echo "define('WP_REDIS_HOST', '127.0.0.1');" >> $INSTALL_DIR/wp-config.php
  echo "define('WP_REDIS_PORT', 6379);" >> $INSTALL_DIR/wp-config.php
fi

# Section 8: Monitoring Setup
if prompt_yes_no "Install Prometheus and Grafana for monitoring?" "N"; then
  echo "Installing Prometheus and Grafana..." | tee -a $LOG_FILE
  sudo apt-get install -y prometheus grafana >> $LOG_FILE 2>&1
  sudo systemctl enable prometheus grafana-server >> $LOG_FILE 2>&1
  sudo systemctl start prometheus grafana-server >> $LOG_FILE 2>&1
fi

# Section 9: Backup Configuration
if prompt_yes_no "Configure automated backups?" "Y"; then
  BACKUP_TOOL=$(prompt_with_default "Choose backup tool (duplicity/rsync)" "duplicity")
  BACKUP_LOCATION=$(prompt_with_default "Enter backup location" "/backups")
  
  echo "Configuring $BACKUP_TOOL backups to $BACKUP_LOCATION..." | tee -a $LOG_FILE
  sudo mkdir -p $BACKUP_LOCATION
  sudo chown -R $USER:$USER $BACKUP_LOCATION
  
  if [ "$BACKUP_TOOL" == "duplicity" ]; then
    sudo apt-get install -y duplicity >> $LOG_FILE 2>&1
    # Add cron job for daily backups
    (crontab -l 2>/dev/null; echo "0 2 * * * duplicity --full-if-older-than 7D $INSTALL_DIR $BACKUP_LOCATION") | crontab -
  else
    # Add cron job for daily rsync backups
    (crontab -l 2>/dev/null; echo "0 2 * * * rsync -a $INSTALL_DIR $BACKUP_LOCATION") | crontab -
  fi
fi

# Final Output
echo "WordPress deployment complete!" | tee -a $LOG_FILE
echo "Access your installation at: http://$(hostname -I | awk '{print $1}')/$(basename $INSTALL_DIR)" | tee -a $LOG_FILE
echo "Detailed log available at: $LOG_FILE" | tee -a $LOG_FILE