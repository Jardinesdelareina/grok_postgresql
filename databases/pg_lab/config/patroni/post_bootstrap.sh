#!/bin/bash
set -euo pipefail

echo "[post_bootstrap] start"

echo "[post_bootstrap] creating pgBackRest stanza"
pgbackrest --stanza=pg-lab stanza-create || true

until pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; do
  echo "[post_bootstrap] waiting for postgres..."
  sleep 1
done

echo "[post_bootstrap] applying /seed/init.sql"
psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -f /seed/init.sql

echo "[post_bootstrap] done"