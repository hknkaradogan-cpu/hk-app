-- ============================================================
-- 002_rls.sql  –  Row Level Security policies
-- ============================================================

-- Enable RLS
alter table public.users      enable row level security;
alter table public.tasks      enable row level security;
alter table public.audit_logs enable row level security;

-- Helper: current user's row in public.users
create or replace function public.current_user_role()
returns text language sql security definer stable as $$
  select role from public.users where id = auth.uid()
$$;

-- ── users policies ───────────────────────────────────────────
-- Supervisors can read/write all users
create policy "supervisor full access on users"
  on public.users for all
  using (public.current_user_role() = 'supervisor')
  with check (public.current_user_role() = 'supervisor');

-- Everyone can read their own row
create policy "user reads own row"
  on public.users for select
  using (id = auth.uid());

-- ── tasks policies ───────────────────────────────────────────
-- Supervisors see/modify all tasks
create policy "supervisor full access on tasks"
  on public.tasks for all
  using (public.current_user_role() = 'supervisor')
  with check (public.current_user_role() = 'supervisor');

-- Maid sees only tasks assigned to herself
create policy "maid sees own tasks"
  on public.tasks for select
  using (
    public.current_user_role() = 'maid'
    and assigned_to = auth.uid()
  );

-- Maid can update status/note on own tasks
create policy "maid updates own tasks"
  on public.tasks for update
  using (
    public.current_user_role() = 'maid'
    and assigned_to = auth.uid()
  )
  with check (
    public.current_user_role() = 'maid'
    and assigned_to = auth.uid()
  );

-- ── audit_logs policies ──────────────────────────────────────
-- Supervisors see all logs
create policy "supervisor full access on audit_logs"
  on public.audit_logs for all
  using (public.current_user_role() = 'supervisor')
  with check (public.current_user_role() = 'supervisor');

-- Maid can insert audit logs and read own
create policy "maid inserts audit logs"
  on public.audit_logs for insert
  with check (by_user_id = auth.uid());

create policy "maid reads own audit logs"
  on public.audit_logs for select
  using (by_user_id = auth.uid());

-- ── Realtime ─────────────────────────────────────────────────
-- Enable realtime for tasks so maids get live updates
alter publication supabase_realtime add table public.tasks;
