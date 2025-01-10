#!/bin/bash

# Initialize log file
LOG_FILE="wordpress_security.log"
echo "WordPress Security Configuration Log - $(date)" > $LOG_FILE
echo "=======================================" >> $LOG_FILE

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

echo "Securing WordPress file permissions..." | tee -a $LOG_FILE

# Set ownership
echo "Setting ownership..." | tee -a $LOG_FILE
run_command sudo chown -R www-data:www-data /var/www/html

# Set directory permissions
echo "Setting directory permissions..." | tee -a $LOG_FILE
run_command sudo find /var/www/html -type d -exec chmod 755 {} \;

# Set file permissions
echo "Setting file permissions..." | tee -a $LOG_FILE
run_command sudo find /var/www/html -type f -exec chmod 644 {} \;

# Secure wp-config.php
echo "Securing wp-config.php..." | tee -a $LOG_FILE
if [ -f "/var/www/html/wp-config.php" ]; then
    run_command sudo chmod 600 /var/www/html/wp-config.php
    run_command sudo chown www-data:www-data /var/www/html/wp-config.php
fi

# Secure .htaccess
echo "Securing .htaccess..." | tee -a $LOG_FILE
if [ -f "/var/www/html/.htaccess" ]; then
    run_command sudo chmod 644 /var/www/html/.htaccess
    run_command sudo chown www-data:www-data /var/www/html/.htaccess
fi

# Secure wp-content directory
echo "Securing wp-content directory..." | tee -a $LOG_FILE
run_command sudo chmod 755 /var/www/html/wp-content
run_command sudo find /var/www/html/wp-content -type d -exec chmod 755 {} \;
run_command sudo find /var/www/html/wp-content -type f -exec chmod 644 {} \;

# Secure uploads directory
echo "Securing uploads directory..." | tee -a $LOG_FILE
if [ -d "/var/www/html/wp-content/uploads" ]; then
    run_command sudo chmod 755 /var/www/html/wp-content/uploads
    run_command sudo find /var/www/html/wp-content/uploads -type d -exec chmod 755 {} \;
    run_command sudo find /var/www/html/wp-content/uploads -type f -exec chmod 644 {} \;
fi

# Add security measures to .htaccess if it exists
if [ -f "/var/www/html/.htaccess" ]; then
    echo "Adding security rules to .htaccess..." | tee -a $LOG_FILE
    cat <<EOT | sudo tee -a /var/www/html/.htaccess > /dev/null

# Protect wp-config.php
<Files wp-config.php>
    Order allow,deny
    Deny from all
</Files>

# Protect .htaccess
<Files .htaccess>
    Order allow,deny
    Deny from all
</Files>

# Disable directory browsing
Options -Indexes

# Protect sensitive files
<FilesMatch "^.*\.(log|txt|md)$">
    Order allow,deny
    Deny from all
</FilesMatch>

# Protect wp-includes
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^wp-admin/includes/ - [F,L]
    RewriteRule !^wp-includes/ - [S=3]
    RewriteRule ^wp-includes/[^/]+\.php$ - [F,L]
    RewriteRule ^wp-includes/js/tinymce/langs/.+\.php - [F,L]
    RewriteRule ^wp-includes/theme-compat/ - [F,L]
</IfModule>
EOT
fi

# Verify permissions
echo "Verifying permissions..." | tee -a $LOG_FILE
ls -la /var/www/html/wp-config.php >> $LOG_FILE 2>&1
ls -la /var/www/html/.htaccess >> $LOG_FILE 2>&1

echo "WordPress security configuration complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE