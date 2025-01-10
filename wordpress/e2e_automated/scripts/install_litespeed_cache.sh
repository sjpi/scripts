#!/bin/bash

# Initialize log file
LOG_FILE="litespeed_cache_install.log"
echo "LiteSpeed Cache Installation Log - $(date)" > $LOG_FILE
echo "=======================================" >> $LOG_FILE

# Install LiteSpeed Cache
echo "Installing LiteSpeed Cache..." | tee -a $LOG_FILE
sudo apt-get install -y lsphp$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1-2)-litespeed >> $LOG_FILE 2>&1

# Download WordPress plugin
echo "Downloading LiteSpeed Cache plugin..." | tee -a $LOG_FILE
PLUGIN_URL="https://downloads.wordpress.org/plugin/litespeed-cache.latest-stable.zip"
wget -q $PLUGIN_URL -P /tmp >> $LOG_FILE 2>&1

# Install plugin in WordPress
echo "Installing LiteSpeed Cache plugin..." | tee -a $LOG_FILE
unzip -q /tmp/litespeed-cache.latest-stable.zip -d /var/www/html/wordpress/wp-content/plugins/ >> $LOG_FILE 2>&1
rm -f /tmp/litespeed-cache.latest-stable.zip

# Configure LiteSpeed Cache
echo "Configuring LiteSpeed Cache..." | tee -a $LOG_FILE
cat <<EOL | sudo tee /etc/litespeed/conf.d/wordpress.conf > /dev/null
<IfModule LiteSpeed>
  CacheLookup on
  CacheRoot /var/cache/litespeed/wordpress/
  CacheMaxSize 100M
  CacheMaxExpire 3600
  CachePurgePrivate on
  CacheEnable public /
  CacheEnable private wp-admin
</IfModule>
EOL

# Set permissions
echo "Setting permissions..." | tee -a $LOG_FILE
sudo chown -R www-data:www-data /var/cache/litespeed/wordpress
sudo chmod -R 755 /var/cache/litespeed/wordpress

# Restart LiteSpeed
echo "Restarting LiteSpeed..." | tee -a $LOG_FILE
sudo systemctl restart lsws >> $LOG_FILE 2>&1

# Enable WordPress plugin
echo "Enabling LiteSpeed Cache plugin..." | tee -a $LOG_FILE
sudo -u www-data wp plugin activate litespeed-cache --path=/var/www/html/wordpress >> $LOG_FILE 2>&1

# Configure WordPress settings
echo "Configuring WordPress cache settings..." | tee -a $LOG_FILE
sudo -u www-data wp option update litespeed-cache-conf --format=json '{
  "cache_priv": true,
  "cache_commenter": true,
  "cache_rest": true,
  "cache_page_login": true,
  "cache_favicon": true,
  "cache_resources": true,
  "cache_mobile": true,
  "cache_mobile_rules": ["mobile","android","iphone","ipod","blackberry"],
  "cache_browser": true,
  "cache_ttl_pub": 3600,
  "cache_ttl_priv": 1800,
  "cache_ttl_frontpage": 3600,
  "cache_ttl_feed": 3600
}' --path=/var/www/html/wordpress >> $LOG_FILE 2>&1

echo "LiteSpeed Cache installation and configuration complete!" | tee -a $LOG_FILE