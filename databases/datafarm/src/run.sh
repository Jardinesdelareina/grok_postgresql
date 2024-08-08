#!/bin/bash

cd /home/fueros/grok_postgresql/databases/datafarm/src/data && psql -U postgres -f init.sql
cd /home/fueros/grok_postgresql/databases/datafarm/src/etl && python3 main.py