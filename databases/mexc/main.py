import requests
import environs
import psycopg2

env = environs.Env()
env.read_env('.env')

DB_USER = env('DB_USER')
DB_PASS = env('DB_PASS')
DB_HOST = env('DB_HOST')
DB_NAME = env('DB_NAME')

try:
    # Устанавливаем соединение с базой данных
    connection = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

    # Создаем курсор для выполнения SQL-запросов
    cursor = connection.cursor()

    # Выполняем SQL-запрос
    cursor.execute("SELECT version();")

    # Получаем результат выполнения запроса
    db_version = cursor.fetchone()
    print("PostgreSQL database version:", db_version)

    # Закрываем курсор
    cursor.close()

except (Exception, psycopg2.Error) as error:
    print("Ошибка подключения к базе данных:", error)

finally:
    # Закрываем соединение с базой данных
    if connection:
        connection.close()
