\connect postgres

DROP DATABASE IF EXISTS med;
CREATE DATABASE med;

\connect med

DROP SCHEMA IF EXISTS test CASCADE;
CREATE SCHEMA test;


CREATE TABLE test.schet
(
    code_mo VARCHAR(6) PRIMARY KEY,
    year SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    plat VARCHAR(5),
    coments VARCHAR(250)
);


CREATE TABLE test.sluch
(
    id_sluch UUID PRIMARY KEY,
    pr_nov SMALLINT CHECK (pr_nov IN (1, 2)) NOT NULL,
    vidpom SMALLINT NOT NULL,
    moddate TIMESTAMPTZ NOT NULL,
    mo_custom VARCHAR(6) REFERENCES test.schet(code_mo) ON DELETE CASCADE,
    singpay SMALLINT CHECK (singpay IN (1, 2)) NOT NULL,
    idsp SMALLINT NOT NULL,
    prvs INT NOT NULL,
    npr_mdcode VARCHAR(8),
    podr INT UNIQUE NOT NULL,
    iddokt VARCHAR(8) NOT NULL
);


CREATE TABLE test.usl
(
    id_usl UUID PRIMARY KEY,
    prvs INT NOT NULL,
    podr INT REFERENCES test.sluch(podr) ON DELETE CASCADE,
    profil VARCHAR(11) NOT NULL,
    vid_vme VARCHAR(15) NOT NULL
);


-- Создание временной таблицы
CREATE TEMPORARY TABLE xml_buffer
(
    s TEXT
);

-- Копирование содержимого xml-файла в таблицу
COPY xml_buffer(s) FROM '/home/fueros/grok_postgresql/databases/test_task/test.xml';

INSERT INTO xml_buffer(s)
VALUES(xmlparse(DOCUMENT '/home/fueros/grok_postgresql/databases/test_task/test.xml'))

-- Парсинг данных в таблицы по тегам
INSERT INTO test.schet(code_mo, year, month, plat, coments)
SELECT subquery.f FROM 
	(SELECT xmlparse(DOCUMENT xml_buffer.s) AS f FROM xml_buffer) AS subquery, 
	xmltable(
	    '//SCHET/*'
	    PASSING subquery.f
	    COLUMNS
	        code_mo text PATH 'CODE_MO', 
	        plat text PATH 'PLAT',
	        coments text PATH 'COMENTS'
	);