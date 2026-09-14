-- ZICO Energy v7 production schema for Supabase/Postgres
create extension if not exists pgcrypto;

create table if not exists zico_demand (
  id text primary key,
  country text not null default 'Iraq',
  city text not null,
  flavor text,
  qty integer not null default 1 check (qty between 1 and 100000),
  created_at timestamptz not null default now()
);

create table if not exists zico_distributors (
  id text primary key,
  name text not null,
  phone text not null,
  city text not null,
  business text,
  capacity text,
  status text not null default 'pending' check (status in ('pending','reviewing','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists zico_reviews (
  id text primary key,
  flavor text,
  stars integer not null check (stars between 1 and 5),
  text text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists zico_club_events (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  code text,
  points integer not null default 0 check (points between 0 and 1000),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists zico_orders (
  id text primary key,
  region text not null check (region in ('kurdistan','sweden')),
  currency text not null check (currency in ('IQD','SEK')),
  customer jsonb not null,
  items jsonb not null,
  total numeric(14,2) not null default 0 check (total >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','processing','completed','cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists zico_demand_city_idx on zico_demand(city);
create index if not exists zico_demand_created_idx on zico_demand(created_at desc);
create index if not exists zico_distributors_status_idx on zico_distributors(status);
create index if not exists zico_reviews_status_idx on zico_reviews(status);
create index if not exists zico_orders_region_idx on zico_orders(region);
create index if not exists zico_orders_status_idx on zico_orders(status);
create index if not exists zico_orders_created_idx on zico_orders(created_at desc);
create index if not exists zico_club_code_idx on zico_club_events(code);

-- RLS is enabled. The API uses the service role key server-side; never expose it in browser code.
alter table zico_demand enable row level security;
alter table zico_distributors enable row level security;
alter table zico_reviews enable row level security;
alter table zico_club_events enable row level security;
alter table zico_orders enable row level security;
