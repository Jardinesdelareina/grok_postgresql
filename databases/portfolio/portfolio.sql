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
-- МОДЕЛИ ДАННЫХ
--


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
);


--
-- Рыночные ордера
--
CREATE TABLE qts.deals
(
    d_symbol ms.valid_symbol NOT NULL,
    d_time TIMESTAMPTZ NOT NULL,
    d_side VARCHAR(4) CHECK (d_side IN ('BUY', 'SELL')) NOT NULL,
    d_price REAL NOT NULL,
    d_qty REAL NOT NULL
) PARTITION BY LIST (d_symbol);

CREATE TABLE qts.deals_btcusdt PARTITION OF qts.deals FOR VALUES IN ('btcusdt');
CREATE TABLE qts.deals_ethusdt PARTITION OF qts.deals FOR VALUES IN ('ethusdt');
CREATE TABLE qts.deals_solusdt PARTITION OF qts.deals FOR VALUES IN ('solusdt');
CREATE TABLE qts.deals_xrpusdt PARTITION OF qts.deals FOR VALUES IN ('xrpusdt');
CREATE TABLE qts.deals_adausdt PARTITION OF qts.deals FOR VALUES IN ('adausdt');
CREATE TABLE qts.deals_avaxusdt PARTITION OF qts.deals FOR VALUES IN ('avaxusdt');
CREATE TABLE qts.deals_dotusdt PARTITION OF qts.deals FOR VALUES IN ('dotusdt');
CREATE TABLE qts.deals_linkusdt PARTITION OF qts.deals FOR VALUES IN ('linkusdt');


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
    id INT PRIMARY KEY,
    symbol ms.valid_symbol DEFAULT 'btcusdt',
    description TEXT
);

--
-- Добавление записей используемых криптовалют
--
INSERT INTO ms.currencies(id, symbol, description)
VALUES(1, 'btcusdt', 'Биткоин (BTC) — первая криптовалюта, созданная при участии анонима Сатоши Накамото. В своем white paper 2008 года Биткоин описывается как одноранговые (p2p) электронные деньги, которые позволяют совершать онлайн-транзакции без участия третьей стороны, какого-либо финансового института. Сеть Биткоина была запущена 3 января 2009 года с протоколом Proof-of-Work (PoW). На сегодняшний день Биткоин является самой популярной криптовалютой, с наибольшей капитализацией.'),
(2, 'ethusdt', 'Эфир, Ether (ETH) — криптовалюта блокчейн-проекта Ethereum. Он является самой популярной open-source платформой для смарт-контрактов, токенов и децентрализованных приложений (dApps). Концепция эфириума была представлена в 2013 году Виталиком Бутериным. Сеть Ethereum была запущена 30 июля 2015 года, на данный момент ее протокол базируется на Proof-of-Work, однако существует план смены протокола на Proof-of-Stake в 2020 году при запуске Ethereum 2.0.'),
(3, 'solusdt', 'Solana — это блокчейн-платформа с открытым исходным кодом, созданная в 2017 году бывшим руководителем Qualcomm, Анатолием Яковенко. Основная цель Solana — значительно повысить масштабируемость технологии блокчейна, превысив производительность популярных блокчейнов, сохранив при этом затраты на низком уровне. Это достигается за счет гибридной модели, которая позволяет сети Solana теоретически обрабатывать более 710 000 транзакций в секунду (TPS) без необходимости использования дополнительных решений по масштабированию.'),
(4, 'xrpusdt', 'XRP — криптовалюта, которая используется платежной платформой RippleNet. Та, в свою очередь, строится на технологии распределенного реестра XRP Ledger. Цель этой криптовалюты — стать быстрым, масштабируемым трансграничным средством платежа. Впервые идея платежной платформы Ripple появилась в 2004 году, в 2012 году Джед МакКалеб и Крис Ларсон взялись ее реализовать. XRP поддерживается независимыми валидаторами, которым может теоретически стать каждый желающий.'),
(5, 'adausdt', 'Cardano (ADA) — криптовалюта децентрализованной платформы, которая разрабатывается с 2015 года на языке программирования Haskell. Основателем проекта считается Чарльз Хоскинсон, который также участвовал в создании Ethereum. Cardano была запущена в результате ICO в 2017 году. Cardano поддерживается тремя независимыми друг от друга организациями: IOHK, Cardano Foundation, Emurgo. Дорожная карта развития проекта предусматривает 5 этапов, каждый из которых привносит в сеть новые функции.'),
(6, 'avaxusdt', 'Avalanche (AVAX) представляет собой блокчейн сеть, обеспечивающую надежное функционирование смарт контрактов. Сеть предназначена для децентрализованных приложений (dApps), NFT и других сложных блокчейн-платформ.'),
(7, 'dotusdt', 'Polkadot — это протокол, который позволяет передавать любые типы данных или активов между блокчейнами. Объединяя несколько блокчейнов, Polkadot стремится достичь высокой степени безопасности и масштабируемости. DOT — это токен управления протоколом. Его можно использовать для стейкинга, чтобы защищать сеть или подключать («связывать») новые цепочки.'),
(8, 'linkusdt', 'Chainlink (LINK) — сеть-«оракул», предназначенная для объединения смарт-контрактов с реальными данными. Была основана в результате ICO в сентябре 2017 года Сергеем Назаровым и Стивом Эллисом. LINK является токеном стандарта ERC20 с функционалом ERC223. Оракулы — объекты вне сети блокчейна, которые поставляют информацию для смарт-контрактов.');


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


--
-- ХРАНИМЫЕ ПРОЦЕДУРЫ
--


--
-- Создание пользователя
--
CREATE OR REPLACE PROCEDURE ms.create_user(
    input_email VARCHAR(255), 
    input_password VARCHAR(100)
    ) AS $$
    INSERT INTO ms.users(email, password)
    VALUES(input_email, crypt(input_password, gen_salt('md5')));
$$ LANGUAGE sql;


-- Создание портфеля
CREATE OR REPLACE PROCEDURE ms.create_portfolio(
    input_title VARCHAR(200), 
    input_is_published BOOLEAN,
    input_user_id INT
    ) AS $$
    INSERT INTO ms.portfolios(title, is_published, fk_user_id)
    VALUES(input_title, input_is_published, input_user_id);
$$ LANGUAGE sql;


-- Изменение параметров портфеля
CREATE OR REPLACE PROCEDURE ms.update_portfolio(
    input_portfolio_id INT,
    input_portfolio_title VARCHAR(200),
    input_is_published BOOLEAN
    ) AS $$
    UPDATE ms.portfolios
    SET title = input_portfolio_title,
        is_published = input_is_published
    WHERE id = input_portfolio_id;
$$ LANGUAGE sql;


-- Создание транзакции
CREATE OR REPLACE PROCEDURE ms.create_transaction(
    input_action_type VARCHAR(4),
    input_quantity REAL,
    input_portfolio_id INT,
    input_currency_id INT
    ) AS $$
    INSERT INTO ms.transactions(action_type, quantity, fk_portfolio_id, fk_currency_id)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_id);
$$ LANGUAGE sql;


--
-- ФУНКЦИИ
--


--
-- Назначение id определенному тикеру
--
CREATE OR REPLACE FUNCTION ms.symbol_id(input_symbol_id INT) 
RETURNS ms.valid_symbol AS $$
DECLARE
    symbol_id INT := input_symbol_id;
    symbol VARCHAR(10);
BEGIN
    IF symbol_id = 1 THEN symbol := 'btcusdt';
    ELSIF symbol_id = 2 THEN symbol := 'ethusdt';
    ELSIF symbol_id = 3 THEN symbol := 'solusdt';
    ELSIF symbol_id = 4 THEN symbol := 'xrpusdt';
    ELSIF symbol_id = 5 THEN symbol := 'adausdt';
    ELSIF symbol_id = 6 THEN symbol := 'avaxusdt';
    ELSIF symbol_id = 7 THEN symbol := 'dotusdt';
    ELSIF symbol_id = 8 THEN symbol := 'linkusdt';
    ELSE RAISE WARNING 'Несуществующий тикер';
    END IF;
    RETURN symbol;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


--
-- Получение последней цены закрытия определенного тикера
--
CREATE OR REPLACE FUNCTION qts.get_price(input_symbol ms.valid_symbol) 
RETURNS REAL AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$ LANGUAGE sql VOLATILE;


--
-- Получение нужной котировки по выбранному тикеру в выбранный момент времени
--
CREATE OR REPLACE FUNCTION qts.get_price_with_time(
    input_symbol ms.valid_symbol,
    input_time TIMESTAMPTZ
) RETURNS REAL AS $$
    SELECT m_close AS current_price
    FROM qts.quotes
    WHERE m_symbol = input_symbol AND m_time = input_time
$$ LANGUAGE sql IMMUTABLE;


--
-- Вывод списка портфелей определенного пользователя
--
CREATE OR REPLACE FUNCTION ms.get_portfolios(input_user_id INT) 
RETURNS TABLE(title VARCHAR(200), is_published BOOLEAN) AS $$
BEGIN
    RETURN QUERY SELECT p.title, p.is_published
                FROM ms.portfolios p
                WHERE fk_user_id = input_user_id;
END;
$$ LANGUAGE plpgsql STABLE;


--
-- Расчет объема транзакции в usdt
--
CREATE OR REPLACE FUNCTION ms.get_value_transaction(input_transaction_id UUID) 
RETURNS REAL AS $$
DECLARE qty_transaction REAL;
BEGIN
    WITH qty_currency AS (
        SELECT t.created_at, t.quantity, t.fk_currency_id AS curr
        FROM ms.transactions t
        WHERE t.id = input_transaction_id
    )
    SELECT quantity * qts.get_price_with_time(ms.symbol_id(curr), created_at)
	INTO qty_transaction
    FROM qty_currency;
    RETURN qty_transaction;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


--
-- Вывод баланса портфеля в usdt
--
CREATE OR REPLACE FUNCTION ms.get_balance_portfolio(input_portfolio_id INT)
RETURNS REAL AS $$
DECLARE total_quantity REAL := 0;
BEGIN
    SELECT SUM(
        CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
    ) * qts.get_price(ms.symbol_id(t.fk_currency_id))
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id, t.created_at;
    IF total_quantity < 0 THEN 
        total_quantity = 0;
	END IF;
    RETURN total_quantity;
END;
$$ LANGUAGE plpgsql VOLATILE;


--
-- Вывод криптовалют, их количества и балансов в портфеле
--
CREATE OR REPLACE FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id INT) 
RETURNS TABLE(symbol ms.valid_symbol, qty_currency REAL, usdt_qty_currency REAL) AS $$
BEGIN
    RETURN QUERY SELECT DISTINCT 
        ms.symbol_id(fk_currency_id) AS symbol, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) AS qty_currency, 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) * qts.get_price(ms.symbol_id(fk_currency_id)) AS usdt_qty_currency
    FROM ms.transactions t
    JOIN ms.currencies c ON t.fk_currency_id = c.id
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id;
END;
$$ LANGUAGE plpgsql VOLATILE;


--
-- Вывод совокупного баланса пользователя
--
CREATE OR REPLACE FUNCTION ms.get_total_balance_user(input_user_id INT) 
RETURNS REAL AS $$
DECLARE total_balance REAL := 0;
        portfolio_id INT;
BEGIN
    FOR portfolio_id IN (
        SELECT id 
        FROM ms.portfolios 
        WHERE fk_user_id = input_user_id
    ) 
    LOOP
        total_balance := total_balance + ms.get_balance_portfolio(portfolio_id);
    END LOOP;
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql VOLATILE;


--
-- ТРИГГЕРЫ
--


--
-- Запись в лог о добавлении новой транзакции
--
CREATE OR REPLACE FUNCTION ms.alert_new_transaction() RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Добавлена новая транзакция';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER alert_new_transaction_trigger
AFTER INSERT ON ms.transactions
FOR EACH ROW EXECUTE FUNCTION ms.alert_new_transaction();