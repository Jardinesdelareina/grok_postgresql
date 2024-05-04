# Администрирование и эксплуатация СУБД PostgreSQL

### Установка и использование PostgreSQL в Linux


<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/linux/linux-original.svg" width="40" height="40"/>&nbsp;
    <img src="https://github.com/devicons/devicon/blob/master/icons/postgresql/postgresql-original.svg" width="40" height="40"/>&nbsp;
</div>

`sudo apt-get --purge remove postgresql\*`  удаление PostgreSQL и всех его компонентов

`sudo apt install postgresql`   установка PostgreSQL

`sudo ls -l /usr/lib/postgresql/14/bin`     каталог установки PostgreSQL

`sudo service postgresql status`    проверка, запущен ли сервис

`sudo service postgresql start`     запуск сервера если он не запущен

`sudo service postgresql restart`   перезапуск сервера postgresql

`sudo service postgresql stop`  остановка сервера postgresql

`sudo service postgresql stop -m immediate --skip systemctl-redirect`   остановка сервера postgresql без выполнения контрольной точки

`sudo pg_isready`       проверка, готов ли сервер postgresql принимать подключение от клиентов

`sudo -u postgres psql`     подключение к серверу, активация оболочки <b>psql</b>

`psql -h localhost -U user_name db_name`     подключение по локальной сети к базе данных под определенным пользователем

`sudo tail -n 10 /var/log/postgresql/postgresql-14-main.log`    вывод 10 последних записей из журнала сообщений сервера

`psql -U username -d dbname -c "SELECT * FROM table" > /path/to/file/output.txt`  запись результата запроса в файл

`\q`    выход из <b>psql</b>


### Установка pgAdmin4

1. Установка из репозитория <b>pgAdmin4 APT</b>:

`curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add`

`sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'`

2. Запуск установки <b>pgAdmin4</b>:

`sudo apt install pgadmin4`

3. Запуск скрипта, устанавливающего веб-компоненты. Скрипт находится по адресу `/usr/pgadmin4/bin/setup-web.sh`.

4. В процессе установки будет перезапущена служба Apache2. После завершения работы скрипта необходимо добавить разрешение для Apache2 на доступ через брэндмауэр:

`sudo ufw allow 'Apache'`

5. Запуск брэндмауэра:

`sudo ufw enable`

6. Убедиться, что Apache2 включена в список разрешенных в брэндмауэре:

`sudo ufw status`

7. Для доступа к веб-версии pgAdmin4 ввести в браузере:

`http://<ip-адрес:порт>/pgadmin4`


### Основные команды PSQL

`\! clear`  очистить терминал

`\l`    список баз данных

`\c <db_name>`  подключение к базе данных

`\dt`   список таблиц базы данных

`\dt <schema_name>.*`   список таблиц определенной схемы

`\du`   список пользователей

`\dn`   список схем базы данных

`\df`   список функций и процедур базы данных

`\dx`   список расширений базы данных

`\dT`   список составных типов базы данных

`\db`   список табличных пространств

`\dp <username>.<table>`    список привелегий для таблицы у пользователя

`\i <path_to_file_sql>`    открытие файла (используется для запуска скриптов .sql)


### Роли и привелегии

`CREATE ROLE <роль> [WITH] <атрибут> [атрибут ...]`

<em>LOGIN</em>   возможность подключения
<em>SUPERUSER</em>   суперпользователь
<em>CREATEDB</em>    возможность создавать базы данных
<em>CREATEROLE</em>  возможность создавать роли
<em>REPLICATION</em>     использование протокола репликации
и др.

Создаем базу данных
`CREATE DATABASE access_roles`

Подключение к базе данных
`\c access_roles`

Создаем роль для пользователя alice (появляется возможность подключаться и создавать новые роли)
```sql
CREATE ROLE alice LOGIN CREATEROLE;
```

Подключаемся к базе данных под именем alice

\с - alice

или

`psql -h localhost -U alice acces_roles`

Создание новой роли от alice
```sql
CREATE ROLE bob LOGIN;
```

##### Предопределенные роли

`pg_read_all_settings`  чтение всех параметров сервера

`pg_read_all_stats`     доступ к статистике

`pg_stat_scan_tables`   мониторинг и блокировки таблиц

`pg_read_all_data`      чтение данных из всех таблиц

`pg_write_all_data`     изменение данных во всех таблицах

`pg_read_server_files`      чтение файлов на сервере

`pg_write_server_files`     запись в файлы на сервере

`pg_execute_server_programs`    выполнение программ на сервере


##### Примеры использования управления привелегиями

`CREATE ROLE new_user WITH LOGIN PASSWORD 'new_password' VALID UNTIL '2022-12-31';`      создание пользователя и пароля и установление срока учетной записи

`GRANT ALL PRIVILEGES ON DATABASE your_database TO your_username;`      предоставление привелегий новому пользователю

`GRANT CREATE, USAGE ON SCHEMA alice TO bob`    предоставление привелегий пользователю bob на создание и использование схем

`ALTER ROLE your_username NOLOGIN;`     лишение пользователя возможности подключения в базе данных

`GRANT alice TO postgres`   включение alice в роль postgres

`REVOKE alice TO postgres`  исключение alice из роли postgres


##### Access priveleges

* a - INSERT
* r - SELECT
* w - UPDATE
* d - DELETE
* D - TRUNCATE
* x - REFERENCE
* t - TRIGGER


### Очистка дискового пространства

1. <b>VACUUM</b>: Эта команда выполняет процесс автоматического освобождения пространства в таблицах, которое было выделено для удаленных, обновленных или вставленных строк. Она также обновляет статистику таблицы, которая используется оптимизатором запросов для выбора наиболее эффективных планов выполнения запросов.

2. <b>VACUUM VERBOSE</b>: Параметр VERBOSE указывает на то, что при выполнении операции VACUUM будет выводиться более подробная информация о процессе. Это может включать в себя данные о количестве освобожденного пространства, времени выполнения операции, а также другие дополнительные сведения. Указание параметра VERBOSE делает вывод информации более информативным и обычно используется для отслеживания прогресса операции и оценки ее эффективности.

3. <b>VACUUM FULL</b>: Эта команда выполняет более интенсивный процесс очистки и компактации таблицы. Она перемещает данные из таблицы в новое физическое расположение, освобождая пространство, которое занимали удаленные строки. Однако, <b>VACUUM FULL</b> блокирует таблицу на время выполнения операции и может быть более ресурсоемкой по сравнению с обычным <b>VACUUM</b>.

В целом, <b>VACUUM</b> обычно достаточно для поддержания эффективности работы базы данных, однако, при необходимости выполнить более глубокую очистку и компактацию таблицы, может использоваться <b>VACUUM FULL</b>. Вариант этой команды с ключевым словом <b>CONCURRENTLY</b> работает дольше, но не блокирует индекс и не мешает чтению и обновлению данных


### REINDEX

Команда `REINDEX` используется для перестройки индексов в базе данных. Она удаляет и создает заново индексы, что может улучшить производительность при выполнении запросов к базе.

`REINDEX` применяется в случаях, когда произошли изменения в структуре базы данных, например, при удалении или изменении значений в таблицах, или если произошли проблемы с индексами, в результате чего запросы выполняются медленно.

Команда `REINDEX` не является стандартом SQL, а является частью добавления к стандарту, которое поддерживается не всеми СУБД. Например, PostgreSQL поддерживает команду `REINDEX` для работы с индексами.

`REINDEX INDEX index_name;` Перестройка индекса index_name.


### Подсчет контрольных сумм

Проверка, включено ведение контрольных сумм (по-умолчанию отключено):
```sql
SHOW pg_checksums;
```

`sudo service postgresql stop`

или

`sudo systemctl stop postgresql@14-main`    отключение сервера

`su - postgres -c '/usr/lib/postgresql/12/bin/pg_checksums --enable -D "/var/lib/postgresql/12/main"'`  включение ведения контрольных сумм на сервере

`sudo systemctl start postgresql@14-main`


### Резервное копирование

Все команды выполняются от имени postgres.

##### Логическая копия

* <b>COPY</b> 
COPY используется для копирования данных между таблицей и файлом или между таблицей и другой таблицей. Эта команда предоставляет отличную производительность при загрузке или выгрузке большого объема данных.

Копирование данных из файла в таблицу:
`COPY employees FROM '/path/to/employees.csv' DELIMITER ',' CSV HEADER;`


Копирование данных из таблицы в файл:
`COPY employees TO '/path/to/employees.csv' DELIMITER ',' CSV HEADER;`


DELIMITER ',' указывает, что данные в файле разделены запятыми, и CSV HEADER указывает, что первая строка содержит заголовки столбцов.

Параметры COPY могут включать опции формата данных (CSV, TEXT), разделитель, заголовки, игнорирование ошибок и другие. Кроме того, с помощью COPY можно копировать данные между таблицами, указывая имя целевой таблицы вместо имени файла:
`COPY employees TO employees_copy;`


* <b>pg_dump</b>
Выгружает базу данных в виде скрипта или в архивном формате. `pg_dump` — это программа для создания резервных копий базы данных PostgreSQL. Она создаёт целостные копии, даже если база параллельно используется. Программа `pg_dump` не препятствует доступу других пользователей к базе данных (ни для чтения, ни для записи).

По-умолчанию, файл с дампом будет создан в рабочем каталоге, из которого выполняется команда. Также можно указать абсолютный путь до файла вместо просто имени файла.

Выгрузка в SQL:
`pg_dump db_name > dump_file.sql`

или

`pg_dump -h hostname -U username -d db_name > dump_file.sql`

Восстановление дампа:
`psql db_name > dump_file.sql`

База данных не создастся данной командой. Базу данных нужно предварительно создать в psql от template0. Также к моменту восстановления дампа должны уже существовать все пользователи, которые имели права на объекты, иначе произойдет ошибка.

`--create`  cформировать в начале вывода команду для создания базы данных и затем подключения к ней 

`--file=файл`   отправить вывод в указанный файл

`--format=формат`   

По-умолчанию действует формат `plain`. Серьезное ограничение этого формата состоит в том, что выбирать объекты нужно в момент выгрузки. 
Формат custom позволяет сначала сделать полную копию, а выбирать объекты уже при загрузке. 
Формат directory интересен тем, что позволяет выгружать данные в несколько параллельных потоков. При этом гарантируется согласованность данных: все потоки будут использовать один и тот же снимок данных.


* <b>pg_dumpall</b>
Создает резервную копию всего кластера баз данных, включая все роли и табличные пространства. Поскольку pg_dumpall требуется доступ ко всем объектам всех БД, запускать ее следует суперпользователю или пользователю, включенному в предустановленную роль pg_read_all_data. Результатом работы pg_dumpall является скрипт для psql. Другие форматы не поддерживаются.

Дамп всего кластера:
`pg_dumpall > dump_file.sql`

Восстановлени полученной копии:
`psql -f dump_file.sql`


Дамп со сжатием:
`pg_dump db_name | gzip > filename.gz`

`gunzip -c filename.gz | psql db_name`


`sudo -u postgres pg_dump -d test_db --table=t | psql -d test_db2`  копирование таблицы с содержимым в другую базу данных

`sudo -u postgres pg_dump -d test_db --create`  копия базы данных в виде SQL-скрипта, которая выводится в консоль (stdin)


* <b>pg_restore</b>
Утилита командной строки, предназначенная для восстановления резервной копии. Она позволяет восстановить базу данных из архивного файла, который был создан с помощью pg_dump.

Восстановление базы данных из архивного файла:
`pg_restore -d dbname filename`


Восстановление только схемы базы данных (эта команда восстановит только структуру базы данных без данных):
`pg_restore -s -d dbname filename`


Восстановление только данных без схемы (эта команда загрузит только данные в базу данных без создания таблиц и других объектов):
`pg_restore -a -d dbname filename`


Восстановление базы данных с кастомными параметрами:
`pg_restore -C -d dbname -h localhost -U username filename`


##### Физическая копия

<em>Автономная резервная копия</em>:

Проверка, что включен параметр `replica` и сколько может быть включено процессов одновременно/var/lib/postgresql/14/
```sql
SELECT name, setting 
FROM pg_settings 
WHERE name IN ('wal_level', 'max_val_senders');
```

Проверка, включено ли разрешение на подключение по протоколу репликации
```sql
SELECT type, database, user_name, address, auth_method
FROM pg_hba_file_rules()
WHERE 'replication' = ANY(database);
```

`sudo rm -rf /home/fueros/Desktop/grok_postgresql/databases/test_db/backup/*`  очистка каталога для резервной копии

`pg_basebackup --pgdata=/home/fueros/Desktop/grok_postgresql/databases/test_db/backup -R`    создание резервной копии кластера (-R сформирует необходимые для репликации конфигурационные параметры)

`pg_lsclusters`    проверка, что необходимый кластер, куда будет создана реплика, остановлен (down)

Предоставить пользователю роль REPLICATION
```sql
ALTER ROLE user_name REPLICATION;
```

`sudo mkdir /var/lib/postgresql/14/replica`     создание директории для копии базы данных

или

`sudo rm -rf /var/lib/postgresql/14/replica/*`     очистка каталога кластера

`sudo mv /home/fueros/Desktop/grok_postgresql/databases/test_db/backup/* /var/lib/postgresql/14/replica`   перемещение созданной копии в каталог кластера

`sudo chown -R postgres:postgres /var/lib/postgresql/14/replica`     назначение postgres владельцем файлов каталога кластера

-------------------------------------------------------------------------------------------------------

### Полезные функции PostgreSQL

##### Вывод размера (базы данных, табличных пространств)
```sql
SELECT pg_size_pretty(pg_database_size('<название_базы_данных>')),
        pg_size_pretty(pg_tablespace_size('<название_табличного пространства>'));
```

##### Вывод информации о параметрах конкретной базы данных
```sql
SELECT * FROM pg_database WHERE datname = '<название_базы_данных>';
```

##### Вывод всех таблиц определенной схемы базы данных
```sql
SELECT tablename, tablespace FROM pg_tables WHERE schemaname = '<название_схемы_базы_данных>';
```

##### Вывод пути файла
```sql
SELECT pg_relation_filepath('<название файла>');
```

##### Вывод информации из файла pg_hba.conf в виде таблицы
```sql
SELECT line_number, type, database, username, address, auth_method
FROM pg_hba_file_rules;
```