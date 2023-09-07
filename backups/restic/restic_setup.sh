#!/bin/bash

# Variables
SERVER_USER="your_server_user"
SERVER_IP="your_server_ip_address"
REPO_PATH="/path/to/your/backup/repository"
CLIENT_KEY="/path/to/your/client_private_key"
PASSWORD_FILE="/path/to/your/restic/password_file"
BACKUP_PATH="/path/to/your/data/to/backup"
CRON_SCHEDULE="0 3 * * *"

# Read server information from the file and loop through each line
while read -r SERVER_USER SERVER_IP CLIENT_KEY PASSWORD_FILE; do
    # Step 1: Create the backup repository on the server
    echo "Creating backup repository on the server $SERVER_IP..."
    ssh -i $CLIENT_KEY $SERVER_USER@$SERVER_IP "restic -r $REPO_PATH --password-file $PASSWORD_FILE init"

    # Step 2: Configure the backup script on the client machine
    BACKUP_SCRIPT_PATH="$HOME/restic_backup_${SERVER_IP}.sh"
    echo "Creating backup script on the client machine for server $SERVER_IP..."

    cat << EOF > $BACKUP_SCRIPT_PATH
#!/bin/bash

# Restic backup script
export RESTIC_REPOSITORY="sftp:$SERVER_USER@$SERVER_IP:$REPO_PATH"
export RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
export BORG_RSH="ssh -i $CLIENT_KEY"

# Run backup
restic backup $BACKUP_PATH

# Prune old snapshots
restic forget --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --keep-yearly 3 --prune
EOF

    chmod +x $BACKUP_SCRIPT_PATH

    # Step 3: Add the backup script to the crontab
    echo "Adding backup script to crontab for server $SERVER_IP..."
    (crontab -l ; echo "$CRON_SCHEDULE $BACKUP_SCRIPT_PATH") | crontab -

    echo "Restic backup server setup complete for server $SERVER_IP."

done < $SERVERS_FILE
