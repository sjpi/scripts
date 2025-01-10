#!/bin/bash

# Initialize log file
LOG_FILE="https_configuration.log"
echo "HTTPS Configuration Log - $(date)" > $LOG_FILE
echo "=============================" >> $LOG_FILE

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

# Prompt for SSL/TLS provider
echo "Choose SSL/TLS provider:"
echo "1) Let's Encrypt (Certbot)"
echo "2) Cloudflare Origin Certificates"
read -p "Enter choice (1 or 2): " SSL_CHOICE

case $SSL_CHOICE in
    1)
        # Install Certbot
        echo "Installing Certbot..." | tee -a $LOG_FILE
        sudo apt-get install -y certbot python3-certbot-$WEB_SERVER >> $LOG_FILE 2>&1

        # Get domain name
        read -p "Enter your domain name: " DOMAIN_NAME

        # Obtain certificate
        echo "Obtaining SSL certificate..." | tee -a $LOG_FILE
        sudo certbot --$WEB_SERVER -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME >> $LOG_FILE 2>&1

        # Configure automatic renewal
        echo "Configuring automatic renewal..." | tee -a $LOG_FILE
        (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab - >> $LOG_FILE 2>&1
        ;;
    2)
        # Install Cloudflare SSL
        echo "Installing Cloudflare Origin Certificate..." | tee -a $LOG_FILE
        read -p "Enter path to Cloudflare origin certificate: " CF_CERT
        read -p "Enter path to Cloudflare private key: " CF_KEY

        # Configure web server
        if [ "$WEB_SERVER" == "nginx" ]; then
            sudo sed -i "/server {/a \
            listen 443 ssl;\n\
            ssl_certificate $CF_CERT;\n\
            ssl_certificate_key $CF_KEY;\n\
            ssl_protocols TLSv1.2 TLSv1.3;\n\
            ssl_ciphers HIGH:!aNULL:!MD5;" $CONF_FILE
        else
            sudo sed -i "/<VirtualHost *:80>/a \
            <VirtualHost *:443>\n\
            SSLEngine on\n\
            SSLCertificateFile $CF_CERT\n\
            SSLCertificateKeyFile $CF_KEY\n\
            </VirtualHost>" $CONF_FILE
        fi
        ;;
    *)
        echo "Invalid choice. Exiting." | tee -a $LOG_FILE
        exit 1
        ;;
esac

# Enable HTTPS redirection
echo "Configuring HTTPS redirection..." | tee -a $LOG_FILE
if [ "$WEB_SERVER" == "nginx" ]; then
    sudo sed -i "/server {/a \
    if (\$scheme != 'https') {\n\
        return 301 https://\$host\$request_uri;\n\
    }" $CONF_FILE
else
    sudo sed -i "/<VirtualHost *:80>/a \
    RewriteEngine On\n\
    RewriteCond %{HTTPS} off\n\
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" $CONF_FILE
fi

# Restart web server
echo "Restarting $WEB_SERVER..." | tee -a $LOG_FILE
if [ "$WEB_SERVER" == "nginx" ]; then
    sudo systemctl restart nginx >> $LOG_FILE 2>&1
else
    sudo systemctl restart apache2 >> $LOG_FILE 2>&1
fi

# Verify HTTPS
echo "Verifying HTTPS configuration..." | tee -a $LOG_FILE
curl -I https://localhost >> $LOG_FILE 2>&1

echo "HTTPS configuration complete!" | tee -a $LOG_FILE