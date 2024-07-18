# Базовый образ с Python 3.10
FROM python:3.10

# Указание интерпретатору Python не создавать компилированные файлы `.pyc` при запуске программы, 
# включение этой опции позволяет ускорить процесс запуска и уменьшить использование дискового пространства
ENV PYTHONDONTWRITEBYTECODE=1

# Включение обработчика сбоев (fault handler) в Python, 
# позволяет получать детализированную информацию при возникновении ошибок
ENV PYTHONFAULTHANDLER=1

# Отключение буферизации вывода в Python для отображения вывода без задержки
ENV PYTHONUNBUFFERED=1

# Задание случайного значения для семени хэша в Python,
# это может повлиять на устранение возможных уязвимостей, связанных с коллизиями хэшей
ENV PYTHONHASHSEED=random

# Отключение кэширования пакетов pip
ENV PIP_NO_CACHE_DIR=off

# Отключение проверки версии pip при выполнении команды pip
ENV PIP_DISABLE_PIP_VERSION_CHECK=on

# Установка тайм-аута по умолчанию для команд pip на 100 секунд
ENV PIP_DEFAULT_TIMEOUT=100

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