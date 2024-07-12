\connect postgres

DROP DATABASE IF EXISTS test_types;
CREATE DATABASE test_types;

\connect test_types

DROP SCHEMA test_xml CASCADE;
DROP SCHEMA test_json CASCADE;
CREATE SCHEMA test_xml;
CREATE SCHEMA test_json;


--Парсинг xml-файла
DO $$
DECLARE xml_string xml;
BEGIN
    xml_string := XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('/home/fueros/grok_postgresql/databases/test_types/imc.xml'), 'UTF8'));

    DROP TABLE IF EXISTS test_xml.imc;
    CREATE TABLE test_xml.imc AS 
    SELECT
        unnest(xpath('///ID_SLUCH/text()', xml_string)) as id_sluch,
        unnest(xpath('////ENP/text()', xml_string)) as enp;
END $$;


SELECT * FROM test_xml.imc;

