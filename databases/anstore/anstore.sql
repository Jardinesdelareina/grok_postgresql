\connect postgres

DROP DATABASE anstore;
CREATE DATABASE anstore;

\connect anstore;

DROP SCHEMA IF EXISTS anstore_v1 CASCADE;
CREATE SCHEMA anstore_v1;


--
-- Категории товаров
--
CREATE TABLE anstore_v1.categories
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(24) UNIQUE NOT NULL
);


--
-- Товары
--
CREATE TABLE anstore_v1.products
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    image VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    fk_category_id SMALLINT REFERENCES anstore_v1.categories(id)
);


-- 
-- Покупатели
--
CREATE TABLE anstore_v1.users
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(150) NOT NULL,
    gender VARCHAR(1) CHECK (gender IN ('M', 'F')),

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Привязанные банковские карты
--
CREATE TABLE anstore_v1.cards
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    number VARCHAR(12) NOT NULL,
    term VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) NOT NULL,
    fk_user_id INTEGER REFERENCES anstore_v1.users(id)
);


--
-- Пункты доставки товара
--
CREATE TABLE anstore_v1.delivery_point_items
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    street VARCHAR(100) NOT NULL,
    house VARCHAR(4) NOT NULL
);


--
-- Пункты доставки товара, выбранные пользователем
--
CREATE TABLE anstore_v1.delivery_points
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_delivery_point_item_id SMALLINT REFERENCES anstore_v1.delivery_point_items(id),
    fk_user_id INTEGER REFERENCES anstore_v1.users(id)
);


--
-- Корзины покупок
--
CREATE TABLE anstore_v1.carts
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id INTEGER REFERENCES anstore_v1.users(id)
);


--
-- Содержимое корзины покупок
--
CREATE TABLE anstore_v1.carts_products
(
    fk_cart_id SMALLINT REFERENCES anstore_v1.carts(id),
    fk_product_id INTEGER REFERENCES anstore_v1.products(id)
);


--
-- Заказы
--
CREATE TABLE anstore_v1.orders
(
    id BIGINT UNIQUE NOT NULL PRIMARY KEY,
    status VARCHAR(11) CHECK (status IN ('SUCCESS', 'TIMEOUT', 'CREATED_PAY', 
                                        'FINISHED', 'PAID')) DEFAULT 'PAID',
    comment TEXT,
    time TIMESTAMPTZ DEFAULT NOW(),
    fk_delivery_point_id INTEGER REFERENCES anstore_v1.delivery_points(id)
);


--
-- Детали заказа
--
CREATE TABLE anstore_v1.order_items
(
    amount SMALLINT DEFAULT 1,
    fk_order_id BIGINT REFERENCES anstore_v1.orders(id),
    fk_product_id INTEGER REFERENCES anstore_v1.products(id)
);