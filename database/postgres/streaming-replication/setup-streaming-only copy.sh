#!/bin/bash

# Setup streaming on servers with Postgres already installed.

# Before running this create a superuser that can be used. 
## sudo -u postgres psql
## CREATE USER new_cool_superuser WITH SUPERUSER CREATEDB CREATEROLE PASSWORD 'password'; 

# Define variables
PRIMARY_HOST=<primary_host>
PRIMARY_PORT=<primary_port>
PRIMARY_USER=<primary_user>
PRIMARY_DB=<primary_db>
PRIMARY_PWD=<primary_password>

STANDBY_HOST=<standby_host>
STANDBY_PORT=<standby_port>
STANDBY_USER=<standby_user>
STANDBY_DB=<standby_db>
STANDBY_PWD=<standby_password>

REPLICATION_USER=<replication_user>
REPLICATION_PWD=<replication_password>

# Check if user is a superuser
echo "Checking if user is a superuser..."
is_superuser=$(psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -tAc "SELECT usesuper FROM pg_user WHERE usename='$USER'")
if [ "$is_superuser" != "t" ]; then
    echo "Error: $USER is not a superuser. Please run this script as a superuser (e.g. postgres user)."
    exit 1
fi

# Check if replication role exists
echo "Checking if replication role exists..."
psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='replication'" | grep -q 1 || { echo "Replication role does not exist. Creating replication role..."; psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -c "CREATE ROLE replication REPLICATION LOGIN ENCRYPTED PASSWORD '$REPLICATION_PWD'"; }

# Grant replication privilege to REPLICATION_USER
echo "Granting replication privilege to $REPLICATION_USER..."
psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -c "GRANT REPLICATION TO $REPLICATION_USER" || { echo "Failed to grant replication privilege to $REPLICATION_USER"; exit 1; }

# Prompt to create additional user
echo -n "Create additional user? (y/n): "
read create_user

if [[ $create_user =~ ^[Yy]$ ]]; then
  # Prompt for username and password
  echo -n "Enter new user's name: "
  read new_user
  echo -n "Enter new user's password: "
  read new_user_password
  
  # Create user
  psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER -c "CREATE USER $new_user WITH PASSWORD '$new_user_password';" || { echo "Failed to create user $new_user"; exit 1; }

  # Prompt to grant ownership to databases
  echo -n "Grant ownership to which databases? (comma-separated list): "
  read databases

  # Grant ownership to databases
  IFS=',' read -ra db_array <<< "$databases"
  for db in "${db_array[@]}"; do
    psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER -c "ALTER DATABASE $db OWNER TO $new_user;" || { echo "Failed to grant ownership to $new_user on database $db"; exit 1; }
  done
fi

# Create base backup of primary server
echo "Creating base backup of primary server..."
sudo -u postgres pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -U $REPLICATION_USER -Fp -Xs -P -R -D /var/lib/postgresql/data || { echo "Failed to create base backup of primary server"; exit 1; }

# Modify Postgres configuration file on standby server
echo "Modifying Postgres configuration file on standby server..."
sudo tee /var/lib/postgresql/data/recovery.conf <<EOF
standby_mode = 'on'
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$STANDBY_PWD'
trigger_file = '/var/lib/postgresql/data/failover.trigger'
EOF || { echo "Failed to modify Postgres configuration file on standby server"; exit 1; }

# Restart Postgres server on standby server
echo "Restarting Postgres server on standby server..."
sudo systemctl restart postgresql || { echo "Failed to restart Postgres server on standby server"; exit 1; }

# Restart Postgres server on primary server
echo "Restarting Postgres server on primary server..."
sudo systemctl restart postgresql || { echo "Failed to restart Postgres server on primary server"; exit 1; }
