drop procedure if exists mpcore.product_del;
create or replace procedure mpcore.product_del(p_json_param in varchar) as
$$
/*
  * Удаление товара
  * call mpcore.product_del('{"pr_id": 1}');
*/
declare
	v_json jsonb;
	v_pr_id bigint;
begin
	v_json = p_json_param::jsonb;
	raise notice 'v_json: %', v_json;

	if v_json is null then 
		raise exception 'Нет входных данных';
	end if;

	v_pr_id = (v_json ->> 'pr_id')::bigint;

	if v_pr_id is null then
		raise notice 'Не передан идентификатор товара';
	end if;

	if not exists (select 1 from mpcore.products where pr_id = v_pr_id and delete_date is null) then
		raise exception 'Товар % не найден', v_pr_id;
	end if;

	update mpcore.products
	set 
		delete_date = current_timestamp,
		deleted_by = current_user
	where pr_id = v_pr_id
		and delete_date is null;

	raise notice 'Товар % удален', v_pr_id;

exception
	when others then raise;
end
$$ language plpgsql security definer;

alter procedure mpcore.product_del(varchar) owner to role_mp;
