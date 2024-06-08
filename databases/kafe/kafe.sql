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
CREATE DOMAIN main.valid_phone_number AS VARCHAR(11) 
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
VALUES ('Нет скидки', 0)
('Скидка постоянного гостя', 15),
('Золотая карта', 20);


--
-- Заказчики
--
CREATE TABLE main.customers
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(128),
    phone main.valid_phone_number UNIQUE NOT NULL,
    fk_discount_id INT REFERENCES main.discounts(id)
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
    phone main.valid_phone_number UNIQUE NOT NULL,
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


--
-- ХРАНИМЫЕ ПРОЦЕДУРЫ
--

--
-- Добавление данных нового заказчика
--
CREATE OR REPLACE PROCEDURE main.add_customer(
    input_name VARCHAR(128), 
    input_phone main.phone_number,
    input_discont INT
    ) AS $$
    INSERT INTO main.customers(name, phone, discont)
    VALUES(input_name, input_phone, input_discont);
$$ LANGUAGE sql;


--
-- Добавление нового адреса
--
CREATE OR REPLACE PROCEDURE main.add_address(
    input_street VARCHAR(128), 
    input_house SMALLINT,
    input_apartment SMALLINT,
    input_entrance SMALLINT,
    input_floor SMALLINT
    ) AS $$
    INSERT INTO main.add_address(street, house, apartment, entrance, floor)
    VALUES(input_street, input_house, input_apartment, input_entrance, input_floor);
$$ LANGUAGE sql;


--
-- Привязка адреса к заказчику
--
CREATE OR REPLACE PROCEDURE main.rel_customer_address(
    input_customer_id INT, 
    input_address_id INT,
    ) AS $$
    INSERT INTO main.addresses_customers(fk_customer_id, fk_address_id)
    VALUES(input_customer_id, input_address_id);
$$ LANGUAGE sql;


--
-- Создание заказа на доставку
--
CREATE OR REPLACE PROCEDURE main.create_order_delivery(
    input_dish_id INT,
    input_amount_dish INT,
    input_status VARCHAR(8), 
    input_comment VARCHAR(50),
    input_customer_id INT
    ) AS $$
    INSERT INTO main.orders(status, comment)
    VALUES(input_status, input_comment)
    RETURNING id INTO new_order_id;
    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(input_amount_dish, new_order_id, input_dish_id);
    INSERT INTO main.orders_delivery(fk_customer_id, fk_order_id)
    VALUES(input_customer_id, new_order_id);
$$ LANGUAGE sql;


--
-- Создание заказа на самовывоз
--
CREATE OR REPLACE PROCEDURE main.create_order_take_out(
    input_dish_id INT,
    input_amount_dish INT,
    input_status VARCHAR(8), 
    input_comment VARCHAR(50),
    input_desk SMALLINT,
    input_waiter
    ) AS $$
    INSERT INTO main.orders(status, comment)
    VALUES(input_status, input_comment)
    RETURNING id INTO new_order_id;
    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(input_amount_dish, new_order_id, input_dish_id);
    INSERT INTO main.orders_take_out(desk, fk_order_id)
    VALUES(input_phone, new_order_id);
$$ LANGUAGE sql;


--
-- Создание заказа в зале
--
CREATE OR REPLACE PROCEDURE main.create_order_hall(
    input_dish_id INT,
    input_amount_dish INT,
    input_status VARCHAR(8), 
    input_comment VARCHAR(50),
    input_waiter_id INT
    ) AS $$
    INSERT INTO main.orders(status, comment)
    VALUES(input_status, input_comment)
    RETURNING id INTO new_order_id;
    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(input_amount_dish, new_order_id, input_dish_id);
    INSERT INTO main.orders_hall(desk, fk_order_id, fk_waiter_id)
    VALUES(input_desk, new_order_id, input_waiter_id);
$$ LANGUAGE sql;