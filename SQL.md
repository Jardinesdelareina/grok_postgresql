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

('%A' - если customer_id оканчивается на 'A', 'A%'- если customer_id начинается на 'A')
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

(UNION устраняет дубликаты, UNION ALL выводит результат с дубликатами)
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

##### Соединение
<b>INNER JOIN</b> 
Вывести product_name и units_in_stock из products и company_name из suppliers, левая таблица - products, правая - suppliers, соединить их по колонке supplier_id, одинаковой для обеих таблиц:

(для таблицы products колонка supplier_id является внешним ключом)

<em>Соединение таблиц происходит по внешнему ключу, далее выбираются колонки, которые необходимо вывести из обеих таблиц.</em>

```sql
SELECT products.product_name, suppliers.company_name, products.units_in_stock
FROM products
INNER JOIN suppliers ON products.supplier_id = suppliers.supplier_id;
```

<b>LEFT / RIGHT JOIN</b>
Вывести количество записей из таблицы employees и объединить с таблицей orders по внешнему ключу employee_id:

(LEFT JOIN выведет все данные из левой таблицы и только совпадающие из правой. RIGHT JOIN работает обратным образом)

```sql
SELECT COUNT(*)
FROM employees
LEFT JOIN orders ON orders.employee_id = employees.employee_id;
```

##### Синтаксические конструкции USING и NATURAL при соединениях

<b>USING</b> берет наименование колонки, одинаковое для двух таблиц, по которой идет соединение.

<b>NATURAL</b> соединение происходит по всем одинаково проименованным колонкам.

```sql
INNER JOIN suppliers ON products.supplier_id = suppliers.supplier_id;

-- или

JOIN suppliers USING(supplier_id)

-- или

NATURAL JOIN suppliers
```

##### Подзапросы
Вывести те company_name из suppliers, country которых есть среди country из таблицы customers:

(Подзапросы часто можно заменить соединениями таблиц, но это возможно не всегда, а когда возможно, нужно ориентироваться на производительность запросов и их читабельность)
```sql
SELECT company_name
FROM suppliers
WHERE country IN (SELECT country
                FROM customers)
```

<b>WHERE EXISTS</b>
Вывести company_name и contact_name из customers, если соблюдено условие в подзапросе (Вывести customer_id из orders, где customer_id в таблицах orders и customers совпадает, и где freight находится в заданном диапазоне):

(EXISTS (или NOT EXISTS) возвращает True или False. Если True, то внешний запрос выводит выборку данных, если False то данных нет)

```sql
SELECT company_name, contact_name
FROM customers
WHERE EXISTS (SELECT customer_id
            FROM orders
            WHERE customer_id = customers.customer_id
            AND freight BETWEEN 50 AND 100)
```

<b>ANY / ALL</b>
Вывести company_name из customers, где customer_id равен НЕКОТОРЫМ из выборки в подзапросе (вывести customer_id из orders, соединив таблицы orders и order_details по order_id, где quantity больше 40):

(ANY - некоторые, ALL - все)

```sql
SELECT company_name
FROM customers
WHERE customer_id = ANY(SELECT customer_id
                        FROM orders
                        JOIN order_details USING(order_id)
                        WHERE quantity > 40)
```

### DDL (Data Difinition Language)

`CREATE TABLE table_name`   создать таблицу

`ALTER TABLE table_name`    изменить таблицу
    * `ADD COLUMN column_name data_type`  изменить колонку (с типом данных)
    * `RENAME TO new_table_name`     переименовать таблицу
    * `RENAME old_column_name TO new_column_name`   переименовать колонку
    * `ALTER COLUMN column_name SET DAtA TYPE data_type`    задать новый тип данных для колонки

`DROP TABLE table_name`    удалить таблицу

`TRUNCATE TABLE table_name`     очистить таблицу от данных

`DROP COLUMN column_name`       удалить колонку   


Изменить таблицу и добавить в нее внешний ключ:

(ключевое слово ONLY прямо указывает, что изменения относятся только к указанной таблице)
```sql
ALTER TABLE ONLY orders
    ADD CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES customers;
```

Изменить таблицу и назначить для атрибута PRIMARY KEY:
```sql
ALTER TABLE ONLY categories
    ADD CONSTRAINT pk_categories PRIMARY KEY (category_id);
```

Изменить таблицу, добавить условие CHECK для атрибута:
```sql
ALTER TABLE product
    ADD COLUMN price DECIMAL CONSTRAINT CHK_product_price CHECK (price >= 0);
```

##### Автоинкремент
В PostgreSQL более ранних версий, чем 9 в качестве автоинкремента используется тип SERIAL. В последних версиях наиболее предпочтительна следующая конструкция:

```sql
CREATE TABLE new_table
(
    column_id INT GENERATED ALWAYS AS IDENTITY (START WITH 0 INCREMENT BY 1) NOT NULL
);
```


##### UPDATE
Изменить в таблице table_name в колонке column_name атрибут с id 5:
```sql
UPDATE table_name
SET column_name
WHERE id = 5;
```

##### DELETE
Удалить из таблицы table_name данные, где rating < 50:
```sql
DELETE FROM table_name
WHERE rating < 50;
``` 

### Представление (VIEW)

VIEW (представление) - это виртуальная таблица, созданная на основе одной или нескольких таблиц в базе данных. Представление не содержит собственных данных, оно является логическим представлением данных из одной или нескольких таблиц и сохраняет результат запроса в виде временной или постоянной таблицы.

Представления используются для упрощения запросов к данным. Они позволяют пользователю или приложению работать с данными, не зная сложности запросов или структуры базы данных. 

Преимущества использования представлений:
1. Упрощение сложных запросов: Представления позволяют объединять и фильтровать данные из разных таблиц в один запрос, тем самым упрощая запросы для конечных пользователей.
2. Обеспечение безопасности данных: Представления могут служить фильтрами, ограничивающим доступ к определенным данным или столбцам.
3. Повторное использование запросов: Представления могут быть переиспользованы в различных частях приложения или запросах.
4. Упрощение разработки и обслуживания: Представления позволяют разработчикам абстрагироваться от сложности базы данных и сосредоточиться на запросах и бизнес-логике.

Чтобы создать представление, используется оператор <b>CREATE VIEW</b>, который определяет имя представления, выбирает столбцы и условия для фильтрации данных. Затем представление может быть использовано в запросах, как обычная таблица.

Пример создания представления:
```sql
CREATE VIEW myview AS
SELECT column1, column2
FROM table_name;
```

После создания представления можно использовать его в запросах:
```sql
SELECT * FROM myview;
```

Ограничения, налагаемые на VIEW:

* Можно только добавлять новые колонки,
    * нельзя удалить существующие,
    * нельзя переименовывать колонки,
    * нельзя менять порядок следования колонок
* Можно переименовывать сами VIEW

Чтобы была возможность вносить изменения во VIEW, вместо <b>CREATE VIEW</b> нужно прописывать <b>CREATE OR REPLACE VIEW</b>.

Условия для модификации данных через VIEW:
* Во VIEW используется только одна таблица в секции FROM,
* Во VIEW не используется DISTINCT, GROUP BY, HAVING, UNION, INTERSECT, EXCEPT, LIMIT
* Во VIEW не используются оконные функции MIN, MAX, SUM, COUNT, AVG


### CASE / WHEN

Вывести product_name, unit_price, unit_in_stock из таблицы products, и в зависимости от поставленных условий, в отдельную колонку amount выводить текстовые сообщения 'lots of', 'average' и 'low number':
```sql
SELECT product_name, unit_price, unit_in_stock
    CASE WHEN unit_in_stock >= 100 THEN 'lots of'
         WHEN unit_in_stock > 50 AND unit_in_stock < 100 THEN 'average'
         WHEN unit_in_stock < 50 THEN 'low number'
         ELSE 'unknown'
    END AS amount
FROM products;
```

### COALESCE

Вывести order_id, order_date и обработанную колонку ship_region таки образом, что будут отображены значения не NULL, а значения NULL будут заменены строкой 'нет данных';
```sql
SELECT order_id, order_date, COALESCE(ship_region, 'нет данных') AS ship_region
FROM orders;
```

### Функции

* SQL-функции
* Процедурные (pl/pgSQL функции)
* Серверные функции (написанные на C)
* Собственные C-функции

Простая скалярная функция
```sql
-- Синтаксис функции
CREATE OR REPLACE FUNCTION total_price() RETURNS DOUBLE PRECISION AS $$
	SELECT SUM(unit_price * units_in_stock) AS total
	FROM products
$$ LANGUAGE SQL;

-- Вызов функции
SELECT total_price() AS total_price_products;
```

Функция с аргументами
```sql
CREATE OR REPLACE FUNCTION get_product_price_by_name(p_price VARCHAR) RETURNS DOUBLE PRECISION AS $$
	SELECT unit_price
	FROM products
	WHERE product_name = prod_name
$$ LANGUAGE SQL;
```


### Индексы

Индексы используются для ускорения поиска, сортировки и фильтрации данных в таблицах. Они создаются на одном или нескольких столбцах таблицы и хранят отсортированные значения для эффективного доступа.

В PostgreSQL существует несколько типов индексов:

1. <b>B-дерево (B-tree)</b> - это самый распространенный тип индекса в PostgreSQL. Он хранит отсортированные значения ключей и обеспечивает быстрый поиск данных.
    
    * Создается по-умолчанию;
    ```sql
    CREATE INDEX idx_time ON btcusdt (curr_time);
    ```

    * Поддерживает операции >, <, <=, >=, =;

    * Поддерживает LIKE 'abc%' (но не '%abc');

    * Индексирует NULL;

    * Сложность поиска O(logN);


2. <b>Хэш-индекс (Hash index)</b> - используется для эффективного поиска точных значений ключа. Он создается на основе хэш-функции, что позволяет быстро найти соответствующую запись.
 
    ```sql
    CREATE INDEX idx_time ON btcusdt USING HASH (curr_time);
    ```

    * Поддерживает только операцию  '=';

    * Не отражается в журнале перезаписи (WALL);

    * Сложность поиска O(1) (мгновенно);


3. <b>GIN (Generalized Inverted Index)</b> - используется для полнотекстового поиска и поиска с использованием массивов и других сложных типов данных.

4. <b>GiST (Generalized Search Tree)</b> - обеспечивает поддержку различных типов поиска, таких как географический, полнотекстовый, поиск с учетом расстояния между объектами и многих других.

5. <b>SP-GiST (Space-Partitioned GiST)</b> - обеспечивает эффективный поиск и пространственную индексацию для ключей, связанных с пространственными объектами.

6. <b>BRIN (Block Range INdex)</b> - позволяет быстро и компактно находить блоки записей, которые удовлетворяют условию поиска в больших таблицах.

Для создания индекса в PostgreSQL вы можете использовать команду CREATE INDEX. Например, чтобы создать B-дерево индекс на столбце "name" в таблице "users", можно использовать следующий SQL-запрос:

```sql
CREATE INDEX idx_users_name ON users(name);
```

Использование правильных индексов может значительно улучшить производительность запросов в базе данных. Однако, следует быть осторожными с созданием слишком большого количества индексов, так как это может привести к увеличению времени на обновление данных.


##### <b>EXPLAIN</b>

Команда <b>EXPLAIN</b> в PostgreSQL используется для анализа и оптимизации выполнения запросов. При использовании команды <b>EXPLAIN</b> перед запросом, PostgreSQL предоставляет информацию о плане выполнения запроса, включая порядок выполнения операций, использование индексов, стоимость операций и другую полезную информацию.

Результат выполнения команды <b>EXPLAIN</b> представляет собой таблицу или дерево, которое обозначает порядок выполнения операций в запросе. Это дает возможность анализировать и понимать, как PostgreSQL будет выполнять ваш запрос, и даёт возможность оптимизировать его производительность.

При использовании команды <b>EXPLAIN ANALYZE</b>, кроме плана выполнения, будет произведено и фактическое выполнение запроса, собраны статистические данные и включено время выполнения каждой операции в плане.

Например, чтобы получить план выполнения запроса SELECT * FROM users, можно использовать следующую команду:

```sql
EXPLAIN SELECT * FROM users;
```

Это позволит увидеть, как PostgreSQL планирует выполнить этот запрос, т.е. какие индексы и операции будут использованы. В результате вы получите структурированную информацию, которая поможет вам оптимизировать запросы и улучшить производительность вашей базы данных.