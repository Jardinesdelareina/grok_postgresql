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