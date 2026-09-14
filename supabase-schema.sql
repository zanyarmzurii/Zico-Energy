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

-- ============================================================
-- ZICO REWARDS / REFERRAL / LOYALTY v8
-- Supabase Auth is the identity source. Points are ledger-based and
-- all valuable mutations happen in Postgres RPCs, never in the browser.
-- ============================================================
create table if not exists zico_members (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'ZICO Fan',
  referral_code text not null unique,
  points bigint not null default 0 check (points >= 0),
  lifetime_points bigint not null default 0 check (lifetime_points >= 0),
  level text not null default 'starter' check (level in ('starter','fan','pro','elite')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists zico_referrals (
  id uuid primary key default gen_random_uuid(),
  inviter_user_id uuid not null references zico_members(id) on delete cascade,
  referred_user_id uuid not null unique references zico_members(id) on delete cascade,
  referral_code text not null,
  fingerprint_hash text not null,
  status text not null default 'completed' check (status in ('pending','completed','rejected')),
  points_awarded integer not null default 0 check (points_awarded between 0 and 100),
  created_at timestamptz not null default now()
);

create table if not exists zico_points_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references zico_members(id) on delete cascade,
  kind text not null,
  points integer not null,
  description text not null default '',
  reference text,
  created_at timestamptz not null default now()
);

create table if not exists zico_rewards (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  icon text not null default '🎁',
  reward_type text not null default 'physical' check (reward_type in ('gift_card','product','merch','discount','shipping','exclusive','spin')),
  points_cost integer not null check (points_cost > 0),
  inventory integer not null default 0 check (inventory >= 0),
  requires_code boolean not null default false,
  active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists zico_reward_codes (
  id uuid primary key default gen_random_uuid(),
  reward_id uuid not null references zico_rewards(id) on delete cascade,
  code text not null unique,
  status text not null default 'available' check (status in ('available','reserved','used','disabled')),
  redemption_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists zico_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references zico_members(id) on delete cascade,
  reward_id uuid not null references zico_rewards(id),
  points_spent integer not null check (points_spent > 0),
  status text not null default 'pending' check (status in ('pending','fulfilled','cancelled')),
  code text,
  created_at timestamptz not null default now()
);

create table if not exists zico_spin_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references zico_members(id) on delete cascade,
  fingerprint_hash text not null,
  result_key text not null,
  points_delta integer not null default 0,
  reward_id uuid references zico_rewards(id),
  created_at timestamptz not null default now()
);

create index if not exists zico_members_referral_idx on zico_members(referral_code);
create index if not exists zico_ledger_user_idx on zico_points_ledger(user_id, created_at desc);
create index if not exists zico_referrals_inviter_idx on zico_referrals(inviter_user_id, created_at desc);
create index if not exists zico_redemptions_user_idx on zico_redemptions(user_id, created_at desc);
create index if not exists zico_reward_codes_reward_idx on zico_reward_codes(reward_id, status);
create index if not exists zico_spin_user_idx on zico_spin_events(user_id, created_at desc);

alter table zico_members enable row level security;
alter table zico_referrals enable row level security;
alter table zico_points_ledger enable row level security;
alter table zico_rewards enable row level security;
alter table zico_reward_codes enable row level security;
alter table zico_redemptions enable row level security;
alter table zico_spin_events enable row level security;

insert into zico_rewards (slug,name,description,icon,reward_type,points_cost,inventory,requires_code,sort_order) values
('gift-2000','2,000 IQD Gift Card','Digital gift card — limited inventory.','💳','gift_card',12000,0,true,10),
('gift-5000','5,000 IQD Gift Card','Digital gift card — limited inventory.','💳','gift_card',25000,0,true,20),
('gift-10000','10,000 IQD Gift Card','Digital gift card — limited inventory.','💳','gift_card',45000,0,true,30),
('zico-can','ZICO Energy Drink','Redeem one ZICO can.','🥤','product',10000,100,true,40),
('mini-bundle','ZICO Mini Bundle','ZICO mini bundle.','📦','product',25000,50,true,50),
('cap','ZICO Cap','Official ZICO cap.','🧢','merch',35000,25,false,60),
('family-bundle','ZICO Family Bundle','ZICO family bundle.','📦','product',45000,25,true,70),
('mystery-box','ZICO Mystery Box','A surprise ZICO reward.','🎁','exclusive',50000,10,false,80),
('tshirt','ZICO T-Shirt','Official ZICO T-shirt.','👕','merch',60000,20,false,90),
('limited-edition','ZICO Limited Edition','Limited edition ZICO item.','🥤','exclusive',75000,10,false,100),
('discount-10','10% Discount','One-use ZICO discount code.','🎟️','discount',20000,100,true,110)
on conflict (slug) do update set name=excluded.name,description=excluded.description,icon=excluded.icon,reward_type=excluded.reward_type,points_cost=excluded.points_cost,requires_code=excluded.requires_code,sort_order=excluded.sort_order;

create or replace function zico_level_for(p_points bigint) returns text language sql immutable as $$
  select case when p_points >= 100000 then 'elite' when p_points >= 50000 then 'pro' when p_points >= 10000 then 'fan' else 'starter' end;
$$;

create or replace function zico_make_referral_code() returns text language plpgsql as $$
declare c text; begin
  loop c := 'ZICO-' || upper(substr(encode(gen_random_bytes(6),'hex'),1,8)); exit when not exists(select 1 from zico_members where referral_code=c); end loop; return c;
end; $$;

create or replace function zico_ensure_member(p_user_id uuid) returns zico_members language plpgsql security definer set search_path=public as $$
declare m zico_members; u auth.users; begin
  select * into m from zico_members where id=p_user_id; if found then return m; end if;
  select * into u from auth.users where id=p_user_id;
  insert into zico_members(id,display_name,referral_code,verified_at) values(p_user_id,coalesce(nullif(u.raw_user_meta_data->>'display_name',''),'ZICO Fan'),zico_make_referral_code(),case when u.email_confirmed_at is not null or u.phone_confirmed_at is not null then now() end) returning * into m;
  return m;
end; $$;

create or replace function zico_award_points(p_user_id uuid,p_points integer,p_kind text,p_description text default '',p_reference text default null) returns table(new_balance bigint,level text) language plpgsql security definer set search_path=public as $$
declare m zico_members; begin
  if p_points <= 0 or p_points > 100000 then raise exception 'Invalid points'; end if;
  m:=zico_ensure_member(p_user_id);
  update zico_members set points=points+p_points,lifetime_points=lifetime_points+p_points,level=zico_level_for(lifetime_points+p_points),updated_at=now() where id=p_user_id returning * into m;
  insert into zico_points_ledger(user_id,kind,points,description,reference) values(p_user_id,p_kind,p_points,left(p_description,240),left(p_reference,120));
  return query select m.points,m.level;
end; $$;

create or replace function zico_complete_referral(p_referred_user uuid,p_code text,p_fingerprint text) returns table(ok boolean,awarded integer,inviter_code text) language plpgsql security definer set search_path=public as $$
declare inv zico_members; already zico_referrals; begin
  perform zico_ensure_member(p_referred_user);
  select * into already from zico_referrals where referred_user_id=p_referred_user; if found then return query select false,0,already.referral_code; return; end if;
  select * into inv from zico_members where referral_code=upper(p_code) for update;
  if not found then raise exception 'Referral code not found'; end if;
  if inv.id=p_referred_user then raise exception 'Self referral is not allowed'; end if;
  if exists(select 1 from zico_referrals where inviter_user_id=inv.id and fingerprint_hash=p_fingerprint and status='completed') then raise exception 'Referral blocked by anti-fraud check'; end if;
  insert into zico_referrals(inviter_user_id,referred_user_id,referral_code,fingerprint_hash,points_awarded) values(inv.id,p_referred_user,upper(p_code),p_fingerprint,10);
  update zico_members set points=points+10,lifetime_points=lifetime_points+10,level=zico_level_for(lifetime_points+10),updated_at=now() where id=inv.id;
  insert into zico_points_ledger(user_id,kind,points,description,reference) values(inv.id,'referral',10,'Verified friend referral',p_referred_user::text);
  return query select true,10,upper(p_code);
end; $$;

create or replace function zico_daily_checkin(p_user_id uuid,p_fingerprint text) returns table(ok boolean,awarded integer,new_balance bigint) language plpgsql security definer set search_path=public as $$
declare cnt integer; m zico_members; begin
  perform zico_ensure_member(p_user_id);
  select count(*) into cnt from zico_points_ledger where user_id=p_user_id and kind='checkin' and created_at >= date_trunc('week',now());
  if cnt>=7 then select points into m from zico_members where id=p_user_id; return query select false,0,m.points; return; end if;
  if exists(select 1 from zico_points_ledger where user_id=p_user_id and kind='checkin' and created_at::date=current_date) then select points into m from zico_members where id=p_user_id; return query select false,0,m.points; return; end if;
  return query select true,10,new_balance from zico_award_points(p_user_id,10,'checkin','Daily check-in',p_fingerprint);
end; $$;

create or replace function zico_redeem_reward(p_user_id uuid,p_reward_id uuid,p_fingerprint text) returns table(ok boolean,redemption_id uuid,new_balance bigint,code text) language plpgsql security definer set search_path=public as $$
declare m zico_members; r zico_rewards; rd zico_redemptions; rc zico_reward_codes; begin
  m:=zico_ensure_member(p_user_id);
  select * into r from zico_rewards where id=p_reward_id and active=true for update;
  if not found then raise exception 'Reward unavailable'; end if;
  if r.inventory <= 0 then raise exception 'Reward is out of stock'; end if;
  if m.points < r.points_cost then raise exception 'Not enough points'; end if;
  if exists(select 1 from zico_redemptions where user_id=p_user_id and reward_id=r.id and created_at > now()-interval '24 hours' and status <> 'cancelled') then raise exception 'Reward redemption cooldown active'; end if;
  if r.requires_code then select * into rc from zico_reward_codes where reward_id=r.id and status='available' limit 1 for update; if not found then raise exception 'Reward code inventory is empty'; end if; end if;
  update zico_members set points=points-r.points_cost,level=zico_level_for(lifetime_points),updated_at=now() where id=p_user_id returning * into m;
  insert into zico_redemptions(user_id,reward_id,points_spent,status,code) values(p_user_id,r.id,r.points_cost,'pending',case when r.requires_code then rc.code else null end) returning * into rd;
  insert into zico_points_ledger(user_id,kind,points,description,reference) values(p_user_id,'redeem',-r.points_cost,'Redeemed: '||r.name,rd.id::text);
  update zico_rewards set inventory=inventory-1,updated_at=now() where id=r.id;
  if r.requires_code then update zico_reward_codes set status='used',redemption_id=rd.id where id=rc.id; end if;
  return query select true,rd.id,m.points,rd.code;
end; $$;

create or replace function zico_lucky_spin(p_user_id uuid,p_fingerprint text) returns table(ok boolean,result_key text,points_delta integer,new_balance bigint) language plpgsql security definer set search_path=public as $$
declare k text; delta integer; m zico_members; begin
  perform zico_ensure_member(p_user_id);
  if exists(select 1 from zico_spin_events where user_id=p_user_id and created_at::date=current_date) then raise exception 'One spin per day'; end if;
  k := (array['10_off','500_points','free_zico','2000_points','try_again','free_shipping','mystery'])[1+floor(random()*7)::int];
  delta := case k when '500_points' then 500 when '2000_points' then 2000 else 0 end;
  if delta>0 then select points into m from zico_award_points(p_user_id,delta,'spin','Lucky Spin reward',k); else select points into m from zico_members where id=p_user_id; end if;
  insert into zico_spin_events(user_id,fingerprint_hash,result_key,points_delta) values(p_user_id,p_fingerprint,k,delta);
  return query select true,k,delta,m.points;
end; $$;

create or replace view zico_rewards_leaderboard as
select row_number() over(order by count(r.id) desc, m.points desc) as rank,
       left(m.display_name,30) as display_name,count(r.id)::integer as referrals,m.points
from zico_members m left join zico_referrals r on r.inviter_user_id=m.id and r.status='completed' and r.created_at >= date_trunc('week',now())
where m.created_at >= date_trunc('week',now()) - interval '12 weeks'
group by m.id,m.display_name,m.points order by referrals desc,m.points desc limit 50;

-- Purchase points are awarded only when an admin changes an order to completed.
create or replace function zico_award_order_points(p_user_id uuid,p_order_id text,p_total numeric) returns table(awarded integer,new_balance bigint) language plpgsql security definer set search_path=public as $$
declare pts integer; m zico_members; begin
  pts:=floor(greatest(p_total,0)/1000)::integer; if pts<=0 then select points into m from zico_members where id=p_user_id; return query select 0,coalesce(m.points,0); return; end if;
  if exists(select 1 from zico_points_ledger where kind='purchase' and reference=p_order_id) then select points into m from zico_members where id=p_user_id; return query select 0,m.points; return; end if;
  return query select pts,new_balance from zico_award_points(p_user_id,pts,'purchase','ZICO purchase points',p_order_id);
end; $$;

create or replace function zico_cancel_redemption(p_redemption_id uuid) returns table(ok boolean,new_balance bigint) language plpgsql security definer set search_path=public as $$
declare rd zico_redemptions; m zico_members; begin
  select * into rd from zico_redemptions where id=p_redemption_id for update;
  if not found then raise exception 'Redemption not found'; end if;
  if rd.status='cancelled' then select points into m from zico_members where id=rd.user_id; return query select false,m.points; return; end if;
  if rd.status='fulfilled' then raise exception 'Fulfilled redemption cannot be cancelled'; end if;
  update zico_redemptions set status='cancelled' where id=rd.id;
  update zico_members set points=points+rd.points_spent,level=zico_level_for(lifetime_points),updated_at=now() where id=rd.user_id returning * into m;
  insert into zico_points_ledger(user_id,kind,points,description,reference) values(rd.user_id,'refund',rd.points_spent,'Cancelled reward redemption refund',rd.id::text);
  update zico_rewards set inventory=inventory+1,updated_at=now() where id=rd.reward_id;
  if rd.code is not null then update zico_reward_codes set status='available',redemption_id=null where code=rd.code; end if;
  return query select true,m.points;
end; $$;
