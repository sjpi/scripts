#!/bin/bash

# Initialize log file
LOG_FILE="security_headers.log"
echo "Security Headers Implementation Log - $(date)" > $LOG_FILE
echo "=====================================" >> $LOG_FILE

# Determine web server type
if [ -f /etc/nginx/nginx.conf ]; then
    WEB_SERVER="nginx"
    CONF_FILE="/etc/nginx/nginx.conf"
elif [ -f /etc/apache2/apache2.conf ]; then
    WEB_SERVER="apache"
    CONF_FILE="/etc/apache2/apache2.conf"
else
    echo "Web server not found. Exiting." | tee -a $LOG_FILE
    exit 1
fi

# Backup current configuration
echo "Backing up $WEB_SERVER configuration..." | tee -a $LOG_FILE
sudo cp $CONF_FILE "$CONF_FILE.bak" >> $LOG_FILE 2>&1

# Add security headers
echo "Adding security headers..." | tee -a $LOG_FILE
if [ "$WEB_SERVER" == "nginx" ]; then
    sudo sed -i '/http {/a \
    add_header X-Content-Type-Options "nosniff";\
    add_header X-Frame-Options "SAMEORIGIN";\
    add_header X-XSS-Protection "1; mode=block";\
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";\
    add_header Content-Security-Policy "default-src \x27self\x27; script-src \x27self\x27 \x27unsafe-inline\x27; style-src \x27self\x27 \x27unsafe-inline\x27; img-src \x27self\x27 data:; font-src \x27self\x27 data:; frame-ancestors \x27self\x27;";\
    more_set_headers -s 400,401,403,404,500 "Server: ";' $CONF_FILE
else
    sudo sed -i '/<IfModule mod_headers.c>/a \
    Header set X-Content-Type-Options "nosniff"\
    Header set X-Frame-Options "SAMEORIGIN"\
    Header set X-XSS-Protection "1; mode=block"\
    Header set Strict-Transport-Security "max-age=31536000; includeSubDomains"\
    Header set Content-Security-Policy "default-src \x27self\x27; script-src \x27self\x27 \x27unsafe-inline\x27; style-src \x27self\x27 \x27unsafe-inline\x27; img-src \x27self\x27 data:; font-src \x27self\x27 data:; frame-ancestors \x27self\x27;"\
    Header unset Server' $CONF_FILE
fi

# Restart web server
echo "Restarting $WEB_SERVER..." | tee -a $LOG_FILE
if [ "$WEB_SERVER" == "nginx" ]; then
    sudo systemctl restart nginx >> $LOG_FILE 2>&1
else
    sudo systemctl restart apache2 >> $LOG_FILE 2>&1
fi

# Verify headers
echo "Verifying security headers..." | tee -a $LOG_FILE
curl -I http://localhost | grep -E 'X-Content-Type-Options|X-Frame-Options|X-XSS-Protection|Strict-Transport-Security|Content-Security-Policy' >> $LOG_FILE 2>&1

echo "Security headers implementation complete!" | tee -a $LOG_FILE