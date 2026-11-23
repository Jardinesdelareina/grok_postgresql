insert into customers (email)
select 'user' || g || '@example.com'
from generate_series(1, 1000) g
on conflict do nothing;

insert into orders (customer_id, amount, status, payload)
select
    (random() * 999 + 1)::bigint,
    (random() * 1000)::numeric(12, 2),
    (array['new', 'paid', 'shipped', 'cancelled'])[floor(random() * 4) + 1],
    jsonb_build_object('source', 'seed', 'n', g)
from generate_series(1, 5000) g;