import json
import psycopg2
import environs
import datetime

env = environs.Env()
env.read_env('.env')

DB_HOST = env('DB_HOST')
DB_NAME = env('DB_NAME')
DB_USER = env('DB_USER')
DB_PASS = env('DB_PASS')

connection = psycopg2.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASS
)
cursor = connection.cursor()


def load_data():

    with open('data.json', 'r') as f:
        obj = json.load(f)
    
    for i in obj:
        cursor.execute("INSERT INTO main.dishes(title, description, price, is_available, created_at, fk_category_id) VALUES(%s, %s, %s, %s, %s, %s)", 
                        (
                            i['title'], 
                            i['description'], 
                            i['price'], 
                            i['is_available'],
                            datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                            i['category']
                        ))
        connection.commit()
        print(i['title'])


load_data()