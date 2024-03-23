/*
    Предварительная очистка схемы со всем содержимым, удаление табличного пространства, 
    создание нового табличного пространства и новой схемы базы данных
*/

DROP SCHEMA IF EXISTS kafe_v1 CASCADE;
DROP TABLESPACE IF EXISTS main_kafe;
CREATE TABLESPACE main_kafe LOCATION '/etc/postgresql/14/main';
CREATE SCHEMA kafe_v1;


/*
    Создание таблиц
*/

--
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses
(
    address_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_street VARCHAR(128) NOT NULL,
    address_house SMALLINT NOT NULL,
    address_apartment SMALLINT,
    address_entrance SMALLINT,
    address_floor SMALLINT
) TABLESPACE main_kafe;


--
-- Заказчики
--
CREATE TABLE kafe_v1.customers
(
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(128),
    customer_phone VARCHAR(10) UNIQUE NOT NULL,
    customer_discount BOOLEAN DEFAULT FALSE
) TABLESPACE main_kafe;

CREATE INDEX idx_phone_customers 
ON kafe_v1.customers (customer_phone) TABLESPACE main_kafe;


--
-- Many to Many addresses и customers
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses_customers
(
    addresses_customers_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INT REFERENCES kafe_v1.customers(customer_id),
    fk_address_id INT REFERENCES kafe_v1.addresses(address_id)
) TABLESPACE main_kafe;

CREATE INDEX idx_address_customers 
ON kafe_v1.addresses (address_street, address_house) TABLESPACE main_kafe;


--
-- Заказы
--
CREATE TABLE kafe_v1.orders
(
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number VARCHAR(16) NOT NULL,
    order_status VARCHAR(10) CHECK (order_status IN ('ACCEPTED', 
                                                                'CLOSED', 
                                                                'CANCELED')) NOT NULL,
    order_created TIMESTAMPTZ DEFAULT NOW(),
    order_updated TIMESTAMPTZ DEFAULT NOW(),
    fk_customer_id INT REFERENCES kafe_v1.customers(category_id) 
) TABLESPACE main_kafe;


--
-- Категории блюд
--
CREATE TABLE kafe_v1.categories
(
    category_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_title VARCHAR(32) NOT NULL
) TABLESPACE main_kafe;


--
-- Блюда
--
CREATE TABLE kafe_v1.dishes
(
    dish_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dish_title VARCHAR(128) UNIQUE NOT NULL,
    dish_description TEXT,
    dish_price DECIMAL(10, 2) NOT NULL,
    dish_is_available BOOLEAN DEFAULT TRUE,
    fk_category_id INT REFERENCES kafe_v1.categories(category_id)
) TABLESPACE main_kafe;

CREATE INDEX idx_dish 
ON kafe_v1.dishes (dish_title) TABLESPACE main_kafe;


--
-- Many to Many orders и dishes
-- Блюда в заказе
--
CREATE TABLE kafe_v1.orders_dishes
(
    orders_dishes_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orders_dishes_amount SMALLINT DEFAULT 1,
    fk_order_id INT REFERENCES kafe_v1.orders(order_id),
    fk_dish_id INT REFERENCES kafe_v1.dishes(dish_id)
) TABLESPACE main_kafe;
