\connect postgres

DROP DATABASE IF EXISTS datafarm WITH (FORCE);
CREATE DATABASE datafarm;

\connect datafarm


CREATE SCHEMA market;
CREATE SCHEMA p2p;
CREATE SCHEMA profile;
CREATE SCHEMA trading;
CREATE SCHEMA service;

SET search_path TO market, profile, trading, p2p, service, public;

CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA service;


--
-- DATA MODELS
--


CREATE TABLE market.currencies
(
    symbol VARCHAR(20) PRIMARY KEY
);
COMMENT ON TABLE market.currencies IS 'Тикеры криптовалют';

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


CREATE TABLE market.tickers
(
    fk_symbol VARCHAR(20) REFERENCES market.currencies(symbol),
    t_time TIMESTAMPTZ NOT NULL,
    t_price NUMERIC NOT NULL
);
COMMENT ON TABLE market.tickers IS 'Ценовые данные тикеров';


CREATE DOMAIN service.valid_email AS VARCHAR(128)
    CHECK (VALUE ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
COMMENT ON DOMAIN service.valid_email IS 'Валидация email';


CREATE DOMAIN service.valid_action_type AS VARCHAR(4)
    CHECK (VALUE IN ('BUY', 'SELL'));
COMMENT ON DOMAIN service.valid_action_type IS 'Валидация action_type';


CREATE TABLE profile.users
(
    email TEXT PRIMARY KEY,
    password VARCHAR(100) NOT NULL
);
COMMENT ON TABLE profile.users IS 'Пользователи';


CREATE TABLE profile.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    fk_user_email service.valid_email REFERENCES profile.users(email)
);
COMMENT ON TABLE profile.portfolios IS 'Портфели пользователей';


CREATE TABLE p2p.emitents
(
    title VARCHAR(50) PRIMARY KEY
);
COMMENT ON TABLE p2p.emitents IS 'Эмитенты/платежные системы';


CREATE TABLE p2p.payments
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    number VARCHAR(100) NOT NULL,
    fk_emitent VARCHAR(50) REFERENCES p2p.emitents(title)
);
COMMENT ON TABLE p2p.payments IS 'Сплатежные средства';


CREATE TABLE p2p.reviews
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sentiment VARCHAR(8) CHECK (sentiment IN ('positive', 'negative')) NOT NULL,
    text_rewiew TEXT,
    fk_user_on service.valid_email REFERENCES profile.users(email),
    fk_user_from service.valid_email REFERENCES profile.users(email)
);
COMMENT ON TABLE p2p.reviews IS 'Отзывы о мерчантах';


CREATE TABLE p2p.offers
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type service.valid_action_type NOT NULL,
    currency VARCHAR(20) CHECK (currency IN ('usdt', 'btc', 'eth', 'xrp')) NOT NULL,
    quantity NUMERIC NOT NULL,
    limit_min NUMERIC NOT NULL,
    limit_max NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    comment TEXT,
    offer_status VARCHAR(6) CHECK (offer_status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE',
    fk_user_creator service.valid_email REFERENCES profile.users(email)
);
COMMENT ON TABLE p2p.offers IS 'Предложения о покупке/продаже криптовалюты';


CREATE TABLE p2p.deals
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_status VARCHAR(8) CHECK (deal_status IN ('AWAITS', 'PAYED', 'CANCELLED')) DEFAULT 'AWAITS',
    fk_offer_id UUID REFERENCES p2p.offers(id),
    fk_user_merchant service.valid_email REFERENCES profile.users(email),
    fk_user_recipient service.valid_email REFERENCES profile.users(email)
);
COMMENT ON TABLE p2p.deals IS 'Сделки p2p';


CREATE TABLE trading.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type service.valid_action_type DEFAULT 'BUY',
    quantity NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    fk_portfolio_id INT REFERENCES profile.portfolios(id),
    fk_currency_symbol VARCHAR(20) REFERENCES market.currencies(symbol)
);
COMMENT ON TABLE trading.transactions IS 'Транзакции (покупка/продажа тикера в портфеле)';


--
-- SERVICE
--


CREATE OR REPLACE FUNCTION service.generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT FLOOR(RANDOM() * limit_num) + 1;
$$ LANGUAGE sql;
COMMENT ON FUNCTION service.generate_num(BIGINT) IS 'Генерация случайного целочисленного значения';


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
COMMENT ON FUNCTION service.count_after_comma(NUMERIC) IS 'Определение количества знаков после запятой в десятичном числе';


CREATE OR REPLACE FUNCTION service.obfuscate_email(email service.valid_email)
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
COMMENT ON FUNCTION service.obfuscate_email(service.valid_email) IS 'Обфускация email-адресов';


CREATE OR REPLACE FUNCTION service.deobfuscate_email(obfuscated_email TEXT)
RETURNS service.valid_email AS $$
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
COMMENT ON FUNCTION service.deobfuscate_email(TEXT) IS 'Деобфускация email-адресов';


--
-- PROCEDURES
--


CREATE OR REPLACE PROCEDURE profile.create_user(
    input_email service.valid_email, 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO profile.users(email, password)
    VALUES(input_email, service.crypt(input_password, service.gen_salt('md5')));
$$ LANGUAGE sql;
COMMENT ON PROCEDURE profile.create_user(service.valid_email, VARCHAR(100)) IS 'Создание пользователя';


CREATE OR REPLACE PROCEDURE profile.create_portfolio(
    input_title VARCHAR(200), 
    input_user_email service.valid_email
    ) AS $$
    INSERT INTO profile.portfolios(title, fk_user_email)
    VALUES(input_title, input_user_email);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE profile.create_portfolio(VARCHAR(200), service.valid_email) IS 'Создание портфеля';


CREATE OR REPLACE PROCEDURE trading.create_transaction(
    input_action_type VARCHAR(4),
    input_quantity NUMERIC,
    input_portfolio_id INT,
    input_currency_symbol VARCHAR(20)
    ) AS $$
    INSERT INTO trading.transactions(action_type, quantity, fk_portfolio_id, fk_currency_symbol)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_symbol);
$$ LANGUAGE sql;
COMMENT ON PROCEDURE trading.create_transaction(VARCHAR(4), NUMERIC, INT, VARCHAR(20)) IS 'Создание транзакции';


--
-- FUNCTIONS
--


CREATE OR REPLACE FUNCTION market.get_price(input_symbol VARCHAR(20)) 
RETURNS NUMERIC AS $$
    SELECT t_price AS last_price 
    FROM market.tickers
    WHERE fk_symbol = input_symbol
    ORDER BY t_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;
COMMENT ON FUNCTION market.get_price(VARCHAR(20))  IS 'Получение последней котировки определенного тикера';


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
COMMENT ON FUNCTION market.get_price_with_time(VARCHAR(20), TIMESTAMPTZ)  IS 'Получение последней котировки определенного тикера';


CREATE OR REPLACE FUNCTION profile.get_portfolios(input_user_email service.valid_email) 
RETURNS TABLE(title VARCHAR(200)) AS $$
    SELECT p.title
    FROM profile.portfolios p
    WHERE fk_user_email = input_user_email;
$$ LANGUAGE sql STABLE;
COMMENT ON FUNCTION profile.get_portfolios(service.valid_email) IS 'Вывод списка портфелей определенного пользователя';


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
COMMENT ON FUNCTION trading.get_value_transaction(UUID) IS 'Расчет объема транзакции в usdt';


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
COMMENT ON FUNCTION market.get_balance_portfolio(INT) IS 'Вывод баланса портфеля в usdt';


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
COMMENT ON FUNCTION market.get_balance_ticker_portfolio(INT)  IS 'Вывод криптовалют, их количества и балансов в портфеле';


CREATE OR REPLACE FUNCTION market.get_total_balance_user(input_user_email service.valid_email) 
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
COMMENT ON FUNCTION market.get_total_balance_user(service.valid_email) IS 'Вывод совокупного баланса пользователя';


--
-- TRIGGERS
--


CREATE OR REPLACE FUNCTION trading.print_size_transactions() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(id) FROM trading.transactions) % 100000 = 0 THEN
        RAISE NOTICE 'Размер таблицы transactions %', pg_size_pretty(pg_total_relation_size('trading.transactions')) AS object_size;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tgr_print_size_transactions
AFTER INSERT ON trading.transactions
FOR EACH ROW EXECUTE FUNCTION trading.print_size_transactions();
COMMENT ON TRIGGER tgr_print_size_transactions ON trading.transactions IS 'Печать размера таблицы';


--
-- INDEXES
--


CREATE INDEX idx_symbol ON market.tickers(fk_symbol);
CREATE INDEX idx_user_email ON profile.portfolios(fk_user_email);
CREATE INDEX idx_portfolio_id ON trading.transactions(fk_portfolio_id);
CREATE INDEX idx_review_from ON p2p.reviews(fk_user_from);
CREATE INDEX idx_user_creator_offer ON p2p.offers(fk_user_creator);
CREATE INDEX idx_user_merchant ON p2p.deals(fk_user_merchant);
CREATE INDEX idx_user_recipient ON p2p.deals(fk_user_recipient);