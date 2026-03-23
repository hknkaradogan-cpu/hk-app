-- ============================================================
-- 001_schema.sql  –  Housekeeping App – Supabase Postgres
-- Run this in Supabase SQL Editor
-- ============================================================

-- Extension for UUID
create extension if not exists "pgcrypto";

-- ── users ────────────────────────────────────────────────────
create table if not exists public.users (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  email       text not null unique,
  role        text not null check (role in ('supervisor','maid')),
  active      boolean not null default true,
  fcm_token   text,
  created_at  timestamptz not null default now()
);

-- ── tasks ────────────────────────────────────────────────────
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  date        date not null default current_date,
  room_no     text not null,
  floor       int  not null,
  task_type   text not null check (task_type in ('checkout','stayover','arrival')),
  status      text not null default 'BEKLIYOR'
                check (status in ('BEKLIYOR','YAPILDI','DND','RED')),
  assigned_to uuid references public.users(id),
  note        text,
  updated_at  timestamptz not null default now()
);

-- auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tasks_updated_at on public.tasks;
create trigger tasks_updated_at
  before update on public.tasks
  for each row execute procedure public.set_updated_at();

-- ── audit_logs ───────────────────────────────────────────────
create table if not exists public.audit_logs (
  id          uuid primary key default gen_random_uuid(),
  task_id     uuid references public.tasks(id) on delete set null,
  action      text not null,
  by_user_id  uuid references public.users(id),
  note        text,
  created_at  timestamptz not null default now()
);

-- ── Storage bucket for CSV uploads (optional) ────────────────
insert into storage.buckets (id, name, public)
values ('csv-imports','csv-imports', false)
on conflict do nothing;
