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

alter table public.profiles enable row level security;
alter table public.crms enable row level security;
alter table public.crm_members enable row level security;
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


create or replace function public.has_crm_access(target_crm_id text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from public.crm_members m
    where m.crm_id = target_crm_id and lower(m.invited_email) = lower(auth.jwt()->>'email')
  );
$$;

drop policy if exists "Users can read accessible crms" on public.crms;
create policy "Users can read accessible crms" on public.crms for select to authenticated using (
  owner_id = auth.uid() or public.has_crm_access(id)
);
drop policy if exists "Users can create own crms" on public.crms;
create policy "Users can create own crms" on public.crms for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists "Owners can update crms" on public.crms;
create policy "Owners can update crms" on public.crms for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "Owners can delete crms" on public.crms;
create policy "Owners can delete crms" on public.crms for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "Users can read own crm memberships" on public.crm_members;
create policy "Users can read own crm memberships" on public.crm_members for select to authenticated using (
  lower(invited_email) = lower(auth.jwt()->>'email') or exists (select 1 from public.crms c where c.id = crm_members.crm_id and c.owner_id = auth.uid())
);
drop policy if exists "Owners can invite crm members" on public.crm_members;
create policy "Owners can invite crm members" on public.crm_members for insert to authenticated with check (
  exists (select 1 from public.crms c where c.id = crm_members.crm_id and c.owner_id = auth.uid())
);
drop policy if exists "Owners can update crm members" on public.crm_members;
create policy "Owners can update crm members" on public.crm_members for update to authenticated using (
  exists (select 1 from public.crms c where c.id = crm_members.crm_id and c.owner_id = auth.uid())
) with check (
  exists (select 1 from public.crms c where c.id = crm_members.crm_id and c.owner_id = auth.uid())
);
drop policy if exists "Owners can delete crm members" on public.crm_members;
create policy "Owners can delete crm members" on public.crm_members for delete to authenticated using (
  exists (select 1 from public.crms c where c.id = crm_members.crm_id and c.owner_id = auth.uid())
);

do $$
declare table_name text;
begin
  foreach table_name in array array['companies', 'contacts', 'followUps', 'products', 'sales'] loop
    execute format('drop policy if exists "Users can read own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can read own %1$s" on public.%2$I for select to authenticated using (public.has_crm_access(%2$I.crm_id))', table_name, table_name);
    execute format('drop policy if exists "Users can insert own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can insert own %1$s" on public.%2$I for insert to authenticated with check (public.has_crm_access(%2$I.crm_id))', table_name, table_name);
    execute format('drop policy if exists "Users can update own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can update own %1$s" on public.%2$I for update to authenticated using (public.has_crm_access(%2$I.crm_id)) with check (public.has_crm_access(%2$I.crm_id))', table_name, table_name);
    execute format('drop policy if exists "Users can delete own %1$s" on public.%2$I', table_name, table_name);
    execute format('create policy "Users can delete own %1$s" on public.%2$I for delete to authenticated using (public.has_crm_access(%2$I.crm_id))', table_name, table_name);
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
