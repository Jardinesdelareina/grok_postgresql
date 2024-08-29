\connect postgres

DROP DATABASE IF EXISTS datafarm WITH (FORCE);
CREATE DATABASE datafarm;

\connect datafarm


CREATE SCHEMA market;
CREATE SCHEMA p2p;
CREATE SCHEMA profile;
CREATE SCHEMA trading;
CREATE SCHEMA service;

CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA service;


--
-- DATA MODELS
--


-- Тикеры криптовалют
CREATE TABLE market.currencies
(
    symbol VARCHAR(20) PRIMARY KEY
);

-- Наполнение таблицы тикерами
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


-- Ценовые данные тикеров
CREATE TABLE market.tickers
(
    fk_symbol VARCHAR(20) REFERENCES market.currencies(symbol),
    t_time TIMESTAMPTZ NOT NULL,
    t_price NUMERIC NOT NULL
);


-- Валидация email
CREATE DOMAIN service.valid_email AS TEXT
    CHECK (VALUE ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');


-- Валидация action_type
CREATE DOMAIN service.valid_action_type AS VARCHAR(4)
    CHECK (VALUE IN ('BUY', 'SELL'));


-- Пользователи
CREATE TABLE profile.users
(
    email TEXT PRIMARY KEY,
    password VARCHAR(100) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    date_of_register TIMESTAMPTZ DEFAULT NOW()
);


-- Портфели пользователей
CREATE TABLE profile.portfolios
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    fk_user_email service.valid_email REFERENCES profile.users(email)
);


-- Эмитенты/платежные системы
CREATE TABLE p2p.emitents
(
    title VARCHAR(50) PRIMARY KEY
);

-- Наполнение таблицы эмитентами
DO $$
DECLARE
    emitent_list VARCHAR[] := ARRAY[
        'SBER', 'VTB', 'T', 'ALFA', 'ROSBANK', 'RAIFFAISEN', 
        'GAZPROM', 'URALSIB', 'OPEN', 'ROSSELHOZ', 'RUSSTANDART'
    ];
    i VARCHAR;
BEGIN
    FOREACH i IN ARRAY emitent_list
    LOOP
        INSERT INTO p2p.emitents(title) VALUES(i);
    END LOOP;
END $$;


-- Платежные способы
CREATE TABLE p2p.payments
(
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_emitent VARCHAR(50) REFERENCES p2p.emitents(title),
    name VARCHAR(50) NOT NULL,
    number VARCHAR(16) UNIQUE NOT NULL,
    fk_user_email service.valid_email REFERENCES profile.users(email)
);


-- Отзывы о мерчантах
CREATE TABLE p2p.reviews
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sentiment VARCHAR(8) CHECK (sentiment IN ('positive', 'negative')) NOT NULL,
    text_review TEXT,
    fk_user_on service.valid_email REFERENCES profile.users(email),
    fk_user_from service.valid_email REFERENCES profile.users(email)
);


-- Предложения о покупке/продаже криптовалюты
CREATE TABLE p2p.offers
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action_type service.valid_action_type DEFAULT 'BUY',
    currency VARCHAR(4) CHECK (currency IN ('usdt', 'btc', 'eth', 'xrp')) NOT NULL,
    quantity NUMERIC NOT NULL,
    limit_min NUMERIC DEFAULT 0,
    limit_max NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    comment TEXT,
    offer_status VARCHAR(16) CHECK (offer_status IN (
        'ACTIVE', 'AWAITING PAYMENT', 'CLOSED'
    )) DEFAULT 'ACTIVE',
    fk_user_creator service.valid_email REFERENCES profile.users(email)
);


-- Сделки p2p
CREATE TABLE p2p.deals
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_status VARCHAR(9) CHECK (deal_status IN (
        'AWAIT', 'PAYED', 'CANCELLED'
    )) DEFAULT 'AWAIT',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    quantity NUMERIC NOT NULL,
    fk_offer_id BIGINT REFERENCES p2p.offers(id),
    fk_user_contragent service.valid_email REFERENCES profile.users(email)
);


-- Транзакции (покупка/продажа тикера в портфеле)
CREATE TABLE trading.transactions
(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type service.valid_action_type DEFAULT 'BUY',
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
    SELECT FLOOR(RANDOM() * limit_num) + 1;
$$ LANGUAGE sql;


-- Определение количества знаков после запятой в десятичном числе
CREATE OR REPLACE FUNCTION service.count_after_comma(num NUMERIC)
RETURNS INT AS $$
DECLARE
    num_str TEXT := num::TEXT;
    num_len INT := LENGTH(num_str);
    comma_pos INT := POSITION('.' IN num_str);
BEGIN
RETURN num_len - comma_pos;
END;
$$ LANGUAGE plpgsql;


-- Обфускация email-адресов
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


-- Деобфускация email-адресов
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


--
-- PROCEDURES
--


-- Создание пользователя
CREATE OR REPLACE PROCEDURE profile.create_user(
    input_email service.valid_email, 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO profile.users(email, password)
    VALUES(input_email, service.crypt(input_password, service.gen_salt('md5')));
$$ LANGUAGE sql;


-- Создание портфеля
CREATE OR REPLACE PROCEDURE profile.create_portfolio(
    input_title VARCHAR(200), 
    input_user_email service.valid_email
    ) AS $$
    INSERT INTO profile.portfolios(title, fk_user_email)
    VALUES(input_title, input_user_email);
$$ LANGUAGE sql;


-- Изменение названия портфеля
CREATE OR REPLACE PROCEDURE profile.update_portfolio(
    input_id INT,
    input_title VARCHAR(200)
    ) AS $$
    UPDATE profile.portfolios
    SET title = input_title
    WHERE id = input_id;
$$ LANGUAGE sql;


-- Удаление портфеля
CREATE OR REPLACE PROCEDURE profile.delete_portfolio(
    input_id INT
    ) AS $$
    DELETE FROM profile.portfolios WHERE id = input_id;
$$ LANGUAGE sql;


-- Алгоритм Луна для валидации номеров бансковских карт
CREATE OR REPLACE FUNCTION service.sum_of_digits(num INT) RETURNS INT AS $$
DECLARE
    sum INT := 0;
BEGIN
    WHILE num > 0 LOOP
        sum := sum + num % 10;
        num := num / 10;
    END LOOP;
    RETURN sum;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION service.sum_of_digits(INT) IS 'Алгоритм Луна';


-- Валидация номеров банковских карт
CREATE OR REPLACE FUNCTION service.valid_bank_card_number(card_number VARCHAR) 
RETURNS VARCHAR AS $$
DECLARE
    card_number_digits INT[];
    total_sum INT := 0;
    alternate_sum INT := 0;
BEGIN
    -- Проверка, что номер карты состоит только из цифр
    IF card_number ~ '^\d+$' THEN

        -- Преобразование номера карты в массив цифр
        card_number_digits := string_to_array(card_number, NULL);
        
        -- Проверка, что номер карты состоит из 16 цифр
        IF array_length(card_number_digits, 1) = 16 THEN

            -- Применение алгоритма Луна для валидации номера карты
            FOR i IN REVERSE 1..16 LOOP
                IF i % 2 = 0 THEN
                    alternate_sum := alternate_sum + card_number_digits[i];
                ELSE
                    total_sum := total_sum + sum_of_digits(card_number_digits[i] * 2);
                END IF;
            END LOOP;
            
            -- Проверка, что сумма делится на 10 без остатка
            IF (total_sum + alternate_sum) % 10 = 0 THEN
                RETURN card_number;
            ELSE
                RETURN 'Невалидный номер';
            END IF;
        ELSE
            RAISE EXCEPTION 'Номер карты состоит из 16-ти цифр';
        END IF;
    ELSE
        RAISE EXCEPTION 'Номер карты должен состоять только из цифр';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Добавление платежного способа
CREATE OR REPLACE PROCEDURE p2p.create_payment(
    input_emitent VARCHAR(50),
    input_name VARCHAR(50),
    input_number VARCHAR(16),
    input_user_email service.valid_email
    ) AS $$
    INSERT INTO p2p.payments(fk_emitent, name, number, fk_user_email)
    VALUES(
        input_emitent, 
        UPPER(input_name), 
        service.valid_bank_card_number(input_number), 
        input_user_email
    );
$$ LANGUAGE sql;


-- Добавление отзыва о мерчанте 
CREATE OR REPLACE PROCEDURE p2p.create_review(
    input_sentiment VARCHAR(8),
    input_text_review TEXT,
    input_user_on service.valid_email,
    input_user_from service.valid_email
    ) AS $$
    INSERT INTO p2p.reviews(sentiment, text_review, fk_user_on, fk_user_from)
    VALUES(input_sentiment, input_text_review, input_user_on, input_user_from);
$$ LANGUAGE sql;


-- Создание предложения
CREATE OR REPLACE PROCEDURE p2p.create_offer(
    input_action_type service.valid_action_type,
    input_currency VARCHAR(4),
    input_quantity NUMERIC,
    input_limit_min NUMERIC,
    input_limit_max NUMERIC,
    input_comment TEXT,
    input_user_creator service.valid_email
    ) AS $$
    INSERT INTO p2p.offers(
        action_type, currency, quantity, limit_min, limit_max, comment, fk_user_creator
    )
    VALUES(
        input_action_type, input_currency, input_quantity, input_limit_min, 
        input_limit_max, input_comment, input_user_creator
    );
$$ LANGUAGE sql;


-- Создание сделки
CREATE OR REPLACE PROCEDURE p2p.create_deal(
    input_quantity NUMERIC,
    input_offer_id BIGINT,
    input_user_contragent service.valid_email
    ) AS $$
    INSERT INTO p2p.deals(quantity, fk_offer_id, fk_user_contragent)
    VALUES(input_quantity, input_offer_id, input_user_contragent);
$$ LANGUAGE sql;


-- Изменение статуса предложения
CREATE OR REPLACE PROCEDURE p2p.update_status_offer(
    input_id BIGINT,
    input_status VARCHAR(16)
    ) AS $$
    UPDATE p2p.offers
    SET offer_status = input_status
    WHERE id = input_id;
$$ LANGUAGE sql;


-- Изменение статуса сделки
CREATE OR REPLACE PROCEDURE p2p.update_status_deal(
    input_id UUID,
    input_status VARCHAR(9)
    ) AS $$
    UPDATE p2p.deals
    SET deal_status = input_status
    WHERE id = input_id;
$$ LANGUAGE sql;


-- Оплата quantity по offer
CREATE OR REPLACE PROCEDURE p2p.deal_payment(
    input_offer_id BIGINT, 
    input_deal_id UUID
    ) AS $$

    -- Разница между offers.quantity и deal.quantity (процесс совершения сделки)
    UPDATE p2p.offers
    SET quantity = p2p.offers.quantity - (
        SELECT p2p.deals.quantity
        FROM p2p.deals
        WHERE p2p.deals.id = input_deal_id
    )
    WHERE offers.id = input_offer_id;
    
    -- Изменение статуса deal
    UPDATE p2p.deals
    SET deal_status = 'PAYED'
    WHERE id = input_deal_id
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


-- Получение последней котировки определенного тикера
CREATE OR REPLACE FUNCTION market.get_price(input_symbol VARCHAR(20)) 
RETURNS NUMERIC AS $$
    SELECT t_price AS last_price 
    FROM market.tickers
    WHERE fk_symbol = input_symbol
    ORDER BY t_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;


-- Получение последней котировки определенного тикера по времени
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
PREPARE get_portfolios (service.valid_email) AS
SELECT p.title
FROM profile.portfolios p
WHERE fk_user_email = $1;


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
PREPARE get_balance_ticker_portfolio (INT) AS
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
WHERE t.fk_portfolio_id = $1
GROUP BY fk_currency_symbol;


-- Вывод совокупного баланса пользователя
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


--
-- TRIGGERS
--


-- Печать размера таблицы trading.transactions
CREATE OR REPLACE FUNCTION trading.print_size_transactions() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(id) FROM trading.transactions) % 100000 = 0 THEN
        RAISE NOTICE 'Размер таблицы transactions %', pg_size_pretty(pg_total_relation_size('trading.transactions')) AS object_size;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_print_size_transactions
AFTER INSERT ON trading.transactions
FOR EACH ROW EXECUTE FUNCTION trading.print_size_transactions();


CREATE OR REPLACE FUNCTION service.set_default_limit_offer()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.limit_min IS NULL THEN
        UPDATE p2p.offers
        SET limit_min = 0
        WHERE id = NEW.id;
    END IF;
    IF NEW.limit_max IS NULL THEN
        UPDATE p2p.offers
        SET limit_max = quantity
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_default_limit_offer
AFTER INSERT ON p2p.offers
FOR EACH ROW EXECUTE FUNCTION service.set_default_limit_offer();


-- Контроль превышения предложения в p2p-сделках
CREATE OR REPLACE FUNCTION p2p.check_deal_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity > (SELECT quantity FROM p2p.offers WHERE id = NEW.fk_offer_id) THEN
        RAISE EXCEPTION 'Превышен лимит предложения';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_deal_quantity
BEFORE INSERT ON p2p.deals
FOR EACH ROW EXECUTE FUNCTION check_deal_quantity();


-- Динамическое изменение статуса сделок
CREATE OR REPLACE FUNCTION p2p.update_offer_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.deal_status = 'AWAIT' THEN
        UPDATE p2p.offers
        SET offer_status = 'AWAITING PAYMENT'
        WHERE id = NEW.fk_offer_id;
    ELSIF NEW.deal_status = 'PAYED' THEN
        UPDATE p2p.offers
        SET offer_status = CASE WHEN (
            SELECT quantity FROM p2p.offers WHERE id = NEW.fk_offer_id
        ) = 0 THEN 'CLOSED' ELSE 'ACTIVE'END
        WHERE id = NEW.fk_offer_id;
    ELSIF NEW.deal_status = 'PAYED' AND NEW.quantity > 0 OR NEW.deal_status = 'CANCELLED' THEN
        UPDATE p2p.offers
        SET offer_status = 'ACTIVE'
        WHERE id = NEW.fk_offer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_offer_status
BEFORE UPDATE ON p2p.deals
FOR EACH ROW EXECUTE FUNCTION p2p.update_offer_status();


--
-- INDEXES
--


CREATE INDEX idx_symbol ON market.tickers(fk_symbol);
CREATE INDEX idx_user_email ON profile.portfolios(fk_user_email);
CREATE INDEX idx_portfolio_id ON trading.transactions(fk_portfolio_id);
CREATE INDEX idx_review_from ON p2p.reviews(fk_user_from);
CREATE INDEX idx_user_creator_offer ON p2p.offers(fk_user_creator);
CREATE INDEX idx_user_contragent ON p2p.deals(fk_user_contragent);