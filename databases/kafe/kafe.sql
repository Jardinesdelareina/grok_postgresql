\connect postgres

DROP DATABASE IF EXISTS kafe;
CREATE DATABASE kafe;

\connect kafe

DROP SCHEMA IF EXISTS main CASCADE;
CREATE SCHEMA main;


--
-- МОДЕЛИ ДАННЫХ
--


--
-- Валидация номера телефона
--
CREATE DOMAIN main.phone_number AS VARCHAR(11) 
    CHECK(VALUE LIKE '79%');


--
-- Адреса заказчиков
--
CREATE TABLE main.addresses
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    street VARCHAR(128) NOT NULL,
    house SMALLINT NOT NULL,
    apartment SMALLINT,
    entrance SMALLINT,
    floor SMALLINT
);


--
-- Скидки
--
CREATE TABLE main.discounts
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    discount SMALLINT NOT NULL
);

INSERT INTO main.discounts(title, discount)
VALUES('Скидка постоянного гостя', 15),
('Золотая карта', 20);


--
-- Заказчики
--
CREATE TABLE main.customers
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(128),
    phone main.phone_number UNIQUE NOT NULL,
    FK_discount_id INT REFERENCES main.discounts(id)
);


--
-- Many to Many addresses <=> customers
-- Адреса заказчиков
--
CREATE TABLE main.addresses_customers
(
    addresses_customers_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_customer_id INT REFERENCES main.customers(id),
    fk_address_id INT REFERENCES main.addresses(id)
);


--
-- Заказы
--
CREATE TABLE main.orders
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status VARCHAR(8) CHECK (status IN ('ACCEPTED', 'CLOSED', 'CANCELED')) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    comment VARCHAR(50)
);


--
-- Many to Many orders <=> customers
-- Заказы (доставка)
--
CREATE TABLE main.orders_delivery
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fk_customer_id INT REFERENCES main.customers(id),
    fk_order_id UUID REFERENCES main.orders(id)
);


--
-- Официанты
--
CREATE TABLE main.waiters
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO main.waiters(name) VALUES('Борщева Е.'),
('Онуфриенко И.'), ('Картаполова Т.'), ('Расмус К.'), ('Воронцовская В.');


--
-- Заказы (зал)
--
CREATE TABLE main.orders_hall
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    desk SMALLINT CHECK (desk >= 1 AND desk <= 32),
    fk_order_id UUID REFERENCES main.orders(id),
    fk_waiter_id SMALLINT REFERENCES main.waiters(id)
);


--
-- Заказы (самовывоз)
--
CREATE TABLE main.orders_take_out
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone main.phone_number UNIQUE NOT NULL,
    fk_order_id UUID REFERENCES main.orders(id)
);


--
-- Категории блюд
--
CREATE TABLE main.categories
(
    id SMALLINT PRIMARY KEY,
    title VARCHAR(32) NOT NULL
);

INSERT INTO main.categories(id, title) VALUES(1, 'Десерты'), 
(2, 'Горячие блюда'), (3, 'Салаты'), (4, 'Японская кухня'), (5, 'Напитки'),
(6, 'Пиццы'), (7, 'Супы');


--
-- Позиции меню
--
CREATE TABLE main.dishes
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) UNIQUE NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    fk_category_id SMALLINT REFERENCES main.categories(id)
);


--
-- Many to Many orders <=> dishes
-- Блюда в заказе
--
CREATE TABLE main.orders_dishes
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    amount SMALLINT DEFAULT 1,
    fk_order_id UUID REFERENCES main.orders(id),
    fk_dish_id SMALLINT REFERENCES main.dishes(id)
);