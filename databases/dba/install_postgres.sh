#!/bin/bash

set -e

LSB_RELEASE="jammy"

sudo apt install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
  https://www.postgresql.org/media/keys/ACCC4CF8.asc

echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
  https://apt.postgresql.org/pub/repos/apt ${LSB_RELEASE}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt update

sudo apt install -y postgresql-16