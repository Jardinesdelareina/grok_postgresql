#!/bin/bash
set -euo pipefail

echo "[post_bootstrap] start"

# Ждём, пока PostgreSQL поднимется (Patroni запускает его после initdb)
until pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; do
  echo "[post_bootstrap] waiting for postgres..."
  sleep 1
done

# Применяем все *.sql из /seed в алфавитном порядке
for f in $(ls /seed/*.sql | sort); do
  echo "[post_bootstrap] applying $f"
  psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -f "$f"
done

echo "[post_bootstrap] done"