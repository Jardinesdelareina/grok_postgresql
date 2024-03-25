\connect postgres

DROP DATABASE IF EXISTS kafe;
CREATE DATABASE kafe;

\connect kafe

DROP SCHEMA IF EXISTS kafe_v1 CASCADE;
CREATE SCHEMA kafe_v1;

--
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    street VARCHAR(128) NOT NULL,
    house SMALLINT NOT NULL,
    apartment SMALLINT,
    entrance SMALLINT,
    floor SMALLINT
);


--
-- Заказчики
--
CREATE TABLE kafe_v1.customers
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(128),
    phone VARCHAR(10) UNIQUE NOT NULL,
    discount BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_phone_customers 
ON kafe_v1.customers (phone);


--
-- Many to Many addresses и customers
-- Адреса заказчиков
--
CREATE TABLE kafe_v1.addresses_customers
(
    addresses_customers_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INT REFERENCES kafe_v1.customers(id),
    fk_address_id INT REFERENCES kafe_v1.addresses(id)
);

CREATE INDEX idx_address_customers 
ON kafe_v1.addresses (street, house);


--
-- Заказы
--
CREATE TABLE kafe_v1.orders
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    number VARCHAR(16) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('ACCEPTED', 
                                                'CLOSED', 
                                                'CANCELED')) NOT NULL,
    created TIMESTAMPTZ DEFAULT NOW(),
    updated TIMESTAMPTZ DEFAULT NOW(),
    is_available BOOLEAN DEFAULT TRUE,
    fk_customer_id INT REFERENCES kafe_v1.customers(id)
);


--
-- Категории блюд
--
CREATE TABLE kafe_v1.categories
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(32) NOT NULL
);


--
-- Блюда
--
CREATE TABLE kafe_v1.dishes
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) UNIQUE NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    fk_category_id INT REFERENCES kafe_v1.categories(id)
);

CREATE INDEX idx_dish 
ON kafe_v1.dishes (title);


--
-- Many to Many orders и dishes
-- Блюда в заказе
--
CREATE TABLE kafe_v1.orders_dishes
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    amount SMALLINT DEFAULT 1,
    fk_order_id INT REFERENCES kafe_v1.orders(id),
    fk_dish_id INT REFERENCES kafe_v1.dishes(id)
);