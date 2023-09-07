#!/bin/bash

# Set variables
DATE=`date +%Y%m%d`
PGUSER=<postgres-user>
BACKUP_DIR=/backup
REMOTE_SERVER=<remote-server>
REMOTE_USER=<remote-user>
REMOTE_DIR=/backup
SSH_KEY=<path-to-ssh-key>
LOG_FILE=/var/log/postgres-backup.log

# Create backup directory
mkdir -p $BACKUP_DIR

# Get list of databases
DATABASES=$(psql -U $PGUSER -Atc "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")

# Loop through each database and create a backup
for DB in $DATABASES
do
    BACKUP_FILE=$DB-$DATE.sql.gz
    ENCRYPTED_BACKUP_FILE=$BACKUP_FILE.gpg

    # Backup the PostgreSQL database
    pg_dump -U $PGUSER -Fc $DB | gzip > $BACKUP_DIR/$BACKUP_FILE

    # Check if backup was successful and log result
    if [ $? -eq 0 ]; then
        echo "$(date): Backup of $DB completed successfully" >> $LOG_FILE
    else
        echo "$(date): Backup of $DB failed" >> $LOG_FILE
        continue
    fi

    # Encrypt the backup file using GPG
    gpg --encrypt --recipient <recipient-email> $BACKUP_DIR/$BACKUP_FILE

    # Copy the encrypted backup to the remote server using SCP with SSH key
    scp -i $SSH_KEY $BACKUP_DIR/$ENCRYPTED_BACKUP_FILE $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR

    # Verify the backup file exists on the remote server
    ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_SERVER "ls $REMOTE_DIR/$ENCRYPTED_BACKUP_FILE > /dev/null 2>&1"
    if [ $? -ne 0 ]; then
        echo "$(date): Backup file for $DB not found on remote server. Aborting." >> $LOG_FILE
        continue
    else
        echo "$(date): Backup file for $DB transferred successfully" >> $LOG_FILE
    fi

    # Remove the local backup file
    rm $BACKUP_DIR/$BACKUP_FILE

done

# Remove old backups
find $BACKUP_DIR -type f -name '*.sql.gz' -o -name '*.sql.gz.gpg' -mtime +7 -exec rm {} \;
