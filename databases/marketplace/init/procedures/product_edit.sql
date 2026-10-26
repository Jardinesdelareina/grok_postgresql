drop procedure if exists mpcore.product_edit;
create or replace procedure mpcore.product_edit(p_json_param in varchar) as
$$
/*
  * Редактирование товара
  * call mpcore.product_edit('{"pr_id": 1, "us_id": 1, "cat_id": 17, "pr_name": "iPhone 16", "cnt_pr": 10, "price": 74000}');
*/
declare
	v_json jsonb;
	v_pr_id bigint;
	v_us_id bigint;
	v_cat_id bigint;
	v_pr_name text;
	v_cnt_pr int;
	v_price numeric;
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_pr_id = v_json ->> 'pr_id';

	if v_pr_id is null then 
		raise exception 'Не указан ID товара';
	end if;

	if not exists (select 1 from mpcore.products where pr_id = v_pr_id and delete_date is null) then
		raise exception 'Товар % не найден', v_us_id;
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

	update mpcore.products 
	set 
		us_id = v_us_id, 
		cat_id = v_cat_id, 
		pr_name = v_pr_name, 
		cnt_pr = v_cnt_pr, 
		price = v_price,
		update_date = current_timestamp,
		updated_by = current_user
	where us_id = v_us_id
		and delete_date is null;

	raise notice 'Товар "%" отредактирован (ID %)', v_pr_name, v_pr_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.product_edit(varchar) owner to role_mp;
