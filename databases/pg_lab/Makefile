SHELL := /bin/bash
COMPOSE := docker compose -f compose/docker-compose.yml --env-file .env

.PHONY: setup up down reset psql pgb verify load logs stats backup-now verify-backup restore-to-point restart-postgres drop-for-pitr

setup:
	@test -f .env || cp .env.example .env
	@chmod +x app/load/load.sh backup/scripts/*.sh 2>/dev/null || true
	@echo "OK: .env готов, скрипты исполняемые"

up: setup
	$(COMPOSE) up -d
	@echo "Ждём готовности PostgreSQL..."
	@until docker exec pg-lab-postgres pg_isready -U postgres -d shop >/dev/null 2>&1; do sleep 1; done
	@echo "Стенд поднят"
	@echo "  PostgreSQL:  localhost:5432"
	@echo "  PgBouncer:   localhost:6432"
	@echo "  Grafana:     http://localhost:3000  (admin/admin)"
	@echo "  Prometheus:  http://localhost:9090"
	@echo "  Exporter:    http://localhost:9187/metrics"

down:
	$(COMPOSE) down

reset:
	$(COMPOSE) down -v
	$(COMPOSE) up -d
	@until docker exec pg-lab-postgres pg_isready -U postgres -d shop >/dev/null 2>&1; do sleep 1; done
	@echo "Стенд сброшен в чистое состояние"

psql:
	docker exec -it pg-lab-postgres psql -U postgres -d shop

pgb:
	psql "postgresql://postgres:$${POSTGRES_PASSWORD:-postgres}@localhost:6432/shop"

verify:
	@echo "== containers =="; docker ps --format 'table {{.Names}}\t{{.Status}}'
	@echo "== pg_isready =="; docker exec pg-lab-postgres pg_isready -U postgres -d shop
	@echo "== top tables by size =="; docker exec pg-lab-postgres psql -U postgres -d shop -c "select relname, pg_size_pretty(pg_total_relation_size(relid)) as size from pg_catalog.pg_statio_user_tables order by pg_total_relation_size(relid) desc limit 5;"
	@echo "== slowest queries (pg_stat_statements) =="; docker exec pg-lab-postgres psql -U postgres -d shop -c "select round(total_exec_time::numeric, 1) as ms, calls, left(query, 80) as query from pg_stat_statements order by total_exec_time desc limit 5;"

load:
	./app/load/load.sh 60

stats:
	docker exec pg-lab-postgres psql -U postgres -d shop -c "select relname, n_live_tup, n_dead_tup, last_autovacuum from pg_stat_user_tables order by n_dead_tup desc limit 10;"

logs:
	$(COMPOSE) logs -f --tail=100

backup-now:
	docker exec -u postgres pg-lab-postgres pgbackrest --stanza=pg-lab stanza-create
	docker exec -u postgres pg-lab-postgres pgbackrest --stanza=pg-lab check
	docker exec -u postgres pg-lab-postgres pgbackrest --stanza=pg-lab backup --type=full

verify-backup:
	docker exec -u postgres pg-lab-postgres pgbackrest --stanza=pg-lab info
	docker exec -u postgres pg-lab-postgres pgbackrest --stanza=pg-lab check

drop-for-pitr:
	docker exec pg-lab-postgres psql -U postgres -d shop -c "drop table if exists customers cascade;"

restore-to-point:
	@test -n "$(T)" || (echo "Usage: make restore-to-point T='2026-11-24 06:56:48+00'"; exit 1)
	docker volume create pg-lab_pgdata_restore
	docker run --rm \
	  --network pg-lab_default \
	  -u postgres \
	  -v pg-lab_pgdata_restore:/var/lib/postgresql/data \
	  -v pg-lab_pgbackrest_spool:/var/spool/pgbackrest \
	  -v $(PWD)/config/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf:ro \
	  pg-lab/postgres:16-pgbackrest \
	  pgbackrest --stanza=pg-lab --type=time --target="$(T)" --target-action=promote restore
	@echo "Restore done into volume pg-lab_pgdata_restore."
	@echo "Запустите проверочный инстанс: make start-restore-check"

start-restore-check:
	docker run -d --name pg-lab-postgres-restore \
	  --network pg-lab_default \
	  -e POSTGRES_PASSWORD=$${POSTGRES_PASSWORD:-postgres} \
	  -v pg-lab_pgdata_restore:/var/lib/postgresql/data \
	  -v pg-lab_pgbackrest_spool:/var/spool/pgbackrest \
	  -v $(PWD)/config/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf:ro \
	  -v $(PWD)/config/postgres/postgresql.conf:/etc/postgresql/postgresql.conf:ro \
	  -v $(PWD)/config/postgres/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro \
	  -p 5433:5432 \
	  pg-lab/postgres:16-pgbackrest \
	  postgres -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf

stop-restore-check:
	docker rm -f pg-lab-postgres-restore || true