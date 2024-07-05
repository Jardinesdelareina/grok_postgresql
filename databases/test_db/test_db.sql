\connect postgres

DROP DATABASE IF EXISTS test_db;
DROP DATABASE IF EXISTS test_db_2;
CREATE DATABASE test_db;
CREATE DATABASE test_db_2;

\connect test_db

CREATE TABLE test_table
(
    id INT GENERATED ALWAYS AS IDENTITY,
    s TEXT
);

INSERT INTO test_table(s) SELECT md5(random()::text) FROM generate_series(1, 100000);


-- Копирование данных из таблицы в файл
COPY test_table TO '/home/fueros/grok_postgresql/databases/test_db/copy_test_db.csv' DELIMITER ',' CSV HEADER;;

-- Копирование данных из файла в таблицу
CREATE TABLE test_table_2
(
    id INT GENERATED ALWAYS AS IDENTITY,
    s TEXT
);

COPY test_table_2 FROM '/home/fueros/grok_postgresql/databases/test_db/copy_test_db.csv' DELIMITER ',' CSV HEADER;;
