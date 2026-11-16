#!/bin/bash

set -e

service ssh start

if command -v pg_ctlcluster >/dev/null 2>&1; then
  pg_ctlcluster 16 main start || true
fi

exec tail -f /dev/null