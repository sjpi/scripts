#!/bin/bash

# Initialize log file
LOG_FILE="wordpress_deployment.log"
echo "WordPress Deployment Log - $(date)" > $LOG_FILE
echo "===========================" >> $LOG_FILE

# Function to run non-interactive scripts with error handling
run_script() {
    echo "Running $1..." | tee -a $LOG_FILE
    if bash scripts/$1 >> $LOG_FILE 2>&1; then
        echo "$1 completed successfully" | tee -a $LOG_FILE
    else
        echo "Error in $1. Check $LOG_FILE for details." | tee -a $LOG_FILE
        exit 1
    fi
}

# Function to run interactive scripts
run_interactive_script() {
    echo "Running $1..." | tee -a $LOG_FILE
    if bash scripts/$1; then
        echo "$1 completed successfully" | tee -a $LOG_FILE
    else
        echo "Error in $1. Check $LOG_FILE for details." | tee -a $LOG_FILE
        exit 1
    fi
}

echo "Starting WordPress deployment..." | tee -a $LOG_FILE

# Step 1: System updates and essential utilities
run_script "system_update.sh"

# Step 2: Install and configure PHP with FPM and Opcache
run_script "install_php.sh"

# Step 3: Install and configure MariaDB (Interactive)
run_interactive_script "install_mariadb.sh"

# Step 4: Install WordPress (Interactive)
run_interactive_script "install_wordpress.sh"

# Step 5: Secure WordPress files
run_script "secure_wordpress.sh"

# Step 6: Install and configure Fail2ban
run_script "install_fail2ban.sh"

# Step 7: Install LiteSpeed Cache
run_script "install_litespeed_cache.sh"

# Step 8: Install and configure Redis (after WordPress)
run_interactive_script "install_redis.sh"

# Step 9: Optimize PHP settings
run_script "optimize_php.sh"

# Step 10: Security configurations
run_script "security_headers.sh"
run_interactive_script "configure_https.sh"
run_interactive_script "harden_ssh.sh"
run_interactive_script "restrict_access.sh"

# Step 11: Monitoring and backups
run_interactive_script "install_monitoring.sh"
run_interactive_script "configure_backups.sh"

# Step 12: Configure logging
run_script "configure_logging.sh"

# Final security check
run_script "secure_wordpress.sh"

# Generate installation summary
echo "Generating installation summary..." | tee -a $LOG_FILE
cat > installation_summary.txt <<EOF
WordPress Installation Summary
============================
Date: $(date)

Installation Paths:
------------------
WordPress Root: /var/www/html
PHP Configuration: /etc/php/*/fpm/php.ini
MariaDB Configuration: /etc/mysql/mariadb.conf.d/50-server.cnf
Redis Configuration: /etc/redis/redis.conf
Fail2ban Configuration: /etc/fail2ban/jail.local

Modified Files:
--------------
- /var/www/html/wp-config.php (Permission: 600)
- /var/www/html/.htaccess (Permission: 644)
- /etc/php/*/fpm/php.ini
- /etc/mysql/mariadb.conf.d/50-server.cnf
- /etc/redis/redis.conf
- /etc/fail2ban/jail.local
- /etc/logrotate.d/wordpress
- Security headers configuration
- SSL/TLS configuration

Services Status:
---------------
PHP-FPM: $(systemctl is-active php*-fpm)
MariaDB: $(systemctl is-active mariadb)
Redis: $(systemctl is-active redis-server)
Fail2ban: $(systemctl is-active fail2ban)

Access Information:
------------------
WordPress URL: http://your-domain.com
Admin Panel: http://your-domain.com/wp-admin
Monitoring Dashboard: http://your-domain.com:3000

Configuration Files:
------------------
Database: wordpress_db.conf
Redis: redis.conf

Log Files:
---------
Main Log: wordpress_deployment.log
Component Logs: *_install.log

Security Measures:
----------------
- File permissions secured
- SSH hardened
- Fail2ban configured
- Security headers implemented
- HTTPS configured
- Access restrictions in place

Important Notes:
--------------
1. Keep all configuration files secure
2. Regularly check log files for issues
3. Monitor system performance
4. Keep backups current
5. Update WordPress and plugins regularly
EOF

echo "WordPress deployment complete!" | tee -a $LOG_FILE
echo "Access your site at http://your-domain.com" | tee -a $LOG_FILE
echo "Detailed logs available in ./*_install.log files" | tee -a $LOG_FILE
echo "Installation summary available in installation_summary.txt" | tee -a $LOG_FILE

# Display important information
echo -e "\nImportant Next Steps:"
echo "1. Review installation_summary.txt for complete setup details"
echo "2. Verify all file permissions are correct"
echo "3. Test all functionality"
echo "4. Configure WordPress settings through admin panel"