#!/usr/bin/env bash
set -euo pipefail

DURATION="${1:-60}"   # секунды ожидания
PSQL_URL="${PSQL_URL:-postgresql://postgres:postgres@localhost:6432/shop}"

echo "Load for ${DURATION}s against ${PSQL_URL}"

end=$(( $(date +%s) + DURATION ))
i=0
while [ "$(date +%s)" -lt "$end" ]; do
  i=$((i+1))
  psql "$PSQL_URL" -q -c "
    with c as (
      insert into customers(email)
      values ('load' || '$i' || '-' || (random() * 1000000)::int || '@example.com')
      on conflict do nothing
      returning id
    )
    insert into orders(customer_id, amount, status, payload)
    select coalesce((select id from c), (random() * 999 + 1)::bigint),
           (random() * 1000)::numeric(12,2),
           (array['new', 'paid', 'shipped', 'cancelled'])[floor(random() * 4) + 1],
           jsonb_build_object('load', '$i');
  " >/dev/null

  # обновление статусов (создаёт bloat, тренирует autovacuum)
  psql "$PSQL_URL" -q -c "
    update orders set status = 'paid'
    where id in (select id from orders where status = 'new' order by random() limit 50);
  " >/dev/null

  # аналитический запрос (нагрузка на планировщик и индексы)
  psql "$PSQL_URL" -q -c "
    select status, count(*), sum(amount)
    from orders
    where created_at > now() - interval '1 day'
    group by status;
  " >/dev/null
done

echo "Done: ${i} iterations"