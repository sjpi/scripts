#!/bin/bash
# backup script for multiple directories using rsync
### NO ENCRYPTION ###

# array of source dir
SOURCES=("/ADD-Disk" "/yourdisk")

# dest dir for backups
DESTINATION="/add destination"

# --exclude=dir2  --exclude=dir3
EXCLUDES="--exclude=.* --exclude=dont_backup_ME_*"

# Loop through all sources and backup each one
for SOURCE in "${SOURCES[@]}"; do
    rsync -av --delete $EXCLUDES "$SOURCE" "${DESTINATION}/$(basename "$SOURCE")"
done