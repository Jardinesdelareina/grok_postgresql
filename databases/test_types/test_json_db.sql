\connect postgres

DROP DATABASE IF EXISTS test_json_db;
CREATE DATABASE test_json_db;

\connect test_json_db


-- Парсинг json-файла
DROP TABLE IF EXISTS json_table;
CREATE TABLE json_table
(
	title TEXT,
	price NUMERIC,
	is_available BOOLEAN,
	category INT,
	description TEXT
);

WITH json_data(d) AS (
   SELECT pg_read_file('/home/fueros/grok_postgresql/databases/test_types/data.json')::jsonb
)

INSERT INTO json_table (title, price, is_available, category, description)
SELECT
elem->>'title' as title,
(elem->>'price')::numeric as price,
(elem->>'is_available')::boolean as is_available,
(elem->>'category')::integer as category,
elem->>'description' as description
FROM json_data, jsonb_array_elements(d) elem;
