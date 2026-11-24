# pg-lab — production-like стенд PostgreSQL для обучения DBA

## Запуск (Windows 11 + Docker Desktop + WSL2)
1. Скопировать `.env.example` в `.env` (или `make setup`)
2. `make up` — поднять стенд
3. `make verify` — проверить состояние
4. `make load` — дать нагрузку 60 секунд
5. Grafana: http://localhost:3000 (admin/admin) -> datasource Prometheus http://prometheus:9090 -> дашборд ID 9628

## Что есть сейчас (v0.2)
- PostgreSQL 16 (свой образ `pg-lab/postgres:16-pgbackrest`, внутри pgBackRest 2.60)
- PgBouncer (transaction pooling, `6432 → 5432`)
- **LocalStack S3** + бакет `pgbackrest`
- **pgBackRest**: full backup + WAL-архив (`archive-push`) + **PITR**
- Prometheus + postgres_exporter + Grafana
- Демо-схема `shop` + генератор нагрузки
- Makefile: `up/down/reset/verify/load/stats/psql/pgb/backup-now/verify-backup/restore-to-point/start-restore-check/stop-restore-check`

## Этапы
- [x] v0.1: 1 нода, PgBouncer, мониторинг, нагрузка
- [x] v0.2: pgBackRest + LocalStack S3 + WAL-архив + PITR
- [ ] v0.3: etcd + Patroni (3 ноды) + HAProxy + тест failover
- [ ] v0.4: Alertmanager + алерты (lag, connections, WAL, bloat, long tx)
- [ ] v0.5: Ansible-роль (поднять с нуля) + `make up` из IaC
- [ ] v0.6: k8s (CloudNativePG/Zalando)

## Полезные команды диагностики
- `make psql` — в контейнер PostgreSQL
- `make pgb` — через PgBouncer (как приложение)
- `make stats` — bloat/autovacuum по таблицам
- `make verify` — контейнеры, размеры, топ медленных запросов
- `make backup-now` — stanza-create + check + full backup
- `make verify-backup` — `info` + `check`
- `make restore-to-point T='YYYY-MM-DD HH:MM:SS+00'` — PITR в отдельный том `pgdata_restore`
- `make start-restore-check` / `make stop-restore-check` — проверочный инстанс на 5433

## Grafana
http://localhost:3000 (admin / admin)
Connections -> Data sources -> Add -> Prometheus -> URL `http://prometheus:9090` -> Save & test
Dashboards -> Import -> ID 9628 -> datasource Prometheus -> Import

## Ключевые решения и trade-off
- **PgBouncer transaction pooling** — ломает `SET` на сессию, prepared statements, advisory locks. Плюс: масштабирование соединений. Минус: часть приложений требует session pooling.
- **`repo1-s3-uri-style=path`** — LocalStack/MinIO не резолвят `<bucket>.host`, нужен path-style. В AWS — можно virtual-hosted-style (по умолчанию).
- **`repo1-s3-endpoint=http://...`** — схема обязательна, иначе pgBackRest предполагает HTTPS и падает на проверке сертификата (`[095]`).
- **`archive_timeout=60s`** — WAL архивируется не реже раза в минуту, иначе PITR «отстаёт» при низкой нагрузке. На проде 60–300 с.
- **Restore в отдельный том** (`pgdata_restore`, порт 5433) — не поверх живого primary. В проде: restore → проверка → переключение трафика.
- **`-u postgres` в `docker exec`** — pgBackRest запрещает root (создаст файлы, недоступные `postgres`).
- **Проверочный контейнер должен монтировать `pgbackrest.conf`** — иначе `archive-get` не знает `pg1-path` и recovery падает.