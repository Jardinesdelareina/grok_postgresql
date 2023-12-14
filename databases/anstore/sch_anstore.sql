--
-- Drop tables;
--
DROP TABLE order_items;
DROP TABLE orders;
DROP TABLE users;
DROP TABLE carts;
DROP TABLE products;
DROP TABLE categories;


--
-- Name: categories; 
-- Type: TABLE;
--
CREATE TABLE categories
(
    category_id SMALLSERIAL PRIMARY KEY,
    category_title VARCHAR(24) UNIQUE NOT NULL
);


--
-- Name: products; 
-- Type: TABLE;
--
CREATE TABLE products
(
    product_id SERIAL PRIMARY KEY,
    product_title VARCHAR(100) NOT NULL,
    product_image VARCHAR(200) NOT NULL,
    product_description TEXT,
    product_price DOUBLE PRECISION NOT NULL,
    product_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_category_id SMALLINT REFERENCES categories(category_id)
);


--
-- Name: carts; 
-- Type: TABLE;
--
CREATE TABLE carts
(
    cart_id SERIAL PRIMARY KEY,
    fk_product_id INTEGER REFERENCES products(product_id)
);


-- Name: users; 
-- Type: TABLE;
--
CREATE TABLE users
(
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    fk_cart_id INTEGER REFERENCES carts(cart_id),

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Name: orders; 
-- Type: TABLE;
--
CREATE TABLE orders
(
    order_id BIGSERIAL PRIMARY KEY,
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


--
-- Name: order_items; 
-- Type: TABLE;
--
CREATE TABLE order_items
(
    fk_order_id BIGINT REFERENCES orders(order_id),
    fk_product_id INTEGER REFERENCES products(product_id),
    amount INTEGER NOT NULL
);