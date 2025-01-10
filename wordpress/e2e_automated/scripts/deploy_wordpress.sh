#!/bin/bash

# Initialize log file
LOG_FILE="wordpress_deployment.log"
echo "WordPress Deployment Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# Function to run scripts with error handling
run_script() {
    echo "Running $1..." | tee -a $LOG_FILE
    if bash $1 >> $LOG_FILE 2>&1; then
        echo "$1 completed successfully" | tee -a $LOG_FILE
    else
        echo "Error in $1. Check $LOG_FILE for details." | tee -a $LOG_FILE
        exit 1
    fi
}

# Step 1: System updates and essential utilities
run_script "scripts/system_update.sh"

# Step 2: Install and configure PHP
run_script "scripts/install_php.sh"

# Step 3: Install and configure MariaDB
run_script "scripts/install_mariadb.sh"

# Step 4: Install WordPress
run_script "scripts/install_wordpress.sh"

# Step 5: Performance optimizations
run_script "scripts/install_litespeed_cache.sh"
run_script "scripts/install_redis.sh"
run_script "scripts/optimize_php.sh"

# Step 6: Security configurations
run_script "scripts/security_headers.sh"
run_script "scripts/configure_https.sh"
run_script "scripts/harden_ssh.sh"
run_script "scripts/restrict_access.sh"

# Step 7: Monitoring and backups
run_script "scripts/install_monitoring.sh"
run_script "scripts/configure_backups.sh"

echo "WordPress deployment complete!" | tee -a $LOG_FILE
echo "Access your site at http://your-domain.com" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE