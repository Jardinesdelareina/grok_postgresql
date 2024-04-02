\connect postgres

DROP DATABASE IF EXISTS mexc;
CREATE DATABASE mexc;

\connect mexc

CREATE TABLE spot
(
    m_symbol VARCHAR(10) NOT NULL,
    m_time TIMESTAMPTZ NOT NULL,
    m_open REAL NOT NULL,
    m_high REAL NOT NULL,
    m_low REAL NOT NULL,
    m_close REAL NOT NULL
) PARTITION BY RANGE (m_time);

CREATE INDEX idx_m_symbol ON spot (m_symbol);
CREATE INDEX idx_m_time ON spot (m_time);


CREATE TABLE spot_202404 PARTITION OF spot
FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

CREATE TABLE spot_202405 PARTITION OF spot
FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

CREATE TABLE spot_202406 PARTITION OF spot
FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

CREATE TABLE spot_202407 PARTITION OF spot
FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');