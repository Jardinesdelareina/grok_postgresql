DROP TABLE IF EXISTS register;

CREATE TABLE register
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER,
    mark INTEGER
);


CREATE OR REPLACE FUNCTION random_mark()
RETURNS INTEGER AS $$
BEGIN
    RETURN CASE WHEN random() < 0.5 THEN 3 ELSE 5 END;
END;
$$ LANGUAGE plpgsql;


DO $$
BEGIN
    FOR i IN 1..1000 LOOP
        INSERT INTO register (student_id, mark)
        VALUES (floor(random() * 20) + 1, random_mark());
    END LOOP;
END $$;


-- Вывести количество пятерок у студентов, у которых количество троек меньше двадцати

SELECT student_id, COUNT(*) AS mark_5_count
FROM register
WHERE mark = 5 AND student_id IN (
    SELECT student_id
    FROM register
    WHERE mark = 3
    GROUP BY student_id
    HAVING COUNT(*) < 20
)
GROUP BY student_id;

