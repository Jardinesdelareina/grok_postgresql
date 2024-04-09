INSERT INTO kafe_v1.categories(title) VALUES('Горячий цех');
INSERT INTO kafe_v1.categories(title) VALUES('Пицца');
INSERT INTO kafe_v1.categories(title) VALUES('Холодный цех');
INSERT INTO kafe_v1.categories(title) VALUES('Роллы');

INSERT INTO kafe_v1.waiters(name) VALUES('Борщева Е.');
INSERT INTO kafe_v1.waiters(name) VALUES('Онуфриенко И.');
INSERT INTO kafe_v1.waiters(name) VALUES('Картаполова Т.');
INSERT INTO kafe_v1.waiters(name) VALUES('Расмус К.');
INSERT INTO kafe_v1.waiters(name) VALUES('Воронцовская В.');


--
-- Генерация номера заказа
--
CREATE OR REPLACE FUNCTION kafe_v1.generate_order_number() RETURNS INT AS $$
    SELECT EXTRACT(milliseconds FROM now())::int + random() * 100::int;
$$ LANGUAGE sql;


--
-- Генерация мобильных номеров
--
CREATE OR REPLACE FUNCTION kafe_v1.generate_phone_number() RETURNS VARCHAR(11) AS $$
    SELECT '79' || lpad(floor(random() * 1000000000)::text, 9, '0');
$$ LANGUAGE sql;


--
-- Генерация булевого значения
--
CREATE OR REPLACE FUNCTION kafe_v1.generate_boolean_value() RETURNS BOOLEAN AS $$
    SELECT CASE WHEN random() < 0.5 THEN TRUE ELSE FALSE END
$$ LANGUAGE sql;


--
-- Мужские имена/фамилии
--
CREATE VIEW kafe_v1.male_name_list AS
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
CREATE VIEW kafe_v1.female_name_list AS
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
CREATE OR REPLACE FUNCTION kafe_v1.generate_num(limit_num INT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;


--
-- Генерация значения имя/фамилия
--
CREATE OR REPLACE FUNCTION kafe_v1.generate_name() RETURNS VARCHAR AS $$
    SELECT 
        CASE WHEN random() > 0.5 
            THEN (SELECT male_name FROM kafe_v1.male_name_list)
            ELSE (SELECT female_name FROM kafe_v1.female_name_list)
            END
$$ LANGUAGE sql;


--
-- Создание заказа доставки (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE kafe_v1.create_data_delivery(fid INT) AS $$

    INSERT INTO kafe_v1.customers(name, phone, discount)
    VALUES(kafe_v1.generate_name(), kafe_v1.generate_phone_number(), kafe_v1.generate_boolean_value());

    SELECT title, description, price, is_available, fk_category_id
    FROM kafe_v1.dishes;

    INSERT INTO kafe_v1.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO kafe_v1.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(kafe_v1.generate_num(5), fid, kafe_v1.generate_num(267));

    INSERT INTO kafe_v1.orders_delivery(fk_customer_id, fk_order_id)
    VALUES(fid, fid);

    SELECT pg_sleep(20); 
    
    UPDATE kafe_v1.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Создание заказа самовывоза (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE kafe_v1.create_data_take_out(fid INT) AS $$

    SELECT title, description, price, is_available, fk_category_id
    FROM kafe_v1.dishes;

    INSERT INTO kafe_v1.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO kafe_v1.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(kafe_v1.generate_num(5), fid, kafe_v1.generate_num(271));

    INSERT INTO kafe_v1.orders_take_out(phone, fk_order_id)
    VALUES(kafe_v1.generate_phone_number(), fid);

    SELECT pg_sleep(20); 
    
    UPDATE kafe_v1.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Создание заказа зала (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE kafe_v1.create_data_hall(fid INT) AS $$

    SELECT title, description, price, is_available, fk_category_id
    FROM kafe_v1.dishes;

    INSERT INTO kafe_v1.orders(status, created_at)
    VALUES('ACCEPTED', now());

    INSERT INTO kafe_v1.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(kafe_v1.generate_num(5), fid, kafe_v1.generate_num(271));

    INSERT INTO kafe_v1.orders_hall(table_number, fk_order_id, fk_waiter_id)
    VALUES(kafe_v1.generate_num(32), fid, kafe_v1.generate_num(5));

    SELECT pg_sleep(20); 
    
    UPDATE kafe_v1.orders
    SET status = 'CLOSED', updated_at = now()
    WHERE id = fid;

$$ LANGUAGE sql;


--
-- Генерация данных (основной поток)
--
CREATE OR REPLACE FUNCTION kafe_v1.send_loop() RETURNS VOID AS $$
    DECLARE
        fid INT;
    BEGIN
        WHILE TRUE LOOP
            FOR fid IN 1..1600 LOOP
                CASE
                    WHEN random() > 0.5 THEN
                        CALL kafe_v1.create_data_delivery(fid);
                    WHEN random() < 0.5 THEN
                        CALL kafe_v1.create_data_hall(fid);
                    ELSE
                        CALL kafe_v1.create_data_take_out(fid);
                END CASE;
            END LOOP;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;