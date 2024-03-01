# Администрирование и эксплуатация СУБД PostgreSQL

### Установка и использование PostgreSQL в Linux


<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/linux/linux-original.svg" width="40" height="40"/>&nbsp;
    <img src="https://github.com/devicons/devicon/blob/master/icons/postgresql/postgresql-original.svg" width="40" height="40"/>&nbsp;
</div>


`sudo apt install postgresql`   установка

`sudo service postgresql status`    проверка, запущен ли сервис

`sudo service postgresql start`     запуск сервера если он не запущен

`sudo service postgresql restart`   перезапуск сервера postgresql

`sudo service postgresql stop`  остановка сервера postgresql

`sudo service postgresql stop -m immediate --skip systemctl-redirect`   остановка сервера postgresql без выполнения контрольной точки

`sudo pg_isready`       проверка, готов ли сервер postgresql принимать подключение от клиентов

`sudo -u postgres psql`     подключение к серверу, активация оболочки <b>psql</b>

`sudo tail -n 10 /var/log/postgresql/postgresql-14-main.log`    вывод 10 последних записей из журнала сообщений сервера

`CREATE USER your_username WITH PASSWORD 'your_password';`      создание пользователя и пароля

`GRANT ALL PRIVILEGES ON DATABASE your_database TO your_username;`      предоставление привелегий новому пользователю

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

`\l`    список баз данных

`\c <db_name>`  подключение к базе данных

`\dt`   список таблиц базы данных

`\du`   список пользователей

`\dn`   список схем базы данных

`\df`   список функций и процедур базы данных

`\db`   список табличных пространств

`\i <path_to_file_sql>`    открытие файла (используется для запуска скриптов .sql)


### Очистка дискового пространства

1. <b>VACUUM</b>: Эта команда выполняет процесс автоматического освобождения пространства в таблицах, которое было выделено для удаленных, обновленных или вставленных строк. Она также обновляет статистику таблицы, которая используется оптимизатором запросов для выбора наиболее эффективных планов выполнения запросов.

2. <b>VACUUM FULL</b>: Эта команда выполняет более интенсивный процесс очистки и компактации таблицы. Она перемещает данные из таблицы в новое физическое расположение, освобождая пространство, которое занимали удаленные строки. Однако, <b>VACUUM FULL</b> блокирует таблицу на время выполнения операции и может быть более ресурсоемкой по сравнению с обычным <b>VACUUM</b>.

В целом, <b>VACUUM</b> обычно достаточно для поддержания эффективности работы базы данных, однако, при необходимости выполнить более глубокую очистку и компактацию таблицы, может использоваться <b>VACUUM FULL</b>.


### Системные функции PostgreSQL

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