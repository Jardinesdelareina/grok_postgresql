drop procedure if exists mpcore.payment_create;
create or replace procedure mpcore.payment_create(p_json_param in varchar) as
$$
/*
  * Создание позиции заказа
  * call mpcore.payment_create('{"o_id": 1}');
*/
declare
	v_json jsonb;
	v_o_id bigint;
	v_pay_id bigint;

	c_status_code varchar := 'pending';
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_o_id = v_json ->> 'o_id';
	
	if v_o_id is null then 
		raise exception 'Не указан ID заказа';
	end if;

	if exists (select 1 from mpcore.payments where o_id = v_o_id and status_code = c_status_code and delete_date is null) then
		raise exception 'Заказ % уже в обработке', v_o_id;
	end if;
	
	insert into mpcore.payments(o_id, status_code)
	values(v_o_id, c_status_code)
	returning pay_id into v_pay_id;

	raise notice 'Платеж % добавлен', v_pay_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.payment_create(varchar) owner to role_mp;
