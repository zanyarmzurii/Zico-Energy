-- ZICO v6 backend schema (Supabase/Postgres)
create extension if not exists pgcrypto;
create table if not exists zico_demand (id text primary key, country text, city text not null, flavor text, qty integer, created_at timestamptz default now());
create table if not exists zico_distributors (id text primary key, name text not null, phone text not null, city text not null, business text, capacity text, status text default 'pending', created_at timestamptz default now());
create table if not exists zico_reviews (id text primary key, flavor text, stars integer check(stars between 1 and 5), text text not null, status text default 'pending', created_at timestamptz default now());
create table if not exists zico_club_events (id uuid primary key default gen_random_uuid(), type text not null, code text, created_at timestamptz default now());
create index if not exists zico_demand_city_idx on zico_demand(city);
create index if not exists zico_reviews_status_idx on zico_reviews(status);

create table if not exists zico_orders (id text primary key, region text not null, currency text not null, customer jsonb not null, items jsonb not null, total numeric not null default 0, created_at timestamptz default now());
create index if not exists zico_orders_region_idx on zico_orders(region);
