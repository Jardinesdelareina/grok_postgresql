--
-- Генерация случайного номера
--
CREATE OR REPLACE FUNCTION main.generate_random_int() RETURNS INT AS $$
    SELECT (cast((random() * 100) AS DECIMAL(18,15)) * 1000000000)::bigint + EXTRACT(milliseconds FROM now())::int;
$$ LANGUAGE sql;


--
-- Генерация мобильного номера
--
CREATE OR REPLACE FUNCTION main.generate_phone_number() RETURNS VARCHAR(11) AS $$
    SELECT '79' || lpad(floor(random() * 1000000000)::text, 9, '0');
$$ LANGUAGE sql;


--
-- Генерация булевого значения
--
CREATE OR REPLACE FUNCTION main.generate_boolean_value() RETURNS BOOLEAN AS $$
    SELECT CASE WHEN random() < 0.5 THEN TRUE ELSE FALSE END
$$ LANGUAGE sql;


--
-- Мужские имена/фамилии
--
CREATE VIEW main.male_name_list AS
SELECT (f_name || ' ' || l_name) AS male_name 
    FROM (SELECT unnest(array[
        'Андрей', 'Александр', 'Алексей', 'Артем', 'Борис', 'Вадим', 
        'Василий', 'Виктор', 'Геннадий', 'Георгий', 'Даниил', 
        'Дмитрий', 'Евгений', 'Иван', 'Игорь', 'Илья', 'Константин', 
        'Леонид', 'Максим', 'Михаил', 'Никита', 'Николай', 'Олег', 
        'Павел', 'Петр', 'Роман', 'Сергей', 'Станислав', 'Тимофей', 
        'Федор', 'Юрий', 'Яков', 'Ярослав', 'Артур', 'Владимир', 
        'Григорий', 'Захар', 'Анатолий']) AS f_name) AS f
    CROSS JOIN
        (SELECT unnest(array[
            'Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 
            'Васильев', 'Петров', 'Смирнов', 'Морозов', 'Новиков', 'Зайцев', 
            'Борисов', 'Александров', 'Сергеев', 'Ковалев', 'Илларионов', 
            'Григорьев', 'Романов', 'Федоров', 'Яковлев', 'Поляков', 'Соколов', 
            'Макаров', 'Антонов', 'Крылов', 'Гаврилов', 'Ефимов', 'Фомин', 
            'Дорофеев', 'Беляев', 'Никонов', 'Артемьев', 'Левин', 'Зуев', 
            'Кондратьев', 'Андреев', 'Захаров']) AS l_name) AS l
    ORDER BY random()
    LIMIT 1;


--
-- Женские имена/фамилии
--
CREATE VIEW main.female_name_list AS
SELECT (f_name || ' ' || l_name) AS female_name
    FROM (SELECT unnest(array[
        'Анна', 'Виктория', 'Екатерина', 'Мария', 'Ольга', 'Татьяна', 
        'Алиса', 'Дарья', 'Елена', 'Ирина', 'Ксения', 'Лариса', 
        'Надежда', 'Полина', 'София', 'Юлия', 'Анжела', 'Валентина', 
        'Евгения', 'Марина', 'Оксана', 'Тамара', 'Антонина', 'Валерия', 
        'Ева', 'Кристина', 'Лилия', 'Нина', 'Раиса', 'Светлана', 
        'Юлиана', 'Ангелина', 'Галина', 'Елена', 'Лидия', 'Милена', 
        'Ольга', 'Таисия', 'Агата']) AS f_name) AS f
    CROSS JOIN
        (SELECT unnest(array[
            'Иванова', 'Петрова', 'Сидорова', 'Смирнова', 'Кузнецова', 'Попова', 
            'Васильева', 'Петрова', 'Смирнова', 'Морозова', 'Новикова', 'Зайцева', 
            'Борисова', 'Александрова', 'Сергеева', 'Ковалева', 'Илларионова', 'Григорьева', 
            'Романова', 'Федорова', 'Яковлева', 'Полякова', 'Соколова', 'Макарова', 
            'Антонова', 'Крылова', 'Гаврилова', 'Ефимова', 'Фомина', 'Дорофеева', 
            'Беляева', 'Никонова', 'Артемьева', 'Левина', 'Зуева', 'Кондратьева', 
            'Андреева', 'Захарова']) AS l_name) AS l
    ORDER BY random()
    LIMIT 1;


--
-- Генерация произвольного числа (предел указывается в качестве параметра) 
--
CREATE OR REPLACE FUNCTION main.generate_num(limit_num INT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;


--
-- Генерация значения имя/фамилия
--
CREATE OR REPLACE FUNCTION main.generate_name() RETURNS VARCHAR AS $$
    SELECT 
        CASE WHEN random() > 0.5 
            THEN (SELECT male_name FROM main.male_name_list)
            ELSE (SELECT female_name FROM main.female_name_list)
            END
$$ LANGUAGE sql;


--
-- Создание заказа доставки (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE main.create_data_delivery(fid INT) AS $$

    INSERT INTO main.customers(name, phone, discount)
    VALUES(main.generate_name(), main.generate_phone_number(), main.generate_boolean_value());

    SELECT title, description, price, is_available, fk_category_id
    FROM main.dishes;

    INSERT INTO main.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(main.generate_num(5), fid, main.generate_num(267));

    INSERT INTO main.orders_delivery(fk_customer_id, fk_order_id)
    VALUES(fid, fid);

    SELECT pg_sleep(20); 
    
    UPDATE main.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Создание заказа самовывоза (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE main.create_data_take_out(fid INT) AS $$

    SELECT title, description, price, is_available, fk_category_id
    FROM main.dishes;

    INSERT INTO main.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(main.generate_num(5), fid, main.generate_num(271));

    INSERT INTO main.orders_take_out(phone, fk_order_id)
    VALUES(main.generate_phone_number(), fid);

    SELECT pg_sleep(20); 
    
    UPDATE main.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Создание заказа зала (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE main.create_data_hall(fid INT) AS $$

    SELECT title, description, price, is_available, fk_category_id
    FROM main.dishes;

    INSERT INTO main.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO main.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(main.generate_num(5), fid, main.generate_num(271));

    INSERT INTO main.orders_hall(table_number, fk_order_id, fk_waiter_id)
    VALUES(main.generate_num(32), fid, main.generate_num(5));

    SELECT pg_sleep(20); 
    
    UPDATE main.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Генерация данных (основной поток)
--
CREATE OR REPLACE FUNCTION main.send_loop() RETURNS VOID AS $$
    DECLARE
        fid INT;
    BEGIN
        WHILE TRUE LOOP
            FOR fid IN 1..1600 LOOP
                CASE
                    WHEN random() > 0.5 THEN
                        CALL main.create_data_delivery(fid);
                    WHEN random() < 0.5 THEN
                        CALL main.create_data_hall(fid);
                    ELSE
                        CALL main.create_data_take_out(fid);
                END CASE;
            END LOOP;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;