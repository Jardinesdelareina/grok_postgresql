# Сборка PostgreSQL из исходников

### Среда выполнения WSL2 в Windows11 (Ubuntu)

1. Обновляем систему внутри WSL: 
```sudo apt update && sudo apt upgrade -y```

2. Установка необходимых пакетов: 
```sudo apt install -y \
    build-essential \
    git \
    flex \
    bison \
    libreadline-dev \
    zlib1g-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libpam0g-dev \
    libedit-dev \
    pkg-config \
    gdb \
    valgrind \
    universal-ctags \
    vim \
    libzstd-dev \
    liblz4-dev \
    libicu-dev \
    perl \
    python3 \
    python3-dev \
    libkrb5-dev \
    libsystemd-dev
```

3. Клонирование репозитория и установка в директорию pg_build
```
cd ~
mkdir -p example_pg
cd example_pg
git clone https://github.com/postgres/postgres.git
cd postgres
ls configure
mkdir ../pg_build
cd ../pg_build
../postgres/configure --prefix=$HOME/pg_install --enable-debug
make -j4           
make install                                                 
```

4. Настройка переменных окружения
#### Добавим ваш PostgreSQL в PATH
```
echo 'export PATH="$HOME/pg_install/bin:$PATH"' >> ~/.bashrc
echo 'export PGDATA="$HOME/pg_data"' >> ~/.bashrc
source ~/.bashrc
```

#### Проверим
```
which postgres
which psql
```

5. Создание тестового кластера БД
#### Создадим директорию для данных
```
mkdir -p ~/pg_data
```

#### Инициализируем БД
```
initdb -D ~/pg_data -U postgres --locale=C --encoding=UTF8
```

#### Настроим для отладки
```
cat >> ~/pg_data/postgresql.conf << 'EOF'
port = 5433
listen_addresses = 'localhost'
log_statement = 'all'
logging_collector = on
EOF
```

#### Настроим простую аутентификацию
```
echo "local all all trust" > ~/pg_data/pg_hba.conf
echo "host all all 127.0.0.1/32 trust" >> ~/pg_data/pg_hba.conf
```

6. Запуск и тестирование
#### Запускаем сервер
```
pg_ctl -D ~/pg_data -l ~/pg_data/logfile start
```

#### Ждём 2 секунды
```
sleep 2
```

#### Проверяем статус
```
pg_ctl -D ~/pg_data status
```

#### Тестируем подключение
```
psql -h localhost -p 5433 -U postgres -c "SELECT version();"
```

#### Создадим тестовую таблицу
```
psql -h localhost -p 5433 -U postgres -c "
CREATE TABLE test (id SERIAL PRIMARY KEY, message TEXT);
INSERT INTO test (message) VALUES ('PostgreSQL успешно установлен из исходников!');
SELECT * FROM test;
"
```

7. Создание алиасов
```
cat >> ~/.bashrc << 'EOF'

# PostgreSQL Development Aliases
alias pgstart='pg_ctl -D $HOME/pg_data -l $HOME/pg_data/logfile start'
alias pgstop='pg_ctl -D $HOME/pg_data stop'
alias pgstatus='pg_ctl -D $HOME/pg_data status'
alias pgreload='pg_ctl -D $HOME/pg_data reload'
alias pgl='tail -f $HOME/pg_data/logfile'
alias pgsql='psql -h localhost -p 5433 -U postgres'
alias pgedit='vim $HOME/pg_data/postgresql.conf'

# Для пересборки PostgreSQL
alias pgbuild='cd ~/example_pg/pg_build && make -j4 && make install'
EOF

source ~/.bashrc
```

### Где теперь всё находится
Исходный код: `~/example_pg/postgres/`

Директория сборки: `~/example_pg/pg_build/` (туда можно добавлять свои изменения)

Установленные файлы: `~/pg_install/` (программы и библиотеки)

Данные БД: `~/pg_data/` (ваши базы данных)

Логи: `~/pg_data/logfile`


### Отладчик GDB

Запуск программы под отладчиком: 
`gdb --args ~/pg_install/bin/postgres -D ~/pg_data`

Основные команды внутри GDB:

`(gdb) break main`              Поставить точку останова на функцию main()

`(gdb) run`                     Запустить программу

`(gdb) continue`                Продолжить выполнение после остановки

`(gdb) next`                    Выполнить следующую строку (не заходя в функции)

`(gdb) step`                    Выполнить следующую строку (заходя в функции)

`(gdb) backtrace`               Показать стек вызовов (кто кого вызвал)

`(gdb) print variable_name`     Напечатать значение переменной

`(gdb) quit`                    Выйти из GDB