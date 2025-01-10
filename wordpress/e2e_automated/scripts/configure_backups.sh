#!/bin/bash

# init log file
LOG_FILE="backup_configuration.log"
echo "Backup Configuration Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# prompt for backup tool choice
echo "Choose backup tool:"
echo "1) Duplicity"
echo "2) Rsync"
read -p "Enter choice (1 or 2): " BACKUP_CHOICE

case $BACKUP_CHOICE in
    1)
        echo "Installing Duplicity..." | tee -a $LOG_FILE
        sudo apt-get install -y duplicity >> $LOG_FILE 2>&1
        BACKUP_TOOL="duplicity"
        ;;
    2)
        echo "Using Rsync..." | tee -a $LOG_FILE
        BACKUP_TOOL="rsync"
        ;;
    *)
        echo "Invalid choice. Exiting." | tee -a $LOG_FILE
        exit 1
        ;;
esac

# prompt for remote storage location
echo "Choose remote storage location:"
echo "1) AWS S3"
echo "2) Local disk"
echo "3) Other (specify)"
read -p "Enter choice (1, 2, or 3): " STORAGE_CHOICE

case $STORAGE_CHOICE in
    1)
        read -p "Enter S3 bucket name: " S3_BUCKET
        REMOTE_LOCATION="s3://$S3_BUCKET"
        ;;
    2)
        read -p "Enter local backup directory: " LOCAL_DIR
        REMOTE_LOCATION="$LOCAL_DIR"
        ;;
    3)
        read -p "Enter custom remote location: " CUSTOM_LOC
        REMOTE_LOCATION="$CUSTOM_LOC"
        ;;
    *)
        echo "Invalid choice. Exiting." | tee -a $LOG_FILE
        exit 1
        ;;
esac

# set up encryption
echo "Configuring encryption..." | tee -a $LOG_FILE
read -p "Enter encryption passphrase: " ENCRYPT_PASS
export PASSPHRASE=$ENCRYPT_PASS

# create backup script
echo "Creating backup script..." | tee -a $LOG_FILE
sudo cat <<EOL | sudo tee /usr/local/bin/backup_system > /dev/null
#!/bin/bash
export PASSPHRASE=$ENCRYPT_PASS
if [ "$BACKUP_TOOL" == "duplicity" ]; then
    duplicity --full-if-older-than 1M /var/www/html $REMOTE_LOCATION
else
    rsync -avz --progress /var/www/html $REMOTE_LOCATION
fi
EOL

# make backup script executable
sudo chmod +x /usr/local/bin/backup_system >> $LOG_FILE 2>&1

# configure cron job
echo "Configuring daily backup schedule..." | tee -a $LOG_FILE
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup_system") | sudo crontab - >> $LOG_FILE 2>&1

# verify configuration
echo "Backup configuration complete!" | tee -a $LOG_FILE
echo "Backup tool: $BACKUP_TOOL" | tee -a $LOG_FILE
echo "Remote location: $REMOTE_LOCATION" | tee -a $LOG_FILE
echo "Cron job configured for daily backups at 2 AM" | tee -a $LOG_FILE