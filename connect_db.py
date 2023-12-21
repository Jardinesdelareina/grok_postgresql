import psycopg2
import environs

env = environs.Env()
env.read_env('.env')


def connect_db(database: str):
    # Установка соединения
    try:
        connection = psycopg2.connect(
            host= env ('HOST'),
            port= env ('PORT'),
            database = database,
            user = env('USER'),
            password = env('PASSWORD')
        )
        cursor = connection.cursor()
        print(f'[SUCCESS] Connect {database}')
        
        # Здесь можно выполнять SQL-запросы используя 'cursor'

    except (Exception, psycopg2.Error) as error:
        print('[ERROR]', error)
    finally:
        if connection:
            cursor.close()
            connection.close()
            print(f'[INFO] Connection {database} closed')