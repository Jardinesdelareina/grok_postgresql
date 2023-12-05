DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS persons;


CREATE TABLE persons
(
    person_id SERIAL,
    name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_person_id PRIMARY KEY (person_id)
);


CREATE TABLE orders
(
    order_id SERIAL,
    num INTEGER NOT NULL UNIQUE,
    CONSTRAINT pk_order_id PRIMARY KEY (order_id)
);


-- Добавление новой колонки
ALTER TABLE orders ADD COLUMN fk_person_id INTEGER;


/* 
Создание отношения в fk_order_person,
назначение созданному полю fk_person_id зависимости от
поля person_id таблицы persons, отношение "один ко многим"
*/
ALTER TABLE orders
ADD CONSTRAINT fk_order_person
FOREIGN KEY (fk_person_id) REFERENCES persons(person_id);


INSERT INTO persons
VALUES
(1, 'Milana'),
(2, 'Marina'),
(3, 'Nina'),
(4, 'Nona'),
(5, 'Olga');


INSERT INTO orders
VALUES
(1, 7483, 4),
(2, 7583, 4),
(3, 7476, 2),
(4, 4483, 1),
(5, 7482, 5),
(6, 7487, 3),
(7, 7983, 1);