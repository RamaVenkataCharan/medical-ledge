-- MedTrack Initial Database Migration
-- Run this in Supabase SQL Editor or via Supabase CLI

-- Enable required extensions
create extension if not exists "pg_cron" schema cron;
create extension if not exists "uuid-ossp";

-- =============================================
-- SHOPS
-- =============================================
create table if not exists shops (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  address text,
  gst_number text,
  licence_number text,
  licence_valid_from date,
  licence_valid_till date,
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table shops enable row level security;
create policy "owner_shops" on shops
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- =============================================
-- PHARMACISTS
-- =============================================
create table if not exists pharmacists (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  shop_id uuid references shops(id) on delete set null,
  name text not null,
  registration_number text,
  valid_from date,
  valid_till date,
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table pharmacists enable row level security;
create policy "owner_pharmacists" on pharmacists
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- =============================================
-- CUSTOMERS
-- =============================================
create table if not exists customers (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null,
  village text,
  address text,
  notes text,
  is_favorite boolean not null default false,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table customers enable row level security;
create policy "owner_customers" on customers
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Partial unique index: phone unique per owner among non-deleted
create unique index if not exists customers_owner_phone_unique
  on customers (owner_id, phone)
  where deleted_at is null;

-- Indexes
create index if not exists idx_customers_owner_phone on customers (owner_id, phone);
create index if not exists idx_customers_owner_name on customers (owner_id, name);

-- =============================================
-- MEDICINES (optional catalog)
-- =============================================
create table if not exists medicines (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  pack_label text,
  default_rate numeric(10, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table medicines enable row level security;
create policy "owner_medicines" on medicines
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- =============================================
-- PURCHASES
-- =============================================
create table if not exists purchases (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid not null references customers(id) on delete restrict,
  purchased_at timestamptz not null default now(),
  subtotal numeric(12, 2) not null default 0,
  discount_percent numeric(5, 2) not null default 0,
  discount_amount numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  notes text,
  deleted_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table purchases enable row level security;
create policy "owner_purchases" on purchases
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create index if not exists idx_purchases_customer_date
  on purchases (customer_id, purchased_at desc)
  where deleted_at is null;

create index if not exists idx_purchases_owner_date
  on purchases (owner_id, purchased_at desc)
  where deleted_at is null;

-- =============================================
-- PURCHASE ITEMS
-- =============================================
create table if not exists purchase_items (
  id uuid primary key default uuid_generate_v4(),
  purchase_id uuid not null references purchases(id) on delete cascade,
  medicine_name text not null,
  pack_label text,
  qty integer not null default 1,
  rate numeric(10, 2) not null,
  amount numeric(12, 2) not null,
  created_at timestamptz not null default now()
);

-- No RLS needed — accessed only through purchases (owner_id check there)
-- But add for defense in depth
alter table purchase_items enable row level security;
create policy "owner_purchase_items" on purchase_items
  using (
    exists (
      select 1 from purchases p
      where p.id = purchase_items.purchase_id
        and p.owner_id = auth.uid()
    )
  );

create index if not exists idx_purchase_items_medicine
  on purchase_items (medicine_name);

create index if not exists idx_purchase_items_purchase_id
  on purchase_items (purchase_id);

-- =============================================
-- PAYMENTS
-- =============================================
create table if not exists payments (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid not null references customers(id) on delete restrict,
  purchase_id uuid references purchases(id) on delete set null,
  amount numeric(12, 2) not null,
  method text not null check (method in ('cash', 'upi', 'card', 'other')),
  paid_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table payments enable row level security;
create policy "owner_payments" on payments
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create index if not exists idx_payments_customer_date
  on payments (customer_id, paid_at desc);

create index if not exists idx_payments_owner_date
  on payments (owner_id, paid_at desc);

-- =============================================
-- REMINDERS
-- =============================================
create table if not exists reminders (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in (
    'shop_licence', 'pharmacist_licence', 'medicine_expiry',
    'stock_review', 'backup', 'followup', 'custom'
  )),
  title text not null,
  remind_at timestamptz,
  repeat text,
  lead_days integer default 30,
  enabled boolean not null default true,
  status text not null default 'upcoming' check (status in ('upcoming', 'done', 'dismissed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table reminders enable row level security;
create policy "owner_reminders" on reminders
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- =============================================
-- ACTIVITY LOG
-- =============================================
create table if not exists activity_log (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  type text not null, -- purchase_added | payment_received | customer_added | customer_restored | customer_deleted
  ref_id uuid,
  meta jsonb,
  created_at timestamptz not null default now()
);

alter table activity_log enable row level security;
create policy "owner_activity" on activity_log
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create index if not exists idx_activity_owner_date
  on activity_log (owner_id, created_at desc);

-- =============================================
-- CUSTOMER BALANCES VIEW
-- Due = sum(purchases.total) - sum(payments.amount) per customer
-- Never stored — always computed
-- =============================================
create or replace view customer_balances as
select
  c.id,
  c.owner_id,
  c.name,
  c.phone,
  c.village,
  c.is_favorite,
  c.deleted_at,
  coalesce(p.total_purchased, 0) as total_purchased_rupees,
  coalesce(py.total_paid, 0) as total_paid_rupees,
  coalesce(p.total_purchased, 0) - coalesce(py.total_paid, 0) as due_rupees,
  coalesce(p.purchase_count, 0) as purchase_count,
  p.last_purchase_at,
  c.created_at,
  c.updated_at
from customers c
left join (
  select
    customer_id,
    sum(total) as total_purchased,
    count(*) as purchase_count,
    max(purchased_at) as last_purchase_at
  from purchases
  where deleted_at is null
  group by customer_id
) p on p.customer_id = c.id
left join (
  select
    customer_id,
    sum(amount) as total_paid
  from payments
  group by customer_id
) py on py.customer_id = c.id;

-- =============================================
-- CREATE PURCHASE RPC (atomic purchase + optional payment)
-- =============================================
create or replace function create_purchase(
  p_owner_id uuid,
  p_customer_id uuid,
  p_items jsonb,           -- [{medicine_name, pack_label, qty, rate_rupees, amount_rupees}]
  p_discount_percent numeric,
  p_paid_amount numeric,   -- 0 means no payment now
  p_payment_method text,
  p_notes text,
  p_purchased_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_purchase_id uuid;
  v_subtotal numeric := 0;
  v_discount_amount numeric;
  v_total numeric;
  v_item jsonb;
begin
  -- Verify ownership
  if p_owner_id != auth.uid() then
    raise exception 'Unauthorized';
  end if;

  -- Compute subtotal from items
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_subtotal := v_subtotal + (v_item->>'amount_rupees')::numeric;
  end loop;

  -- Discount rounded to nearest rupee
  v_discount_amount := round(v_subtotal * p_discount_percent / 100);
  v_total := v_subtotal - v_discount_amount;

  -- Insert purchase
  insert into purchases (
    owner_id, customer_id, purchased_at,
    subtotal, discount_percent, discount_amount, total, notes
  ) values (
    p_owner_id, p_customer_id, p_purchased_at,
    v_subtotal, p_discount_percent, v_discount_amount, v_total, p_notes
  ) returning id into v_purchase_id;

  -- Insert items
  for v_item in select * from jsonb_array_elements(p_items) loop
    insert into purchase_items (
      purchase_id, medicine_name, pack_label, qty, rate, amount
    ) values (
      v_purchase_id,
      v_item->>'medicine_name',
      v_item->>'pack_label',
      (v_item->>'qty')::integer,
      (v_item->>'rate_rupees')::numeric,
      (v_item->>'amount_rupees')::numeric
    );
  end loop;

  -- Optional payment
  if p_paid_amount > 0 and p_payment_method is not null then
    insert into payments (
      owner_id, customer_id, purchase_id, amount, method, paid_at
    ) values (
      p_owner_id, p_customer_id, v_purchase_id,
      p_paid_amount, p_payment_method, p_purchased_at
    );
  end if;

  -- Log activity
  insert into activity_log (owner_id, type, ref_id, meta)
  values (
    p_owner_id, 'purchase_added', v_purchase_id,
    jsonb_build_object('customer_id', p_customer_id, 'total', v_total)
  );

  return v_purchase_id;
end;
$$;

-- =============================================
-- UPDATED_AT TRIGGER
-- =============================================
create or replace function update_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Apply to all tables with updated_at
do $$
declare
  tbl text;
begin
  foreach tbl in array array['shops', 'pharmacists', 'customers', 'medicines', 'purchases', 'payments', 'reminders'] loop
    execute format(
      'create trigger trg_%s_updated_at before update on %s for each row execute function update_updated_at()',
      tbl, tbl
    );
  end loop;
end;
$$;

-- =============================================
-- PG_CRON: Purge deleted customers after 30 days
-- =============================================
-- Run daily at 2:00 AM UTC
select cron.schedule(
  'medtrack_purge_deleted_customers',
  '0 2 * * *',
  $$
    delete from customers
    where deleted_at is not null
      and deleted_at < now() - interval '30 days';
  $$
);
