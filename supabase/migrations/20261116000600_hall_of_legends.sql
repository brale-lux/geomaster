-- GeoMaster 0600: ranks, historical people, character roles, guide assignments, trophies,
-- mentor dialogue and character art. One person row can hold several roles
-- (Ibn Battuta: Traveler rank legend + Explorers category guide).

create table if not exists public.rank_definitions (
  slug             text primary key check (slug ~ '^[a-z_]{3,40}$'),
  position         smallint not null unique check (position between 1 and 9),
  display_name     text not null unique
);

-- v1.3 A1: cumulative lifetime verified-XP thresholds, versioned with the 'xp_ranks' policy.
create table if not exists public.xp_rank_thresholds (
  policy_version_id  uuid not null references public.game_policy_versions (id),
  rank_slug          text not null references public.rank_definitions (slug) on update cascade,
  min_verified_xp    bigint not null check (min_verified_xp >= 0),
  primary key (policy_version_id, rank_slug),
  unique (policy_version_id, min_verified_xp)
);

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'country_mastery_policy_version_fkey') then
    alter table public.country_mastery add constraint country_mastery_policy_version_fkey
      foreign key (policy_version_id) references public.game_policy_versions (id);
  end if;
end $$;

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
                          check (biography_status in ('draft_unverified', 'needs_review', 'approved')),
  source_notes          text not null,
  -- Owner's cultural-accuracy requirements for how the person is depicted (art direction).
  depiction_brief       text,
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
  -- v1.3 A6: unique (historical_person_id, role_type, role_key).
  role_key       text generated always as (coalesce(rank_slug, category_slug)) stored,
  -- Outfit/visual variant from the style guide (Ibn Battuta: 'legend' vs 'guide').
  visual_variant text not null default 'default',
  created_at     timestamptz not null default now(),
  check ((role_type = 'rank_legend' and rank_slug is not null and category_slug is null)
      or (role_type = 'category_guide' and category_slug is not null and rank_slug is null
          and guide_title is not null)),
  unique (person_id, role_type, role_key)
);
create unique index if not exists character_roles_one_legend_per_rank
  on public.character_roles (rank_slug) where role_type = 'rank_legend';
-- Several guide roles per category are allowed; category_guide_assignments picks the active one.

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
  -- Folder holding bronze.svg / silver.svg / gold.svg (rank trophies show gold.svg).
  art_bundle_dir     text check (art_bundle_dir ~ '^assets/art/trophies/[a-z0-9-]+$'),
  unlock_rule        jsonb not null,
  is_purchasable     boolean not null default false check (is_purchasable = false)
);

-- v1.3 A4: category trophy tier rules, versioned with the 'category_trophies' policy.
create table if not exists public.category_trophy_rules (
  policy_version_id      uuid not null references public.game_policy_versions (id),
  tier                   text not null check (tier in ('bronze', 'silver', 'gold')),
  min_distinct_correct   integer not null check (min_distinct_correct > 0),
  min_subtopics          smallint not null check (min_subtopics > 0),
  min_accuracy           numeric(4, 3) check (min_accuracy between 0 and 1),
  accuracy_window        smallint check (accuracy_window > 0),
  min_distinct_utc_dates smallint check (min_distinct_utc_dates > 0),
  primary key (policy_version_id, tier),
  check ((min_accuracy is null) = (accuracy_window is null))
);

create table if not exists public.user_trophies (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  trophy_id      uuid not null references public.trophy_definitions (id),
  tier           text not null default 'standard' check (tier in ('standard', 'bronze', 'silver', 'gold')),
  unlocked_at    timestamptz not null default now(),
  unlock_source  text not null,
  -- Earned trophies stay earned; the rule version that awarded them is recorded.
  policy_version_id uuid references public.game_policy_versions (id),
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
                       check (editorial_status in ('draft_unverified', 'needs_review', 'approved', 'retired'))
);

create table if not exists public.character_art_assets (
  id              uuid primary key default gen_random_uuid(),
  person_id       uuid not null references public.historical_people (id),
  character_role_id uuid references public.character_roles (id),
  variant         text not null check (variant in ('bust', 'locked_silhouette', 'trophy', 'thumbnail')),
  storage_path    text,
  bundle_path     text check (bundle_path ~ '^assets/art/[a-z0-9/_-]+\.svg$'),
  sha256          text check (sha256 ~ '^[0-9a-f]{64}$'),
  -- true until final art exists; the current flat vector art is interim (same file names will be swapped).
  is_placeholder  boolean not null default true,
  license_status  text not null default 'pending_review'
                    check (license_status in ('pending_review', 'original_work_confirmed', 'licensed',
                                              'ai_generated_assigned', 'rejected')),
  attribution     text,
  provenance      text,
  alt_text        text not null,
  cultural_review_status text not null default 'pending'
                    check (cultural_review_status in ('pending', 'approved', 'changes_requested', 'not_required'))
);
