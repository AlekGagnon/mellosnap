-- MelloSnap: orders, profiles shipping fields, rolls storage policies

-- Profiles (shipping address for Mediaclip orders)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  address text,
  city text,
  province text,
  postal_code text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  roll_id text not null,
  format text not null,
  amount numeric not null,
  status text not null default 'pending',
  mediaclip_order_id text,
  mediaclip_project_id text,
  created_at timestamptz default now()
);

alter table public.orders enable row level security;

drop policy if exists "Users insert own orders" on public.orders;
create policy "Users insert own orders"
  on public.orders for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users read own orders" on public.orders;
create policy "Users read own orders"
  on public.orders for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users update own orders" on public.orders;
create policy "Users update own orders"
  on public.orders for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Storage bucket for roll photos
insert into storage.buckets (id, name, public)
values ('rolls', 'rolls', false)
on conflict (id) do nothing;

drop policy if exists "Users upload own roll photos" on storage.objects;
create policy "Users upload own roll photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'rolls'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users read own roll photos" on storage.objects;
create policy "Users read own roll photos"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'rolls'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users update own roll photos" on storage.objects;
create policy "Users update own roll photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'rolls'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users delete own roll photos" on storage.objects;
create policy "Users delete own roll photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'rolls'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
