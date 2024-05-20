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
-- Name: valid_action_type; Type: DOMAIN; Schema: ms; Owner: postgres
--

CREATE DOMAIN ms.valid_action_type AS character varying(4)
	CONSTRAINT valid_action_type_check CHECK (((VALUE)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying])::text[])));


ALTER DOMAIN ms.valid_action_type OWNER TO postgres;

--
-- Name: valid_email; Type: DOMAIN; Schema: ms; Owner: postgres
--

CREATE DOMAIN ms.valid_email AS character varying(255)
	CONSTRAINT valid_email_check CHECK (((VALUE)::text ~* '^[A-Za-z0-9._+%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text));


ALTER DOMAIN ms.valid_email OWNER TO postgres;

--
-- Name: valid_symbol; Type: DOMAIN; Schema: ms; Owner: postgres
--

CREATE DOMAIN ms.valid_symbol AS character varying(10)
	CONSTRAINT valid_symbol_check CHECK (((VALUE)::text = ANY ((ARRAY['btcusdt'::character varying, 'ethusdt'::character varying, 'solusdt'::character varying, 'xrpusdt'::character varying, 'adausdt'::character varying, 'avaxusdt'::character varying, 'dotusdt'::character varying, 'linkusdt'::character varying])::text[])));


ALTER DOMAIN ms.valid_symbol OWNER TO postgres;

--
-- Name: valid_time; Type: DOMAIN; Schema: ms; Owner: postgres
--

CREATE DOMAIN ms.valid_time AS timestamp with time zone
	CONSTRAINT valid_time_check CHECK ((date_trunc('minute'::text, VALUE) = VALUE));


ALTER DOMAIN ms.valid_time OWNER TO postgres;

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
-- Name: get_balance_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE total_quantity REAL := 0;
BEGIN
    SELECT SUM(
        CASE WHEN t.action_type = 'BUY' THEN t.quantity ELSE -t.quantity END
    ) * qts.get_price_with_time(ms.symbol_id(t.fk_currency_id), t.created_at)
    INTO total_quantity
    FROM ms.transactions t
    WHERE t.fk_portfolio_id = input_portfolio_id
	GROUP BY fk_currency_id;
    IF total_quantity < 0 THEN 
        total_quantity = 0;
	END IF;
    RETURN total_quantity;
END;
$$;


ALTER FUNCTION ms.get_balance_portfolio(input_portfolio_id integer) OWNER TO postgres;

--
-- Name: get_balance_ticker_portfolio(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_balance_ticker_portfolio(input_portfolio_id integer) RETURNS TABLE(symbol ms.valid_symbol, qty_currency real, usdt_qty_currency real)
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
    JOIN ms.currencies c ON t.fk_currency_id = c.id
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
-- Name: get_value_transaction(uuid); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.get_value_transaction(input_transaction_id uuid) RETURNS real
    LANGUAGE plpgsql IMMUTABLE
    AS $$
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
$$;


ALTER FUNCTION ms.get_value_transaction(input_transaction_id uuid) OWNER TO postgres;

--
-- Name: symbol_id(integer); Type: FUNCTION; Schema: ms; Owner: postgres
--

CREATE FUNCTION ms.symbol_id(input_symbol_id integer) RETURNS ms.valid_symbol
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

CREATE PROCEDURE ms.update_portfolio(IN input_portfolio_id integer, IN input_portfolio_title character varying, IN input_is_published boolean)
    LANGUAGE sql
    AS $$
    UPDATE ms.portfolios
    SET title = input_portfolio_title,
        is_published = input_is_published
    WHERE id = input_portfolio_id;
$$;


ALTER PROCEDURE ms.update_portfolio(IN input_portfolio_id integer, IN input_portfolio_title character varying, IN input_is_published boolean) OWNER TO postgres;

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
-- Name: get_price(ms.valid_symbol); Type: FUNCTION; Schema: qts; Owner: postgres
--

CREATE FUNCTION qts.get_price(input_symbol ms.valid_symbol) RETURNS real
    LANGUAGE sql
    AS $$
    SELECT m_close AS last_price 
    FROM qts.quotes 
    WHERE m_symbol = input_symbol
    ORDER BY m_time DESC 
    LIMIT 1;
$$;


ALTER FUNCTION qts.get_price(input_symbol ms.valid_symbol) OWNER TO postgres;

--
-- Name: get_price_with_time(ms.valid_symbol, timestamp with time zone); Type: FUNCTION; Schema: qts; Owner: postgres
--

CREATE FUNCTION qts.get_price_with_time(input_symbol ms.valid_symbol, input_time timestamp with time zone) RETURNS real
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT m_close AS current_price
    FROM qts.quotes
    WHERE m_symbol = input_symbol AND m_time = input_time
$$;


ALTER FUNCTION qts.get_price_with_time(input_symbol ms.valid_symbol, input_time timestamp with time zone) OWNER TO postgres;

--
-- Name: currencies; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.currencies (
    id integer NOT NULL,
    symbol ms.valid_symbol DEFAULT 'btcusdt'::character varying,
    description text
);


ALTER TABLE ms.currencies OWNER TO postgres;

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
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    action_type ms.valid_action_type DEFAULT 'BUY'::character varying,
    quantity real NOT NULL,
    created_at ms.valid_time DEFAULT date_trunc('minute'::text, now()),
    fk_portfolio_id integer,
    fk_currency_id integer
);


ALTER TABLE ms.transactions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: ms; Owner: postgres
--

CREATE TABLE ms.users (
    id integer NOT NULL,
    email ms.valid_email NOT NULL,
    password character varying(100) NOT NULL
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
    m_symbol ms.valid_symbol NOT NULL,
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
    m_symbol ms.valid_symbol NOT NULL,
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
    m_symbol ms.valid_symbol NOT NULL,
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
    m_symbol ms.valid_symbol NOT NULL,
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
    m_symbol ms.valid_symbol NOT NULL,
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
\.


--
-- Data for Name: portfolios; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.portfolios (id, title, is_published, fk_user_id) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.transactions (id, action_type, quantity, created_at, fk_portfolio_id, fk_currency_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: ms; Owner: postgres
--

COPY ms.users (id, email, password) FROM stdin;
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
-- Name: portfolios_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.portfolios_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: ms; Owner: postgres
--

SELECT pg_catalog.setval('ms.users_id_seq', 1, false);


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
-- Name: idx_portfolios_user; Type: INDEX; Schema: ms; Owner: postgres
--

CREATE INDEX idx_portfolios_user ON ms.portfolios USING btree (fk_user_id);


--
-- Name: idx_transactions_currency; Type: INDEX; Schema: ms; Owner: postgres
--

CREATE INDEX idx_transactions_currency ON ms.transactions USING btree (fk_currency_id);


--
-- Name: idx_transactions_portfolio; Type: INDEX; Schema: ms; Owner: postgres
--

CREATE INDEX idx_transactions_portfolio ON ms.transactions USING btree (fk_portfolio_id);


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

