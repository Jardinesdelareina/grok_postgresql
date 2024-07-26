-- \i /home/fueros/grok_postgresql/databases/datafarm/df_ohlc.sql

\connect postgres

DROP DATABASE IF EXISTS df_ohlc;
CREATE DATABASE df_ohlc;

\connect df_ohlc

CREATE SCHEMA mexc;

CREATE EXTENSION http SCHEMA mexc;


CREATE TABLE mexc.market_data
(
    m_symbol VARCHAR(20) NOT NULL,
    m_time TIMESTAMPTZ NOT NULL,
    m_open NUMERIC NOT NULL,
    m_high NUMERIC NOT NULL,
    m_low NUMERIC NOT NULL,
    m_close NUMERIC NOT NULL
);


DO $$
BEGIN
    SELECT content FROM mexc.http_get('https://contract.mexc.com/v3/time');
END $$;