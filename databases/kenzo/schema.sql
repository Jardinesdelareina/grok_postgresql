/*
    Конфигурация сессии PostgreSQL
*/

-- Устанавливает ограничение времени выполнения для SQL-запросов в 0, 
-- что означает, что ограничение времени выполнения отключено.
SET statement_timeout = 0;

-- Устанавливает ограничение времени выполнения для SQL-запросов в 0, 
-- что означает, что ограничение времени выполнения отключено.
SET lock_timeout = 0;

-- Устанавливает кодировку клиента для работы с базой данных в UTF-8, 
-- что позволяет использовать символы Unicode.
SET client_encoding = 'UTF8';

-- Включает режим соответствия стандартам для строковых литералов, 
-- где символ ' может быть представлен как ''.
SET standard_conforming_strings = on;

-- Отключает проверку тел функций при создании / изменении функций.
SET check_function_bodies = false;

-- Устанавливает минимальный уровень сообщений для клиента на уровне предупреждений.
SET client_min_messages = warning;

-- Определяет таблицовое пространство по умолчанию для новых таблиц, 
-- в данном случае, значение `''` указывает на отсутствие значения (null).
SET default_tablespace = '';

-- Отключает использование OIDs (объектных идентификаторов)
SET default_with_oids = false;


/*
    Предварительное удаление таблиц
*/

DROP TABLE orders_dishes;
DROP TABLE addresses_customers;
DROP Table customers;
DROP TABLE addresses;
DROP TABLE dishes;
DROP TABLE categories;
DROP TABLE orders;


/*
    Создание таблиц
*/

--
-- Адреса заказчиков
--
CREATE TABLE addresses
(
    address_id SERIAL PRIMARY KEY,
    address_street CHARACTER VARYING(128) NOT NULL,
    address_house SMALLINT NOT NULL,
    address_apartment SMALLINT,
    address_entrance SMALLINT,
    address_floor SMALLINT
);


--
-- Заказчики
--
CREATE TABLE customers
(
    customer_id INTEGER PRIMARY KEY,
    customer_name CHARACTER VARYING(128),
    customer_phone CHARACTER VARYING(10) UNIQUE NOT NULL,
    customer_discount BOOLEAN DEFAULT FALSE
);


--
-- Many to Many addresses и customers
-- Адреса заказчиков
--
CREATE TABLE addresses_customers
(
    addresses_customers_id SERIAL PRIMARY KEY,
    fk_customer_id INTEGER REFERENCES customers(customer_id),
    fk_address_id INTEGER REFERENCES addresses(address_id)
);


--
-- Заказы
--
CREATE TABLE orders
(
    order_id BIGSERIAL PRIMARY KEY,
    order_number CHARACTER VARYING(16) NOT NULL,
    order_status CHARACTER VARYING(10) CHECK (order_status IN ('ACCEPTED', 
                                                                'CLOSED', 
                                                                'CANCELED')) NOT NULL,
    order_created TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    order_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


--
-- Категории блюд
--
CREATE TABLE categories
(
    category_id SMALLINT PRIMARY KEY,
    category_title CHARACTER VARYING(32) NOT NULL
);


--
-- Блюда
--
CREATE TABLE dishes
(
    dish_id SMALLINT PRIMARY KEY,
    dish_title CHARACTER VARYING(128) UNIQUE NOT NULL,
    dish_description TEXT,
    dish_price NUMERIC(10, 2) NOT NULL,
    fk_category_id INTEGER REFERENCES categories(category_id)
);


--
-- Many to Many orders и dishes
-- Блюда в заказе
--
CREATE TABLE orders_dishes
(
    orders_dishes_id BIGSERIAL PRIMARY KEY,
    orders_dishes_amount DOUBLE PRECISION DEFAULT 1,
    fk_order_id INTEGER REFERENCES orders(order_id),
    fk_dish_id INTEGER REFERENCES dishes(dish_id)
);