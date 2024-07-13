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
