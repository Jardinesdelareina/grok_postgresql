\connect postgres

DROP DATABASE IF EXISTS datafarm;
CREATE DATABASE datafarm;

\connect datafarm

CREATE SCHEMA market;
CREATE SCHEMA profile;
CREATE SCHEMA trading;

CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA profile;


--
-- DATA MODELS
--


-- Тикеры криптовалют
CREATE TABLE market.currencies
(
    symbol VARCHAR(20) PRIMARY KEY
);


-- Рыночные ордера
CREATE TABLE market.tickers
(
    fk_symbol VARCHAR(20) REFERENCES market.currencies(symbol),
    t_time TIMESTAMPTZ NOT NULL,
    t_price NUMERIC NOT NULL
);


-- Валидация email
CREATE DOMAIN profile.valid_email AS VARCHAR(128)
    CHECK (VALUE ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');


-- Пользователи
CREATE TABLE profile.users
(
    email profile.valid_email PRIMARY KEY,
    password VARCHAR(100) NOT NULL
);


-- Портфели пользователей
CREATE TABLE profile.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) UNIQUE NOT NULL,
    fk_user_email profile.valid_email REFERENCES profile.users(email)
);


-- Торговые стратегии
CREATE TABLE trading.bots
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    params JSONB NOT NULL
);


-- Транзакции (покупка/продажа тикера в портфеле)
CREATE TABLE trading.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(4) CHECK (action_type IN ('BUY', 'SELL')) DEFAULT 'BUY',
    quantity NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INT REFERENCES profile.portfolios(id),
    fk_currency_symbol VARCHAR(20) REFERENCES market.currencies(symbol),
    fk_bot_id INT REFERENCES trading.bots(id)
);


--
-- PROCEDURES
--


-- Создание пользователя
CREATE OR REPLACE PROCEDURE profile.create_user(
    input_email VARCHAR(128), 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO profile.users(email, password)
    VALUES(input_email, profile.crypt(input_password, profile.gen_salt('md5')));
$$ LANGUAGE sql;


-- Создание портфеля
CREATE OR REPLACE PROCEDURE profile.create_portfolio(
    input_title VARCHAR(200), 
    input_user_email profile.valid_email
    ) AS $$
    INSERT INTO profile.portfolios(title, fk_user_email)
    VALUES(input_title, input_user_email);
$$ LANGUAGE sql;


-- Изменение параметров портфеля
CREATE OR REPLACE PROCEDURE profile.update_portfolio(
    input_portfolio_id INT,
    input_portfolio_title VARCHAR(200)
    ) AS $$
    UPDATE profile.portfolios
    SET title = input_portfolio_title
    WHERE id = input_portfolio_id;
$$ LANGUAGE sql;


-- Создание стратегии
CREATE OR REPLACE PROCEDURE trading.create_bot(
    input_title VARCHAR(100),
    input_description TEXT,
    input_params JSONB
    ) AS $$
    INSERT INTO trading.bots(title, description, params)
    VALUES(input_title, input_description, input_params);
$$ LANGUAGE sql;


-- Изменение стратегии
CREATE OR REPLACE PROCEDURE trading.update_bot(
    input_bot_id INT,
    input_title_bot VARCHAR(100),
    input_description_bot TEXT,
    input_params_bot JSONB
    ) AS $$
    UPDATE trading.bots
    SET title = input_title_bot, description = input_description_bot, params = input_params_bot
    WHERE id = input_bot_id;
$$ LANGUAGE sql;


-- Создание транзакции
CREATE OR REPLACE PROCEDURE trading.create_transaction(
    input_action_type VARCHAR(4),
    input_quantity NUMERIC,
    input_portfolio_id INT,
    input_currency_symbol VARCHAR(20),
    input_bot_id INT
    ) AS $$
    INSERT INTO trading.transactions(action_type, quantity, fk_portfolio_id, fk_currency_symbol, fk_bot_id)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_symbol, input_bot_id);
$$ LANGUAGE sql;


-- Отключение стратегии
CREATE OR REPLACE PROCEDURE trading.set_off(input_bot_title VARCHAR(100)) AS $$
    UPDATE trading.bots 
    SET is_active = FALSE
    WHERE title = input_bot_title;
$$ LANGUAGE sql;


--
-- FUNCTIONS
--


--
-- Получение последней котировки определенного тикера
--
CREATE OR REPLACE FUNCTION market.get_price(input_symbol VARCHAR(20)) 
RETURNS NUMERIC AS $$
    SELECT t_price AS last_price 
    FROM market.tickers
    WHERE fk_symbol = input_symbol
    ORDER BY t_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;


-- Получение нужной котировки по выбранному тикеру в выбранный момент времени
CREATE OR REPLACE FUNCTION market.get_price_with_time(
    input_symbol VARCHAR(20),
    input_time TIMESTAMPTZ
) RETURNS NUMERIC AS $$
    SELECT t_price AS current_price
    FROM market.tickers
    WHERE fk_symbol = input_symbol
    ORDER BY ABS(EXTRACT(EPOCH FROM (t_time - input_time)))
    LIMIT 1
$$ LANGUAGE sql IMMUTABLE;


-- Вывод списка портфелей определенного пользователя
CREATE OR REPLACE FUNCTION profile.get_portfolios(input_user_email profile.valid_email) 
RETURNS TABLE(title VARCHAR(200)) AS $$
    SELECT p.title
    FROM profile.portfolios p
    WHERE fk_user_email = input_user_email;
$$ LANGUAGE sql STABLE;


-- Расчет объема транзакции в usdt
CREATE OR REPLACE FUNCTION trading.get_value_transaction(input_transaction_id UUID) 
RETURNS NUMERIC AS $$
DECLARE qty_transaction NUMERIC;
BEGIN
    WITH qty_currency AS (
        SELECT t.created_at, t.quantity, t.fk_currency_symbol AS curr
        FROM trading.transactions t
        WHERE t.id = input_transaction_id
    )
    SELECT quantity * market.get_price_with_time(curr, created_at)
	INTO qty_transaction
    FROM qty_currency;
    RETURN qty_transaction;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Вывод баланса портфеля в usdt
CREATE OR REPLACE FUNCTION market.get_balance_portfolio(input_portfolio_id INT)
RETURNS NUMERIC AS $$
DECLARE total_quantity NUMERIC := 0;
BEGIN
    SELECT SUM(
        CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
    ) * market.get_price(t.fk_currency_symbol)
    INTO total_quantity
    FROM trading.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_symbol, t.created_at;
    IF total_quantity < 0 THEN 
        total_quantity = 0;
	END IF;
    RETURN total_quantity;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- Вывод криптовалют, их количества и балансов в портфеле
CREATE OR REPLACE FUNCTION market.get_balance_ticker_portfolio(input_portfolio_id INT) 
RETURNS TABLE(symbol VARCHAR(20), qty_currency NUMERIC, usdt_qty_currency NUMERIC) AS $$
    SELECT DISTINCT 
        fk_currency_symbol AS symbol, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) AS qty_currency, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) * market.get_price(fk_currency_symbol) AS usdt_qty_currency
    FROM trading.transactions t
    JOIN market.currencies c ON t.fk_currency_symbol = c.symbol
    WHERE t.fk_portfolio_id = input_portfolio_id
    GROUP BY fk_currency_symbol;
$$ LANGUAGE sql VOLATILE;


-- Вывод совокупного баланса пользователя
CREATE OR REPLACE FUNCTION market.get_total_balance_user(input_user_email profile.valid_email) 
RETURNS NUMERIC AS $$
DECLARE total_balance NUMERIC := 0;
        portfolio_id INT;
BEGIN
    FOR portfolio_id IN (
        SELECT id 
        FROM profile.portfolios 
        WHERE fk_user_email = input_user_email
    ) 
    LOOP
        total_balance := total_balance + market.get_balance_portfolio(portfolio_id);
    END LOOP;
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql VOLATILE;


--
-- TRIGGERS
--


-- Запись в лог о добавлении новой транзакции
CREATE OR REPLACE FUNCTION trading.alert_new_transaction() RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Добавлена новая транзакция';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER alert_new_transaction_trigger
AFTER INSERT ON trading.transactions
FOR EACH ROW EXECUTE FUNCTION trading.alert_new_transaction();