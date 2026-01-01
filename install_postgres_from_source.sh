cat > ~/install_postgres_from_source.sh << 'EOF'
#!/bin/bash

# ============================================
# Скрипт сборки PostgreSQL из исходников
# Автоматическая установка в WSL2/Ubuntu
# ============================================

set -e  # Выйти при первой ошибке

echo "=========================================="
echo " Начало установки PostgreSQL из исходников"
echo "=========================================="

# Функция для вывода цветного текста
green() { echo -e "\033[0;32m$1\033[0m"; }
yellow() { echo -e "\033[1;33m$1\033[0m"; }
red() { echo -e "\033[0;31m$1\033[0m"; }

# Проверка что мы в WSL/Ubuntu
if ! grep -q Microsoft /proc/version 2>/dev/null && ! grep -q WSL /proc/version 2>/dev/null; then
    yellow "Внимание: Похоже вы не в WSL2. Скрипт может работать некорректно."
    read -p "Продолжить? [y/N]: " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ============================
# 1. Обновление системы
# ============================
green "1. Обновление системы..."
sudo apt update && sudo apt upgrade -y

# ============================
# 2. Установка зависимостей
# ============================
green "2. Установка зависимостей..."
sudo apt install -y \
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
    libsystemd-dev \
    autoconf \
    automake \
    libtool

# ============================
# 3. Клонирование и сборка
# ============================
green "3. Клонирование репозитория PostgreSQL..."

# Удаляем старые директории если есть
rm -rf ~/example_pg ~/pg_install ~/pg_data 2>/dev/null || true

# Создаём структуру
mkdir -p ~/example_pg
cd ~/example_pg

# Клонируем репозиторий
git clone https://github.com/postgres/postgres.git

cd postgres

# Генерируем configure если нужно
if [ ! -f configure ]; then
    green "Генерация configure..."
    autoreconf -f -i
fi

# Создаём отдельную директорию для сборки
green "Создание директории сборки..."
mkdir -p ../pg_build
cd ../pg_build

# Конфигурация
green "Конфигурация сборки..."
../postgres/configure --prefix=$HOME/pg_install --enable-debug --enable-cassert

# Компиляция
green "Компиляция PostgreSQL (это займёт 5-15 минут)..."
make -j$(nproc) 2>&1 | tee make.log

# Проверка успешности компиляции
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    green "✅ Компиляция успешна!"
else
    red "❌ Ошибка компиляции. Смотрите make.log"
    exit 1
fi

# Установка
green "Установка..."
make install 2>&1 | tee install.log

# ============================
# 4. Настройка переменных окружения
# ============================
green "4. Настройка переменных окружения..."

# Удаляем старые настройки если есть
sed -i '/pg_install\|pg_data\|PGINSTALL\|PGDATA/d' ~/.bashrc
sed -i '/alias pgstart\|alias pgstop\|alias pgstatus/d' ~/.bashrc

# Добавляем новые
cat >> ~/.bashrc << 'BASHRC'

# ============================================
# PostgreSQL Development Environment
# ============================================
export PGINSTALL="$HOME/pg_install"
export PGDATA="$HOME/pg_data"
export PATH="$PGINSTALL/bin:$PATH"

# PostgreSQL Aliases
alias pgstart='pg_ctl -D $PGDATA -l $PGDATA/logfile start'
alias pgstop='pg_ctl -D $PGDATA stop'
alias pgrestart='pg_ctl -D $PGDATA restart'
alias pgstatus='pg_ctl -D $PGDATA status'
alias pgreload='pg_ctl -D $PGDATA reload'
alias pgl='tail -f $PGDATA/logfile'
alias pgsql='psql -h localhost -p 5433 -U postgres'
alias pgedit='vim $PGDATA/postgresql.conf'
alias pglog='vim $PGDATA/logfile'

# Development Aliases
alias pgbuild='cd ~/example_pg/pg_build && make -j$(nproc) && make install'
alias pgclean='cd ~/example_pg/pg_build && make clean'
alias pgdistclean='cd ~/example_pg/pg_build && make distclean'
alias pgconfigure='cd ~/example_pg/pg_build && ../postgres/configure --prefix=$HOME/pg_install --enable-debug --enable-cassert'

# Debugging Aliases
alias pgdebug='gdb --args $PGINSTALL/bin/postgres -D $PGDATA'
alias pgdebug2='gdb --args $PGINSTALL/bin/postgres -D $PGDATA -d 2'
BASHRC

source ~/.bashrc

# ============================
# 5. Инициализация кластера БД
# ============================
green "5. Инициализация кластера БД..."

# Создаём директорию для данных
mkdir -p ~/pg_data

# Инициализируем БД
initdb -D ~/pg_data -U postgres --locale=C --encoding=UTF8 --no-locale

# Настраиваем конфигурацию для разработки
cat > ~/pg_data/postgresql.conf << 'CONFIG'
# Основные настройки
listen_addresses = 'localhost'
port = 5433
max_connections = 100
shared_buffers = 128MB

# Настройки для разработки
log_statement = 'all'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 10MB

# Отладочные настройки
debug_print_parse = on
debug_print_rewritten = on
debug_print_plan = on
debug_pretty_print = on

# Ускорение разработки (ТОЛЬКО для разработки!)
fsync = off
full_page_writes = off
synchronous_commit = off
CONFIG

# Настраиваем аутентификацию
cat > ~/pg_data/pg_hba.conf << 'HBA'
# PostgreSQL Client Authentication Configuration File
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
HBA

# ============================
# 6. Тестовый запуск
# ============================
green "6. Тестовый запуск..."

# Останавливаем если запущен
pgstop 2>/dev/null || true

# Запускаем
pgstart

# Ждём запуска
sleep 3

# Проверяем статус
if pgstatus >/dev/null 2>&1; then
    green "✅ Сервер запущен успешно!"
else
    red "❌ Не удалось запустить сервер"
    exit 1
fi

# Тестируем подключение
green "Тестирование подключения..."
if psql -h localhost -p 5433 -U postgres -c "SELECT version();" postgres 2>/dev/null; then
    green "✅ Подключение к БД работает!"
else
    red "❌ Не удалось подключиться к БД"
    exit 1
fi

# ============================
# 7. Создание тестовой БД
# ============================
green "7. Создание тестовой базы данных..."
createdb -h localhost -p 5433 -U postgres test_db 2>/dev/null || true

# ============================
# 8. Финальные проверки
# ============================
green "8. Финальные проверки..."

echo ""
echo "=== Проверка установки ==="
echo "Версия PostgreSQL: $(postgres --version 2>/dev/null || echo 'не определена')"
echo "Директория установки: $(ls -d ~/pg_install 2>/dev/null || echo 'не найдена')"
echo "Директория данных: $(ls -d ~/pg_data 2>/dev/null || echo 'не найдена')"
echo "Размер postgres: $(ls -lh ~/pg_install/bin/postgres 2>/dev/null | awk '{print $5}' || echo 'N/A')"

# ============================
# 9. Создание скрипта управления
# ============================
cat > ~/pg_manager.sh << 'MANAGER'
#!/bin/bash
# Скрипт управления PostgreSQL

case "$1" in
    start)
        pgstart
        echo "PostgreSQL запущен"
        ;;
    stop)
        pgstop
        echo "PostgreSQL остановлен"
        ;;
    restart)
        pgrestart
        echo "PostgreSQL перезапущен"
        ;;
    status)
        pgstatus
        ;;
    log)
        tail -f ~/pg_data/logfile
        ;;
    connect)
        psql -h localhost -p 5433 -U postgres
        ;;
    rebuild)
        echo "Пересборка PostgreSQL..."
        cd ~/example_pg/pg_build
        make -j$(nproc) && make install
        pgrestart
        ;;
    reset)
        echo "Сброс базы данных..."
        pgstop
        rm -rf ~/pg_data
        mkdir -p ~/pg_data
        initdb -D ~/pg_data -U postgres --locale=C --encoding=UTF8
        echo "port = 5433" > ~/pg_data/postgresql.conf
        echo "listen_addresses = 'localhost'" >> ~/pg_data/postgresql.conf
        echo "local all all trust" > ~/pg_data/pg_hba.conf
        pgstart
        ;;
    debug)
        echo "Запуск под отладчиком..."
        pgstop
        gdb --args ~/pg_install/bin/postgres -D ~/pg_data
        ;;
    *)
        echo "Использование: $0 {start|stop|restart|status|log|connect|rebuild|reset|debug}"
        echo ""
        echo "  start    - запустить PostgreSQL"
        echo "  stop     - остановить PostgreSQL"
        echo "  restart  - перезапустить PostgreSQL"
        echo "  status   - показать статус"
        echo "  log      - показать логи в реальном времени"
        echo "  connect  - подключиться к БД"
        echo "  rebuild  - пересобрать из исходников"
        echo "  reset    - сбросить БД до начального состояния"
        echo "  debug    - запустить под отладчиком gdb"
        exit 1
esac
MANAGER

chmod +x ~/pg_manager.sh

# ============================
# 10. Вывод информации
# ============================
echo ""
echo "=========================================="
green "✅ Установка PostgreSQL завершена успешно!"
echo "=========================================="
echo ""
echo "📁 Директории:"
echo "   Исходный код:    ~/example_pg/postgres/"
echo "   Директория сборки: ~/example_pg/pg_build/"
echo "   Установленные файлы: ~/pg_install/"
echo "   Данные БД:       ~/pg_data/"
echo ""
echo "🚀 Команды управления:"
echo "   pgstart                    - запустить сервер"
echo "   pgstop                     - остановить сервер"
echo "   pgstatus                   - проверить статус"
echo "   pgsql                      - подключиться к БД"
echo "   pgbuild                    - пересобрать PostgreSQL"
echo "   ~/pg_manager.sh [команда]  - расширенное управление"
echo ""
echo "🔧 Пример использования:"
echo "   pgsql                      # Подключиться к БД"
echo "   SELECT version();          # Проверить версию"
echo "   \q                         # Выйти"
echo ""
echo "🐛 Отладка:"
echo "   pgdebug                    # Запустить под gdb"
echo "   pgdebug2                   # Запустить с отладочным выводом"
echo ""
echo "📝 Для начала работы выполните:"
echo "   source ~/.bashrc           # Обновить настройки"
echo "   pgstart                    # Запустить сервер"
echo "   pgsql                      # Подключиться"
echo ""
yellow "Примечание: Сервер PostgreSQL сейчас запущен."
echo "Чтобы остановить: pgstop"
echo "=========================================="

# Финальный тест
echo ""
green "Финальный тест..."
psql -h localhost -p 5433 -U postgres -c "
CREATE TABLE IF NOT EXISTS installation_test (
    id SERIAL PRIMARY KEY,
    message TEXT,
    installed_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO installation_test (message) 
VALUES ('PostgreSQL успешно установлен из исходников! Дата: $(date)');
SELECT * FROM installation_test;
" postgres 2>/dev/null || yellow "Не удалось создать тестовую таблицу (но это нормально при первом запуске)"

EOF

# Делаем скрипт исполняемым
chmod +x ~/install_postgres_from_source.sh