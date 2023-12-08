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

##### Соединение
<b>INNER JOIN</b> 
Вывести product_name и units_in_stock из products и company_name из suppliers, левая таблица - products, правая - suppliers, соединить их по колонке supplier_id, одинаковой для обеих таблиц:
(для таблицы products колонка supplier_id является внешним ключом),
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