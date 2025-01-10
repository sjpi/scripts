#!/bin/bash

# Initialize log file
LOG_FILE="fail2ban_install.log"
echo "Fail2ban Installation Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

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

# Install Fail2ban
echo "Installing Fail2ban..." | tee -a $LOG_FILE
run_command sudo apt-get update
run_command sudo apt-get install -y fail2ban

# Configure Fail2ban
echo "Configuring Fail2ban..." | tee -a $LOG_FILE

# Create jail.local file
sudo cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[wordpress]
enabled = true
filter = wordpress
logpath = /var/log/auth.log
maxretry = 3
port = http,https

[wordpress-xmlrpc]
enabled = true
filter = wordpress-xmlrpc
logpath = /var/log/auth.log
maxretry = 2
port = http,https
EOF

# Create WordPress filter
sudo cat > /etc/fail2ban/filter.d/wordpress.conf <<EOF
[Definition]
failregex = ^%(__prefix_line)s.*authentication failure.*rhost=<HOST>\s*$
            ^%(__prefix_line)s.*unknown user.*rhost=<HOST>\s*$
ignoreregex =
EOF

# Create WordPress XML-RPC filter
sudo cat > /etc/fail2ban/filter.d/wordpress-xmlrpc.conf <<EOF
[Definition]
failregex = ^%(__prefix_line)s.*XML-RPC request from <HOST>$
ignoreregex =
EOF

# Enable and start Fail2ban
echo "Starting Fail2ban service..." | tee -a $LOG_FILE
run_command sudo systemctl enable fail2ban
run_command sudo systemctl start fail2ban

# Verify Fail2ban status
echo "Verifying Fail2ban status..." | tee -a $LOG_FILE
sudo fail2ban-client status | tee -a $LOG_FILE

echo "Fail2ban installation and configuration complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE