import os
import json
import requests
import psycopg2
import environs
from bs4 import BeautifulSoup
from transliterate import translit

env = environs.Env()
env.read_env('.env')

DB_USER = env('DB_USER')
DB_PASS = env('DB_PASS')
DB_HOST = env('DB_HOST')
DB_NAME = env('DB_NAME')

connection = psycopg2.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASS
)
cursor = connection.cursor()


dirs = ['obj/', 'data/']
for i in dirs:
    if not os.path.exists(i):
        os.mkdir(i)

headers = {
    'Accept': '/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36',
}
url = 'https://kenzo29.ru/catalog'

""" req = requests.get(url=url, headers=headers)
soup = BeautifulSoup(req.text, 'lxml')

menu_dict = {}
menu = soup.find_all(class_='catalog-section-list-item-wrapper')
for i in menu:
    cat_title = i.find(class_='catalog-section-list-item-name').text.strip().replace(' ', '_')
    cat_title_translit = translit(cat_title, 'ru', reversed=True)
    cat_link = url + i.find('a').get('href').replace('/catalog', '')
    menu_dict[cat_title_translit] = cat_link

    with open('obj/menu.json', 'w', encoding='utf-8') as file:
        json.dump(menu_dict, file, indent=4, ensure_ascii=False) """

with open('obj/menu.json', 'r') as file:
    cat = json.load(file)

count = 0

def scrap_data(url):
    global count
    req = requests.get(url=url, headers=headers)
    soup = BeautifulSoup(req.text, 'lxml')
    dishes = soup.find_all(class_='catalog-section-item-wrapper')

    dish_dict = []

    for i in dishes:
        title = i.find('div', class_='intec-cl-text-hover').text.strip()
        try:
            description = i.find('div', class_='catalog-section-item-description').text.strip()
        except:
            description = '---'
        price = i.find('div', class_='catalog-section-item-price-base').text.replace("\xa0", "").replace('₽', '').strip()

        result_data = {
            'title': title,
            'description': description,
            'price': price,
            'is_available': True,
            'category': 1
        }
        dish_dict.append(result_data)
        count += 1
        print(count, key)

    with open(f'data/{key.lower()}.json', 'w', encoding='utf-8') as file:
        json.dump(dish_dict, file, indent=4, ensure_ascii=False)

    
    for dish in dish_dict:
        cursor.execute("INSERT INTO kafe_v1.dishes(title, description, price, is_available, fk_category_id) VALUES(%s, %s, %s, %s, %s)", 
                        (dish['title'], dish['description'], dish['price'], dish['is_available'], dish['category']))
        connection.commit()
        

for key, value in cat.items():
    req = requests.get(url=value, headers=headers)
    soup = BeautifulSoup(req.text, 'lxml')
    pagination = soup.find(class_='system-pagenavigation-item-next')
    if pagination:
        pages_count = pagination.find_previous().text
        for page in range(1, int(pages_count) + 1):
            url_pagination = f'{value}?PAGEN_1={page}'
            scrap_data(url=url_pagination)
    else:
        scrap_data(url=value)