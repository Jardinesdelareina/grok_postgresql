drop procedure if exists mpcore.user_del;
create or replace procedure mpcore.user_del(p_json_param in varchar) as
$$
/*
  * Удаление пользователя
  * call mpcore.user_del('{"us_id": 1}');
*/
declare
	v_json jsonb;
	v_us_id bigint;
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

	if not exists (select 1 from mpcore.users where us_id = v_us_id) then
		raise exception 'Пользователь % не найден', v_us_id;
	end if;

	update mpcore.users 
	set 
		delete_date = current_date,
		deleted_by = current_user
	where us_id = v_us_id;

	raise notice 'Пользователь % удален', v_us_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.user_del(varchar) owner to role_mp;
