# pg-lab — production-like стенд PostgreSQL для обучения DBA

## Запуск (Windows 11 + Docker Desktop + WSL2)
1. Скопировать `.env.example` в `.env` (или `make setup`)
2. `make up` — поднять кластер (Patroni выберет лидера, `post_bootstrap` накатит seed)
3. `make ha-status` — проверить роли (Leader / Replica / Sync Standby, lag)
4. `make load` — нагрузка 60 с (PgBouncer → HAProxy → primary)
5. Grafana: http://localhost:3000 (admin/admin) → datasource Prometheus http://prometheus:9090 → дашборд ID 9628

## Что есть сейчас (v0.4)

### HA-кластер
- **3 ноды PostgreSQL** (`pg1`, `pg2`, `pg3`) под **Patroni 4.1.5**
- **etcd 3.5** — DCS (состояние кластера)
- **HAProxy 2.9** — `:5000` → primary, `:5001` → standby (healthcheck на Patroni REST API)
- **Streaming replication** (`use_pg_rewind`, `use_slots`)
- **Автоматический failover** (TTL 30 с), **плановый switchover** (`patronictl switchover`)
- **Синхронная репликация** (strict, RPO=0): `synchronous_mode: on` + `synchronous_mode_strict: true` в `bootstrap.dcs`

### Точки входа
- **HAProxy primary** — `localhost:5000` (запись)
- **HAProxy standby** — `localhost:5001` (чтение)
- **PgBouncer** — `localhost:6432` → HAProxy → primary (transaction pooling)
- **Patroni REST API** — `localhost:8008` (pg1), `:8009` (pg2), `:8010` (pg3)

### Наблюдаемость (v0.4)
- **Prometheus + postgres_exporter + Grafana**
- **Alertmanager** (`:9093`) — 10 правил: `PostgresDown`, `ReplicaLagHigh`, `ConnectionsHigh`, `LongRunningTransaction`, `ManyLocks`, `LowCacheHitRatio`, `FrequentCheckpoints`, `DatabaseSizeGrowing`, `HighWalGeneration`, `AlertmanagerDown`
- **UI:** `:9093/#/alerts` (алерты), `:9090/rules` (правила), `:9090/alerts` (активные), `:3000` (Grafana)
- **Тест:** `docker stop` всех трёх нод → `PostgresDown` firing через 90 с → `docker start` → inactive

### Синхронная репликация (v0.4)
- **Режим strict** (финансы): RPO=0 всегда, **простой** при падении sync-реплики
- **Patroni выбирает** sync-реплику (`Sync Standby` в `ha-status`)
- **Тест:** `docker stop` обеих реплик → `timeout 5 psql insert` → timeout → `docker start` → запись идёт
- **Три режима** (off / on+false / on+true) — в `patroni.yml` с комментариями

### Бэкапы (v0.2, проверено на кластере в v0.4)
- **pgBackRest 2.60** на каждой ноде (образ `pg-lab/postgres:16-pgbackrest`)
- **LocalStack S3** + бакет `pgbackrest`
- **Full backup + WAL-архив** (`archive-push`)
- **PITR** (restore в отдельный том `pgdata_restore`, не поверх живого primary)
- **Тест:** `make backup-now` → `T0` → `drop table` → `sleep 120` → `pgbackrest info` (WAL есть) → `restore-to-point T0` → `start-restore-check` → `count = N` → `stop-restore-check`

### Seed
- **`bootstrap.post_bootstrap`** — SQL из `app/seed/init.sql` (один файл) накатывается **автоматически** при bootstrap (только на лидере, один раз)
- **`init.sql`** — создание `shop` + `\c shop` + схема + данные (один `psql`, `\c` работает для всего файла)
- Меняете SQL — меняется то, что накатывается при следующем `make reset`

### Makefile (динамический лидер)
`setup/init-perms/build/up/down/reset/etcd-reset/verify/load/stats/psql/pgb/logs/backup-now/verify-backup/restore-to-point/drop-for-pitr/start-restore-check/stop-restore-check/ha-status/ha-failover/ha-switchover/ha-restart`
- **`PATRONI_CTL`** / **`LEADER`** — **ленивые** (`define` + `$(call ...)`), **не** **при** **старте** `make` — **лидер** **может** **смениться**
- **`psql`**, **`backup-now`**, **`verify-backup`**, **`ha-*`** — **на** **текущем** **лидере** (**динамически**)
- **`restore-to-point`** — **чистый** **том** (`docker rm -f` + `volume rm` + `chown` + `restore`)
- **`reset`** — `down -v` + `volume rm` + `up etcd` + `etcdctl del` + **`init-perms`** + `up -d` + **ждать** `Leader`

## Этапы
- [x] v0.1: 1 нода, PgBouncer, мониторинг, нагрузка
- [x] v0.2: pgBackRest + LocalStack S3 + WAL-архив + PITR
- [x] v0.3: etcd + Patroni (3 ноды) + HAProxy + failover/switchover + seed через `post_bootstrap`
- [x] v0.4: Alertmanager + 10 алертов + sync replication (strict) + PITR на кластере
- [ ] v0.5: Ansible-роль (поднять с нуля) + `make up` из IaC
- [ ] v0.6: k8s (CloudNativePG/Zalando)

## Полезные команды диагностики

### HA-кластер
- `make ha-status` — Member/Role/State/TL/Lag (Leader + Replica + Sync Standby)
- `make ha-failover` — принудительный failover (аварийный)
- `make ha-switchover TO=pg2` — плановое переключение (`--leader` = текущий, `--candidate` = `TO`)
- `make ha-restart` — `patronictl restart pg-lab`
- `psql ...:5000 -c "select pg_is_in_recovery();"` → `f` (primary)
- `psql ...:5001 -c "select pg_is_in_recovery();"` → `t` (replica)

### Seed и БД
- Seed — автоматически при bootstrap (`post_bootstrap`). Для «накатить поверх» — `make reset` (снести тома) или ручной `psql -f`.
- `docker logs pg-lab-pg1 --tail=50 | grep post_bootstrap` — проверить, что seed применился

### Клиенты
- `make psql` — в контейнер **текущего лидера** (динамически)
- `make pgb` — через PgBouncer (`:6432`)
- `make load` — 60 с через PgBouncer → HAProxy → primary
- `make stats` — bloat/autovacuum
- `make verify` — контейнеры, размеры, топ медленных запросов (через HAProxy)

### Бэкапы / PITR
- `make backup-now` — stanza-create + check + full backup **на текущем лидере**
- `make verify-backup` — `info` + `check`
- `make restore-to-point T='YYYY-MM-DD HH:MM:SS'` — PITR в **чистый** том `pgdata_restore` (`docker rm -f` + `volume rm` + `chown` + `restore`)
- `make start-restore-check` / `make stop-restore-check` — проверочный инстанс на `5433` (`-D /home/postgres/pgdata/data`)
- **PITR-сценарий:** `backup-now` → `T0` → `drop table` → `sleep 120` → `pgbackrest info` (WAL есть) → `restore-to-point T0` → `start-restore-check` → `count = N` → `stop-restore-check`

### Алерты (v0.4)
- `curl -s http://localhost:9090/api/v1/rules | python3 -m json.tool | grep -E '"name"|"state"'` — 10 правил, inactive
- `curl -s http://localhost:9093/api/v2/status` — `status: ready`
- **Тест:** `docker stop` всех трёх → `sleep 90` → `curl :9090/api/v1/alerts` → `PostgresDown` → `docker start` → inactive
- **UI:** `:9093/#/alerts`, `:9090/rules`, `:9090/alerts`

## Grafana
http://localhost:3000 (admin / admin)
Connections → Data Sources → Prometheus → URL `http://prometheus:9090` → Save & test
Dashboards → Import → ID 9628 → datasource Prometheus → Import

## Ключевые решения и trade-off

### HA (v0.3)
- **Patroni = PID 1** (`entrypoint: /bin/bash -c`, `command: exec patroni ...`), `user: postgres`. Entrypoint `postgres` **не участвует**.
- **Один путь в контейнере** (`/etc/patroni/patroni.yml`), **разные файлы снаружи**. `command` одинаковый, mount — разный.
- **`etcd3:`** (v3), не `etcd:` (v2). etcd 3.5 **удалил** v2.
- **`restapi.listen: 0.0.0.0:8008`** у всех трёх, наружу `8008`/`8009`/`8010`.
- **Лидер — кто первым захватил ключ в etcd** (CAS), не «pg1». Makefile `LEADER` динамический.
- **`init-perms`** — `chown postgres:postgres` на тома (`pg1data`/`pg2data`/`pg3data` + `pgdata_restore`).
- **Чистка etcd** (`etcdctl del --prefix /pg-lab/`) — если bootstrap «застрял».
- **`data_dir` пуст** для bootstrap.

### Seed (v0.3)
- **`bootstrap.post_bootstrap`** — **только на лидере**, **один раз** (не при restart/failover/switchover).
- **Все SQL-объекты — в `app/seed/init.sql`** (один файл, `\c shop` работает для всего).
- **Идемпотентность** (`IF NOT EXISTS`, `ON CONFLICT`) — страховка.
- **`chmod +x` в `setup`** — скрипт монтируется `:ro`, права сохраняются.

### Sync replication (v0.4)
- **Async** (off) — RPO > 0, максимальная доступность.
- **Sync + деградация** (on+false) — RPO=0 в норме, async в окне без sync (**большинство**).
- **Strict** (on+true) — RPO=0 всегда, **простой** при падении sync (**финансы**).
- **Patroni выбирает** sync-реплику (лучшую), **не** «фиксированную».

### Бэкапы (v0.2)
- **`repo1-s3-uri-style=path`** — LocalStack/MinIO не резолвят `<bucket>.host`.
- **`repo1-s3-endpoint=http://...`** — схема обязательна (иначе HTTPS, `[095]`).
- **`archive_timeout=60s`** — WAL архивируется не реже раза в минуту.
- **Restore в отдельный том** (`pgdata_restore`, `5433`) — **не** поверх живого primary.
- **`-u postgres` в `docker exec`** — pgBackRest запрещает root.
- **Проверочный контейнер монтирует `pgbackrest.conf`** — иначе `archive-get` не знает `pg1-path`.

### PITR (v0.4)
- **`T`** — **после** backup, **до** инцидента. **WAL до T** — **в** архиве (`pgbackrest info`).
- **`restore-to-point`** — **чистый** том (`docker rm -f` + `volume rm` + `chown` + `restore`).
- **`start-restore-check`** — `postgres -D /home/postgres/pgdata/data`, иначе `initdb` в дефолт.
- **Если `FATAL: recovery ended before target`** — WAL до `T` нет в архиве → `T` раньше или `backup-now` до drop.

### PgBouncer (v0.1)
- **Transaction pooling** — ломает `SET` на сессию, prepared statements, advisory locks.
- **PgBouncer → HAProxy** (`haproxy:5000`), не на ноду — при failover не перенастраивать.

## Типовые проблемы и фикс (v0.4)

| Симптом | Причина | Фикс |
|---|---|---|
| `pull access denied for pg-lab/postgres` | образ удалён, `init-perms` до `build` | `make build` перед `make up`, или `init-perms: build` в Makefile |
| `port is already allocated` на 5432 | локальный PostgreSQL Windows | остановить службу или сменить порт на `55432` |
| `Can not find suitable configuration` | `etcd:` вместо `etcd3:` / CRLF / `command` на несуществующий файл | `etcd3:`; `sed -i 's/\r$//'`; `command: patroni /etc/patroni/patroni.yml` у всех |
| `initdb: Permission denied` | том принадлежит root | `make init-perms` (chown) |
| `waiting for leader to bootstrap` | `data_dir` не пуст / etcd «помнит» bootstrap | `make reset` (тома + etcd); `rm -rf /home/postgres/pgdata/data` |
| HAProxy `Exited (1)`, `Missing LF on last line` | нет `\n` в конце `haproxy.cfg` | `printf '\n' >> config/haproxy/haproxy.cfg` |
| `connection refused` на 5000/5001 | HAProxy мёртв | `docker logs pg-lab-haproxy`, фикс конфига, restart |
| `database "shop" does not exist` | seed не применён / в `postgres`, а не в `shop` | `post_bootstrap` + `init.sql` (`\c shop`); `chmod +x` |
| `switchover --leader pg3`: `Member X is not the leader` | `--leader` — текущий, не цель | `--leader $(LEADER) --candidate $(TO)` |
| `patronictl` на `pg1` падает после failover | `pg1` остановлен | `PATRONI_CTL` (любая живая нода) |
| `PostgresDown` не firing | остановлена одна нода (HAProxy переключился) | остановить **все три** (`pg_up=0`) |
| `synchronous_standby_names` пуст | `edit-config` не применил / не в корень DCS | `bootstrap.dcs` (`synchronous_mode: on` + `strict: true`), `make reset` |
| Запись не встаёт при strict | остановлена одна реплика (sync ещё есть) | остановить **обе** реплики, `timeout 5 psql insert` |
| `[040] unable to restore ... contains files` | том `pgdata_restore` не удалён | `docker rm -f` + `volume rm` перед `restore` (в Makefile) |
| `[047] Permission denied` при restore | том `pgdata_restore` от root | `chown postgres:postgres` после `create` |
| `FATAL: recovery ended before target` | WAL до `T` нет в архиве | `make backup-now` **до** drop; `T` после backup, до drop; `sleep 120` |
| `database "shop" does not exist` на 5433 | `postgres` без `-D` (initdb в `/var/lib/postgresql/data`) | `postgres -D /home/postgres/pgdata/data` в `start-restore-check` |
