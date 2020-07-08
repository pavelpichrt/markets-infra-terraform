#!/bin/bash
PG_PWD="$1"
pg_hba_file=/etc/postgresql/12/main/pg_hba.conf
postgres_conf_file=/etc/postgresql/12/main/postgresql.conf

echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c -s)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

sudo sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/debian/ `lsb_release -c -s` main' > /etc/apt/sources.list.d/timescaledb.list"
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
sudo apt-get update

# Now install appropriate package for PG version
sudo apt-get install -y timescaledb-postgresql-12

sudo timescaledb-tune --yes

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PG_PWD';"
sudo -u postgres psql -c "CREATE DATABASE market;"

# Allow remote connections
echo "host    all             all              0.0.0.0/0              md5" >> "$pg_hba_file"
echo "host    all             all              ::/0                   md5" >> "$pg_hba_file"

echo "listen_addresses = '*'" >> "$postgres_conf_file"

service postgresql restart

# Create a schema
sudo chmod 0777 /home/admin/ddl.sql
sudo -u postgres psql -d market -f /home/admin/ddl.sql
