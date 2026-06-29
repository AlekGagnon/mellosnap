-- Stripe fields on orders (amount = total charged, taxes stored separately)

alter table public.orders
  add column if not exists taxes numeric,
  add column if not exists stripe_payment_intent_id text;

create index if not exists orders_stripe_payment_intent_id_idx
  on public.orders (stripe_payment_intent_id)
  where stripe_payment_intent_id is not null;
