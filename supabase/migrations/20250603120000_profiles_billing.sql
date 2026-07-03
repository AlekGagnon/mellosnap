-- Billing address fields on profiles (checkout)

alter table public.profiles
  add column if not exists billing_name text,
  add column if not exists billing_address text,
  add column if not exists billing_city text,
  add column if not exists billing_province text,
  add column if not exists billing_postal_code text,
  add column if not exists billing_same_as_shipping boolean not null default true;
