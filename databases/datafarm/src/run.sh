#!/bin/bash

cd /home/fueros/grok_postgresql/databases/datafarm/src && psql -U postgres -f init.sql
cd /home/fueros/grok_postgresql/databases/datafarm/src && python3 main.py