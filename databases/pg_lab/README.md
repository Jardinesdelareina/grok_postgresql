# pg-lab — production-like стенд PostgreSQL для обучения DBA

## Запуск (Windows 11 + Docker Desktop + WSL2)
1. Скопировать `.env.example` в `.env` (или `make setup`)
2. `make up` — поднять кластер (Patroni выберет лидера, `post_bootstrap` накатит seed)
3. `make ha-status` — проверить роли (Leader / Replica, lag)
4. `make load` — дать нагрузку 60 секунд (через PgBouncer → HAProxy → primary)
5. Grafana: http://localhost:3000 (admin/admin) -> datasource Prometheus http://prometheus:9090 -> дашборд ID 9628

## Что есть сейчас (v0.3)

### HA-кластер
- **3 ноды PostgreSQL** (`pg1`, `pg2`, `pg3`) под управлением **Patroni 4.1.5**
- **etcd 3.5** — DCS (distributed configuration store), где Patroni хранит состояние
- **HAProxy 2.9** — точка входа: `:5000` → primary, `:5001` → standby (healthcheck на Patroni REST API)
- **Streaming replication** (`use_pg_rewind: true`, `use_slots: true`)
- **Автоматический failover** при падении лидера (TTL 30 с)
- **Плановый switchover** через `patronictl switchover`

### Точки входа
- **HAProxy primary** — `localhost:5000` (запись)
- **HAProxy standby** — `localhost:5001` (чтение)
- **PgBouncer** — `localhost:6432` → HAProxy → primary (transaction pooling)
- **Patroni REST API** — `localhost:8008` (pg1), `:8009` (pg2), `:8010` (pg3)

### Бэкапы (из v0.2)
- **pgBackRest 2.60** на каждой ноде (в образе `pg-lab/postgres:16-pgbackrest`)
- **LocalStack S3** + бакет `pgbackrest`
- **Full backup + WAL-архив** (`archive-push` через Patroni)
- **PITR** (restore в отдельный том, не поверх живого primary)

### Seed
- **`bootstrap.post_bootstrap`** — SQL-скрипты из `app/seed/` накатываются **автоматически** при bootstrap кластера (только на лидере, один раз)
- `00_create_db.sql` → `01_schema.sql` → `02_data.sql` (по алфавиту)
- Имя БД — `SEED_DB` в `docker-compose.yml` (единственное место)
- Меняете SQL — меняется то, что накатывается при следующем `make reset`

### Мониторинг
- **Prometheus + postgres_exporter + Grafana**
- Exporter смотрит на primary через HAProxy (`haproxy:5000`)

### Makefile
`setup/init-perms/build/up/down/reset/verify/load/stats/psql/pgb/logs/backup-now/verify-backup/restore-to-point/start-restore-check/stop-restore-check/ha-status/ha-failover/ha-switchover/ha-restart`

## Этапы
- [x] v0.1: 1 нода, PgBouncer, мониторинг, нагрузка
- [x] v0.2: pgBackRest + LocalStack S3 + WAL-архив + PITR
- [x] v0.3: etcd + Patroni (3 ноды) + HAProxy + failover/switchover + seed через `post_bootstrap`
- [ ] v0.4: Alertmanager + алерты (lag, connections, WAL, bloat, long tx) + синхронная репликация
- [ ] v0.5: Ansible-роль (поднять с нуля) + `make up` из IaC
- [ ] v0.6: k8s (CloudNativePG/Zalando)

## Полезные команды диагностики

### HA-кластер
- `make ha-status` — таблица Member/Role/State/TL/Lag (Leader + 2 Replica)
- `make ha-failover` — принудительный failover (аварийный)
- `make ha-switchover TO=pg2` — плановое переключение на `pg2` (`--candidate` подставляется, `--leader` — текущий)
- `make ha-restart` — `patronictl restart pg-lab` (перезапуск PostgreSQL на всех нодах)
- `psql "postgresql://postgres:postgres@localhost:5000/shop" -c "select pg_is_in_recovery();"` → `f` (primary)
- `psql "postgresql://postgres:postgres@localhost:5001/shop" -c "select pg_is_in_recovery();"` → `t` (replica)

### Seed и БД
- Seed применяется автоматически при bootstrap (`post_bootstrap`). Для «накатить поверх» — `make reset` (снести тома) или ручной `psql -f`.
- `docker logs pg-lab-pg1 --tail=50 | grep post_bootstrap` — проверить, что seed применился

### Клиенты
- `make psql` — в контейнер PostgreSQL (на `pg1`; для лидера — `docker exec pg-lab-$(LEADER) psql`)
- `make pgb` — через PgBouncer (`:6432`, как приложение)
- `make load` — нагрузка 60 с через PgBouncer → HAProxy → primary
- `make stats` — bloat/autovacuum по таблицам
- `make verify` — контейнеры, размеры, топ медленных запросов (через HAProxy)

### Бэкапы
- `make backup-now` — stanza-create + check + full backup **на текущем лидере** (динамически через `LEADER`)
- `make verify-backup` — `info` + `check`
- `make restore-to-point T='YYYY-MM-DD HH:MM:SS+00'` — PITR в отдельный том `pgdata_restore`
- `make start-restore-check` / `make stop-restore-check` — проверочный инстанс на `5433`

## Grafana
http://localhost:3000 (admin / admin)
Connections -> Data sources -> Add -> Prometheus -> URL `http://prometheus:9090` -> Save & test
Dashboards -> Import -> ID 9628 -> datasource Prometheus -> Import

## Ключевые решения и trade-off

### HA (v0.3)
- **Patroni = PID 1** (`entrypoint: /bin/bash -c`, `command: exec patroni /etc/patroni/patroni.yml`), `user: postgres`. Entrypoint `postgres` **не участвует** — Patroni сам делает `initdb`.
- **Один путь в контейнере** (`/etc/patroni/patroni.yml`), **разные файлы снаружи** (`patroni-pg1.yml`, `patroni-pg2.yml`, `patroni-pg3.yml`). `command` у всех одинаковый, mount — разный.
- **`etcd3:`** (v3 API), не `etcd:` (v2). etcd 3.5 **удалил** v2 — `etcd:` даёт `404` и `Can not find suitable configuration`.
- **`restapi.listen: 0.0.0.0:8008`** у всех трёх (внутри контейнера), наружу — `8008`/`8009`/`8010`. HAProxy healthcheck на `pgN:8008`.
- **Лидер — кто первым захватил ключ в etcd** (CAS), не «pg1 по умолчанию». Makefile определяет `LEADER` динамически.
- **`init-perms`** — `chown -R postgres:postgres` на тома (named volume создаётся от root, Patroni от postgres). Без этого `initdb: Permission denied`.
- **Чистка etcd** (`etcdctl del --prefix /pg-lab/`) — если bootstrap «застрял» на `waiting for leader`. Ключи от прошлых попыток блокируют новый bootstrap.
- **`data_dir` должен быть пуст** для bootstrap. Остатки (`rm -rf /home/postgres/pgdata/data`) блокируют `initdb`.

### Seed (v0.3)
- **`bootstrap.post_bootstrap`** — выполняется **только на лидере**, который делал bootstrap, **один раз**. При restart/failover/switchover **не** повторяется.
- **Все SQL-объекты — в `app/seed/*.sql`**, никаких `CREATE DATABASE`/`CREATE TABLE` в `patroni.yml` или `post_bootstrap.sh`.
- **`00_create_db.sql`** — создание БД (`\gexec` + `\c shop`), **`01_schema.sql`** — схема, **`02_data.sql`** — данные.
- **Идемпотентность** (`IF NOT EXISTS`, `ON CONFLICT`) — страховка на случай повторного bootstrap.
- **`chmod +x` в `Makefile` (`setup`)** — скрипт монтируется `:ro`, права сохраняются, но `setup` гарантирует.

### Бэкапы (v0.2)
- **`repo1-s3-uri-style=path`** — LocalStack/MinIO не резолвят `<bucket>.host`, нужен path-style. В AWS — virtual-hosted-style (по умолчанию).
- **`repo1-s3-endpoint=http://...`** — схема обязательна, иначе pgBackRest предполагает HTTPS и падает на проверке сертификата (`[095]`).
- **`archive_timeout=60s`** — WAL архивируется не реже раза в минуту, иначе PITR «отстаёт» при низкой нагрузке. На проде 60–300 с.
- **Restore в отдельный том** (`pgdata_restore`, порт `5433`) — не поверх живого primary. В проде: restore → проверка → переключение трафика.
- **`-u postgres` в `docker exec`** — pgBackRest запрещает root (создаст файлы, недоступные `postgres`).
- **Проверочный контейнер должен монтировать `pgbackrest.conf`** — иначе `archive-get` не знает `pg1-path` и recovery падает.

### PgBouncer (v0.1)
- **Transaction pooling** — ломает `SET` на сессию, prepared statements, advisory locks. Плюс: масштабирование соединений. Минус: часть приложений требует session pooling.
- **PgBouncer → HAProxy** (`haproxy:5000`), не на конкретную ноду — при failover пулер не нужно перенастраивать.

## Типовые проблемы и фикс (v0.3)

| Симптом | Причина | Фикс |
|---|---|---|
| `pull access denied for pg-lab/postgres` | образ удалён, `init-perms` до `build` | `make build` перед `make up`, или `init-perms: build` в Makefile |
| `port is already allocated` на 5432 | локальный PostgreSQL Windows | остановить службу (`Stop-Service postgresql-x64-16`) или сменить порт на `55432` |
| `Can not find suitable configuration` | `etcd:` вместо `etcd3:` / CRLF / `command` на несуществующий файл | `etcd3:` в `patroni-pgN.yml`; `sed -i 's/\r$//'`; `command: patroni /etc/patroni/patroni.yml` у всех трёх |
| `initdb: Permission denied` | том принадлежит root | `make init-perms` (chown) |
| `waiting for leader to bootstrap` | `data_dir` не пуст / etcd «помнит» bootstrap | `rm -rf /home/postgres/pgdata/data`; `etcdctl del --prefix /pg-lab/` |
| HAProxy `Exited (1)`, `Missing LF on last line` | нет `\n` в конце `haproxy.cfg` | `printf '\n' >> config/haproxy/haproxy.cfg` |
| `connection refused` на 5000/5001 | HAProxy мёртв | `docker logs pg-lab-haproxy`, фикс конфига, `restart haproxy` |
| `database "shop" does not exist` | seed не применён (entrypoint убран) | `post_bootstrap` в `patroni.yml` + `chmod +x` в `setup` |
| `switchover --leader pg3`: `Member X is not the leader` | `--leader` — это текущий, не цель | `--leader $(LEADER) --candidate $(TO)` (в Makefile) |
| `patronictl` на `pg1` падает после failover | `pg1` остановлен | `PATRONI_CTL` (любая живая нода) в Makefile |


```
cd /mnt/d/grok_postgresql/databases/pg_lab

# 4.1
curl -s http://localhost:9090/api/v1/rules | python3 -m json.tool | grep -E '"name"|"state"' | head -30
docker stop pg-lab-pg1 pg-lab-pg2 pg-lab-pg3
sleep 90
curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool | grep alertname
docker start pg-lab-pg1 pg-lab-pg2 pg-lab-pg3
sleep 90

# 4.2
docker exec pg-lab-pg1 patronictl -c /etc/patroni/patroni.yml edit-config
# synchronous_mode: on, synchronous_mode_strict: true
make ha-status
docker exec pg-lab-pg2 psql -U postgres -c "show synchronous_standby_names;"   # "pg1" или "pg3"
psql "postgresql://postgres:postgres@localhost:5000/shop" -c "insert into customers(email) values ('sync-ok@example.com');"

# 4.2 strict-тест
docker stop pg-lab-pg1 pg-lab-pg3   # НЕ лидера
sleep 10
timeout 5 psql "postgresql://postgres:postgres@localhost:5000/shop" -c "insert into customers(email) values ('blocked@example.com');"   # timeout
docker start pg-lab-pg1 pg-lab-pg3
sleep 25

# 4.3
make ha-status
make backup-now
make verify-backup
date -u   # T0
psql "postgresql://postgres:postgres@localhost:5000/shop" -c "select count(*) from customers;"   # N
psql "postgresql://postgres:postgres@localhost:5000/shop" -c "drop table customers cascade;"
sleep 120
make restore-to-point T='<T0>'
make start-restore-check
sleep 10
psql "postgresql://postgres:postgres@localhost:5433/shop" -c "select count(*) from customers;"   # N
make stop-restore-check
```