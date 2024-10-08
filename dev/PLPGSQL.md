# pl/pgSQL

<b>pl/pgSQL</b> (PostgreSQL's procedural language) отличается от обычного SQL тем, что это полноценный язык программирования, специально разработанный для использования в PostgreSQL. В отличие от SQL, который предназначен для работы с данными и манипуляции с ними, pl/pgSQL позволяет создавать хранимые процедуры и функции, которые могут содержать условия, циклы, переменные, операции присваивания, обработку исключений и другие конструкции, характерные для программирования.

pl/pgSQL расширяет возможности базы данных PostgreSQL, предоставляя следующий функционал:
* Выполнение сложных операций и логики, включая условные операторы, циклы и обработку ошибок.
* Использование переменных для хранения промежуточных результатов и промежуточных данных.
* Создание функций, которые могут принимать аргументы и возвращать значения.
* Возможность оперировать с данными внутри хранимых процедур, включая выборку, модификацию и вставку данных.
* Доступ к системным функциям и возможность выполнения дополнительных операций, таких как работа с файлами или сетью.
* Поддержка транзакций и обработки параллельных запросов.

В целом, pl/pgSQL обеспечивает более гибкую и мощную функциональность в сравнении с обычным SQL, позволяя создавать более сложные и динамические программы внутри базы данных.

Синтаксис функции на pl/pgSQL:
```sql
CREATE OR REPLACE FUNCTION calc_sum(a INTEGER, b INTEGER) RETURNS INTEGER AS $$
DECLARE 
    sum INTEGER;    -- Объявление переменной
BEGIN
    sum := a + b;   -- Присвоение значения переменной
RETURN
    sum;            -- Возвращение переменной (функция calc_sum() возвращает переменную sum) 
END;
$$ LANGUAGE plpgsql;

SELECT calc_sum(5, 3);  -- Вызов функции
```

Анонимная функция:
```sql
DO $$
DECLARE
    var_1 TEXT;
    var_2 TEXT := 'World';
BEGIN
    var_1 := 'Hello';
    RAICE NOTICE '%, %!', var_1, var_2;     -- Вывод сообщения в терминал psql с меткой NOTICE
END 
$$;
```

Вложенные блоки:
```sql
DO $$
<<outer_block>>
DECLARE
    strng TEXT := 'Hello';
BEGIN
    <<inner_block>>
    DECLARE
        strng TEXT := 'World';
    BEGIN
        RAICE NOTICE '%, %!', outer_block.strng, inner_block.strng;
        RAICE NOTICE 'Внутренняя переменная strng: %!', strng;
    END inner_block;
END outer_block;
$$
```


### SETOF

Ключевое слово <b>SETOF</b> в функциях SQL указывает, что функция возвращает набор значений, то есть результатом функции будет таблица или набор строк. В примере функция вернет набор значений типа users (что является таблицей, или, иначе говоря в данной ситуации - пользовательским типом данных):
```sql
CREATE FUNCTION get_users() RETURNS SETOF users AS $$
BEGIN
    RETURN QUERY SELECT * FROM users;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_users();      -- Возвращает все значения из таблицы users
```

### IF ELSE

Условная конструкция, синтаксис функций pl/pgSQL:
```sql
CREATE OR REPLACE FUNCTION check_grade(grade NUMERIC) RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    IF grade >= 90 THEN
        result := 'A';
    ELSEIF grade >= 80 THEN     -- Допустимый синтаксис ELSIF и ELSEIF
        result := 'B';
    ELSIF grade >= 70 THEN
        result := 'C';
    ELSE
        result := 'F';
    END IF;
        
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```


### CASE / WHEN

```sql
DO $$
DECLARE
    code TEXT := (fmt(89317478592)).code;
BEGIN
    CASE code
        WHEN '495', '499' THEN
            RAICE NOTICE '% - Москва', code;
        WHEN '812' THEN
            RAICE NOTICE '% - Санкт-Петербург', code;
        WHEN '384' THEN
            RAICE NOTICE '% - Кемеровская область', code;
        ELSE
            RAICE NOTICE '% - Прочие', code;
    END CASE;
END;
$$;
```


### Циклы

1.  Цикл продолжается до тех пор, пока условие равно TRUE:

    ```sql
    WHILE expression
    LOOP
        --logic
    END LOOP;
    ```

2.  Цикл продолжается до тех пор, пока условие EXIT WHEN равно FALSE. Если условие TRUE, цикл разрывается:

    ```sql
    LOOP
        EXIT WHEN expression
        --logic
    END LOOP;
    ```

3.  Цикл повторяется определенное количество раз (от <b>a</b> до <b>b</b> раз). Необязательный оператор <b>BY</b> определяет шаг.

    ```sql
    FOR counter IN a..b BY x
    LOOP
        --logic
    END LOOP;
    ```

4. Цикл FOREACH очень похож на FOR. Отличие в том, что вместо перебора строк SQL-запроса происходит перебор элементов массива.

    ```sql
    FOREACH i IN ARRAY array_value
    LOOP
        --logic
    END LOOP; 
    ```
    
5.  Конструкция <b>CONTINUE</b> прерывает исполнение логики при определенных условиях, цикл переходит к следующей итерации:

    ```sql
    CONTINUE WHEN expression;
    ```


Функция, расчитывающая число Фибоначчи с помощью цикла:
```sql
CREATE OR REPLACE FUNCTION fib(x INTEGER) RETURNS INTEGER AS $$
    DECLARE
        counter INTEGER = 0;
        i INTEGER = 0;
        j INTEGER = 1;
    BEGIN
        IF x < 1 THEN
            RETURN 0;
        END IF;

        WHILE counter < x
        LOOP
            counter = counter + 1;
            SELECT j, i + j INTO i, j;
        END LOOP;
		
		RETURN i;
    END;     
$$ LANGUAGE plpgsql;

SELECT fib(5);
```

### Динамические команды

В PL/pgSQL введены динамические команды, которые позволяют выполнять SQL запросы и DDL команды в виде динамических строк. Это может быть полезно, когда нужно создавать или изменять SQL запросы динамически во время выполнения функции.

Динамические команды в PL/pgSQL могут быть выполнены с помощью функции `EXECUTE`. Этот оператор выполняет строку, которая представляет собой динамическую команду.

```sql
CREATE OR REPLACE FUNCTION get_employee_info(employee_id INT)
RETURNS TABLE (first_name TEXT, last_name TEXT) AS $$
    BEGIN
        EXECUTE 'SELECT first_name, last_name FROM employees WHERE id = $1' 
        INTO first_name, last_name 
        USING employee_id;
        RETURN NEXT;
    END;
$$ LANGUAGE plpgsql;
```

В приведенном примере функции get_employee_info выполняется динамический SQL-запрос, который выбирает first_name и last_name сотрудника по идентификатору employee_id. Результаты запроса помещаются в переменные first_name и last_name, которые затем возвращаются из функции.

Динамические команды в PL/pgSQL обычно используются для создания универсальных функций, которые могут работать с различными таблицами и столбцами в зависимости от входных данных или условий. Однако, следует использовать динамические команды с осторожностью из-за потенциальных уязвимостей безопасности (например, SQL-инъекции).


### CURSOR

Курсоры в PL/pgSQL используются для обработки результирующих наборов данных внутри хранимой процедуры или функции. Курсор позволяет выполнять SQL-запрос, перебирать полученные строки по одной и при необходимости производить дополнительные действия с каждой строкой.

```sql
CREATE OR REPLACE FUNCTION get_employees_salary() RETURNS SETOF emp_salary AS $$
    DECLARE
        emp_record employees%ROWTYPE;
        emp_cursor CURSOR FOR SELECT * FROM employees;
    BEGIN
        OPEN emp_cursor;
        LOOP
            FETCH emp_cursor INTO emp_record;
            EXIT WHEN NOT FOUND;
            
            -- дополнительная обработка данных (например, подсчет суммарной зарплаты)
            
            RETURN NEXT emp_record;
        END LOOP;
        CLOSE emp_cursor;
    END;
$$ LANGUAGE plpgsql;
```

В приведенном примере функции get_employees_salary создается курсор emp_cursor, который выбирает все данные из таблицы employees. Затем с помощью цикла LOOP обрабатывается каждая запись, извлеченная из курсора, сохраняется в переменную emp_record, и при необходимости выполняются дополнительные операции (например, подсчет суммарной зарплаты). После этого запись возвращается с помощью RETURN NEXT.

Курсоры в PL/pgSQL могут быть полезны, когда нужно обработать результирующий набор построчно и выполнить дополнительные операции с каждой строкой. Однако, следует помнить о затратности использования курсоров в плане производительности, поэтому стоит использовать их с умом в случаях, когда это необходимо и возможно эффективное выполнение операций.


### Обработка ошибок

Обработка ошибок осуществляется с помощью блока операторов EXCEPTION:

```sql
CREATE OR REPLACE FUNCTION divide_numbers(x INT, y INT) RETURNS FLOAT AS $$
DECLARE
    result FLOAT;
BEGIN
    BEGIN
        result := x / y;
    EXCEPTION
        WHEN division_by_zero THEN
            RAISE EXCEPTION 'Division by zero error';
    END;
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

В данном примере функция divide_numbers принимает два целых числа x и y, и возвращает результат их деления. Внутри блока операторов `EXCEPTION` проверяется, если происходит деление на ноль, то генерируется ошибка с сообщением "Division by zero error".


### Триггеры

Триггеры - это специальные объекты базы данных, которые активизируются автоматически при определенных событиях или изменениях данных в таблице. Триггеры могут использоваться для автоматического выполнения определенных действий, проверки целостности данных или записи изменений в журналы.

Триггер состоит из двух частей: собственно триггера (который определяет события) и триггерной функции (которая определяет действия и возвращает значение типа trigger). 

<em>Триггеры могут срабатывать на вставку (<b>INSERT</b>), обновление (<b>UPDATE</b>) или удаление (<b>DELETE</b>) строк в таблице или представлении, а также на опустошение (<b>TRUNCATE</b>) таблиц. Триггер может срабатывать до выполнения действия (<b>BEFORE</b>), после него (<b>AFTER</b>), или вместо него (<b>INSTEAD OF</b>). Триггер может срабатывать один раз для всей операции (<b>FOR EACH STATEMENT</b>), или каждый раз для каждой затронутой строки (<b>FOR EACH ROW</b>).</em>

`BEFORE` триггеры можно использовать для проверки корректности операции и при необходимости вызывать ошибку.

`BEFORE STATEMENT` срабатывает один раз для операции независимо от того, сколько строк будет затронуто (возможно, что и ни одной). Это происходит до того, как операция начала выполняться.Возвращаемое значение триггерной функции игнорируется. Если в триггере возникает ошибка, операция отменяется.

`BEFORE ROW` можно применять для модификации строки (например, заполнить пустое поле нужным значением). Это бывает удобно, чтобы не повторять логику заполнения "технических" полей в каждой операции, а также позволяет вмешаться в работу приложения, код которого недоступен для изменения. Чтобы не вмешиваться в работу операции, триггер должен вернуть строку в том виде, в котором ее собирается изменить операция: `NEW` для вставки и обновления, любое значение (но не NULL) для удаления (обычно используют `OLD`).

`INSTEAD OF ROW` очень похожи на триггеры `BEFORE`, но определяются только для представлений и срабатывают не до, а вместо операции. В задачу таких триггеров обычно входит выполнение необходимых операций над базовыми таблицами представления. Также триггер может вернуть измененное значение `NEW` - именно оно будет видно при выполнении операции с указанием фразы `RETURNING`.

`AFTER ROW` и `AFTER STATEMENT` полезны в случаях, когда нужно знать точное состояние после операции. Если операции затрагивают сразу много строк, то триггер `AFTER STATEMENT` с переходными таблицами может оказаться более эффективным решением, чем триггер `AFTER ROW`, поскольку позволяет обрабатывать все изменения пакетно, а не построчно.

`AFTER ROW` срабатывает для каждой затрагиваемой строки, но не сразу после действия над строкой, а после того, как выполнена вся операция - чтобы при обращении из этих триггеров к изменяющейся таблице результат не зависел от порядка обработки строк. 
Контекст триггерной функции составляют:
* OLD — старая строка (не определено для операции вставки),
* NEW — новое значение строки (не определено для удаления).

`AFTER STATEMENT` срабатывает один раз после окончания операции и после всех триггеров AFTER ROW (независимо от того, сколько строк было затронуто). Возвращаемое значение триггерной функции игнорируется. Контекст вызова передается с помощью переходных таблиц. Обращаясь к ним, триггерная функция может проанализировать все затронутые строки. 

Триггерная функция:
```sql
CREATE OR REPLACE FUNCTION flights_v_update() RETURNS trigger AS $$
DECLARE
    code_to char(3);
BEGIN
    BEGIN
        SELECT code INTO STRICT code_to
        FROM airports
        WHERE name = NEW.airport_to;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE EXCEPTION 'Аэропорт "%" отсутствует', NEW.airport_to;
    END;
    UPDATE flights
    SET airport_to = code_to
    WHERE id = OLD.id; -- изменение id игнорируем
    RETURN NEW;
END
$$ LANGUAGE plpgsql;
```

Триггер:
```sql
CREATE TRIGGER flights_v_upd_trigger
INSTEAD OF UPDATE ON flights_v
FOR EACH ROW EXECUTE FUNCTION flights_v_update();
```


### RAISE

Команда RAISE предназначена для вывода сообщений и вызова ошибок. В простом случае для отладки нужно добавить вызовы RAISE NOTICE в код функции, запустить функцию на выполнение и проанализировать получаемые по ходу выполнения сообщения. Сообщения RAISE нетранзакционные: они отправляются асинхронно и не зависят от статуса завершения транзакции. 

Для управления отправкой сообщений используются уровень сообщения (DEBUG, LOG, NOTICE, INFO, WARNING) и параметры сервера. 

В консоль выведется текстовое сообщение, переданное параметром в debug_message:
```sql
CREATE PROCEDURE debug_message(msg TEXT) AS $$
BEGIN
	RAISE NOTICE '%', msg;
END;
$$ LANGUAGE plpgsql;
```

Выдача сообщений с уровнем, установленным в app.raise_level:
```sql
CREATE OR REPLACE PROCEDURE debug_message(msg TEXT)
AS $$
BEGIN
    CASE current_setting('app.raise_level', true)
        WHEN 'NOTICE'  THEN RAISE NOTICE  '%, %, %', user, clock_timestamp(), msg;
        WHEN 'DEBUG'   THEN RAISE DEBUG   '%, %, %', user, clock_timestamp(), msg;
        WHEN 'LOG'     THEN RAISE LOG     '%, %, %', user, clock_timestamp(), msg;
        WHEN 'INFO'    THEN RAISE INFO    '%, %, %', user, clock_timestamp(), msg;
        WHEN 'WARNING' THEN RAISE WARNING '%, %, %', user, clock_timestamp(), msg;
        ELSE NULL; -- все прочие значения отключают вывод сообщений
    END CASE;
END
$$ LANGUAGE plpgsql;
```

Определение уровня (например NOTICE):
```sql
SET app.raise_level TO 'NOTICE';
```


### Запись сообщений в файл

Установка расширения:
```sql
CREATE EXTENSION adminpack;
```

Создание процедуры с функционалом записи:
```sql
CREATE OR REPLACE PROCEDURE debug_message(msg TEXT)
AS $$
DECLARE
    filename CONSTANT TEXT := '/var/lib/postgresql/log.txt';
    message TEXT;
BEGIN
    message := format(E'%s, %s, %s\n',
        session_user, clock_timestamp()::TEXT, debug_message.msg
    );
    PERFORM pg_file_write(filename, message, /* append */ true);
END
$$ LANGUAGE plpgsql;
```

Чтение созданного файла с записями 

`sudo cat /var/lib/postgresql/log.txt`