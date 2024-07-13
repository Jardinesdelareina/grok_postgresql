\connect postgres

DROP DATABASE IF EXISTS test_xml_db;
CREATE DATABASE test_xml_db;

\connect test_xml_db

DROP SCHEMA test_xml CASCADE;
CREATE SCHEMA test_xml;


-- Парсинг xml-файла
DO $$
DECLARE xml_string xml;
BEGIN
    xml_string := XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('/home/fueros/grok_postgresql/databases/test_types/data.xml'), 'UTF8'));

    DROP TABLE IF EXISTS test_xml.imc;
    CREATE TABLE test_xml.imc AS 
    SELECT
        unnest(xpath('///ID_SLUCH/text()', xml_string)) as id_sluch,
        unnest(xpath('////ENP/text()', xml_string)) as enp;
END $$;


SELECT * FROM test_xml.imc;