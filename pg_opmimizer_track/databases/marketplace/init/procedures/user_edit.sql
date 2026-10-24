drop procedure if exists mpcore.user_edit;
create or replace procedure mpcore.user_edit(p_json_param in varchar) as
$$
/*
  * Редактирование пользователя
  * call mpcore.user_edit('{"us_id": 1, "first_name": "Андрей", "last_name": "Костюк", "phone_number": 89112345611, "cit_code": "C053", "acc_type_code": "1"}');
*/
declare
	v_json jsonb;
	v_us_id bigint;
	v_first_name text;
	v_last_name text;
	v_phone_number text;
	v_cit_code varchar;
	v_acc_type_code varchar;
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_us_id = (v_json ->> 'us_id')::bigint;

	if v_us_id is null then
		raise notice 'Не передан идентификатор пользователя';
	end if;

	v_phone_number = v_json ->> 'phone_number';

	if v_phone_number is null or length(v_phone_number) <> 11 or left(v_phone_number, 1) <> '8' or v_phone_number !~ '^[0-9]+$' then
	    raise exception 'Некорректный phone_number: %', v_phone_number;
	end if;

	if not exists (select 1 from mpcore.users where us_id = v_us_id and delete_date is null) then
		raise exception 'Пользователь % не найден', v_us_id;
	end if;

	v_first_name = (v_json ->> 'first_name')::text;
	v_last_name = (v_json ->> 'last_name')::text;
	v_cit_code = (v_json ->> 'cit_code')::varchar;
	v_acc_type_code = (v_json ->> 'acc_type_code')::varchar;

	update mpcore.users 
	set 
		first_name = v_first_name, 
		last_name = v_last_name, 
		phone_number = v_phone_number, 
		cit_code = v_cit_code, 
		acc_type_code = v_acc_type_code,
		update_date = current_timestamp,
		updated_by = current_user
	where us_id = v_us_id;

	raise notice 'Пользователь % отредактирован', v_us_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.create_user(varchar) owner to role_mp;
