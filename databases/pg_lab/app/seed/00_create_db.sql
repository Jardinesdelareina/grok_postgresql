select 'create database shop'
where not exists (select from pg_database where datname = 'shop')\gexec

\c shop