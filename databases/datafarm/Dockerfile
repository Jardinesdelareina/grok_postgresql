# Базовый образ с Python 3.10
FROM python:3.10

# Зависимости
RUN apt-get update && \
    apt-get install -y postgresql && \
    apt-get install -y libpq-dev && \
    apt-get clean

# Устанавка рабочей директории
WORKDIR /app

# Копирование необходимых файлов в контейнер
COPY req.txt /app
RUN pip3 install --no-cache-dir -r req.txt

# Копирование скрипта, инициализирующего базу данных 
COPY datafarm_init.sql /docker-entrypoint-initdb.d/datafarm_init.sql

# Копирование всех остальных файлов проекта в контейнер
COPY . /app

# Указываем команду, которая будет выполняться при запуске контейнера
CMD ["python", "main.py"]