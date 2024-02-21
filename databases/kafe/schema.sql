/*
    Предварительная очистка схемы со всем содержимым, 
    создание новой схемы базы данных
*/

DROP SCHEMA IF EXISTS kafe_v1 CASCADE;
CREATE SCHEMA kafe_v1;


/*
    Создание таблиц
*/

--
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses
(
    address_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_street CHARACTER VARYING(128) NOT NULL,
    address_house SMALLINT NOT NULL,
    address_apartment SMALLINT,
    address_entrance SMALLINT,
    address_floor SMALLINT
);


--
-- Заказчики
--
CREATE TABLE kafe_v1.customers
(
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name CHARACTER VARYING(128),
    customer_phone CHARACTER VARYING(10) UNIQUE NOT NULL,
    customer_discount BOOLEAN DEFAULT FALSE
);


--
-- Many to Many addresses и customers
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses_customers
(
    addresses_customers_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INTEGER REFERENCES kafe_v1.customers(customer_id),
    fk_address_id INTEGER REFERENCES kafe_v1.addresses(address_id)
);


--
-- Заказы
--
CREATE TABLE kafe_v1.orders
(
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
CREATE TABLE kafe_v1.categories
(
    category_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_title CHARACTER VARYING(32) NOT NULL
);


--
-- Блюда
--
CREATE TABLE kafe_v1.dishes
(
    dish_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dish_title CHARACTER VARYING(128) UNIQUE NOT NULL,
    dish_description TEXT,
    dish_price NUMERIC(10, 2) NOT NULL,
    fk_category_id INTEGER REFERENCES kafe_v1.categories(category_id)
);


--
-- Many to Many orders и dishes
-- Блюда в заказе
--
CREATE TABLE kafe_v1.orders_dishes
(
    orders_dishes_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orders_dishes_amount DOUBLE PRECISION DEFAULT 1,
    fk_order_id INTEGER REFERENCES kafe_v1.orders(order_id),
    fk_dish_id INTEGER REFERENCES kafe_v1.dishes(dish_id)
);


/*
    Индексы
*/

CREATE INDEX idx_address_customers ON kafe_v1.addresses (address_street, address_house);
CREATE INDEX idx_phone_customers ON kafe_v1.customers (customer_phone);
CREATE INDEX idx_dish ON kafe_v1.dishes (dish_title);
