# Базы данных

### Реляционная модель данных

<em>Реляционная модель данных</em> - это математическая модель, которая описывает способ организации и хранения данных в базе данных. Она основана на понятии "таблицы" или "реляции", которая состоит из строк и столбцов.

В реляционной модели каждая таблица имеет набор атрибутов (столбцов), которые определяют тип данных, содержащихся в каждой ячейке столбца. Каждая строка таблицы представляет собой конкретную запись или кортеж данных.

Главная идея реляционной модели заключается в том, что связи между таблицами (реляциями) осуществляются через общие атрибуты, так называемые "внешние ключи". Внешний ключ в таблице ссылается на первичный ключ другой таблицы, что позволяет связывать данные между разными таблицами.

Преимущества реляционной модели данных:
1. Простота структуры и понятность модели.
2. Гибкость и возможность создания сложных запросов для извлечения данных.
3. Независимость от физической реализации данных.
4. Высокая надежность и целостность данных.
5. Поддержка множества операций, таких как сортировка, поиск, фильтрация и соединение данных.


### Установка и использование PostgreSQL в Linux


<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/linux/linux-original.svg" width="40" height="40"/>&nbsp;
    <img src="https://github.com/devicons/devicon/blob/master/icons/postgresql/postgresql-original.svg" width="40" height="40"/>&nbsp;
</div>


`sudo apt install postgresql`   установка

`sudo service postgresql status`    проверка, запущен ли сервис

`sudo service postgresql start`     запуск сервера если он не запущен

`sudo service postgresql restart`   перезапуск сервера postgresql

`sudo pg_isready`       проверка. готов ли сервер postgresql принимать подключение от клиентов

`sudo -u postgres psql`     подключение к серверу, активация оболочки <b>psql</b>

`CREATE USER your_username WITH PASSWORD 'your_password';`      создание пользователя и пароля

`GRANT ALL PRIVILEGES ON DATABASE your_database TO your_username;`      предоставление привелегий новому пользователю

`\q`    выход из <b>psql</b>


### Установка pgAdmin4

1. Установка из репозитория <b>pgAdmin4 APT</b>:

`curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add`

`sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'`

2. Запуск установки <b>pgAdmin4</b>:

`sudo apt install pgadmin4`

3. Запуск скрипта, устанавливающего веб-компоненты. Скрипт находится по адресу `/usr/pgadmin4/bin/setup-web.sh`.

4. В процессе установки будет перезапущена служба Apache2. После завершения работы скрипта необходимо добавить разрешение для Apache2 на доступ через брэндмауэр:

`sudo ufw allow 'Apache'`

5. Запуск брэндмауэра:

`sudo ufw enable`

6. Убедиться, что Apache2 включена в список разрешенных в брэндмауэре:

`sudo ufw status`

7. Для доступа к веб-версии pgAdmin4 ввести в браузере:

`http://<ip-адрес:порт>/pgadmin4`


### Основные команды PSQL

`\l`    список баз данных

`\c <db_name>`  подключение к базе данных

`\dt`   список таблиц базы данных

`\du`   список пользователей


### Типы данных

Типы данных [описаны в документации](https://postgrespro.ru/docs/postgresql/14/datatype). 

Некоторые типы данных PostgreSQl:

1. Числовые:
   - `INTEGER` (целочисленный тип)
   - `BIGINT` (большие целые числа)
   - `DECIMAL` или `NUMERIC` (число с фиксированной точностью)
   - `REAL` или `FLOAT4` (число с плавающей запятой с одинарной точностью)
   - `DOUBLE PRECISION` или `FLOAT8` (число с плавающей запятой с двойной точностью)

2. Символьные:
   - `CHAR(n)` или `CHARACTER(n)` (строка фиксированной длины)
   - `VARCHAR(n)` или `CHARACTER VARYING(n)` (строка переменной длины)
   - `TEXT` (строка переменной длины без ограничений)

3. Дата и время:
   - `DATE` (дата)
   - `TIME` (время без часового пояса)
   - `TIMESTAMP` (дата и время без часового пояса)
   - `TIMESTAMPTZ` (дата и время с часовым поясом)

4. Логический:
   - `BOOLEAN` (логическое значение: `TRUE` или `FALSE`)

5. Бинарные:
   - `BYTEA` (переменная длина для бинарных данных)

6. Массивы:
   - `INTEGER[]` (массив целых чисел)
   - `VARCHAR(255)[]` (массив строк переменной длины)


### Базовые конструкции SQL

##### *
Вывести все колонки из таблицы products:
```sql
SELECT * FROM products;
```

##### Подсчет количества строк в колонке
Вывести количество записей в таблице products:
```sql
SELECT COUNT(*) FROM products;
```

##### Несколько колонок
Вывести колонки product_name и unit_price из таблицы products:
```sql
SELECT product_name, unit_price FROM products;
```

##### Исключение дубликатов
Вывести данные без повторений из колонки unit_price таблицы products:
```sql
SELECT DISTINCT unit_price FROM products;
```

##### WHERE, OFFSET, LIMIT
Вывести product_name из products, где discontinued равен 0, записи с 5 по 10:
```sql
SELECT product_name FROM products WHERE discontinued = 0 OFFSET 5 LIMIT 10;
```

##### IN
Вывести те записи product_name из products, в которых reorder_level равен одному из значений, указанных в скобках:
```sql
SELECT product_name FROM products WHERE reorder_level IN (25, 15);
```

##### BEETWEEN ... AND ...
Вывести данные из колонок order_date и order_id из таблицы orders, где order_date находится в пределах от '1997-01-01' до '1998-01-01':
```sql
SELECT order_date, order_id FROM orders WHERE order_date BETWEEN '1997-01-01' AND '1998-01-01';
```

##### Выборка по совпадениям
Вывести те данные из customer_id и company_name из таблицы customers, где в названии customers_id в середине присутствует символ 'A':
('%A' - если customer_id оканчивается на 'A',
'A%'- если customer_id начинается на 'A')
```sql
SELECT customer_id, company_name FROM customers WHERE customer_id LIKE '%A%';
```

##### Переименование колонок
Вывести данные company_name, переименовав колонку в com_name:
```sql
SELECT company_name AS com_name FROM customers;
```

##### Максимальное значение
Вывести максимальное значение unit_price из таблицы order_details:
```sql
SELECT MAX(unit_price) FROM order_details;
```

##### Округление, среднее значение
Вывести округленное среднее число unit_price из таблицы order_details:
```sql
SELECT ROUND(AVG(unit_price)) FROM order_details;
```

##### Арифметика в запросе
Вывести округленное произведение значений колонок unit_price и quantity и поместить полученные значения в колонку, названную res_values:
```sql
SELECT ROUND(unit_price * quantity) AS res_value FROM order_details;
```

##### НЕ
Вывести значения order_id и discount из order_details, которые НЕ равны 0: 
```sql
SELECT order_id, discount FROM order_details WHERE discount <> 0;
```

##### Обратный порядок
Вывести customer_id и order_date из таблицы orders, где значения отсортированы по колонке order_date В ОБРАТНОМ ПОРЯДКЕ:
```sql
SELECT customer_id, order_date FROM orders ORDER BY order_date DESC;
```

##### Группировка данных
Вывести общее количество записей колонки country из таблицы employees, сгруппировав результат по колонке country (количество каждой из country):
```sql
SELECT country, COUNT(*) FROM employees GROUP BY country;
```

##### Фильтрация результатов
Вывести category_id и сумму произведений unit_price и units_in_stock в таблице products, сгруппировав результаты по category_id (сколько суммарно вышло sum_price на каждый category_id) и отфильтровав результаты (вывести только те category_id), где SUM(unit_price * units_in_stock) больше 5000:
(работает в сочетании с GROUP BY)
```sql
SELECT category_id, SUM(unit_price * units_in_stock) AS sum_price
FROM products
GROUP BY category_id
HAVING SUM(unit_price * units_in_stock) > 5000;
```

##### Объединение
Вывести country из таблицы employees, country из таблицы customers и объединить результаты в одну колонку:
(UNION устраняет дубликаты,
UNION ALL выводит результат с дубликатами)
```sql
SELECT country FROM employees
UNION
SELECT country FROM customers;
```

##### Пересечение
Вывести country, совпадающие для customers и suppliers:
```sql
SELECT country FROM customers
INTERSECT
SELECT country FROM suppliers;
```

##### Исключение
Вывести country из таблицы customers, которых нет в country таблицы suppliers:
```sql
SELECT country FROM customers
EXCEPT
SELECT country FROM suppliers;
```