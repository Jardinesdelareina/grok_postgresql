DROP FUNCTION generate_order_number;
DROP FUNCTION generate_phone_number;
DROP FUNCTION generate_boolean_value;
DROP FUNCTION generate_name;
DROP FUNCTION generate_num;
DROP VIEW male_name_list;
DROP VIEW female_name_list;
DROP PROCEDURE create_data;


--
-- Генерация номера заказа
--
CREATE OR REPLACE FUNCTION generate_order_number() RETURNS INT AS $$
    SELECT EXTRACT(milliseconds FROM now())::int + random() * 100::int;
$$ LANGUAGE sql;


--
-- Генерация мобильных номеров
--
CREATE OR REPLACE FUNCTION generate_phone_number() RETURNS VARCHAR(11) AS $$
    SELECT '79' || lpad(floor(random() * 1000000000)::text, 9, '0');
$$ LANGUAGE sql;


--
-- Генерация булевого значения
--
CREATE OR REPLACE FUNCTION generate_boolean_value() RETURNS BOOLEAN AS $$
    SELECT CASE WHEN random() < 0.5 THEN TRUE ELSE FALSE END
$$ LANGUAGE sql;


--
-- Мужские имена/фамилии
--
CREATE VIEW male_name_list AS
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
CREATE VIEW female_name_list AS
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
CREATE OR REPLACE FUNCTION generate_num(limit_num INT) RETURNS INT AS $$
    SELECT floor(random() * limit_num) + 1;
$$ LANGUAGE sql;


--
-- Генерация значения имя/фамилия
--
CREATE OR REPLACE FUNCTION generate_name() RETURNS VARCHAR AS $$
    SELECT 
        CASE WHEN random() > 0.5 
            THEN (SELECT male_name FROM male_name_list)
            ELSE (SELECT female_name FROM female_name_list)
            END
$$ LANGUAGE sql;


--
-- Создание заказа (имитация от просмотра меню до оформления ACCEPTED и оплаты CLOSED)
--
CREATE OR REPLACE PROCEDURE create_data(fid INT) AS $$

    INSERT INTO kafe_v1.customers(name, phone, discount)
    VALUES(generate_name(), generate_phone_number(), generate_boolean_value());

    SELECT title, description, price
    FROM kafe_v1.dishes;

    INSERT INTO kafe_v1.orders_dishes(amount, fk_order_id, fk_dish_id)
    VALUES(generate_num(limit_num -> 5), fid, generate_num(limit_num-> 271));

    INSERT INTO kafe_v1.orders(number, status, created)
    VALUES(order_number(), 'ACCEPTED', now());

    /* CASE 
        WHEN random() > 0.5 THEN 
        INSERT INTO kafe_v1.orders_hall(table_number, fk_order_id, fk_waiter_id)
        VALUES(generate_num(limit_num-> 32), fid, generate_num(limit_num -> 5))
        
        WHEN random() < 0.5 THEN
        INSERT INTO kafe_v1.orders_delivery(fk_customer_id, fk_order_id)
        VALUES(fid, fid )

        WHEN random() = 0.5 THEN
        INSERT INTO kafe_v1.orders_take_out(phone_number, fk_order_id)
        VALUES(phone_numbr(), fid)
    END */

    SELECT pg_sleep(20); 
    
    UPDATE kafe_1.orders
    SET status = 'CLOSED', updated = now()
    WHERE id = fid 

$$ LANGUAGE sql;
