# СУБД PostgreSQL

Данный репозиторий является базой знаний об открытом программном обеспечении PostgreSQL - системе управления базами данных. Вся информация взята из общедоступных источников и несет исключительно образовательную цель.

<div>
    <img src="https://github.com/devicons/devicon/blob/master/icons/postgresql/postgresql-original-wordmark.svg" width="80" height="80"/>&nbsp;
</div>


### Реляционная модель данных

<em>Реляционная модель данных</em> - это математическая модель, которая описывает способ организации и хранения данных в базе данных. Она основана на понятии "таблицы" или "реляции", которая состоит из строк и столбцов.

В реляционной модели каждая таблица имеет набор атрибутов (столбцов), которые определяют тип данных, содержащихся в каждой ячейке столбца. Каждая строка таблицы представляет собой конкретную запись или кортеж данных.

Главная идея реляционной модели заключается в том, что связи между таблицами (реляциями) осуществляются через общие атрибуты, так называемые "внешние ключи". Внешний ключ в таблице ссылается на первичный ключ другой таблицы, что позволяет связывать данные между разными таблицами.

Преимущества реляционной модели данных:
1. Простота структуры и понятность модели,
2. Гибкость и возможность создания сложных запросов для извлечения данных,
3. Независимость от физической реализации данных,
4. Высокая надежность и целостность данных,
5. Поддержка множества операций, таких как сортировка, поиск, фильтрация и соединение данных.


### Транзакции и транзакционность

<b>Транзакция</b> в базе данных представляет собой последовательность операций базы данных, которые выполняются как единое целое. Транзакция обладает следующими свойствами, известными как ACID-свойства:

1. <em>Атомарность (Atomicity)</em>: (<b>Всё или ничего</b>) Транзакция либо выполняется полностью, либо не выполняется вообще. Если одна из операций внутри транзакции не может быть выполнена, то вся транзакция откатывается, и все изменения, сделанные до этого, отменяются.

2. <em>Согласованность (Consistency)</em>: (<b>Ограничения целостности и пользовательские ограничения</b>)  Транзакция должна приводить базу данных из одного согласованного состояния в другое согласованное состояние. Это означает, что после завершения транзакции должны быть выполнены все правила целостности БД.

3. <em>Изолированность (Isolation)</em>: (<b>Влияние параллельных процессов</b>) Каждая транзакция должна выполняться изолированно от других транзакций. Изменения, внесенные одной транзакцией, должны быть видимы только после успешного завершения этой транзакции. Изолированность обеспечивается с помощью уровней изоляции транзакций. PostgreSQL поддерживает несколько уровней изоляции транзакций, которые позволяют контролировать видимость изменений, выполняемых другими транзакциями. Это позволяет избежать конфликтов одновременного доступа к данным и обеспечивает изоляцию транзакций друг от друга.

4. <em>Долговечность (Durability)</em>: (<b>Сохранность данных даже после сбоя</b>)  После успешного завершения, изменения, сделанные в транзакции, должны быть сохранены и доступны даже в случае сбоя системы или отключения питания. Это обеспечивается с помощью журнала предзаписи (WAL). Все изменения данных записываются сначала в журнал предзаписи перед тем, как они будут применены к реальной базе данных. Это позволяет восстановить данные в случае сбоя, воссоздавая состояние базы данных до сбоя с помощью журнала предзаписи.

<b>Транзакционность</b> в базах данных означает, что операции, выполняемые в рамках транзакции, являются неделимыми и отражают только либо полное выполнение, либо отмену всех изменений. Это обеспечивает надежность и целостность данных.

```sql
-- Начало транзакции
BEGIN;

-- Выполнение операций внутри транзакции
UPDATE users
SET balance = balance - 100
WHERE user_id = 1;

UPDATE products
SET quantity = quantity - 1
WHERE product_id = 100;

-- Проверка результатов операций
SELECT * FROM users WHERE user_id = 1;
SELECT * FROM products WHERE product_id = 100;

-- Если все операции выполнены успешно, фиксируем транзакцию
COMMIT;

-- Если произошла ошибка или нужно отменить изменения, откатываем транзакцию
ROLLBACK;
```