\connect postgres

DROP DATABASE IF EXISTS datafarm;
CREATE DATABASE datafarm;

\connect datafarm


CREATE SCHEMA market;
CREATE SCHEMA profile;
CREATE SCHEMA trading;
CREATE SCHEMA service;

SET search_path TO market, profile, trading, service, public;

CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA service;


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
    email TEXT PRIMARY KEY,
    password VARCHAR(100) NOT NULL
);


-- Портфели пользователей
CREATE TABLE profile.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    fk_user_email profile.valid_email REFERENCES profile.users(email)
);


-- Транзакции (покупка/продажа тикера в портфеле)
CREATE TABLE trading.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type VARCHAR(4) CHECK (action_type IN ('BUY', 'SELL')) DEFAULT 'BUY',
    quantity NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INT REFERENCES profile.portfolios(id),
    fk_currency_symbol VARCHAR(20) REFERENCES market.currencies(symbol)
);


--
-- SERVICE
--


-- Генерация случайного целочисленного значения
CREATE OR REPLACE FUNCTION service.generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;


-- Определение количества знаков после запятой в десятичном числе
CREATE OR REPLACE FUNCTION service.count_after_comma(num NUMERIC)
RETURNS INTEGER AS $$
DECLARE
    num_str TEXT := num::TEXT;
    num_len INT := LENGTH(num_str);
    comma_pos INT := POSITION('.' IN num_str);
BEGIN
RETURN num_len - comma_pos;
END;
$$ LANGUAGE plpgsql;


-- Обфускация email-адресов
CREATE OR REPLACE FUNCTION service.obfuscate_email(email profile.valid_email)
RETURNS TEXT AS $$
DECLARE
    obfuscated_email TEXT := '';
    char_code INT;
    char_item VARCHAR;
BEGIN
    FOR char_item IN SELECT regexp_split_to_table(email, '') LOOP
        char_code := ascii(char_item);
        obfuscated_email := obfuscated_email || '&#' || char_code || ';';
    END LOOP;
    RETURN obfuscated_email;
END;
$$ LANGUAGE plpgsql;


-- Деобфускация email-адресов
CREATE OR REPLACE FUNCTION service.deobfuscate_email(obfuscated_email TEXT)
RETURNS profile.valid_email AS $$
DECLARE
    deobfuscated_email TEXT := '';
    parts TEXT[];
    item TEXT;
    char_code INT;
BEGIN
    parts := string_to_array(obfuscated_email, '&#');
    FOREACH item IN ARRAY parts LOOP
        IF item <> '' THEN
            char_code := CAST(SPLIT_PART(item, ';', 1) AS INT);
            deobfuscated_email := deobfuscated_email || chr(char_code);
        END IF;
    END LOOP;
    RETURN deobfuscated_email;
END;
$$ LANGUAGE plpgsql;


--
-- PROCEDURES
--


-- Создание пользователя
CREATE OR REPLACE PROCEDURE profile.create_user(
    input_email VARCHAR(128), 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO profile.users(email, password)
    VALUES(service.obfuscate_email(input_email), service.crypt(input_password, service.gen_salt('md5')));
$$ LANGUAGE sql;


-- Создание портфеля
CREATE OR REPLACE PROCEDURE profile.create_portfolio(
    input_title VARCHAR(200), 
    input_user_email profile.valid_email
    ) AS $$
    INSERT INTO profile.portfolios(title, fk_user_email)
    VALUES(input_title, input_user_email);
$$ LANGUAGE sql;


-- Создание транзакции
CREATE OR REPLACE PROCEDURE trading.create_transaction(
    input_action_type VARCHAR(4),
    input_quantity NUMERIC,
    input_portfolio_id INT,
    input_currency_symbol VARCHAR(20)
    ) AS $$
    INSERT INTO trading.transactions(action_type, quantity, fk_portfolio_id, fk_currency_symbol)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_symbol);
$$ LANGUAGE sql;


--
-- FUNCTIONS
--


-- Заполнение таблицы тикерами
DO $$
DECLARE
    symbol_list VARCHAR[] := ARRAY[
        'btc', 'eth', 'sol', 'xrp', 'ada', 'avax', 'eos', 'trx',
        'bch', 'ltc', 'xlm', 'etc', 'neo', 'link', 'mx', 'pepe', 
        'luna', 'floki', 'ont', 'ksm', 'mln', 'dash', 'vet', 'doge' 
    ];
    i VARCHAR;
BEGIN
    FOREACH i IN ARRAY symbol_list
    LOOP
        INSERT INTO market.currencies(symbol) VALUES(CONCAT(i, 'usdt'));
    END LOOP;
END $$;


-- Получение последней котировки определенного тикера
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
CREATE OR REPLACE FUNCTION profile.get_portfolios(input_user_email valid_email) 
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
        ) * get_price(fk_currency_symbol) AS usdt_qty_currency
    FROM trading.transactions t
    JOIN market.currencies c ON t.fk_currency_symbol = c.symbol
    WHERE t.fk_portfolio_id = input_portfolio_id
    GROUP BY fk_currency_symbol;
$$ LANGUAGE sql VOLATILE;


-- Вывод совокупного баланса пользователя
CREATE OR REPLACE FUNCTION market.get_total_balance_user(input_user_email valid_email) 
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