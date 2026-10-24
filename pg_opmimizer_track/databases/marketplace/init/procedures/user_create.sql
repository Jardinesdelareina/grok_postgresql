drop procedure if exists mpcore.user_create;
create or replace procedure mpcore.user_create(p_json_param in varchar) as
$$
/*
  * Создание пользователя
  * call mpcore.user_create('{"first_name": "Андрей", "last_name": "Костюк", "phone_number": 89112345678, "cit_code": "C053", "acc_type_code": "1"}');
*/
declare
	v_json jsonb;
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

	v_phone_number = v_json ->> 'phone_number';

	if v_phone_number is null or length(v_phone_number) <> 11 or left(v_phone_number, 1) <> '8' or v_phone_number !~ '^[0-9]+$' then
	    raise exception 'Некорректный phone_number: %', v_phone_number;
	end if;

	if exists (select 1 from mpcore.users where delete_date is null and phone_number = v_phone_number) then
		raise exception 'Пользователь с номером % уже зарегистрирован', v_phone_number;
	end if;

	v_first_name = (v_json ->> 'first_name')::text;
	v_last_name = (v_json ->> 'last_name')::text;
	v_cit_code = (v_json ->> 'cit_code')::varchar;
	v_acc_type_code = (v_json ->> 'acc_type_code')::varchar;

	insert into mpcore.users(first_name, last_name, phone_number, cit_code, acc_type_code)
	values(v_first_name, v_last_name, v_phone_number, v_cit_code, v_acc_type_code);

	raise notice 'Пользователь с номером % добавлен', v_phone_number;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.user_create(varchar) owner to role_mp;
