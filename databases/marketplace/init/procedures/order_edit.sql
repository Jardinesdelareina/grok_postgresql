drop procedure if exists mpcore.order_edit;
create or replace procedure mpcore.order_edit(p_json_param in varchar) as
$$
/*
  * Редактирование заказа
  * call mpcore.order_edit('{"o_id": 2, "cart_json": [{"pr_num": "6b96c931-6687-45ce-910f-e21fe0acd9f2", "cnt_pr": 2}, {"pr_num": "5cddfefb-85d3-488a-9942-368589eee3dd", "cnt_pr": 3}]}');
*/
declare
	v_json jsonb;
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

	v_o_id = v_json ->> 'o_id';
	
	if v_o_id is null then 
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
	
	update mpcore.orders
	set 
		cart_json = v_cart_json,
		total_amount = v_total_amount,
		update_date = current_timestamp,
		updated_by = current_user
	where o_id = v_o_id
		and delete_date is null;

	raise notice 'Заказ  % на сумму % отредактирован', v_o_id, v_total_amount;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.order_edit(varchar) owner to role_mp;
