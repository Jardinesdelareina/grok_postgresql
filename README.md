### Установка и использование PostgreSQL в Linux


<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/linux/linux-original.svg" width="40" height="40"/>&nbsp;
    <img src="https://github.com/devicons/devicon/blob/master/icons/postgresql/postgresql-original.svg" width="40" height="40"/>&nbsp;
</div>


`sudo apt install postgresql`   установка

`sudo service postgresql status`    проверка, запущен ли сервис

`sudo service postgresql start`     запуск сервера если он не запущен

`sudo -u postgres psql`     подключение к серверу, активация оболочки <b>psql</b>

`CREATE USER your_username WITH PASSWORD 'your_password';`      создание пользователя и пароля

`GRANT ALL PRIVILEGES ON DATABASE your_database TO your_username;`      предоставление привелегий новому пользователю

`\q`    выход из <b>psql</b>


### Основные команды PSQL

`\l`    список баз данных
`\c <db_name>`  подключение к базе данных
`\dt`   список таблиц базы данных
