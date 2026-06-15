drop table if exists public.crm_data;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  first_name text not null,
  last_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.companies (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
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

alter table public.profiles enable row level security;
alter table public.companies enable row level security;
alter table public.contacts enable row level security;
alter table public."followUps" enable row level security;
alter table public.products enable row level security;
alter table public.sales enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

do $$
declare table_name text;
begin
  foreach table_name in array array['companies', 'contacts', 'followUps', 'products', 'sales'] loop
    execute format('drop policy if exists "Users can read own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can read own %1$s" on public.%2$I for select to authenticated using (auth.uid() = user_id)', table_name, table_name);
    execute format('drop policy if exists "Users can insert own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can insert own %1$s" on public.%2$I for insert to authenticated with check (auth.uid() = user_id)', table_name, table_name);
    execute format('drop policy if exists "Users can update own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can update own %1$s" on public.%2$I for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)', table_name, table_name);
    execute format('drop policy if exists "Users can delete own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can delete own %1$s" on public.%2$I for delete to authenticated using (auth.uid() = user_id)', table_name, table_name);
  end loop;
end $$;

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
