#!/bin/bash

# Initialize log file
LOG_FILE="system_update.log"
echo "System Update Log - $(date)" > $LOG_FILE
echo "======================" >> $LOG_FILE

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

# Update package lists
echo "Updating package lists..." | tee -a $LOG_FILE
run_command sudo apt-get update

# Upgrade all packages
echo "Upgrading packages..." | tee -a $LOG_FILE
run_command sudo apt-get upgrade -y

# Install essential utilities
echo "Installing essential utilities..." | tee -a $LOG_FILE
run_command sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    nano \
    glances \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    ufw \
    fail2ban \
    logrotate \
    cron \
    rsync

# Clean up package cache
echo "Cleaning up package cache..." | tee -a $LOG_FILE
run_command sudo apt-get autoremove -y
run_command sudo apt-get clean

# Verify installed utilities
echo "Verifying installations..." | tee -a $LOG_FILE
for util in curl wget git unzip nano htop glances; do
    if command -v $util >/dev/null 2>&1; then
        echo "$util is installed: $(command -v $util)" | tee -a $LOG_FILE
    else
        echo "Warning: $util is not installed" | tee -a $LOG_FILE
    fi
done

echo "System update and utilities installation complete!" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE