#!/bin/bash

# Initialize log file
LOG_FILE="access_restriction.log"
echo "Access Restriction Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# Prompt for access restriction method
echo "Choose access restriction method:"
echo "1) Open to all"
echo "2) Restricted to specific IPs"
echo "3) Use Cloudflare IP ranges"
read -p "Enter choice (1, 2, or 3): " ACCESS_CHOICE

case $ACCESS_CHOICE in
    1)
        echo "Allowing access from all IPs..." | tee -a $LOG_FILE
        sudo ufw allow http >> $LOG_FILE 2>&1
        sudo ufw allow https >> $LOG_FILE 2>&1
        ;;
    2)
        read -p "Enter allowed IP addresses (comma separated): " ALLOWED_IPS
        IFS=',' read -r -a IP_ARRAY <<< "$ALLOWED_IPS"
        for IP in "${IP_ARRAY[@]}"; do
            echo "Allowing access from $IP..." | tee -a $LOG_FILE
            sudo ufw allow from $IP to any port http >> $LOG_FILE 2>&1
            sudo ufw allow from $IP to any port https >> $LOG_FILE 2>&1
        done
        ;;
    3)
        echo "Configuring Cloudflare IP ranges..." | tee -a $LOG_FILE
        # Install jq for JSON parsing
        sudo apt-get install -y jq >> $LOG_FILE 2>&1

        # Create Cloudflare IP update script
        echo "Creating Cloudflare IP update script..." | tee -a $LOG_FILE
        sudo cat <<'EOL' | sudo tee /usr/local/bin/update_cloudflare_ips > /dev/null
#!/bin/bash
IPS=$(curl -s https://api.cloudflare.com/client/v4/ips | jq -r '.result.ipv4_cidrs[],.result.ipv6_cidrs[]' | tr '\n' ' ')
sudo ufw delete allow http
sudo ufw delete allow https
for IP in $IPS; do
    sudo ufw allow from $IP to any port http
    sudo ufw allow from $IP to any port https
done
EOL

        # Make script executable
        sudo chmod +x /usr/local/bin/update_cloudflare_ips >> $LOG_FILE 2>&1

        # Run initial update
        sudo /usr/local/bin/update_cloudflare_ips >> $LOG_FILE 2>&1

        # Set up cron job for daily updates
        echo "Setting up daily Cloudflare IP updates..." | tee -a $LOG_FILE
        (sudo crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/update_cloudflare_ips") | sudo crontab - >> $LOG_FILE 2>&1
        ;;
    *)
        echo "Invalid choice. Exiting." | tee -a $LOG_FILE
        exit 1
        ;;
esac

# Enable UFW if not already enabled
echo "Enabling UFW firewall..." | tee -a $LOG_FILE
sudo ufw --force enable >> $LOG_FILE 2>&1

# Verify rules
echo "Current UFW rules:" | tee -a $LOG_FILE
sudo ufw status verbose >> $LOG_FILE 2>&1

echo "Access restriction configuration complete!" | tee -a $LOG_FILE