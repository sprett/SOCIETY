-- SOCIETY - Event Categories & User Interests
--
-- Run in: Supabase Dashboard -> SQL Editor (after supabase_events.sql)
--
-- Creates:
--   1. event_categories – admin-managed list of categories (icons, colors, ordering)
--   2. profile_interests – many-to-many linking users to their preferred categories

-- ============================================================
-- 1. EVENT CATEGORIES TABLE
-- ============================================================

create table if not exists public.event_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_identifier text not null default 'sparkles',
  accent_color_hex text,
  display_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists event_categories_display_order_idx
  on public.event_categories (display_order);

-- RLS: everyone can read categories
alter table public.event_categories enable row level security;

drop policy if exists "categories read all" on public.event_categories;
create policy "categories read all"
on public.event_categories for select
to anon, authenticated
using (true);

-- ============================================================
-- 2. PROFILE INTERESTS TABLE
-- ============================================================

create table if not exists public.profile_interests (
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid not null references public.event_categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, category_id)
);

create index if not exists profile_interests_user_idx
  on public.profile_interests (user_id);

-- RLS: authenticated users can read/write only their own rows
alter table public.profile_interests enable row level security;

drop policy if exists "interests read own" on public.profile_interests;
create policy "interests read own"
on public.profile_interests for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "interests insert own" on public.profile_interests;
create policy "interests insert own"
on public.profile_interests for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "interests delete own" on public.profile_interests;
create policy "interests delete own"
on public.profile_interests for delete
to authenticated
using (user_id = auth.uid());

-- ============================================================
-- 3. SEED CATEGORIES (15)
-- ============================================================

insert into public.event_categories (name, icon_identifier, accent_color_hex, display_order) values
  ('Music',                   'music.note',           '#E040FB', 1),
  ('Tech',                    'desktopcomputer',      '#FFD600', 2),
  ('Food & Drinks',           'fork.knife',           '#FFB300', 3),
  ('Fitness',                 'figure.run',           '#FF7043', 4),
  ('Nature & Outdoors',       'leaf.fill',            '#66BB6A', 5),
  ('Arts & Culture',          'paintpalette.fill',    '#CE93D8', 6),
  ('Education',               'book.fill',            '#42A5F5', 7),
  ('Personal Growth',         'brain.head.profile',   '#AB47BC', 8),
  ('Climate & Sustainability','leaf.circle.fill',     '#4CAF50', 9),
  ('Social & Community',      'person.3.fill',        '#26C6DA', 10),
  ('Business & Networking',   'briefcase.fill',       '#78909C', 11),
  ('Gaming',                  'gamecontroller.fill',  '#7C4DFF', 12),
  ('Film',                    'film',                 '#FDD835', 13),
  ('Culture',                 'theatermasks.fill',     '#EC407A', 14),
  ('Family & Lifestyle',      'house.fill',           '#FFA726', 15)
on conflict (name) do nothing;

-- ============================================================
-- Reload PostgREST schema cache
-- ============================================================
notify pgrst, 'reload schema';
