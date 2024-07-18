import environs
import psycopg2

env = environs.Env()
env.read_env('.env')

DB_USER = env('POSTGRES_USER')
DB_PASS = env('POSTGRES_PASSWORD')
DB_HOST = env('POSTGRES_HOST')
DB_NAME = env('POSTGRES_DB')

try:
    connection = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    cursor = connection.cursor()

except (Exception, psycopg2.Error) as error:
    print("Ошибка подключения к базе данных:", error)

