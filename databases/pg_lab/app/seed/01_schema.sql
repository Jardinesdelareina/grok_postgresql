create extension if not exists pg_stat_statements;

create table if not exists customers 
(
    id bigserial primary key,
    email text not null unique,
    created_at timestamptz not null default now()
);

create table if not exists orders (
    id bigserial primary key,
    customer_id bigint not null references customers(id),
    amount numeric(12, 2) not null,
    status text not null default 'new',
    created_at timestamptz not null default now(),
    payload jsonb not null default '{}'::jsonb
);

create index if not exists orders_customer_id_idx on orders(customer_id);
create index if not exists orders_created_at_idx on orders(created_at);
create index if not exists orders_status_idx on orders(status);