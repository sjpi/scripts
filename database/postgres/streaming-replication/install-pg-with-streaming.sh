#!/bin/bash

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

POSTGRES_VERSION=<postgres_version>

# Generate ssh keys if not already done
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -t rsa
fi

# Copy ssh keys to standby server
ssh-copy-id -i ~/.ssh/id_rsa.pub $STANDBY_HOST

# Install Postgres on standby server
sudo apt-get update
sudo apt-get install postgresql-$POSTGRES_VERSION postgresql-contrib-$POSTGRES_VERSION

# Modify Postgres configuration file
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo sed -i "s/#wal_level = replica/wal_level = replica/" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo sed -i "s/#max_wal_senders = $POSTGRES_VERSIONmax_wal_senders = $POSTGRES_VERSION" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo sed -i "s/#wal_keep_segments = 0/wal_keep_segments = $POSTGRES_VERSION" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
sudo sed -i "s/#hot_standby = off/hot_standby = on/" /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf

# Restart Postgres server
sudo systemctl restart postgresql-$POSTGRES_VERSION

# Create replication user on primary server
psql -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PRIMARY_USER -c "CREATE USER $STANDBY_USER REPLICATION LOGIN ENCRYPTED PASSWORD '$STANDBY_PWD'"

# Create base backup of primary server
sudo -u postgres pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -U $STANDBY_USER -Fp -Xs -P -R -D /var/lib/postgresql/$POSTGRES_VERSION/main

# Create replication configuration file on standby server
sudo tee /var/lib/postgresql/$POSTGRES_VERSION/main/recovery.conf <<EOF
standby_mode = 'on'
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$STANDBY_USER password=$STANDBY_PWD'
trigger_file = '/var/lib/postgresql/$POSTGRES_VERSION/main/failover.trigger'
EOF

# Change ownership of standby server data directory to postgres
sudo chown -R postgres:postgres /var/lib/postgresql/$POSTGRES_VERSION/main

# Restart Postgres server
sudo systemctl restart postgresql-$POSTGRES_VERSION
