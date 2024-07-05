#!/bin/bash

cd /home/fueros/grok_postgresql/databases/test_db
sudo touch copy_test_db.csv
chmod +x /home/fueros/grok_postgresql/databases/test_db/copy_test_db.csv
sudo chown -R postgres:postgres /home/fueros/grok_postgresql/databases/test_db/copy_test_db.csv
psql -U postgres -f test_db.sql

sudo rm copy_test_db.csv

# pg_dump
pg_dump -U postgres -f test_dump.sql test_db

# Восстановление дампа
sudo -u postgres psql -d test_db_2 -f test_dump.sql

# pg_dampall
pg_dumpall -U postgres -f test_dumpall.sql

# Восстановление кластера
sudo -u postgres psql -f test_dumpall.sql postgres