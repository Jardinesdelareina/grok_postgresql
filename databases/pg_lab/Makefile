SHELL := /bin/bash
COMPOSE := docker compose -f compose/docker-compose.yml --env-file .env

PRIMARY_URL := postgresql://postgres:$${POSTGRES_PASSWORD:-postgres}@localhost:5000/shop

# ============================================================
# Утилиты: вычисляются ЛЕНИВО (при каждом вызове), не при старте make
# ============================================================

# Любая живая нода для patronictl (pg1 → pg2 → pg3)
define patroni_ctl
$$(for n in pg1 pg2 pg3; do \
  if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
    echo pg-lab-$$n; break; \
  fi; \
done)
endef

# Текущий лидер (Member из patronictl list)
define patroni_leader
$$(docker exec $(call patroni_ctl) patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | awk '/Leader/ {print $$2; exit}')
endef

.PHONY: setup build init-perms up down etcd-reset reset psql pgb verify load logs stats \
        backup-now verify-backup restore-to-point drop-for-pitr \
        start-restore-check stop-restore-check \
        ha-status ha-failover ha-switchover ha-restart

# ============================================================
# Подготовка / сборка
# ============================================================

setup:
	@test -f .env || cp .env.example .env
	@chmod +x app/load/load.sh config/patroni/post_bootstrap.sh 2>/dev/null || true
	@echo "OK: .env готов, скрипты исполняемые"

build:
	$(COMPOSE) build pg1

init-perms:
	@for v in pg-lab_pg1data pg-lab_pg2data pg-lab_pg3data; do \
	  if [ "$$(docker run --rm -u postgres -v $$v:/home/postgres/pgdata postgres:16 stat -c '%U' /home/postgres/pgdata 2>/dev/null)" != "postgres" ]; then \
	    echo "chown $$v ..."; \
	    docker run --rm -u root -v $$v:/home/postgres/pgdata postgres:16 \
	      chown -R postgres:postgres /home/postgres/pgdata || exit 1; \
	  else \
	    echo "$$v: уже postgres, пропускаю"; \
	  fi; \
	done

# ============================================================
# up / down / reset
# ============================================================

up: setup build init-perms
	$(COMPOSE) up -d
	@echo "Ждём готовности кластера (таймаут 120с)..."
	@for i in $$(seq 1 60); do \
	  CTL=$$(for n in pg1 pg2 pg3; do \
	    if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
	      echo pg-lab-$$n; break; \
	    fi; \
	  done); \
	  if [ -n "$$CTL" ] && docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -q Leader; then \
	    echo "Кластер поднят"; break; \
	  fi; \
	  sleep 2; \
	done
	@CTL=$$(for n in pg1 pg2 pg3; do \
	  if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
	    echo pg-lab-$$n; break; \
	  fi; \
	done); \
	if [ -n "$$CTL" ]; then docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list; else echo "!!! Leader не появился — смотрите docker logs pg-lab-pg1"; fi

down:
	$(COMPOSE) down

etcd-reset:
	@echo "Очистка ключей Patroni в etcd..."
	docker exec pg-lab-etcd etcdctl del --prefix /pg-lab/ || true

# ВАЖНО: reset сносит тома (-v), поднимает etcd, чистит ключи, поднимает всё
reset:
	$(COMPOSE) down -v --remove-orphans
	@docker volume rm pg-lab_pg1data pg-lab_pg2data pg-lab_pg3data pg-lab_pgdata_restore 2>/dev/null || true
	$(COMPOSE) up -d etcd
	@sleep 5
	@docker exec pg-lab-etcd etcdctl del --prefix /pg-lab/ || true
	$(MAKE) init-perms
	$(COMPOSE) up -d
	@echo "Ждём готовности кластера (таймаут 120с)..."
	@for i in $$(seq 1 60); do \
	  CTL=$$(for n in pg1 pg2 pg3; do \
	    if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
	      echo pg-lab-$$n; break; \
	    fi; \
	  done); \
	  if [ -n "$$CTL" ] && docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -q Leader; then \
	    echo "Кластер сброшен."; break; \
	  fi; \
	  sleep 2; \
	done
	@CTL=$$(for n in pg1 pg2 pg3; do \
	  if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
	    echo pg-lab-$$n; break; \
	  fi; \
	done); \
	if [ -n "$$CTL" ]; then docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list; else echo "!!! Leader не появился"; fi

# ============================================================
# Клиентские команды (через HAProxy / динамический лидер)
# ============================================================

psql:
	@LEADER=$(call patroni_leader); \
	test -n "$$LEADER" || (echo "Нет лидера. Проверьте make ha-status"; exit 1); \
	echo "Leader: $$LEADER"; \
	docker exec -it pg-lab-$$LEADER psql -U postgres -d shop

pgb:
	psql "$(PRIMARY_URL)"

verify:
	@echo "== containers =="; docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'pg-lab|NAMES'
	@echo "== HAProxy primary =="; psql "$(PRIMARY_URL)" -c "select pg_is_in_recovery() as in_recovery, inet_server_addr() as node;" 2>&1 || true
	@echo "== top tables by size =="; psql "$(PRIMARY_URL)" -c "select relname, pg_size_pretty(pg_total_relation_size(relid)) as size from pg_catalog.pg_statio_user_tables order by pg_total_relation_size(relid) desc limit 5;" 2>&1 || true
	@echo "== slowest queries =="; psql "$(PRIMARY_URL)" -c "select round(total_exec_time::numeric,1) as ms, calls, left(query,80) as query from pg_stat_statements order by total_exec_time desc limit 5;" 2>&1 || true

load:
	PRIMARY_URL="$(PRIMARY_URL)" ./app/load/load.sh 60

stats:
	psql "$(PRIMARY_URL)" -c "select relname, n_live_tup, n_dead_tup, last_autovacuum from pg_stat_user_tables order by n_dead_tup desc limit 10;"

logs:
	$(COMPOSE) logs -f --tail=100

# ============================================================
# Бэкапы: на текущем лидере (вычисляется в рецепте)
# ============================================================

backup-now:
	@LEADER=$(call patroni_leader); \
	test -n "$$LEADER" || (echo "Нет лидера"; exit 1); \
	echo "Leader: $$LEADER"; \
	docker exec -u postgres pg-lab-$$LEADER pgbackrest --stanza=pg-lab stanza-create; \
	docker exec -u postgres pg-lab-$$LEADER pgbackrest --stanza=pg-lab check; \
	docker exec -u postgres pg-lab-$$LEADER pgbackrest --stanza=pg-lab backup --type=full

verify-backup:
	@LEADER=$(call patroni_leader); \
	test -n "$$LEADER" || (echo "Нет лидера. Проверьте make ha-status"; exit 1); \
	echo "Leader: $$LEADER"; \
	docker exec -u postgres pg-lab-$$LEADER pgbackrest --stanza=pg-lab info; \
	docker exec -u postgres pg-lab-$$LEADER pgbackrest --stanza=pg-lab check

drop-for-pitr:
	psql "$(PRIMARY_URL)" -c "drop table if exists customers cascade;"

# ============================================================
# PITR: restore в отдельный том (не зависит от лидера)
# ============================================================

restore-to-point:
	@test -n "$(T)" || (echo "Usage: make restore-to-point T='2026-11-27 20:41:17'"; exit 1)
	-docker rm -f pg-lab-postgres-restore 2>/dev/null || true
	-docker volume rm pg-lab_pgdata_restore 2>/dev/null || true
	docker volume create pg-lab_pgdata_restore
	@docker run --rm -u root -v pg-lab_pgdata_restore:/home/postgres/pgdata postgres:16 \
	  chown -R postgres:postgres /home/postgres/pgdata
	docker run --rm \
	  --network pg-lab_default \
	  -u postgres \
	  -v pg-lab_pgdata_restore:/home/postgres/pgdata \
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
	  -v pg-lab_pgdata_restore:/home/postgres/pgdata \
	  -v pg-lab_pgbackrest_spool:/var/spool/pgbackrest \
	  -v $(PWD)/config/pgbackrest/pgbackrest.conf:/etc/pgbackrest/pgbackrest.conf:ro \
	  -v $(PWD)/config/postgres/postgresql.conf:/etc/postgresql/postgresql.conf:ro \
	  -v $(PWD)/config/postgres/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro \
	  -p 5433:5432 \
	  pg-lab/postgres:16-pgbackrest \
	  postgres -D /home/postgres/pgdata/data -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf

stop-restore-check:
	docker rm -f pg-lab-postgres-restore 2>/dev/null || true

# ============================================================
# HA: любые команды через живую ноду (patronictl читает etcd)
# ============================================================

ha-status:
	@CTL=$(call patroni_ctl); \
	if [ -z "$$CTL" ]; then echo "Нет живой ноды. Проверьте docker ps"; exit 1; fi; \
	docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list

ha-failover:
	@CTL=$(call patroni_ctl); \
	if [ -z "$$CTL" ]; then echo "Нет живой ноды"; exit 1; fi; \
	docker exec $$CTL patronictl -c /etc/patroni/patroni.yml failover --force

ha-switchover:
	@test -n "$(TO)" || (echo "Usage: make ha-switchover TO=pg2"; exit 1)
	@CTL=$(call patroni_ctl); \
	LEADER=$$(docker exec $$CTL patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | awk '/Leader/ {print $$2; exit}'); \
	if [ -z "$$LEADER" ]; then echo "Нет лидера"; exit 1; fi; \
	echo "Leader: $$LEADER → candidate: $(TO)"; \
	docker exec $$CTL patronictl -c /etc/patroni/patroni.yml switchover --leader $$LEADER --candidate $(TO) --force

ha-restart:
	@CTL=$(call patroni_ctl); \
	if [ -z "$$CTL" ]; then echo "Нет живой ноды"; exit 1; fi; \
	docker exec $$CTL patronictl -c /etc/patroni/patroni.yml restart pg-lab --force