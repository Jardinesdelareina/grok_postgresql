\connect postgres

DROP DATABASE IF EXISTS portfolio;
CREATE DATABASE portfolio;

\connect portfolio;

DROP SCHEMA qts CASCADE;
DROP SCHEMA ms CASCADE;
CREATE SCHEMA IF NOT EXISTS qts;
CREATE SCHEMA IF NOT EXISTS ms;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


--
-- Котировки
--
CREATE TABLE qts.quotes
(
    m_symbol VARCHAR(10) NOT NULL,
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
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,

    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);


--
-- Портфели пользователей
--
CREATE TABLE ms.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(200) UNIQUE NOT NULL,
    balance REAL DEFAULT 0,
    is_published BOOLEAN DEFAULT TRUE,
    fk_user_id INT REFERENCES ms.users(id)
);


--
-- Криптовалюты
--
CREATE TABLE ms.currencies
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    description TEXT,

    CONSTRAINT valid_symbol CHECK (symbol IN (
        'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt', 
        'adausdt', 'avaxusdt', 'dotusdt', 'linkusdt'
    ))
);


--
-- Транзакции (покупка/продажа тикера в портфеле)
--
CREATE TABLE ms.transactions
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type VARCHAR(4) CHECK (action_type IN ('BUY', 'SELL')) DEFAULT 'BUY',
    quantity REAL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INT REFERENCES ms.portfolios(id),
    fk_currency_id INT REFERENCES ms.currencies(id)
);
