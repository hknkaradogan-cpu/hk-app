-- ============================================================
-- 003_test_data.sql  –  Seed: 1 supervisor, 3 maids, 10 rooms
-- Run AFTER creating Auth users via Supabase dashboard or API.
-- Replace the UUIDs below with real Auth user IDs.
-- ============================================================

-- ── Auth users must be created first via Supabase Auth ───────
-- supervisor@hotel.com  / Test1234!
-- maid1@hotel.com       / Test1234!
-- maid2@hotel.com       / Test1234!
-- maid3@hotel.com       / Test1234!

-- ── Insert into public.users ─────────────────────────────────
-- Replace UUIDs with actual auth.users.id values
insert into public.users (id, name, email, role) values
  ('00000000-0000-0000-0000-000000000001', 'Ali Yılmaz',   'supervisor@hotel.com', 'supervisor'),
  ('00000000-0000-0000-0000-000000000002', 'Fatma Kaya',   'maid1@hotel.com',      'maid'),
  ('00000000-0000-0000-0000-000000000003', 'Zeynep Demir', 'maid2@hotel.com',      'maid'),
  ('00000000-0000-0000-0000-000000000004', 'Ayşe Çelik',   'maid3@hotel.com',      'maid')
on conflict (id) do nothing;

-- ── Insert 10 tasks for today ─────────────────────────────────
insert into public.tasks (room_no, floor, task_type, status, assigned_to, date) values
  ('101', 1, 'checkout',  'BEKLIYOR', '00000000-0000-0000-0000-000000000002', current_date),
  ('102', 1, 'stayover',  'BEKLIYOR', '00000000-0000-0000-0000-000000000002', current_date),
  ('103', 1, 'arrival',   'BEKLIYOR', '00000000-0000-0000-0000-000000000002', current_date),
  ('104', 1, 'stayover',  'BEKLIYOR', '00000000-0000-0000-0000-000000000003', current_date),
  ('201', 2, 'checkout',  'BEKLIYOR', '00000000-0000-0000-0000-000000000003', current_date),
  ('202', 2, 'arrival',   'BEKLIYOR', '00000000-0000-0000-0000-000000000003', current_date),
  ('203', 2, 'stayover',  'BEKLIYOR', '00000000-0000-0000-0000-000000000004', current_date),
  ('301', 3, 'checkout',  'BEKLIYOR', '00000000-0000-0000-0000-000000000004', current_date),
  ('302', 3, 'stayover',  'BEKLIYOR', '00000000-0000-0000-0000-000000000004', current_date),
  ('303', 3, 'arrival',   'BEKLIYOR', null,                                   current_date);
