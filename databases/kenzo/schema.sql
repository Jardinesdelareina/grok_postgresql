/* Схема базы данных одного из городских кафе */

--
-- Предварительное удаление таблиц
--
DROP TABLE orders_dish;
DROP TABLE dish;
DROP TABLE categories;
DROP TABLE orders;
DROP Table customers;
DROP TABLE addresses;


--
-- Адреса заказчиков, куда происходит доставка
--
CREATE TABLE addresses
(
    
);


--
-- Заказчики
--
CREATE TABLE customers
(

);


--
-- Заказы
--
CREATE TABLE orders
(

);


--
-- Категории блюд
--
CREATE TABLE categories
(

);


--
-- Блюда
--
CREATE TABLE dishes
(

);


--
-- Many to Many orders и dishes
--
CREATE TABLE orders_dishes
(

);