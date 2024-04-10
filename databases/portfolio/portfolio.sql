\connect postgres

DROP DATABASE IF EXISTS portfolio;
CREATE DATABASE portfolio;

\connect portfolio;

DROP SCHEMA ms CASCADE;
DROP SCHEMA qts CASCADE;
CREATE SCHEMA IF NOT EXISTS ms;
CREATE SCHEMA IF NOT EXISTS qts;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


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

CREATE OR REPLACE PROCEDURE ms.create_user(
    input_email VARCHAR(255), 
    input_password VARCHAR(100)
    ) AS $$

    INSERT INTO ms.users(email, password) 
    VALUES(input_email, crypt(input_password, gen_salt('md5')));

$$ LANGUAGE sql;


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

CREATE INDEX idx_portfolios_user ON ms.portfolios(fk_user_id);

CREATE OR REPLACE PROCEDURE ms.create_portfolio(
    input_title VARCHAR(200), 
    input_is_published BOOLEAN,
    input_user_id INT
    ) AS $$

    INSERT INTO ms.portfolios(title, is_published, fk_user_id)
    VALUES(input_title, input_is_published, input_user_id);
    
$$ LANGUAGE sql;


--
-- Криптовалюты
--
CREATE TABLE ms.tokens
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    symbol VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,

    CONSTRAINT valid_symbol CHECK (symbol IN (
        'btcusdt', 'ethusdt', 'solusdt', 'xrpusdt', 
        'adausdt', 'avaxusdt', 'dotusdt', 'linkusdt'
    ))
);


--
-- Транзакции (добавление/удаление тикера в портфеле)
--
CREATE TABLE ms.transactions
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type VARCHAR(4) CHECK (action_type IN ('BUY', 'SELL')) DEFAULT 'BUY',
    amount REAL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INT REFERENCES ms.portfolios(id),
    fk_token_id INT REFERENCES ms.tokens(id)
);

CREATE INDEX idx_transaction_portfolio ON ms.transactions(fk_portfolio_id);
CREATE INDEX idx_transaction_token ON ms.transactions(fk_token_id);

CREATE OR REPLACE PROCEDURE ms.create_transaction(
    input_action_type VARCHAR(4),
    input_amount REAL,
    input_portfolio_id INT,
    input_token_id INT
    ) AS $$

    INSERT INTO ms.transactions(action_type, amount, fk_portfolio_id, fk_token_id)
    VALUES(input_action_type, input_amount, input_portfolio_id, input_token_id);

$$ LANGUAGE sql;


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


CREATE OR REPLACE PROCEDURE qts.get_price(input_symbol VARCHAR(10)) AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$ LANGUAGE sql;
