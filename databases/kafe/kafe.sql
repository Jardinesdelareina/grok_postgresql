\connect postgres

DROP DATABASE IF EXISTS kafe;
CREATE DATABASE kafe;

\connect kafe

--
-- Адреса заказчиков
--
CREATE TABLE addresses
(
    address_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_street VARCHAR(128) NOT NULL,
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
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(128),
    customer_phone VARCHAR(10) UNIQUE NOT NULL,
    customer_discount BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_phone_customers 
ON customers (customer_phone);


--
-- Many to Many addresses и customers
-- Адреса заказчиков
--
CREATE TABLE addresses_customers
(
    addresses_customers_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INT REFERENCES customers(customer_id),
    fk_address_id INT REFERENCES addresses(address_id)
);

CREATE INDEX idx_address_customers 
ON addresses (address_street, address_house);


--
-- Заказы
--
CREATE TABLE orders
(
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number VARCHAR(16) NOT NULL,
    order_status VARCHAR(10) CHECK (order_status IN ('ACCEPTED', 
                                                                'CLOSED', 
                                                                'CANCELED')) NOT NULL,
    order_created TIMESTAMPTZ DEFAULT NOW(),
    order_updated TIMESTAMPTZ DEFAULT NOW(),
    fk_customer_id INT REFERENCES customers(customer_id) 
);


--
-- Категории блюд
--
CREATE TABLE categories
(
    category_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_title VARCHAR(32) NOT NULL
);


--
-- Блюда
--
CREATE TABLE dishes
(
    dish_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dish_title VARCHAR(128) UNIQUE NOT NULL,
    dish_description TEXT,
    dish_price DECIMAL(10, 2) NOT NULL,
    dish_is_available BOOLEAN DEFAULT TRUE,
    fk_category_id INT REFERENCES categories(category_id)
);

CREATE INDEX idx_dish 
ON dishes (dish_title);


--
-- Many to Many orders и dishes
-- Блюда в заказе
--
CREATE TABLE orders_dishes
(
    orders_dishes_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    orders_dishes_amount SMALLINT DEFAULT 1,
    fk_order_id INT REFERENCES orders(order_id),
    fk_dish_id INT REFERENCES dishes(dish_id)
);
