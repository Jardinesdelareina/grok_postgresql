CREATE TABLE nums
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    num INT NOT NULL
);


CREATE OR REPLACE FUNCTION merge_sort(arr INT[])
RETURNS INT[] AS $$
DECLARE
    n INT;
    left_half INT[];
    right_half INT[];
    result INT[];
BEGIN
    -- Длина входного массива
    n := array_length(arr, 1);
    
    -- Если длина <= 1, то возвращается массив, так как считается, что он отсортирован
    IF n <= 1 THEN
        RETURN arr;
    END IF;
    
    -- Разделение массива пополам
    left_half := arr[1:n/2];
    right_half := arr[n/2+1:n];
    
    -- Рекурсивный вызов текущей функции для разделенных частей массива
    left_half:= merge_sort(left_half);
    right_half:= merge_sort(right_half);
    
    -- Пустой массив для сортировки списка
    result := '{}';
    
    -- Цикл работает, пока в разделенных частях массива есть элементы
    WHILE array_length(left_half, 1) > 0 AND array_length(right_half, 1) > 0 LOOP
        
        -- Если первый элемент левого списка меньше первого элемента правого списка
        -- добавить элемент в массив result и удалить из левого списка
        -- иначе перейти к правому списку и проделать то же самое
        IF left_half[1] < right_half[1] THEN
            result := result || left_half[1];
            left_half:= left_half[2:];
        ELSE
            result := result || right_half[1];
            right_half:= right_half[2:];
        END IF;
    END LOOP;
    
    -- Если в списках ещу остались элементы, то они добавляются к результату
    IF array_length(left_half, 1) > 0 THEN
        result := result || left_half;
    END IF;
    
    IF array_length(right_half, 1) > 0 THEN
        result := result || right_half;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT FLOOR(RANDOM() * limit_num) + 1;
$$ LANGUAGE sql;


DO $$
DECLARE
    i INT;
    array_nums INT[];
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO nums(num) SELECT generate_num(100);
    END LOOP;

END $$;


SELECT merge_sort(array_agg(num)) FROM nums;