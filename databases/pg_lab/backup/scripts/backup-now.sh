#!/usr/bin/env bash
set -euo pipefail
export PGBACKREST_CONFIG=/etc/pgbackrest/pgbackrest.conf
pgbackrest --stanza=pg-lab stanza-create --log-level-console=info 2>/dev/null || true
pgbackrest --stanza=pg-lab check
pgbackrest --stanza=pg-lab backup --type=full --log-level-console=info
pgbackrest --stanza=pg-lab info