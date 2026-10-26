drop procedure if exists mpcore.order_create;
create or replace procedure mpcore.order_create(p_json_param in varchar) as
$$
/*
  * Создание заказа
  * call mpcore.order_create('{"us_id": 1, "cart_json": [{"pr_num": "6b96c931-6687-45ce-910f-e21fe0acd9f2", "cnt_pr": 2}, {"pr_num": "5cddfefb-85d3-488a-9942-368589eee3dd", "cnt_pr": 3}]}');
*/
declare
	v_json jsonb;
	v_us_id bigint;
	v_cart_json text;
	v_total_amount numeric(12, 2);
	v_cnt_pr text;
	v_o_id bigint;

	c_status_code varchar := 'processing';
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_us_id = v_json ->> 'us_id';
	
	if v_us_id is null then 
		raise exception 'Не указан ID пользователя';
	end if;

	v_cart_json = (v_json ->> 'cart_json');
	
	if v_cart_json is null or v_cart_json = '[]' then 
		raise exception 'Не выбрано ни одного товара';
	end if;

	select coalesce(sum(p.price * (item ->> 'cnt_pr')::int), 0)
	into v_total_amount
	from jsonb_array_elements(v_cart_json::jsonb) as item
	join mpcore.products p on p.pr_num::text = (item ->> 'pr_num')::text
	where delete_date is null;
	
	insert into mpcore.orders(us_id, status_code, cart_json, total_amount)
	values(v_us_id, c_status_code, v_cart_json, v_total_amount)
	returning o_id into v_o_id;

	raise notice 'Заказ  % на сумму % добавлен', v_o_id, v_total_amount;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.order_create(varchar) owner to role_mp;
