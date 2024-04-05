\connect postgres

DROP DATABASE portfolio;
CREATE DATABASE portfolio;

\connect portfolio;

DROP SCHEMA IF EXISTS portfolio_v1 CASCADE;
CREATE SCHEMA portfolio_v1;


--
-- Пользователи
--
CREATE TABLE portfolio_v1.users
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    login VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Портфели пользователей
--
CREATE TABLE portfolio_v1.portfolios
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    is_published BOOLEAN NOT NULL,
    fk_user_id INTEGER REFERENCES portfolio_v1.users(id)
);


--
-- Криптовалюты
--
CREATE TABLE portfolio_v1.tokens
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    ticker VARCHAR(10) UNIQUE NOT NULL,
    logo VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    price REAL
);


--
-- Транзакции (добавление/удаление криптовалюты в портфеле)
--
CREATE TABLE portfolio_v1.transactions
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type VARCHAR(4) CHECK (action_type IN ('BUY', 'SELL')) DEFAULT 'BUY',
    amount INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INTEGER REFERENCES portfolio_v1.portfolios(id),
    fk_token_id INTEGER REFERENCES portfolio_v1.tokens(id)
);


--
-- Категории новостей
--
CREATE TABLE portfolio_v1.categories
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(50) NOT NULL
);


--
-- Новости
--
CREATE TABLE portfolio_v1.news
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(155) NOT NULL,
    source VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_category_id SMALLINT REFERENCES portfolio_v1.categories(id)
);


--
-- Подписки пользователей на категории новостей
--
CREATE TABLE portfolio_v1.news_users
(
    fk_user_id SMALLINT REFERENCES portfolio_v1.users(id),
    fk_category_id SMALLINT REFERENCES portfolio_v1.categories(id)
);