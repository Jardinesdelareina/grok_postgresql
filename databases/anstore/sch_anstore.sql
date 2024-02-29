DROP SCHEMA IF EXISTS anstore_v1 CASCADE;
CREATE SCHEMA anstore_v1;

--
-- Категории товаров
--
CREATE TABLE anstore_v1.categories
(
    category_id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_title VARCHAR(24) UNIQUE NOT NULL
);


--
-- Товар
--
CREATE TABLE anstore_v1.products
(
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_title VARCHAR(100) NOT NULL,
    product_image VARCHAR(200) NOT NULL,
    product_description TEXT,
    product_price DOUBLE PRECISION NOT NULL,
    product_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_category_id SMALLINT REFERENCES anstore_v1.categories(category_id)
);

CREATE INDEX idx_products_title ON anstore_v1.products (product_title);


--
-- Корзина покупок
--
CREATE TABLE anstore_v1.carts
(
    cart_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_id INTEGER REFERENCES anstore_v1.products(product_id)
);


-- 
-- Покупатель
--
CREATE TABLE anstore_v1.users
(
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    fk_cart_id INTEGER REFERENCES anstore_v1.carts(cart_id),

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Заказ
--
CREATE TABLE anstore_v1.orders
(
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number BIGINT UNIQUE NOT NULL,
    order_status VARCHAR(11) CHECK (order_status IN ('SUCCESS', 'TIMEOUT', 
                                                    'CREATED_PAY', 'FINISHED', 
                                                    'PAID')) DEFAULT 'PAID',
    order_comment TEXT,
    order_time TIMESTAMPTZ DEFAULT NOW(),
    signer_name VARCHAR(100) NOT NULL,
    signer_address VARCHAR(300) NOT NULL,
    signer_phone VARCHAR(14) NOT NULL
);

CREATE INDEX idx_orders_status ON anstore_v1.orders (order_status);
CREATE INDEX idx_orders_time ON anstore_v1.orders (order_time);


--
-- Детали заказа
--
CREATE TABLE anstore_v1.order_items
(
    fk_order_id BIGINT REFERENCES anstore_v1.orders(order_id),
    fk_product_id INTEGER REFERENCES anstore_v1.products(product_id),
    amount INTEGER NOT NULL
);