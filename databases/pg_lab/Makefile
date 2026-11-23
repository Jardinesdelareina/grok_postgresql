SHELL := /bin/bash
COMPOSE := docker compose -f compose/docker-compose.yml --env-file .env

.PHONY: setup up down reset psql pgb verify load logs stats

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
	@echo "  PgBouncer:   localhost:6432  (используйте это для приложений)"
#	@echo "  MinIO:       http://localhost:9001  (minioadmin/minioadmin)"
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