# Полезные команды PostgreSQL

### Размер баз данных текущего кластера

```sql
SELECT pg_database.datname,
       pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```


### Размер табличных пространств за исключением pg_global

```sql
SELECT spcname, pg_size_pretty(pg_tablespace_size(spcname)) 
FROM pg_tablespace
WHERE spcname<>'pg_global';
```


### Размер схем

Суммарный размер всех таблиц, суммарный размер всех индексов, общий суммарный размер схемы и суммарное количество строк во всех таблицах схемы.
```sql
SELECT A.schemaname,
       pg_size_pretty (SUM(pg_relation_size(C.oid))) as table, 
       pg_size_pretty (SUM(pg_total_relation_size(C.oid)-pg_relation_size(C.oid))) as index, 
       pg_size_pretty (SUM(pg_total_relation_size(C.oid))) as table_index,
       SUM(n_live_tup)
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
INNER JOIN pg_stat_user_tables A ON C.relname = A.relname
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
AND C .relkind <> 'i'
AND nspname !~ '^pg_toast'
GROUP BY A.schemaname;
```


### Размер таблиц

Детальная информация о каждой таблице с указанием её схемы, размера без индексов, размере индексов, суммарном размере таблицы и индексов, а также количестве строк в таблице.
```sql
SELECT schemaname,
       C.relname AS relation,
       pg_size_pretty (pg_relation_size(C.oid)) as table,
       pg_size_pretty (pg_total_relation_size (C.oid)-pg_relation_size(C.oid)) as index,
       pg_size_pretty (pg_total_relation_size (C.oid)) as table_index,
       n_live_tup
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
LEFT JOIN pg_stat_user_tables A ON C.relname = A.relname
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
AND C.relkind <> 'i'
AND nspname !~ '^pg_toast'
AND C.relname = 'trading.transactions'
ORDER BY pg_total_relation_size (C.oid) DESC;
```


### Мониторинг блокировок

Вся информация о заблокированных запросах, и о том, кем они заблокированы.
```sql
SELECT COALESCE(blockingl.relation::regclass::text, blockingl.locktype) AS locked_item,
       now() - blockeda.query_start                                     AS waiting_duration,
       blockeda.pid                                                     AS blocked_pid,
       blockeda.query                                                   AS blocked_query,
       blockedl.mode                                                    AS blocked_mode,
       blockinga.pid                                                    AS blocking_pid,
       blockinga.query                                                  AS blocking_query,
       blockingl.mode                                                   AS blocking_mode
FROM pg_locks blockedl
JOIN pg_stat_activity blockeda ON blockedl.pid = blockeda.pid
JOIN pg_locks blockingl ON (blockingl.transactionid = blockedl.transactionid OR
                            blockingl.relation = blockedl.relation AND
                            blockingl.locktype = blockedl.locktype) AND blockedl.pid <> blockingl.pid
JOIN pg_stat_activity blockinga ON blockingl.pid = blockinga.pid AND blockinga.datid = blockeda.datid
WHERE NOT blockedl.granted AND blockinga.datname = current_database();
```


### Снятие блокировки

```sql
SELECT pg_cancel_backend(PID_ID);
```

или

```sql
SELECT pg_terminate_backend(PID_ID);
```

<b>PID_ID</b> - это ID запроса, который блокирует другие запросы. Чаще всего хватает отмены одного блокирующего запроса, чтобы снять блокировки и запустить всю накопившуюся очередь. Разница между `pg_cancel_backend` и `pg_terminate_backend` в том, что `pg_cancel_backend` отменяет запрос, а `pg_terminate_backend` завершает сеанс и, соответственно, закрывает подключение к базе данных.


### Доля кэшированных данных в таблицах

Какая доля каких таблиц закеширована (и насколько активно используются эти данные).

```sql
SELECT c.relname,
  count(*) blocks,
  round( 100.0 * 8192 * count(*) / pg_table_size(c.oid) ) "% of rel",
  round( 100.0 * 8192 * count(*) FILTER (WHERE b.usagecount > 3) / pg_table_size(c.oid) ) "% hot"
FROM pg_buffercache b
  JOIN pg_class c ON pg_relation_filenode(c.oid) = b.relfilenode
WHERE  b.reldatabase IN (
         0, (SELECT oid FROM pg_database WHERE datname = current_database())
       )
AND    b.usagecount is not null
GROUP BY c.relname, c.oid
ORDER BY 2 DESC
LIMIT 10;
```


### Коэффициент кэширования

Показатель эффективности чтения, измеряемый долей операций чтения из кэша по сравнению с общим количеством операций чтения как с диска, так и из кэша. За исключением случаев использования хранилища данных, идеальный коэффициент кэширования составляет 99% или выше, что означает, что по крайней мере 99% операций чтения выполняются из кэша и не более 1% - с диска.

```sql
SELECT sum(heap_blks_read) as heap_read,
       sum(heap_blks_hit)  as heap_hit,
       sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
FROM 
    pg_statio_user_tables;  
```

### Коэффициент кэширования индексов

```sql
SELECT sum(idx_blks_read) as idx_read,
       sum(idx_blks_hit)  as idx_hit,
       (sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit) as ratio
FROM pg_statio_user_indexes;
```


### Эффективность использовани индексов

Количество строк в таблицах и процент времени использования индексов по сравнению с чтением без индексов. Идеальные кандидаты для добавления индекса - это таблицы размером более 10000 строк с нулевым или низким использованием индекса.

```sql
SELECT relname,   
       100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used,   
       n_live_tup rows_in_table 
FROM pg_stat_user_tables 
WHERE seq_scan + idx_scan > 0 
ORDER BY n_live_tup DESC;
```


### Неиспользуемые индексы

Индексы, которые созданы, но не использовались в SQL-запросах.

```sql
SELECT schemaname, relname, indexrelname
FROM pg_stat_all_indexes
WHERE idx_scan = 0 and schemaname <> 'pg_toast' and  schemaname <> 'pg_catalog'
```


### Статистика использования индекса

```sql
SELECT n_distinct, correlation, null_frac, most_common_vals, most_common_freqs FROM pg_stats 
WHERE tablename = '<название таблицы>' AND attname = '<название индексируемой колонки>'
```

n_distinct - уникальность значений, 
correlation - упорядоченность значений, 
null_frac - объемы NULL-значений, 
most_common_vals и most_common_freqs - частые значения.


### Соотношение размера таблиц и размера индексов в этих таблицах

```sql
SELECT 
    tables.table_schema AS schema_name,
    tables.table_name AS table_name,
    pg_size_pretty(pg_total_relation_size(tables.table_schema || '.' || tables.table_name)) AS table_size,
    pg_size_pretty(pg_indexes_size(tables.table_schema || '.' || tables.table_name)) AS index_size
FROM 
    information_schema.tables AS tables
LEFT JOIN 
    pg_stat_user_tables AS statTables ON tables.table_schema = statTables.schemaname 
    AND tables.table_name = statTables.relname
WHERE 
    tables.table_schema NOT IN ('public', 'pg_catalog', 'information_schema')
ORDER BY 
    table_size DESC;
```


### Количество открытых подключений

```sql
SELECT COUNT(*) as connections,
       backend_type
FROM pg_stat_activity
WHERE state = 'active' OR state = 'idle' AND datname = '<база данных>'
GROUP BY backend_type
ORDER BY connections DESC;
```


### Выполняющиеся запросы и их длительность

```sql
SELECT pid, age(clock_timestamp(), query_start), usename, query, state
FROM pg_stat_activity
WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;
```


### Размер объекта базы данных (таблица, индекс и т.д.)

```sql
SELECT pg_size_pretty(pg_total_relation_size('<название объекта>')) AS object_size;
```


### Информация о параметрах конкретной базы данных

```sql
SELECT * FROM pg_database WHERE datname = '<название базы данных>';
```


### Путь файла

```sql
SELECT pg_relation_filepath('<название файла>');
```


### Информация из файла pg_hba.conf в виде таблицы

```sql
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules;
```

либо из под пользователя linux:
`sudo egrep '^[^#]' /etc/postgresql/14/main/pg_hba.conf`


### Открытие файла pg_hba.conf в ОС

`sudo nano /etc/postgresql/14/main/pg_hba.conf`


### Информация о процессе по его pid

```sql
SELECT query, backend_type, wait_event_type, wait_event
FROM pg_stat_activity WHERE pid = <номер процесса>;
```


### Все незакоментированные параметры конфигурации из файла postgresql.conf

```sql
SELECT sourceline, name, setting, applied
FROM pg_file_settings
WHERE sourcefile LIKE '/etc/postgresql/14/main/postgresql.conf';
```


### Перезагрузка файла конфигурации postgresql.conf без остановки сервера базы данных:

```sql
SELECT pg_reload_conf();
```


### Пароли ролей в базе данных

Пароли хранятся как значение хеш-функции, не допускающее расшифровки. Сервер всегда сравнивает между собой зашифрованные значения — введенный пароль и значение из pg_authid.

```sql
SELECT rolname, rolpassword FROM pg_authid;
```


### Таблицы в базе данных, содержащих определенную колонку

```sql
SELECT table_schema, table_name
FROM information_schema.columns
WHERE column_name = '<название таблицы>'
ORDER BY table_schema, table_name;
```


### Остановка всех процессов кроме текущего с определенной базой данных

```sql
SELECT pg_terminate_backend(pg_stat_activity.pid) 
FROM pg_stat_activity 
WHERE pg_stat_activity.datname = '<название базы данных>' AND pid <> pg_backend_pid();
```