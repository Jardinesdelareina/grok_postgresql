DROP TABLE users_addresses;
DROP TABLE order_details;
DROP TABLE orders;
DROP TABLE products;
DROP TABLE images;
DROP TABLE addresses;
DROP TABLE users;


-- Таблицы products и images связь ONE TO ONE
-- Таблицы users и orders связь ONE TO MANY
-- Таблицы order_details и products связь ONE TO MANY
-- Таблицы order_details и orders связь ONE TO MANY
-- Таблицы users и addresses связь MANY TO MANY 

CREATE TABLE users
(
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(100) NOt NULL UNIQUE,
    password VARCHAR(100) NOT NULL 
);


CREATE TABLE addresses
(
    address_id SERIAL PRIMARY KEY,
    state VARCHAR(30),
    city VARCHAR(50),
    street VARCHAR(100),
    zip_code VARCHAR(10)
);


CREATE TABLE users_addresses
(
    user_id INTEGER REFERENCES users(user_id),
    address_id INTEGER REFERENCES addresses(address_id),
    CONSTRAINT users_addresses_pkey PRIMARY KEY (user_id, address_id)
);


CREATE TABLE orders
(Ё
    order_id SERIAL PRIMARY KEY,
    fk_user_id INTEGER REFERENCES users(user_id),
    order_date TIMESTAMP NOT NULL
);


CREATE TABLE images
(
    image_id SERIAL PRIMARY KEY,
    path TEXT
);


CREATE TABLE products
(
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    product_price DECIMAL(8, 2) NOT NULL,
    fk_image_id INTEGER REFERENCES images(image_id)
);


CREATE TABLE order_details
(
    fk_order_id INTEGER REFERENCES orders(order_id),
    fk_product_id INTEGER REFERENCES products(product_id),
    total_amount INTEGER DEFAULT 0
);