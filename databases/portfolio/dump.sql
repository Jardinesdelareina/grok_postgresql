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
-- Name: alert_new_transaction(); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.alert_new_transaction() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE NOTICE 'Добавлена новая транзакция';
    RETURN NEW;
END;
$$;


ALTER FUNCTION ms.alert_new_transaction() OWNER TO postgres;

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
-- Name: get_balance(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance(input_portfolio_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_quantity REAL := 0;
BEGIN
    SELECT 
        SUM(
            CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
        ) * ms.get_value_transaction(t.id) 
    INTO 
        total_quantity
    FROM 
        ms.transactions t
    WHERE 
        t.fk_portfolio_id = input_portfolio_id
	GROUP BY id;
    
    RETURN total_quantity;
END;
$$;


ALTER FUNCTION ms.get_balance(input_portfolio_id integer) OWNER TO postgres;

--
-- Name: get_balance_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_quantity REAL := 0;
BEGIN
    SELECT SUM(CASE WHEN t.action_type = 'BUY' THEN t.quantity 
                    ELSE -t.quantity 
                    END) * ms.get_value_transaction(t.id) 
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY id;


    RETURN total_quantity;
END;
$$;


ALTER FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Name: get_currencies_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_currencies_portfolio(input_portfolio_id integer) RETURNS SETOF ms.currencies
    LANGUAGE plpgsql
    AS $$
    BEGIN
	    RETURN QUERY SELECT DISTINCT ms.currencies.id, symbol, description
                FROM ms.currencies
                JOIN ms.transactions ON ms.transactions.fk_currency_id = ms.currencies.id
                WHERE fk_portfolio_id = input_portfolio_id
                ORDER BY id;
	END;
$$;


ALTER FUNCTION ms.get_currencies_portfolio(input_portfolio_id integer) OWNER TO postgres;

--
-- Name: portfolios; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.portfolios (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    balance real DEFAULT 0,
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
        RETURN QUERY SELECT id, title, balance, is_published, fk_user_id
                    FROM ms.portfolios 
                    WHERE fk_user_id = input_user_id;
    END;
$$;


ALTER FUNCTION ms.get_portfolios(input_user_id integer) OWNER TO postgres;

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
        SELECT quantity, ms.transactions.fk_currency_id AS curr
        FROM ms.transactions 
        JOIN ms.portfolios ON ms.transactions.id = ms.portfolios.id
        WHERE ms.transactions.id = input_transaction_id
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
    CONSTRAINT transactions_action_type_check CHECK (((action_type)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying])::text[])))
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

COPY ms.portfolios (id, title, balance, is_published, fk_user_id) FROM stdin;
1	test portfolio	0	t	1
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.transactions (id, action_type, quantity, created_at, fk_portfolio_id, fk_currency_id) FROM stdin;
1	BUY	3	2024-04-26 00:38:55.885195+03	1	1
2	BUY	2	2024-04-26 00:42:08.105977+03	1	1
13	SELL	4	2024-04-28 00:44:06.420723+03	1	1
14	BUY	7	2024-04-28 01:01:40.15872+03	1	1
15	BUY	3	2024-04-28 01:02:48.935571+03	1	2
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.users (id, email, password) FROM stdin;
1	fueros.dev@mail.ru	$1$Vmwi9BBm$/2m9JuvlhZtFzVqcuQ1tV.
\.


--
-- Data for Name: quotes_202404; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202404 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
btcusdt	2024-04-26 00:29:00+03	64880.9	64896.1	64862.8	64896.1
ethusdt	2024-04-26 00:29:00+03	3177.26	3179.15	3177	3179.15
solusdt	2024-04-26 00:29:00+03	147.624	147.624	147.504	147.575
xrpusdt	2024-04-26 00:29:00+03	0.5307	0.5307	0.5305	0.5305
adausdt	2024-04-26 00:29:00+03	0.4772	0.4772	0.477	0.477
avaxusdt	2024-04-26 00:29:00+03	36.081	36.081	36.072	36.072
dotusdt	2024-04-26 00:29:00+03	6.952	6.952	6.951	6.952
linkusdt	2024-04-26 00:29:00+03	14.781	14.781	14.779	14.779
btcusdt	2024-04-26 00:30:00+03	64894.5	64921.1	64894.5	64917.4
ethusdt	2024-04-26 00:30:00+03	3179.67	3181.83	3179.66	3181.83
solusdt	2024-04-26 00:30:00+03	147.502	147.528	147.496	147.528
xrpusdt	2024-04-26 00:30:00+03	0.5305	0.5306	0.5305	0.5305
adausdt	2024-04-26 00:30:00+03	0.4769	0.477	0.4768	0.4768
avaxusdt	2024-04-26 00:30:00+03	36.061	36.061	36.052	36.053
dotusdt	2024-04-26 00:30:00+03	6.951	6.951	6.95	6.95
linkusdt	2024-04-26 00:30:00+03	14.782	14.782	14.779	14.779
btcusdt	2024-04-26 00:31:00+03	64917.3	64962.3	64917.2	64962.3
ethusdt	2024-04-26 00:31:00+03	3182.47	3185.33	3182.11	3185.33
solusdt	2024-04-26 00:31:00+03	147.525	147.6	147.525	147.6
xrpusdt	2024-04-26 00:31:00+03	0.5304	0.5307	0.5304	0.5307
adausdt	2024-04-26 00:31:00+03	0.4769	0.4773	0.4768	0.4773
avaxusdt	2024-04-26 00:31:00+03	36.06	36.092	36.059	36.092
dotusdt	2024-04-26 00:31:00+03	6.948	6.951	6.948	6.951
linkusdt	2024-04-26 00:31:00+03	14.781	14.788	14.78	14.787
btcusdt	2024-04-26 00:32:00+03	64998.4	64998.6	64980	64980
ethusdt	2024-04-26 00:32:00+03	3187.87	3188	3184.92	3184.93
solusdt	2024-04-26 00:32:00+03	147.643	147.662	147.554	147.554
xrpusdt	2024-04-26 00:32:00+03	0.5308	0.531	0.5308	0.5309
adausdt	2024-04-26 00:32:00+03	0.4773	0.4776	0.4773	0.4775
avaxusdt	2024-04-26 00:32:00+03	36.099	36.111	36.099	36.103
dotusdt	2024-04-26 00:32:00+03	6.95	6.952	6.95	6.952
linkusdt	2024-04-26 00:32:00+03	14.794	14.8	14.794	14.8
btcusdt	2024-04-26 00:33:00+03	64977.1	65015.5	64976.1	65015.5
ethusdt	2024-04-26 00:33:00+03	3184.02	3186.62	3183.63	3186.61
solusdt	2024-04-26 00:33:00+03	147.525	147.654	147.433	147.631
xrpusdt	2024-04-26 00:33:00+03	0.531	0.5313	0.5309	0.5313
adausdt	2024-04-26 00:33:00+03	0.4777	0.4778	0.4775	0.4778
avaxusdt	2024-04-26 00:33:00+03	36.099	36.133	36.099	36.133
dotusdt	2024-04-26 00:33:00+03	6.948	6.953	6.948	6.953
linkusdt	2024-04-26 00:33:00+03	14.8	14.806	14.788	14.806
btcusdt	2024-04-26 00:34:00+03	65015.3	65059	65015.3	65049.1
ethusdt	2024-04-26 00:34:00+03	3186.24	3187.79	3186.23	3187.49
solusdt	2024-04-26 00:34:00+03	147.539	147.684	147.539	147.632
xrpusdt	2024-04-26 00:34:00+03	0.5312	0.5317	0.5312	0.5317
adausdt	2024-04-26 00:34:00+03	0.4778	0.4779	0.4778	0.4779
avaxusdt	2024-04-26 00:34:00+03	36.133	36.151	36.133	36.151
dotusdt	2024-04-26 00:34:00+03	6.953	6.957	6.953	6.957
linkusdt	2024-04-26 00:34:00+03	14.805	14.818	14.805	14.817
btcusdt	2024-04-26 00:35:00+03	65093.7	65098.7	65030	65030
ethusdt	2024-04-26 00:35:00+03	3187.88	3189.97	3184.91	3184.92
solusdt	2024-04-26 00:36:00+03	147.927	147.927	147.924	147.924
xrpusdt	2024-04-26 00:35:00+03	0.5318	0.5322	0.5317	0.532
adausdt	2024-04-26 00:35:00+03	0.4779	0.4782	0.4779	0.4781
avaxusdt	2024-04-26 00:35:00+03	36.151	36.211	36.151	36.192
dotusdt	2024-04-26 00:35:00+03	6.958	6.962	6.958	6.962
linkusdt	2024-04-26 00:36:00+03	14.824	14.824	14.819	14.819
btcusdt	2024-04-26 00:37:00+03	65030	65032	65030	65032
ethusdt	2024-04-26 00:37:00+03	3185.36	3185.45	3185.36	3185.36
solusdt	2024-04-26 00:37:00+03	148.015	148.031	148.015	148.031
xrpusdt	2024-04-26 00:37:00+03	0.5316	0.5317	0.5316	0.5317
adausdt	2024-04-26 00:37:00+03	0.478	0.4781	0.478	0.4781
avaxusdt	2024-04-26 00:37:00+03	36.189	36.197	36.189	36.197
dotusdt	2024-04-26 00:37:00+03	6.962	6.963	6.962	6.963
linkusdt	2024-04-26 00:37:00+03	14.813	14.813	14.813	14.813
btcusdt	2024-04-26 00:38:00+03	64949.8	64949.8	64943.5	64943.6
ethusdt	2024-04-26 00:38:00+03	3183.62	3183.63	3183.1	3183.1
solusdt	2024-04-26 00:38:00+03	147.791	147.791	147.781	147.784
xrpusdt	2024-04-26 00:38:00+03	0.5314	0.5315	0.5314	0.5315
adausdt	2024-04-26 00:38:00+03	0.478	0.4781	0.478	0.4781
avaxusdt	2024-04-26 00:38:00+03	36.17	36.17	36.162	36.162
dotusdt	2024-04-26 00:38:00+03	6.965	6.965	6.965	6.965
linkusdt	2024-04-26 00:38:00+03	14.811	14.812	14.811	14.811
btcusdt	2024-04-26 00:39:00+03	64929.3	64929.3	64890.4	64896.1
ethusdt	2024-04-26 00:39:00+03	3182.68	3182.69	3181.48	3181.49
solusdt	2024-04-26 00:39:00+03	147.775	147.775	147.719	147.719
xrpusdt	2024-04-26 00:39:00+03	0.5313	0.5313	0.5311	0.5311
adausdt	2024-04-26 00:39:00+03	0.4776	0.4776	0.4772	0.4772
avaxusdt	2024-04-26 00:39:00+03	36.147	36.147	36.144	36.146
dotusdt	2024-04-26 00:39:00+03	6.956	6.956	6.952	6.952
linkusdt	2024-04-26 00:39:00+03	14.781	14.782	14.78	14.782
btcusdt	2024-04-26 00:40:00+03	64878.7	64879.6	64870.5	64878.1
ethusdt	2024-04-26 00:40:00+03	3181.33	3182.44	3181.33	3181.7
solusdt	2024-04-26 00:40:00+03	147.55	147.734	147.538	147.734
xrpusdt	2024-04-26 00:40:00+03	0.531	0.5312	0.531	0.5312
adausdt	2024-04-26 00:40:00+03	0.4773	0.4775	0.4772	0.4775
avaxusdt	2024-04-26 00:40:00+03	36.126	36.156	36.126	36.156
dotusdt	2024-04-26 00:40:00+03	6.951	6.952	6.949	6.952
linkusdt	2024-04-26 00:40:00+03	14.779	14.789	14.779	14.789
btcusdt	2024-04-26 00:41:00+03	64870.6	64872	64809.8	64815
ethusdt	2024-04-26 00:41:00+03	3181.51	3181.51	3178.12	3178.37
solusdt	2024-04-26 00:41:00+03	147.7	147.701	147.5	147.5
xrpusdt	2024-04-26 00:41:00+03	0.5312	0.5313	0.531	0.531
adausdt	2024-04-26 00:41:00+03	0.4775	0.4776	0.4774	0.4774
avaxusdt	2024-04-26 00:41:00+03	36.154	36.155	36.126	36.126
dotusdt	2024-04-26 00:41:00+03	6.952	6.954	6.952	6.953
linkusdt	2024-04-26 00:41:00+03	14.791	14.791	14.784	14.788
btcusdt	2024-04-26 00:42:00+03	64849.9	64879.6	64849.9	64879.6
ethusdt	2024-04-26 00:42:00+03	3180.32	3181.91	3180.32	3181.91
solusdt	2024-04-26 00:42:00+03	147.502	147.584	147.502	147.575
xrpusdt	2024-04-26 00:42:00+03	0.5311	0.5313	0.531	0.5313
adausdt	2024-04-26 00:42:00+03	0.4774	0.4776	0.4774	0.4776
avaxusdt	2024-04-26 00:42:00+03	36.127	36.14	36.127	36.14
dotusdt	2024-04-26 00:42:00+03	6.953	6.955	6.953	6.954
linkusdt	2024-04-26 00:42:00+03	14.789	14.796	14.789	14.796
btcusdt	2024-04-26 00:43:00+03	64873.2	64873.3	64863.7	64863.8
ethusdt	2024-04-26 00:43:00+03	3182.44	3182.44	3180.67	3180.67
solusdt	2024-04-26 00:43:00+03	147.577	147.604	147.575	147.575
xrpusdt	2024-04-26 00:43:00+03	0.5314	0.5318	0.5314	0.5318
adausdt	2024-04-26 00:43:00+03	0.4776	0.4777	0.4775	0.4777
avaxusdt	2024-04-26 00:43:00+03	36.14	36.15	36.139	36.15
dotusdt	2024-04-26 00:44:00+03	6.956	6.956	6.955	6.955
linkusdt	2024-04-26 00:43:00+03	14.796	14.799	14.796	14.798
btcusdt	2024-04-26 00:45:00+03	64772.3	64776.9	64770.7	64772.2
ethusdt	2024-04-26 00:45:00+03	3177.9	3177.91	3177.9	3177.91
solusdt	2024-04-26 00:45:00+03	147.456	147.456	147.455	147.455
xrpusdt	2024-04-26 00:45:00+03	0.5316	0.5316	0.5315	0.5315
adausdt	2024-04-26 00:45:00+03	0.4777	0.4777	0.4776	0.4776
avaxusdt	2024-04-26 00:44:00+03	36.15	36.157	36.141	36.141
dotusdt	2024-04-26 00:45:00+03	6.955	6.955	6.951	6.951
linkusdt	2024-04-26 00:45:00+03	14.799	14.799	14.799	14.799
btcusdt	2024-04-26 00:46:00+03	64823.3	64823.3	64819.6	64819.6
ethusdt	2024-04-26 00:46:00+03	3179.28	3179.29	3179.28	3179.28
solusdt	2024-04-26 00:46:00+03	147.516	147.543	147.516	147.543
xrpusdt	2024-04-26 00:46:00+03	0.5288	0.5289	0.5288	0.5289
adausdt	2024-04-26 00:46:00+03	0.4774	0.4775	0.4774	0.4775
avaxusdt	2024-04-26 00:46:00+03	36.119	36.277	36.119	36.196
dotusdt	2024-04-26 00:46:00+03	6.951	6.952	6.951	6.952
linkusdt	2024-04-26 00:46:00+03	14.798	14.799	14.797	14.797
btcusdt	2024-04-26 00:47:00+03	64814.6	64817.3	64814.6	64817.2
ethusdt	2024-04-26 00:47:00+03	3179.34	3179.35	3179.28	3179.28
solusdt	2024-04-26 00:47:00+03	147.568	147.585	147.568	147.584
xrpusdt	2024-04-26 00:47:00+03	0.5289	0.529	0.5289	0.5289
adausdt	2024-04-26 00:47:00+03	0.4771	0.4772	0.4771	0.4772
avaxusdt	2024-04-26 00:47:00+03	36.203	36.206	36.203	36.203
dotusdt	2024-04-26 00:47:00+03	6.953	6.953	6.952	6.952
linkusdt	2024-04-26 00:47:00+03	14.801	14.802	14.801	14.801
\.


--
-- Data for Name: quotes_202405; Type: TABLE DATA; Schema: qts; Owner: postgres
--

COPY qts.quotes_202405 (m_symbol, m_time, m_open, m_high, m_low, m_close) FROM stdin;
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

SELECT pg_catalog.setval('ms.portfolios_id_seq', 1, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.transactions_id_seq', 15, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.users_id_seq', 1, true);


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
-- Name: transactions alert_new_transaction_trigger; Type: TRIGGER; Schema: ms; Owner: postgres
--

CREATE TRIGGER alert_new_transaction_trigger AFTER INSERT ON ms.transactions FOR EACH ROW EXECUTE FUNCTION ms.alert_new_transaction();


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

