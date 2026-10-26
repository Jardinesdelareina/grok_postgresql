drop procedure if exists mpcore.order_del;
create or replace procedure mpcore.order_del(p_json_param in varchar) as
$$
/*
  * Удаление заказа
  * call mpcore.order_del('{"o_id": 1}');
*/
declare
	v_json jsonb;
	v_o_id bigint;
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_o_id = (v_json ->> 'o_id')::bigint;

	if v_o_id is null then
		raise notice 'Не передан идентификатор заказа';
	end if;

	if not exists (select 1 from mpcore.orders where o_id = v_o_id and delete_date is null) then
		raise exception 'Заказ % не найден', v_o_id;
	end if;

	update mpcore.orders
	set 
		delete_date = current_timestamp,
		deleted_by = current_user
	where o_id = v_o_id
		and delete_date is null;

	raise notice 'Заказ % удален', v_o_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.order_del(varchar) owner to role_mp;
