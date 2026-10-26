drop procedure if exists mpcore.product_create;
create or replace procedure mpcore.product_create(p_json_param in varchar) as
$$
/*
  * Создание товара
  * call mpcore.product_create('{"us_id": 1, "cat_id": 17, "pr_name": "iPhone 16", "cnt_pr": 10, "price": 64000}');
*/
declare
	v_json jsonb;
	v_us_id bigint;
	v_cat_id bigint;
	v_pr_num varchar;
	v_pr_name text;
	v_cnt_pr int;
	v_price numeric;
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_us_id = v_json ->> 'us_id';

	if v_us_id is null then 
		raise exception 'Не указан продавец товара';
	end if;

	v_cat_id = v_json ->> 'cat_id';

	if v_cat_id is null then 
		raise exception 'Не указана категория товара';
	end if;

	v_pr_name = (v_json ->> 'pr_name')::text;

	if v_pr_name is null then 
		raise exception 'Не указано наименование товара';
	end if;

	v_cnt_pr = (v_json ->> 'cnt_pr')::text;

	if v_cnt_pr is null then 
		raise exception 'Не указано количество товара';
	end if;

	v_price = (v_json ->> 'price')::text;

	if v_price is null then 
		raise exception 'Не указана цена товара';
	end if;

	v_pr_num := gen_random_uuid()::text;

	insert into mpcore.products(us_id, cat_id, pr_num, pr_name, cnt_pr, price)
	values(v_us_id, v_cat_id, v_pr_num, v_pr_name, v_cnt_pr, v_price);

	raise notice 'Товар "%" добавлен', v_pr_name;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.product_create(varchar) owner to role_mp;
