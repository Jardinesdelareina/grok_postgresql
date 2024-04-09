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
    phone VARCHAR(11) UNIQUE NOT NULL,
    discount BOOLEAN DEFAULT FALSE
);


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


--
-- Официанты
--
CREATE TABLE kafe_v1.waiters
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);


--
-- Заказы
--
CREATE TABLE kafe_v1.orders
(
    id BIGINT NOT NULL PRIMARY KEY,
    status VARCHAR(10) CHECK (status IN ('ACCEPTED', 'CLOSED', 'CANCELED')) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    comment VARCHAR(50)
);


--
-- Заказы (доставка)
--
CREATE TABLE kafe_v1.orders_delivery
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INT REFERENCES kafe_v1.customers(id),
    fk_order_id BIGINT REFERENCES kafe_v1.orders(id)
);

CREATE INDEX idx_customer_orders_delivery ON kafe_v1.orders_delivery(fk_customer_id);
CREATE INDEX idx_order_orders_delivery ON kafe_v1.orders_delivery(fk_order_id);


--
-- Заказы (зал)
--
CREATE TABLE kafe_v1.orders_hall
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_number SMALLINT,
    fk_order_id BIGINT REFERENCES kafe_v1.orders(id),
    fk_waiter_id SMALLINT REFERENCES kafe_v1.waiters(id),

    CONSTRAINT table_number_range CHECK (table_number >= 1 AND table_number <= 32)
);

CREATE INDEX idx_order_orders_hall ON kafe_v1.orders_hall(fk_order_id);


--
-- Заказы (самовывоз)
--
CREATE TABLE kafe_v1.orders_take_out
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone VARCHAR(11) UNIQUE NOT NULL,
    fk_order_id BIGINT REFERENCES kafe_v1.orders(id)
);

CREATE INDEX idx_order_orders_take_out ON kafe_v1.orders_take_out(fk_order_id);


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