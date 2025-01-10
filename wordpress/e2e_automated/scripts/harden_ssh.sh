#!/bin/bash

# Initialize log file
LOG_FILE="ssh_hardening.log"
echo "SSH Hardening Log - $(date)" > $LOG_FILE
echo "=======================" >> $LOG_FILE

# Backup SSH config
echo "Backing up SSH configuration..." | tee -a $LOG_FILE
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak >> $LOG_FILE 2>&1

# Prompt for SSH port change
read -p "Do you want to change the default SSH port? (y/n): " CHANGE_PORT
if [[ $CHANGE_PORT == "y" ]]; then
    read -p "Enter new SSH port (1024-65535): " NEW_PORT
    echo "Changing SSH port to $NEW_PORT..." | tee -a $LOG_FILE
    sudo sed -i "s/^#Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config
fi

# Configure SSH settings
echo "Configuring SSH settings..." | tee -a $LOG_FILE
sudo sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sudo sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/^#UsePAM.*/UsePAM no/" /etc/ssh/sshd_config
sudo sed -i "s/^#ClientAliveInterval.*/ClientAliveInterval 300/" /etc/ssh/sshd_config
sudo sed -i "s/^#ClientAliveCountMax.*/ClientAliveCountMax 2/" /etc/ssh/sshd_config

# Configure fail2ban for SSH
echo "Configuring fail2ban for SSH..." | tee -a $LOG_FILE
sudo cat <<EOL | sudo tee /etc/fail2ban/jail.d/sshd.local > /dev/null
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOL

# Restart services
echo "Restarting SSH and fail2ban services..." | tee -a $LOG_FILE
sudo systemctl restart ssh >> $LOG_FILE 2>&1
sudo systemctl restart fail2ban >> $LOG_FILE 2>&1

# Verify SSH configuration
echo "Verifying SSH configuration..." | tee -a $LOG_FILE
sshd -t >> $LOG_FILE 2>&1

# Generate SSH keys if needed
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH keys..." | tee -a $LOG_FILE
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" >> $LOG_FILE 2>&1
    echo "SSH public key:" | tee -a $LOG_FILE
    cat ~/.ssh/id_rsa.pub | tee -a $LOG_FILE
fi

echo "SSH hardening complete!" | tee -a $LOG_FILE
echo "IMPORTANT: Ensure you have SSH access via key-based authentication before closing this session!" | tee -a $LOG_FILE