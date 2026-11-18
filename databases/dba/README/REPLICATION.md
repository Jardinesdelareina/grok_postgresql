### Физическая репликация

##### Порядок действий

1. Войти в мастер
`docker exec -it -u postgres server-1 psql`

2. Создать роли для репликации
```sql
create role replicator with replication login password 'replpass';
alter role postgres with password 'postgres';
```

3. Проверка готовности мастера
`docker exec -u postgres server-1 psql -c "show wal_level; show max_wal_senders;"`

4. Остановить пустой кластер
`docker exec -u postgres server-2 pg_ctlcluster 16 main stop`

5. Очистить data-dir
`docker exec -u postgres server-2 bash -c 'rm -rf /var/lib/postgresql/16/main/*'`

6. Дать postgres право писать в его HOME (один раз; в контейнере уже не понадобится)
`docker exec -u root server-2 bash -c 'chown postgres:postgres /var/lib/postgresql'`

7. Создать .pgpass
```
docker exec -u postgres server-2 bash -c \
  'echo "server-1:5432:replication:replicator:replpass" > ~/.pgpass && chmod 600 ~/.pgpass'
```

8. Проверить
`docker exec -u postgres server-2 bash -c 'cat ~/.pgpass; ls -l ~/.pgpass'`

9. basebackup
```
docker exec -u postgres -e PGPASSWORD=replpass server-2 \
  pg_basebackup -h server-1 -U replicator \
  -D /var/lib/postgresql/16/main -Fp -Xs -P -R
```

10. Проверить, что -R создал standby.signal и primary_conninfo
```
docker exec -u postgres server-2 bash -c \
  'ls -l /var/lib/postgresql/16/main/standby.signal; grep primary_conninfo /var/lib/postgresql/16/main/postgresql.auto.conf'
```

11. Старт
`docker exec -u postgres server-2 pg_ctlcluster 16 main start`

12. Лог
`docker exec server-2 tail -n 40 /var/log/postgresql/postgresql-16-main.log`

13. Проверка видимости реплик с мастера
```
docker exec -u postgres server-1 psql -U postgres -c "select client_addr, state, sync_state, sent_lsn, replay_lsn from pg_stat_replication;"
```

##### Проверка работы репликации

14. Создание таблицы на мастере

```
docker exec -u postgres server-1 psql -c "create table demo
(id int primary key, txt text); insert into demo values (1, 'hello replication');"
```

15. Чтение созданной таблицы на реплике

`docker exec -u postgres server-3 psql -U postgres -c "select * from demo;"`

16. Убеждаемся, что реплика readonly

`docker exec -u postgres server-2 psql -c "insert into demo values (2, 'hello replication 2');"`

ERROR:  cannot execute INSERT in a read-only transaction