CREATE FUNCTION cci_func(
  prices double precision[],
  period integer
)
RETURNS double precision
AS '/cci_file', 'cci_func'
LANGUAGE C STRICT; 

select cci_func(array[2.0, 3.0, 5.0, 1.0, 3.0, 4.0, 1.0, 1.0, 2.0, 10.0, 10.0], 3);


drop table dataset;
create table dataset
(
    id int generated always as identity primary key,
    p_high numeric,
    p_low numeric,
    p_close numeric
);

CREATE OR REPLACE FUNCTION generate_num(limit_num BIGINT) RETURNS INT AS $$
    SELECT FLOOR(RANDOM() * limit_num) + 1;
$$ LANGUAGE sql;

do $$
declare
    i int;
begin
    for i in 1..1000 loop
        insert into dataset(p_high, p_low, p_close) values(
            ('0.56' || generate_num(99))::numeric,
            ('0.54' || generate_num(99))::numeric,
            ('0.55' || generate_num(99))::numeric
        );
    end loop;
end $$;


CREATE OR REPLACE FUNCTION c_cci(period INT)
RETURNS NUMERIC AS $$
DECLARE 
    i RECORD; 
    typical_price NUMERIC;
    array_p NUMERIC[];
    indicator NUMERIC; 
BEGIN 
    FOR i IN SELECT p_high, p_low, p_close FROM dataset LOOP 
        typical_price := (i.p_high + i.p_low + i.p_close) / 3; 
        array_p := array_p || typical_price;
    END LOOP;
    indicator := cci_func(array_p, period);
    RETURN indicator; 
END;
$$ LANGUAGE plpgsql;