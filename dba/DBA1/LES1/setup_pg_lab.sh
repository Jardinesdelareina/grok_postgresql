#!/usr/bin/env bash
# Поднимает контейнер Ubuntu 22.04 + PostgreSQL 16 (PGDG) и создаёт кластер через initdb.
# По завершении сервер ОСТАНОВЛЕН — дальше ты сам вводишь pg_ctl и pg_checksums.
set -euo pipefail

CONTAINER=pg-lab
HOST_PORT=5433
PG_VER=16
PG_BIN=/usr/lib/postgresql/${PG_VER}/bin

echo "=== 1. Пересоздаём контейнер ${CONTAINER} ==="
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" -p ${HOST_PORT}:${HOST_PORT} ubuntu:22.04 sleep infinity

echo "=== 2. Ставим PostgreSQL ${PG_VER} из PGDG (неинтерактивно) ==="
docker exec -e DEBIAN_FRONTEND=noninteractive "$CONTAINER" bash -c '
set -e
# Фиксируем UTC, чтобы tzdata не спрашивал интерактивно
ln -fs /usr/share/zoneinfo/UTC /etc/localtime
apt-get update
apt-get install -y --no-install-recommends \
  wget gnupg lsb-release ca-certificates sudo vim less procps tzdata

# Подключаем репозиторий PGDG (в Ubuntu 22.04 нет postgresql-16 в стандартных репах)
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt-get update
apt-get install -y --no-install-recommends postgresql-16 postgresql-client-16
'

echo "=== 3. Создаём пользователя ОС postgres и каталог кластера ==="
docker exec "$CONTAINER" bash -c '
set -e
id postgres >/dev/null 2>&1 || useradd -m -s /bin/bash postgres
mkdir -p /home/postgres/pg_data
chown -R postgres:postgres /home/postgres
'

echo "=== 4. initdb БЕЗ контрольных сумм (включим потом через pg_checksums) ==="
docker exec -u postgres "$CONTAINER" bash -c '
set -e
export PATH='"$PG_BIN"':$PATH
initdb -D $HOME/pg_data -U postgres --locale=C --encoding=UTF8
# Порт 5433 и listen_addresses, чтобы попасть в проброс
cat >> $HOME/pg_data/postgresql.conf <<EOF
port = '"$HOST_PORT"'
listen_addresses = '\''localhost'\''
EOF
'

echo
echo "=== Готово. Сервер ОСТАНОВЛЕН. ==="
echo
echo "Зайди в контейнер:"
echo "  docker exec -it $CONTAINER bash"
echo
echo "Дальше — от пользователя postgres (внутри контейнера):"
echo "  su - postgres"
echo "  export PATH=$PG_BIN:\$PATH"
echo "  export PGDATA=\$HOME/pg_data"
echo
echo "Команды для отработки:"
echo "  pg_ctl -D $PGDATA start"
echo "  pg_ctl -D $PGDATA status"
echo "  pg_ctl -D $PGDATA restart -m fast"
echo "  pg_ctl -D $PGDATA stop -m fast"
echo "  pg_checksums -D $PGDATA --check"
echo "  pg_checksums -D $PGDATA --enable"
echo "  psql -h localhost -p $HOST_PORT -U postgres -c 'SHOW data_checksums;'"