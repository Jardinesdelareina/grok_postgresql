--
-- Определение среднего изменения цены за определенный промежуток времени 
-- (передающийся в аргументе функции)
--
CREATE OR REPLACE FUNCTION avg_value(period INTEGER) RETURNS NUMERIC(10, 2) AS $$
    SELECT AVG(ABS(((m_high - m_low) / m_close) * 100))
                FROM (SELECT * FROM xrpusdt LIMIT period) AS subqueries;
$$ LANGUAGE SQL;

SELECT avg_value(14);