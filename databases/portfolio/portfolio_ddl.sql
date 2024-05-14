\connect postgres

DROP DATABASE IF EXISTS portfolio;
CREATE DATABASE portfolio;

\connect portfolio;

DROP SCHEMA qts CASCADE;
DROP SCHEMA ms CASCADE;
CREATE SCHEMA qts;
CREATE SCHEMA ms;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


--
-- Валидация email
--
CREATE DOMAIN ms.valid_email AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');


--
-- Валидация названия тикера
--
CREATE DOMAIN ms.valid_symbol AS VARCHAR(10)
    CHECK (VALUE IN (
        'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt', 
        'adausdt', 'avaxusdt', 'dotusdt', 'linkusdt'
    ));


--
-- Валидация типа транзакции
--
CREATE DOMAIN ms.valid_action_type AS VARCHAR(4)
    CHECK (VALUE IN ('BUY', 'SELL'));


--
-- Валидация времени (округление до минут)
--
CREATE DOMAIN ms.valid_time AS TIMESTAMPTZ
    CHECK (date_trunc('minute', VALUE) = VALUE);


--
-- Котировки
--
CREATE TABLE qts.quotes
(
    m_symbol ms.valid_symbol NOT NULL,
    m_time TIMESTAMPTZ NOT NULL,
    m_open REAL NOT NULL,
    m_high REAL NOT NULL,
    m_low REAL NOT NULL,
    m_close REAL NOT NULL
) PARTITION BY RANGE (m_time);

CREATE TABLE qts.quotes_202404 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE qts.quotes_202405 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE qts.quotes_202406 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE qts.quotes_202407 PARTITION OF qts.quotes
FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');


--
-- Пользователи
--
CREATE TABLE ms.users
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email ms.valid_email UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
);


--
-- Портфели пользователей
--
CREATE TABLE ms.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) UNIQUE NOT NULL,
    is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INT REFERENCES ms.users(id)
);


--
-- Криптовалюты
--
CREATE TABLE ms.currencies
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol ms.valid_symbol DEFAULT 'btcusdt',
    description TEXT
);


--
-- Транзакции (покупка/продажа тикера в портфеле)
--
CREATE TABLE ms.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type ms.valid_action_type DEFAULT 'BUY',
    quantity REAL NOT NULL,
    created_at ms.valid_time DEFAULT date_trunc('minute', NOW()),
    fk_portfolio_id INT REFERENCES ms.portfolios(id),
    fk_currency_id INT REFERENCES ms.currencies(id)
);