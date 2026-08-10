-- ============================================================
--  NVEX tech · Онбординг — схема бази
--  Вставте цей файл цілком у Supabase → SQL Editor → Run
-- ============================================================

-- 1. Профілі співробітників -----------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  role        text not null default 'employee' check (role in ('admin','employee')),
  created_at  timestamptz not null default now()
);

-- 2. Прогрес по розділах --------------------------------------
create table if not exists public.progress (
  user_id     uuid not null references auth.users(id) on delete cascade,
  chapter     int  not null,
  passed      boolean not null default false,
  score       int,
  total       int,
  attempts    int not null default 1,
  updated_at  timestamptz not null default now(),
  primary key (user_id, chapter)
);

-- 3. Профіль створюється автоматично при реєстрації ------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4. Хто адмін (без рекурсії в політиках) ----------------------
create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- 5. Row Level Security ---------------------------------------
alter table public.profiles enable row level security;
alter table public.progress enable row level security;

drop policy if exists "profiles: read own or admin"   on public.profiles;
drop policy if exists "profiles: update own or admin" on public.profiles;
drop policy if exists "progress: read own or admin"   on public.progress;
drop policy if exists "progress: write own"           on public.progress;
drop policy if exists "progress: update own"          on public.progress;

create policy "profiles: read own or admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

create policy "profiles: update own or admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin());

create policy "progress: read own or admin" on public.progress
  for select using (user_id = auth.uid() or public.is_admin());

create policy "progress: write own" on public.progress
  for insert with check (user_id = auth.uid());

create policy "progress: update own" on public.progress
  for update using (user_id = auth.uid());

-- 6. Зведення для адмін-панелі --------------------------------
create or replace view public.admin_overview
with (security_invoker = true) as
select
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.created_at,
  count(pr.chapter) filter (where pr.passed)      as chapters_done,
  max(pr.updated_at)                              as last_active
from public.profiles p
left join public.progress pr on pr.user_id = p.id
group by p.id;

-- ============================================================
--  ПІСЛЯ ЗАПУСКУ:
--  1) Authentication → Providers → Email → вимкнути "Confirm email"
--     (щоб створені вами акаунти працювали одразу, без листів)
--  2) Створіть собі акаунт (Authentication → Users → Add user)
--  3) Зробіть себе адміном, підставивши свою пошту:
--     update public.profiles set role = 'admin' where email = 'ваша@пошта';
-- ============================================================
