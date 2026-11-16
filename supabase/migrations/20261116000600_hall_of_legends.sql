-- GeoMaster 0600: ranks, historical people, character roles, guide assignments, trophies,
-- mentor dialogue and character art. One person row can hold several roles
-- (Ibn Battuta: Traveler rank legend + Explorers category guide).

create table if not exists public.rank_definitions (
  slug             text primary key check (slug ~ '^[a-z_]{3,40}$'),
  position         smallint not null unique check (position between 1 and 9),
  display_name     text not null unique,
  -- Thresholds are configurable data; v1.1 values were unavailable at import time.
  min_verified_xp  bigint not null unique check (min_verified_xp >= 0)
);

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'profiles_rank_slug_fkey') then
    alter table public.profiles
      add constraint profiles_rank_slug_fkey foreign key (rank_slug)
      references public.rank_definitions (slug) on update cascade deferrable initially deferred;
  end if;
end $$;

create table if not exists public.historical_people (
  id                    uuid primary key default gen_random_uuid(),
  slug                  text not null unique check (slug ~ '^[a-z0-9_]{2,60}$'),
  display_name          text not null unique,
  lifespan_label        text not null,
  era_label             text not null,
  historical_region     text not null,
  contribution_summary  text not null,
  biography             text not null,
  biography_status      text not null default 'draft_unverified'
                          check (biography_status in ('draft_unverified', 'in_review', 'approved')),
  source_notes          text not null,
  portrait_disclaimer   text not null default
    'Stylised educational illustration. Not a verified likeness.',
  created_at            timestamptz not null default now()
);

create table if not exists public.character_roles (
  id             uuid primary key default gen_random_uuid(),
  person_id      uuid not null references public.historical_people (id),
  role_type      text not null check (role_type in ('rank_legend', 'category_guide')),
  rank_slug      text references public.rank_definitions (slug) on update cascade,
  category_slug  text references public.subject_categories (slug) on update cascade,
  guide_title    text,
  created_at     timestamptz not null default now(),
  check ((role_type = 'rank_legend' and rank_slug is not null and category_slug is null)
      or (role_type = 'category_guide' and category_slug is not null and rank_slug is null
          and guide_title is not null)),
  unique (person_id, role_type, rank_slug, category_slug)
);
create unique index if not exists character_roles_one_legend_per_rank
  on public.character_roles (rank_slug) where role_type = 'rank_legend';
create unique index if not exists character_roles_one_guide_role_per_category_person
  on public.character_roles (person_id, category_slug) where role_type = 'category_guide';

-- Data-driven: swapping a guide is an update of this row, not a code change.
create table if not exists public.category_guide_assignments (
  category_slug      text primary key references public.subject_categories (slug) on update cascade,
  character_role_id  uuid not null unique references public.character_roles (id),
  assigned_at        timestamptz not null default now()
);

create table if not exists public.trophy_definitions (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique check (slug ~ '^[a-z0-9_]{2,60}$'),
  character_role_id  uuid not null unique references public.character_roles (id),
  name               text not null,
  icon_key           text not null,
  -- Category trophies have bronze/silver/gold tiers; rank trophies are single.
  tiered             boolean not null,
  unlock_rule        jsonb not null,
  is_purchasable     boolean not null default false check (is_purchasable = false)
);

create table if not exists public.user_trophies (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  trophy_id      uuid not null references public.trophy_definitions (id),
  tier           text not null default 'standard' check (tier in ('standard', 'bronze', 'silver', 'gold')),
  unlocked_at    timestamptz not null default now(),
  unlock_source  text not null,
  primary key (user_id, trophy_id, tier)
);

create table if not exists public.mentor_dialogue (
  id                 uuid primary key default gen_random_uuid(),
  character_role_id  uuid not null references public.character_roles (id) on delete cascade,
  context            text not null check (context in ('lesson_intro', 'correct', 'incorrect', 'milestone', 'tip')),
  line_text          text not null check (char_length(line_text) <= 280),
  -- Lines are original educational copy, never presented as real quotes.
  is_historical_quote boolean not null default false check (is_historical_quote = false),
  editorial_status   text not null default 'draft_unverified'
                       check (editorial_status in ('draft_unverified', 'in_review', 'approved', 'retired'))
);

create table if not exists public.character_art_assets (
  id              uuid primary key default gen_random_uuid(),
  person_id       uuid not null references public.historical_people (id),
  character_role_id uuid references public.character_roles (id),
  variant         text not null check (variant in ('bust', 'locked_silhouette', 'trophy', 'thumbnail')),
  storage_path    text,
  bundle_path     text,
  is_placeholder  boolean not null default true,
  license_status  text not null default 'pending_review'
                    check (license_status in ('pending_review', 'original_work_confirmed', 'licensed', 'rejected')),
  attribution     text,
  alt_text        text not null,
  cultural_review_status text not null default 'pending'
                    check (cultural_review_status in ('pending', 'approved', 'changes_requested', 'not_required'))
);
