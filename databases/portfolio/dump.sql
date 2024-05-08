--
-- PostgreSQL database dump
--

-- Dumped from database version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ms; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA ms;


ALTER SCHEMA ms OWNER TO postgres;

--
-- Name: qts; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA qts;


ALTER SCHEMA qts OWNER TO postgres;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: create_portfolio(character varying, boolean, integer); Type: PROCEDURE; Schema: ms; Owner: postgres
--

CREATE PROCEDURE ms.create_portfolio(IN input_title character varying, IN input_is_published boolean, IN input_user_id integer)
    LANGUAGE sql
    AS $$
    INSERT INTO ms.portfolios(title, is_published, fk_user_id)
    VALUES(input_title, input_is_published, input_user_id);
$$;


ALTER PROCEDURE ms.create_portfolio(IN input_title character varying, IN input_is_published boolean, IN input_user_id integer) OWNER TO postgres;

--
-- Name: create_transaction(character varying, real, integer, integer); Type: PROCEDURE; Schema: ms; Owner: postgres
--

CREATE PROCEDURE ms.create_transaction(IN input_action_type character varying, IN input_quantity real, IN input_portfolio_id integer, IN input_currency_id integer)
    LANGUAGE sql
    AS $$
    INSERT INTO ms.transactions(action_type, quantity, fk_portfolio_id, fk_currency_id)
    VALUES(input_action_type, input_quantity, input_portfolio_id, input_currency_id);
$$;


ALTER PROCEDURE ms.create_transaction(IN input_action_type character varying, IN input_quantity real, IN input_portfolio_id integer, IN input_currency_id integer) OWNER TO postgres;

--
-- Name: create_user(character varying, character varying); Type: PROCEDURE; Schema: ms; Owner: postgres
--

CREATE PROCEDURE ms.create_user(IN input_email character varying, IN input_password character varying)
    LANGUAGE sql
    AS $$
    INSERT INTO ms.users(email, password)
    VALUES(input_email, crypt(input_password, gen_salt('md5')));
$$;


ALTER PROCEDURE ms.create_user(IN input_email character varying, IN input_password character varying) OWNER TO postgres;

--
-- Name: get_balance_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE total_quantity REAL := 0;
BEGIN
    SELECT SUM(CASE WHEN t.action_type = 'BUY' THEN t.quantity 
                    ELSE -t.quantity 
                    END) * qts.get_price(ms.symbol_id(t.fk_currency_id))
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id;
    RETURN total_quantity;
END;
$$;


ALTER FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) OWNER TO postgres;

--
-- Name: get_balance_ticker_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id integer) RETURNS TABLE(symbol character varying, qty_currency real, usdt_qty_currency real)
    LANGUAGE plpgsql
    AS $$
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
    JOIN ms.currencies c ON t.id = c.id
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id;
END;
$$;


ALTER FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: portfolios; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.portfolios (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    is_published boolean DEFAULT true,
    fk_user_id integer
);


ALTER TABLE ms.portfolios OWNER TO postgres;

--
-- Name: get_portfolios(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_portfolios(input_user_id integer) RETURNS SETOF ms.portfolios
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY SELECT id, title, is_published, fk_user_id
                FROM ms.portfolios 
                WHERE fk_user_id = input_user_id;
END;
$$;


ALTER FUNCTION ms.get_portfolios(input_user_id integer) OWNER TO postgres;

--
-- Name: get_total_balance_user(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_total_balance_user(input_user_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION ms.get_total_balance_user(input_user_id integer) OWNER TO postgres;

--
-- Name: get_value_transaction(bigint); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_value_transaction(input_transaction_id bigint) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
    qty_transaction REAL;
BEGIN
    WITH qty_currency AS (
        SELECT quantity, t.fk_currency_id AS curr
        FROM ms.transactions t
        WHERE t.id = input_transaction_id
    )
    SELECT INTO qty_transaction
    CASE curr
        WHEN 1 THEN (SELECT qts.get_price('btcusdt'))
        WHEN 2 THEN (SELECT qts.get_price('ethusdt'))
        WHEN 3 THEN (SELECT qts.get_price('solusdt'))
        WHEN 4 THEN (SELECT qts.get_price('xrpusdt'))
        WHEN 5 THEN (SELECT qts.get_price('adausdt'))
        WHEN 6 THEN (SELECT qts.get_price('avaxusdt'))
        WHEN 7 THEN (SELECT qts.get_price('dotusdt'))
        WHEN 8 THEN (SELECT qts.get_price('linkusdt'))
        ELSE 0
    END * quantity
    FROM qty_currency;
    RETURN qty_transaction;
END;
$$;


ALTER FUNCTION ms.get_value_transaction(input_transaction_id bigint) OWNER TO postgres;

--
-- Name: symbol_id(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.symbol_id(input_symbol_id integer) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;


ALTER FUNCTION ms.symbol_id(input_symbol_id integer) OWNER TO postgres;

--
-- Name: update_portfolio(integer, character varying, boolean); Type: PROCEDURE; Schema: ms; Owner: postgres
--

CREATE PROCEDURE ms.update_portfolio(IN input_portfolio_id integer, IN input_portfolio_title character varying, IN input_portfolio_is_published boolean)
    LANGUAGE sql
    AS $$
    UPDATE ms.portfolios
    SET title = input_portfolio_title,
        is_published = input_portfolio_is_published
    WHERE id = input_portfolio_id;
$$;


ALTER PROCEDURE ms.update_portfolio(IN input_portfolio_id integer, IN input_portfolio_title character varying, IN input_portfolio_is_published boolean) OWNER TO postgres;

--
-- Name: calculate_total_quantity(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_total_quantity(input_portfolio_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_quantity REAL := 0;
BEGIN
    SELECT 
        SUM(CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END)
    INTO 
        total_quantity
    FROM 
        ms.transactions t
    WHERE 
        t.fk_portfolio_id = input_portfolio_id;
    
    RETURN total_quantity;
END;
$$;


ALTER FUNCTION public.calculate_total_quantity(input_portfolio_id integer) OWNER TO postgres;

--
-- Name: update_balance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    transaction_quantity REAL;
BEGIN
    transaction_quantity := qts.get_value_transaction(NEW.ms.transactions.id);
    IF NEW.ms.portfolios.balance IS NOT NULL AND OLD.ms.portfolios.balance IS NOT NULL THEN
        IF NEW.ms.transactions.action_type = 'BUY' THEN
            UPDATE ms.portfolios
            SET balance = balance + (NEW.quantity * transaction_quantity)
            WHERE id = NEW.ms.transactions.fk_portfolio_id;
        ELSIF NEW.ms.transactions.action_type = 'SELL' THEN
            IF ms.portfolios.balance > 0 THEN
                UPDATE ms.portfolios
                SET balance = balance - (NEW.quantity * transaction_quantity)
                WHERE id = NEW.ms.transactions.fk_portfolio_id;
            ELSE
                RAISE EXCEPTION 'Баланс не может быть отрицательным';
            END IF;
        END IF;
    ELSE
        RAISE EXCEPTION 'Баланс не может быть NULL';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_balance() OWNER TO postgres;

--
-- Name: get_price(character varying); Type: FUNCTION; Schema: qts; Owner: postgres
--

CREATE FUNCTION qts.get_price(input_symbol character varying) RETURNS real
    LANGUAGE sql
    AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$;


ALTER FUNCTION qts.get_price(input_symbol character varying) OWNER TO postgres;

--
-- Name: currencies; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.currencies (
    id integer NOT NULL,
    symbol character varying(10) NOT NULL,
    description text,
    CONSTRAINT valid_symbol CHECK (((symbol)::text = ANY ((ARRAY['btcusdt'::character varying, 'ethusdt'::character varying, 'solusdt'::character varying, 'xrpusdt'::character varying, 'adausdt'::character varying, 'avaxusdt'::character varying, 'dotusdt'::character varying, 'linkusdt'::character varying])::text[])))
);


ALTER TABLE ms.currencies OWNER TO postgres;

--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: ms; Owner: postgres
--

ALTER TABLE ms.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ms.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: portfolios_id_seq; Type: SEQUENCE; Schema: ms; Owner: postgres
--

ALTER TABLE ms.portfolios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ms.portfolios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: transactions; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.transactions (
    id bigint NOT NULL,
    action_type character varying(4) DEFAULT 'BUY'::character varying,
    quantity real NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    fk_portfolio_id integer,
    fk_currency_id integer,
    CONSTRAINT valid_action_type CHECK (((action_type)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying])::text[])))
);


ALTER TABLE ms.transactions OWNER TO postgres;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: ms; Owner: postgres
--

ALTER TABLE ms.transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ms.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(100) NOT NULL,
    CONSTRAINT valid_email CHECK (((email)::text ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE ms.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: ms; Owner: postgres
--

ALTER TABLE ms.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ms.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: quotes; Type: TABLE; Schema: qts; Owner: postgres
--

CREATE TABLE qts.quotes (
    m_symbol character varying(10) NOT NULL,
    m_time timestamp with time zone NOT NULL,
    m_open real NOT NULL,
    m_high real NOT NULL,
    m_low real NOT NULL,
    m_close real NOT NULL
)
PARTITION BY RANGE (m_time);


ALTER TABLE qts.quotes OWNER TO postgres;

--
-- Name: quotes_202404; Type: TABLE; Schema: qts; Owner: postgres
--

CREATE TABLE qts.quotes_202404 (
    m_symbol character varying(10) NOT NULL,
    m_time timestamp with time zone NOT NULL,
    m_open real NOT NULL,
    m_high real NOT NULL,
    m_low real NOT NULL,
    m_close real NOT NULL
);


ALTER TABLE qts.quotes_202404 OWNER TO postgres;

--
-- Name: quotes_202405; Type: TABLE; Schema: qts; Owner: postgres
--

CREATE TABLE qts.quotes_202405 (
    m_symbol character varying(10) NOT NULL,
    m_time timestamp with time zone NOT NULL,
    m_open real NOT NULL,
    m_high real NOT NULL,
    m_low real NOT NULL,
    m_close real NOT NULL
);


ALTER TABLE qts.quotes_202405 OWNER TO postgres;

--
-- Name: quotes_202406; Type: TABLE; Schema: qts; Owner: postgres
--

CREATE TABLE qts.quotes_202406 (
    m_symbol character varying(10) NOT NULL,
    m_time timestamp with time zone NOT NULL,
    m_open real NOT NULL,
    m_high real NOT NULL,
    m_low real NOT NULL,
    m_close real NOT NULL
);


ALTER TABLE qts.quotes_202406 OWNER TO postgres;

--
-- Name: quotes_202407; Type: TABLE; Schema: qts; Owner: postgres
--

CREATE TABLE qts.quotes_202407 (
    m_symbol character varying(10) NOT NULL,
    m_time timestamp with time zone NOT NULL,
    m_open real NOT NULL,
    m_high real NOT NULL,
    m_low real NOT NULL,
    m_close real NOT NULL
);


ALTER TABLE qts.quotes_202407 OWNER TO postgres;

--
-- Name: quotes_202404; Type: TABLE ATTACH; Schema: qts; Owner: postgres
--

ALTER TABLE ONLY qts.quotes ATTACH PARTITION qts.quotes_202404 FOR VALUES FROM ('2024-04-01 00:00:00+03') TO ('2024-05-01 00:00:00+03');


--
-- Name: quotes_202405; Type: TABLE ATTACH; Schema: qts; Owner: postgres
--

ALTER TABLE ONLY qts.quotes ATTACH PARTITION qts.quotes_202405 FOR VALUES FROM ('2024-05-01 00:00:00+03') TO ('2024-06-01 00:00:00+03');


--
-- Name: quotes_202406; Type: TABLE ATTACH; Schema: qts; Owner: postgres
--

ALTER TABLE ONLY qts.quotes ATTACH PARTITION qts.quotes_202406 FOR VALUES FROM ('2024-06-01 00:00:00+03') TO ('2024-07-01 00:00:00+03');


--
-- Name: quotes_202407; Type: TABLE ATTACH; Schema: qts; Owner: postgres
--

ALTER TABLE ONLY qts.quotes ATTACH PARTITION qts.quotes_202407 FOR VALUES FROM ('2024-07-01 00:00:00+03') TO ('2024-08-01 00:00:00+03');


--
-- Data for Name: currencies; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.currencies (id, symbol, description) FROM stdin;
1	btcusdt	Биткоин (BTC) — первая криптовалюта, созданная при участии анонима Сатоши Накамото. В своем white paper 2008 года Биткоин описывается как одноранговые (p2p) электронные деньги, которые позволяют совершать онлайн-транзакции без участия третьей стороны, какого-либо финансового института. Сеть Биткоина была запущена 3 января 2009 года с протоколом Proof-of-Work (PoW). На сегодняшний день Биткоин является самой популярной криптовалютой, с наибольшей капитализацией.
2	ethusdt	Эфир, Ether (ETH) — криптовалюта блокчейн-проекта Ethereum. Он является самой популярной open-source платформой для смарт-контрактов, токенов и децентрализованных приложений (dApps). Концепция эфириума была представлена в 2013 году Виталиком Бутериным. Сеть Ethereum была запущена 30 июля 2015 года, на данный момент ее протокол базируется на Proof-of-Work, однако существует план смены протокола на Proof-of-Stake в 2020 году при запуске Ethereum 2.0.
3	solusdt	Solana — это блокчейн-платформа с открытым исходным кодом, созданная в 2017 году бывшим руководителем Qualcomm, Анатолием Яковенко. Основная цель Solana — значительно повысить масштабируемость технологии блокчейна, превысив производительность популярных блокчейнов, сохранив при этом затраты на низком уровне. Это достигается за счет гибридной модели, которая позволяет сети Solana теоретически обрабатывать более 710 000 транзакций в секунду (TPS) без необходимости использования дополнительных решений по масштабированию.
4	xrpusdt	XRP — криптовалюта, которая используется платежной платформой RippleNet. Та, в свою очередь, строится на технологии распределенного реестра XRP Ledger. Цель этой криптовалюты — стать быстрым, масштабируемым трансграничным средством платежа. Впервые идея платежной платформы Ripple появилась в 2004 году, в 2012 году Джед МакКалеб и Крис Ларсон взялись ее реализовать. XRP поддерживается независимыми валидаторами, которым может теоретически стать каждый желающий.
5	adausdt	Cardano (ADA) — криптовалюта децентрализованной платформы, которая разрабатывается с 2015 года на языке программирования Haskell. Основателем проекта считается Чарльз Хоскинсон, который также участвовал в создании Ethereum. Cardano была запущена в результате ICO в 2017 году. Cardano поддерживается тремя независимыми друг от друга организациями: IOHK, Cardano Foundation, Emurgo. Дорожная карта развития проекта предусматривает 5 этапов, каждый из которых привносит в сеть новые функции.
6	avaxusdt	Avalanche (AVAX) представляет собой блокчейн сеть, обеспечивающую надежное функционирование смарт контрактов. Сеть предназначена для децентрализованных приложений (dApps), NFT и других сложных блокчейн-платформ.
7	dotusdt	Polkadot — это протокол, который позволяет передавать любые типы данных или активов между блокчейнами. Объединяя несколько блокчейнов, Polkadot стремится достичь высокой степени безопасности и масштабируемости. DOT — это токен управления протоколом. Его можно использовать для стейкинга, чтобы защищать сеть или подключать («связывать») новые цепочки.
8	linkusdt	Chainlink (LINK) — сеть-«оракул», предназначенная для объединения смарт-контрактов с реальными данными. Была основана в результате ICO в сентябре 2017 года Сергеем Назаровым и Стивом Эллисом. LINK является токеном стандарта ERC20 с функционалом ERC223. Оракулы — объекты вне сети блокчейна, которые поставляют информацию для смарт-контрактов.
\.


--
-- Data for Name: portfolios; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.portfolios (id, title, is_published, fk_user_id) FROM stdin;
1	test portfolio	t	1
2	test portfolio2	t	1
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.transactions (id, action_type, quantity, created_at, fk_portfolio_id, fk_currency_id) FROM stdin;
3	BUY	3	2024-05-07 23:46:33.419337+03	1	1
4	BUY	2	2024-05-07 23:46:37.778987+03	1	1
5	BUY	20	2024-05-07 23:46:44.977147+03	2	2
6	BUY	30	2024-05-07 23:47:05.402212+03	1	4
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.users (id, email, password) FROM stdin;
1	fueros.dev@mail.ru	$1$kwtmU/sJ$Caq0P6YLh/qBPN.kkY/jC0
\.


--
-- Data for Name: quotes_202404; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202404 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
\.


--
-- Data for Name: quotes_202405; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202405 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
btcusdt	2024-05-07 23:42:00+03	63003	63020.8	62995	63020.6
ethusdt	2024-05-07 23:42:00+03	3052.73	3053.44	3052.02	3052.99
solusdt	2024-05-07 23:42:00+03	151.526	151.599	151.493	151.566
xrpusdt	2024-05-07 23:42:00+03	0.5346	0.5347	0.5344	0.5346
adausdt	2024-05-07 23:42:00+03	0.4474	0.4474	0.4472	0.4474
avaxusdt	2024-05-07 23:43:00+03	36.137	36.139	36.137	36.139
dotusdt	2024-05-07 23:43:00+03	7.108	7.109	7.108	7.109
linkusdt	2024-05-07 23:42:00+03	14.259	14.26	14.256	14.259
btcusdt	2024-05-07 23:44:00+03	63050.2	63050.2	63050.1	63050.2
ethusdt	2024-05-07 23:44:00+03	3054.99	3055	3054.8	3054.8
solusdt	2024-05-07 23:44:00+03	151.76	151.76	151.731	151.731
xrpusdt	2024-05-07 23:44:00+03	0.535	0.535	0.535	0.535
adausdt	2024-05-07 23:44:00+03	0.4476	0.4477	0.4476	0.4477
avaxusdt	2024-05-07 23:44:00+03	36.159	36.163	36.159	36.163
dotusdt	2024-05-07 23:44:00+03	7.11	7.111	7.11	7.111
linkusdt	2024-05-07 23:44:00+03	14.261	14.263	14.261	14.263
btcusdt	2024-05-07 23:45:00+03	63035.6	63040	63035.6	63040
ethusdt	2024-05-07 23:45:00+03	3054.42	3054.73	3054.42	3054.73
solusdt	2024-05-07 23:45:00+03	151.692	151.787	151.678	151.787
xrpusdt	2024-05-07 23:45:00+03	0.535	0.5351	0.5349	0.535
adausdt	2024-05-07 23:45:00+03	0.4475	0.4476	0.4475	0.4475
avaxusdt	2024-05-07 23:45:00+03	36.174	36.176	36.174	36.176
dotusdt	2024-05-07 23:45:00+03	7.11	7.111	7.11	7.11
linkusdt	2024-05-07 23:45:00+03	14.262	14.27	14.262	14.27
btcusdt	2024-05-07 23:46:00+03	63070.3	63070.3	63040.3	63043.9
ethusdt	2024-05-07 23:46:00+03	3054.94	3054.95	3053.65	3053.76
solusdt	2024-05-07 23:46:00+03	151.923	151.923	151.802	151.848
xrpusdt	2024-05-07 23:46:00+03	0.5352	0.5353	0.5351	0.5352
adausdt	2024-05-07 23:46:00+03	0.4477	0.4479	0.4477	0.4477
avaxusdt	2024-05-07 23:46:00+03	36.207	36.207	36.201	36.202
dotusdt	2024-05-07 23:46:00+03	7.115	7.116	7.114	7.116
linkusdt	2024-05-07 23:46:00+03	14.28	14.28	14.277	14.279
btcusdt	2024-05-07 23:47:00+03	63052.5	63052.6	63052.5	63052.5
ethusdt	2024-05-07 23:47:00+03	3054.65	3054.65	3054.64	3054.65
solusdt	2024-05-07 23:47:00+03	151.913	151.955	151.913	151.954
xrpusdt	2024-05-07 23:47:00+03	0.5352	0.5354	0.5352	0.5354
adausdt	2024-05-07 23:47:00+03	0.4478	0.4479	0.4478	0.4478
avaxusdt	2024-05-07 23:47:00+03	36.226	36.239	36.226	36.239
dotusdt	2024-05-07 23:47:00+03	7.119	7.121	7.119	7.121
linkusdt	2024-05-07 23:47:00+03	14.279	14.28	14.278	14.279
btcusdt	2024-05-07 23:48:00+03	63052.5	63055.8	63036.1	63044.1
ethusdt	2024-05-07 23:48:00+03	3054.85	3054.99	3054	3054.79
solusdt	2024-05-07 23:48:00+03	151.964	152.016	151.933	151.963
xrpusdt	2024-05-07 23:48:00+03	0.5354	0.5354	0.5352	0.5353
adausdt	2024-05-07 23:48:00+03	0.4479	0.448	0.4478	0.4479
avaxusdt	2024-05-07 23:48:00+03	36.238	36.242	36.228	36.232
dotusdt	2024-05-07 23:48:00+03	7.12	7.122	7.119	7.119
linkusdt	2024-05-07 23:48:00+03	14.278	14.282	14.278	14.282
btcusdt	2024-05-07 23:49:00+03	63034	63037.4	63005.5	63013.2
ethusdt	2024-05-07 23:49:00+03	3054.27	3054.28	3052.91	3053.03
solusdt	2024-05-07 23:49:00+03	151.902	151.927	151.672	151.691
xrpusdt	2024-05-07 23:49:00+03	0.5352	0.5352	0.535	0.535
adausdt	2024-05-07 23:50:00+03	0.4478	0.4478	0.4477	0.4477
avaxusdt	2024-05-07 23:50:00+03	36.19	36.19	36.182	36.182
dotusdt	2024-05-07 23:49:00+03	7.118	7.12	7.117	7.118
linkusdt	2024-05-07 23:50:00+03	14.284	14.287	14.282	14.282
btcusdt	2024-05-07 23:51:00+03	62897.4	62912.5	62864.6	62912.5
ethusdt	2024-05-07 23:51:00+03	3037.67	3037.72	3034.3	3037.54
solusdt	2024-05-07 23:51:00+03	151.362	151.479	151.263	151.475
xrpusdt	2024-05-07 23:51:00+03	0.5335	0.534	0.5332	0.534
adausdt	2024-05-07 23:51:00+03	0.4464	0.4464	0.4462	0.4463
avaxusdt	2024-05-07 23:51:00+03	36.072	36.084	36.059	36.084
dotusdt	2024-05-07 23:51:00+03	7.109	7.109	7.1	7.102
linkusdt	2024-05-07 23:51:00+03	14.231	14.249	14.231	14.249
btcusdt	2024-05-07 23:52:00+03	62983.7	63000	62983.6	62999.9
ethusdt	2024-05-07 23:52:00+03	3048.24	3049.8	3048.15	3049.26
solusdt	2024-05-07 23:52:00+03	151.726	151.749	151.661	151.674
xrpusdt	2024-05-07 23:52:00+03	0.5346	0.5346	0.5345	0.5346
adausdt	2024-05-07 23:52:00+03	0.4476	0.4477	0.4476	0.4477
avaxusdt	2024-05-07 23:52:00+03	36.182	36.182	36.171	36.171
dotusdt	2024-05-07 23:52:00+03	7.123	7.127	7.123	7.125
linkusdt	2024-05-07 23:52:00+03	14.274	14.274	14.269	14.272
btcusdt	2024-05-07 23:53:00+03	62982.1	62989.9	62974	62981.7
ethusdt	2024-05-07 23:53:00+03	3047.83	3049.53	3047.24	3049.53
solusdt	2024-05-07 23:53:00+03	151.642	151.642	151.539	151.557
xrpusdt	2024-05-07 23:53:00+03	0.5348	0.5348	0.5346	0.5346
adausdt	2024-05-07 23:53:00+03	0.4476	0.4477	0.4475	0.4477
avaxusdt	2024-05-07 23:53:00+03	36.177	36.177	36.154	36.166
dotusdt	2024-05-07 23:53:00+03	7.123	7.124	7.122	7.124
linkusdt	2024-05-07 23:53:00+03	14.274	14.274	14.269	14.273
btcusdt	2024-05-07 23:54:00+03	62994.9	62995	62983.2	62992.8
ethusdt	2024-05-07 23:54:00+03	3049.59	3050.74	3048.79	3050.55
solusdt	2024-05-07 23:54:00+03	151.573	151.579	151.537	151.579
xrpusdt	2024-05-07 23:54:00+03	0.5349	0.5349	0.5347	0.5349
adausdt	2024-05-07 23:54:00+03	0.4476	0.4477	0.4475	0.4476
avaxusdt	2024-05-07 23:54:00+03	36.174	36.174	36.159	36.162
dotusdt	2024-05-07 23:54:00+03	7.129	7.132	7.128	7.128
linkusdt	2024-05-07 23:54:00+03	14.272	14.276	14.272	14.275
btcusdt	2024-05-07 23:55:00+03	62992.7	62992.8	62950.6	62950.7
ethusdt	2024-05-07 23:55:00+03	3050.8	3050.81	3045.2	3046.12
solusdt	2024-05-07 23:55:00+03	151.576	151.576	151.294	151.329
xrpusdt	2024-05-07 23:55:00+03	0.5349	0.5349	0.5338	0.5338
adausdt	2024-05-07 23:55:00+03	0.4477	0.4477	0.4469	0.447
avaxusdt	2024-05-07 23:55:00+03	36.161	36.161	36.093	36.093
dotusdt	2024-05-07 23:55:00+03	7.129	7.129	7.113	7.114
linkusdt	2024-05-07 23:56:00+03	14.253	14.258	14.253	14.258
btcusdt	2024-05-07 23:57:00+03	62945.1	62945.1	62945	62945.1
ethusdt	2024-05-07 23:57:00+03	3048	3048.42	3047.99	3048.41
solusdt	2024-05-07 23:57:00+03	151.417	151.428	151.4	151.428
xrpusdt	2024-05-07 23:57:00+03	0.5342	0.5342	0.5341	0.5341
adausdt	2024-05-07 23:57:00+03	0.4471	0.4471	0.4471	0.4471
avaxusdt	2024-05-07 23:57:00+03	36.098	36.099	36.098	36.098
dotusdt	2024-05-07 23:57:00+03	7.118	7.12	7.118	7.12
linkusdt	2024-05-07 23:57:00+03	14.266	14.268	14.266	14.268
\.


--
-- Data for Name: quotes_202406; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202406 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
\.


--
-- Data for Name: quotes_202407; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202407 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
\.


--
-- Name: currencies_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.currencies_id_seq', 8, true);


--
-- Name: portfolios_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.portfolios_id_seq', 2, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.transactions_id_seq', 6, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.users_id_seq', 2, true);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: portfolios portfolios_pkey; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (id);


--
-- Name: portfolios portfolios_title_key; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.portfolios
    ADD CONSTRAINT portfolios_title_key UNIQUE (title);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: portfolios portfolios_fk_user_id_fkey; Type: FK CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.portfolios
    ADD CONSTRAINT portfolios_fk_user_id_fkey FOREIGN KEY (fk_user_id) REFERENCES ms.users(id);


--
-- Name: transactions transactions_fk_currency_id_fkey; Type: FK CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.transactions
    ADD CONSTRAINT transactions_fk_currency_id_fkey FOREIGN KEY (fk_currency_id) REFERENCES ms.currencies(id);


--
-- Name: transactions transactions_fk_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: ms; Owner: postgres
--

ALTER TABLE ONLY ms.transactions
    ADD CONSTRAINT transactions_fk_portfolio_id_fkey FOREIGN KEY (fk_portfolio_id) REFERENCES ms.portfolios(id);


--
-- PostgreSQL database dump complete
--

