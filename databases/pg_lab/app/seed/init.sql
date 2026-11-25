select 'create database shop'
where not exists (select from pg_database where datname = 'shop')\gexec

\c shop

create extension if not exists pg_stat_statements;

create table if not exists customers 
(
    id          bigserial primary key,
    email       text not null unique,
    created_at  timestamptz not null default now()
);

create table if not exists orders (
    id           bigserial primary key,
    customer_id  bigint not null references customers(id),
    amount       numeric(12,2) not null,
    status       text not null default 'new',
    created_at   timestamptz not null default now(),
    payload      jsonb not null default '{}'::jsonb
);

create index if not exists orders_customer_id_idx on orders(customer_id);
create index if not exists orders_created_at_idx  on orders(created_at);
create index if not exists orders_status_idx      on orders(status);


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