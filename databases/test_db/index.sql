-- Удаление таблицы если она существует
DROP TABLE IF EXISTS test_table;

-- Создание таблицы
CREATE TABLE test_table
(
    test_id SERIAL PRIMARY KEY,
    test_key TEXT
);

-- Добавление в таблицу миллиона рандомных записей
INSERT INTO test_table(test_id, test_key)
SELECT s.id, md5(random()::text)
FROM generate_series(1, 1000000) AS s(id);

-- Изменение таблицы (верхний регистр содержимого колонки)
UPDATE test_table
SET test_key = UPPER(md5(random()::text));

-- Анализ выполнения запроса
EXPLAIN
SELECT * 
FROM test_table 
WHERE test_id = 100000;

-- Создание индекса
CREATE INDEX idx_test_id ON test_table(test_id);

-- Повторный запрос
SELECT * 
FROM test_table 
WHERE test_id = 100000;