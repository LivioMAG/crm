-- Supabase-Schema ohne Row Level Security (RLS).
-- Für Setups, in denen die App ohne Supabase-RLS-Policies betrieben wird.
-- Dieses Skript ist nicht destruktiv: Es löscht keine Tabellen.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  first_name text not null,
  last_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


create table if not exists public.crms (
  id text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  "createdAt" text,
  "updatedAt" text
);

create table if not exists public.crm_members (
  id text primary key,
  crm_id text not null references public.crms(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  invited_email text not null,
  role text not null default 'editor',
  "createdAt" text
);

create unique index if not exists crm_members_crm_email_key on public.crm_members (crm_id, lower(invited_email));

create table if not exists public.companies (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crm_id text references public.crms(id) on delete cascade,
  name text not null,
  website text,
  industry text,
  status text,
  notes text,
  "createdAt" text,
  "updatedAt" text
);

create table if not exists public.contacts (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crm_id text references public.crms(id) on delete cascade,
  "companyId" text references public.companies(id) on delete cascade,
  role text,
  "firstName" text not null,
  "lastName" text not null,
  email text,
  phone text,
  notes text,
  "createdAt" text,
  "updatedAt" text
);

create table if not exists public."followUps" (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crm_id text references public.crms(id) on delete cascade,
  "companyId" text references public.companies(id) on delete cascade,
  "contactId" text references public.contacts(id) on delete set null,
  title text,
  type text,
  priority text,
  "dueDate" text,
  status text,
  description text,
  "completedAt" text,
  "createdAt" text,
  "updatedAt" text
);

create table if not exists public.products (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crm_id text references public.crms(id) on delete cascade,
  name text not null,
  description text,
  price numeric not null default 0,
  category text,
  status text,
  "createdAt" text,
  "updatedAt" text
);

create table if not exists public.sales (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  crm_id text references public.crms(id) on delete cascade,
  "contactId" text references public.contacts(id) on delete cascade,
  "companyId" text references public.companies(id) on delete cascade,
  "productId" text references public.products(id) on delete set null,
  quantity numeric not null default 1,
  "unitPrice" numeric not null default 0,
  "totalPrice" numeric not null default 0,
  price numeric not null default 0,
  currency text not null default 'CHF',
  status text,
  "saleDate" text,
  description text,
  notes text,
  "createdAt" text,
  "updatedAt" text
);

alter table public.companies add column if not exists crm_id text references public.crms(id) on delete cascade;
alter table public.contacts add column if not exists crm_id text references public.crms(id) on delete cascade;
alter table public."followUps" add column if not exists crm_id text references public.crms(id) on delete cascade;
alter table public.products add column if not exists crm_id text references public.crms(id) on delete cascade;
alter table public.sales add column if not exists crm_id text references public.crms(id) on delete cascade;

alter table public.profiles disable row level security;
alter table public.crms disable row level security;
alter table public.crm_members disable row level security;
alter table public.companies disable row level security;
alter table public.contacts disable row level security;
alter table public."followUps" disable row level security;
alter table public.products disable row level security;
alter table public.sales disable row level security;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', '')
  )
  on conflict (id) do update set
    email = excluded.email,
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();
