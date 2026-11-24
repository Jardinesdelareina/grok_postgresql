SHELL := /bin/bash
COMPOSE := docker compose -f compose/docker-compose.yml --env-file .env

# Текущий primary через HAProxy (клиентская точка входа)
PRIMARY_URL := postgresql://postgres:$${POSTGRES_PASSWORD:-postgres}@localhost:5000/shop

# Утилита: имя живого контейнера для patronictl (любая нода, читает etcd)
PATRONI_CTL := $(shell \
  for n in pg1 pg2 pg3; do \
    if docker exec pg-lab-$$n patronictl -c /etc/patroni/patroni.yml list >/dev/null 2>&1; then \
      echo pg-lab-$$n; break; \
    fi; \
  done)

# Утилита: имя текущего лидера (Member из patronictl list)
LEADER := $(shell \
  docker exec $(PATRONI_CTL) patronictl -c /etc/patroni/patroni.yml list 2>/dev/null \
  | awk '/Leader/ {print $$2; exit}')
.PHONY: setup build init-perms up etcd-reset reset psql pgb verify load logs stats \
        backup-now verify-backup restore-to-point drop-for-pitr \
        start-restore-check stop-restore-check \
        ha-status ha-failover ha-switchover ha-restart

setup:
	@test -f .env || cp .env.example .env
	@chmod +x app/load/load.sh config/patroni/post_bootstrap.sh 2>/dev/null || true
	@echo "OK: .env готов, скрипты исполняемые"

build:
	$(COMPOSE) build pg1

init-perms: build
	@for v in pg-lab_pg1data pg-lab_pg2data pg-lab_pg3data; do \
	  if [ "$$(docker run --rm -u postgres -v $$v:/home/postgres/pgdata pg-lab/postgres:16-pgbackrest stat -c '%U' /home/postgres/pgdata 2>/dev/null)" != "postgres" ]; then \
	    echo "chown $$v ..."; \
	    docker run --rm -u root -v $$v:/home/postgres/pgdata pg-lab/postgres:16-pgbackrest \
	      chown -R postgres:postgres /home/postgres/pgdata || exit 1; \
	  else \
	    echo "$$v: уже postgres, пропускаю"; \
	  fi; \
	done

up: setup build init-perms
	$(COMPOSE) up -d
	@echo "Ждём готовности кластера (таймаут 120с)..."
	@for i in $$(seq 1 60); do \
	  if docker exec pg-lab-pg1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -q Leader; then \
	    echo "Кластер поднят"; break; \
	  fi; \
	  sleep 2; \
	done
	@docker exec pg-lab-pg1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || echo "!!! Leader не появился — смотрите docker logs pg-lab-pg1"

etcd-reset:
	@echo "Очистка ключей Patroni в etcd..."
	docker exec pg-lab-etcd etcdctl del --prefix /pg-lab/ || true

reset: down etcd-reset init-perms
	$(COMPOSE) up -d
	@echo "Ждём готовности кластера (таймаут 120с)..."
	@for i in $$(seq 1 60); do \
	  if docker exec pg-lab-pg1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null | grep -q Leader; then \
	    echo "Кластер сброшен."; break; \
	  fi; \
	  sleep 2; \
	done
	@docker exec pg-lab-pg1 patronictl -c /etc/patroni/patroni.yml list 2>/dev/null || echo "!!! Leader не появился"

psql:
	docker exec -it pg-lab-pg1 psql -U postgres -d shop

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

backup-now:
	@test -n "$(LEADER)" || (echo "Не могу определить leader. Проверьте make ha-status"; exit 1)
	@echo "Leader: $(LEADER)"
	docker exec -u postgres pg-lab-$(LEADER) pgbackrest --stanza=pg-lab stanza-create
	docker exec -u postgres pg-lab-$(LEADER) pgbackrest --stanza=pg-lab check
	docker exec -u postgres pg-lab-$(LEADER) pgbackrest --stanza=pg-lab backup --type=full

verify-backup:
	@test -n "$(LEADER)" || (echo "Не могу определить leader. Проверьте make ha-status"; exit 1)
	docker exec -u postgres pg-lab-$(LEADER) pgbackrest --stanza=pg-lab info
	docker exec -u postgres pg-lab-$(LEADER) pgbackrest --stanza=pg-lab check

drop-for-pitr:
	psql "$(PRIMARY_URL)" -c "drop table if exists customers cascade;"


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

ha-status:
	docker exec $(PATRONI_CTL) patronictl -c /etc/patroni/patroni.yml list

ha-failover:
	docker exec $(PATRONI_CTL) patronictl -c /etc/patroni/patroni.yml failover --force

ha-switchover:
	@test -n "$(TO)" || (echo "Usage: make ha-switchover TO=pg2"; exit 1)
	@test -n "$(LEADER)" || (echo "Не могу определить лидера. Проверьте make ha-status"; exit 1)
	docker exec $(PATRONI_CTL) patronictl -c /etc/patroni/patroni.yml switchover --leader $(LEADER) --candidate $(TO) --force

ha-restart:
	docker exec $(PATRONI_CTL) patronictl -c /etc/patroni/patroni.yml restart pg-lab --force