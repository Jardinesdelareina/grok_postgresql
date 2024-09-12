# Создание расширений PostgreSQL

Расширение устанавливается в базу данных командой `CREATE EXTENSION`. При этом должны существовать два файла: 
* Управляющий файл 'filename.control' с параметрами расширения; 
* Cкрипт создания объектов расширения 'filename--version.sql'.

Расширение удаляется командой `DROP EXTENSION`.

Создание расширения `fib`:
`mkdir fib`

Создание управляющего файла с настройками:
```
cat >fib/fib.control <<EOF
default_version = '1.0'
relocatable = true
encoding = UTF8
comment = 'Числа Фибоначчи'
EOF
```

`default_version`   определяет версию по умолчанию, без этого параметра версию придется указывать явно;

`relocatable`    говорит о том, что расширение можно перемещать из схемы в схему;

`encoding`  требуется, если используются символы, отличные от ASCII;

`comment`   определяет комментарии к расширению.

Создание файла с расширением:
```cat >fib/fib--1.0.sql <<'EOF'
\echo Use "CREATE EXTENSION fib" to load this file. \quit
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
$$ LANGUAGE plpgsql STABLE STRICT;
EOF
```

Чтобы PostgreSQL нашел созданные файлы, они должны оказаться в каталоге SHAREDIR/extension. Значение SHAREDIR можно узнать так:
`pg_config --sharedir`

Создание файла для утилиты make:
```
cat >fib/Makefile <<'EOF'
EXTENSION = fib
DATA = fib--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
EOF
```

Выполнение make install в каталог расширения:
`sudo make install -C fib`

Проверка наличия файлов расширения в каталоге расширения:
`ls `pg_config --sharedir`/extension/fib*`

Проверка доступности расширения:
```sql
SELECT * FROM pg_available_extensions WHERE name = 'fib';
```

Само расширение не относится к какой-либо схеме, но объекты расширения — относятся. По-умолчанию схема - public. Но если установить расширение к отдельную схему `CREATE EXTENSION fib SCHEMA fib;` и вызвать `SELECT fib.fib(5)`, то произойдет ошибка, так как объект расширения не находится в данной схеме. Нужно обозначить путь поиска:
```sql
SET search_path TO fib, public;
```

Так как расширение переносимо (relocatable = true), то расширение можно переместить в другую схему:
```sql
ALTER EXTENSION fib SET SCHEMA public;
```


### Обновления

Обновление версии расширения выполняется командой `ALTER EXTENSION UPDATE`. При этом должен существовать скрипт обновления 'filename--old-version--new-version.sql', содержащий необходимые для обновления команды.

В файле `fib.control` при смене версии нужно изменить параметр `default_version`:
```cat >fib/fib.control <<EOF
default_version = '1.1'
relocatable = true
encoding = UTF8
comment = 'Единицы измерения'
EOF
```

Создание файла с командами для обновления:
```
cat >fib/fib--1.0--1.1.sql <<'EOF'
\echo Use "CREATE EXTENSION fib" to load this file. \quit
CREATE OR REPLACE FUNCTION fib(x INTEGER) RETURNS INTEGER AS $$
    DECLARE
        counter INTEGER = 0;
        i INTEGER = 0;
        j INTEGER = 1;
    BEGIN
        IF x < 1 THEN
            RETURN 0;
        ELSEIF x > 45 THEN
            RETURN 0;
        END IF;
        WHILE counter < x
        LOOP
            counter = counter + 1;
            SELECT j, i + j INTO i, j;
        END LOOP;
		RETURN i;
    END;     
$$ LANGUAGE plpgsql STABLE STRICT;
EOF 
```

Добавление в Makefile новый файл в список DATA:
```cat >fib/Makefile <<'EOF'
EXTENSION = fib
DATA = fib--1.0.sql fib--1.0--1.1.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
EOF
```

Выполнение make install:
`sudo make install -C fib`

Вывод доступных версий расширения:
```sql
SELECT name, version, installed
FROM pg_available_extension_versions
WHERE name = 'fib';
```

Обновление расширения:
```sql
ALTER EXTENSION fib UPDATE;
```

Список доступных расширений, доступных для загрузки в базу данных:
```sql
SELECT name, default_version, installed_version
FROM pg_available_extensions
ORDER BY name;
```


### Расширения на языке C

1. Содержимое файла, обязатеьное для инициализации принадлежности к PostgreSQL:
```c
#include "postgres.h"
#include "fmgr.h"

PG_MODULE_MAGIC;             // Макрос, определяющий версию модуля для PostgreSQL
PG_FUNCTION_INFO_V1(postgres_func);    // Макрос, определяющий соглашения о вызове функций C в PostgreSQL

Datum postgresf_func(PG_FUNCTION_ARGS) 
{
    int32 arg_a = PG_GETARG_INT32(0);
    int32 arg_b = PG_GETARG_INT32(1);
    PG_RETURN_INT32(arg_a + arg_b);
}
```


2. Компиляция файла:

`gcc -fPIC -I /usr/include/postgresql/14/server -c postgres_func.c`

`gcc -shared -o postgres_func.so postgres_func.o`


3. Объявление функции:

```sql
CREATE OR REPLACE FUNCTION postgres_func(INT, INT) 
RETURNS INT AS 'path/to/file_so', 'postgres_func'
LANGUAGE C STRICT;
```