#!/bin/bash

# Setup streaming on servers with Postgres already installed.

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

# Grant membership to replication role if not already a member
echo "Granting replication membership to replication role..."
if psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='replication' AND rolcanlogin='t' AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname='replication' AND rolinherit='t' AND oid=pg_authid.oid)"; then
    echo "Replication role is already a member of replication role."
else
    psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER postgres -c "GRANT replication TO replication";
fi

# Create base backup of primary server
echo "Creating base backup of primary server..."
sudo -u postgres pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -U $REPLICATION_USER -Fp -Xs -P -R -D /var/lib/postgresql/data || { echo "Failed to create base backup of primary server"; exit 1; }

# Modify Postgres configuration file on standby server
echo "Modifying Postgres configuration file on standby server..."
sudo tee /var/lib/postgresql/data/recovery.conf <<EOF
standby_mode = 'on'
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$
