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
    END
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
    
4.  Конструкция <b>CONTINUE</b> прерывает исполнение логики при определенных условиях, цикл переходит к следующей итерации:

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
        EXECUTE 'SELECT first_name, last_name FROM employees WHERE id = $1' INTO first_name, last_name USING employee_id;
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