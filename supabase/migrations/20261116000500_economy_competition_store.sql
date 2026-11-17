-- GeoMaster 0500: XP/GeoPoints ledgers, badges, daily challenges, competition, leagues,
-- friendships, cosmetics, purchases, subscriptions. All award tables are append-only ledgers
-- written by server code with idempotency keys.

-- v1.3 A1/A6: versioned game policies. Thresholds and award rules are data, never hardcoded in UI.
create table if not exists public.game_policy_versions (
  id              uuid primary key default gen_random_uuid(),
  policy_key      text not null check (policy_key in
                    ('xp_ranks', 'xp_awards', 'league_scoring', 'country_mastery', 'category_trophies')),
  version         integer not null check (version >= 1),
  is_active       boolean not null default false,
  effective_from  timestamptz not null default now(),
  config          jsonb not null default '{}'::jsonb,
  source          text not null,
  created_at      timestamptz not null default now(),
  unique (policy_key, version)
);
create unique index if not exists game_policy_versions_one_active
  on public.game_policy_versions (policy_key) where is_active;

-- Generic idempotency registry for every permanent award (XP, GeoPoints, LP, trophies).
create table if not exists public.award_idempotency_keys (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  source_event_id  text not null check (char_length(source_event_id) between 8 and 200),
  award_type       text not null,
  created_at       timestamptz not null default now(),
  primary key (user_id, source_event_id, award_type)
);

-- XP never decreases (v1.3 A1): amounts are strictly positive.
create table if not exists public.xp_ledger (
  id                 bigint generated always as identity primary key,
  user_id            uuid not null references public.profiles (id) on delete cascade,
  amount             integer not null check (amount > 0 and amount <= 1000),
  award_type         text not null check (award_type in
                       ('practice_correct', 'practice_incorrect', 'lesson_complete', 'daily_complete',
                        'daily_perfect', 'ranked', 'achievement')),
  source_event_id    text not null check (char_length(source_event_id) between 8 and 200),
  reason             text not null,
  is_verified        boolean not null default true,
  policy_version_id  uuid references public.game_policy_versions (id),
  award_date_utc     date not null default (now() at time zone 'utc')::date,
  created_at         timestamptz not null default now(),
  unique (user_id, source_event_id, award_type)
);
create index if not exists xp_ledger_user_day_idx on public.xp_ledger (user_id, award_date_utc);

create table if not exists public.geopoints_ledger (
  id                 bigint generated always as identity primary key,
  user_id            uuid not null references public.profiles (id) on delete cascade,
  amount             integer not null check (amount <> 0 and abs(amount) <= 1000000),
  award_type         text not null check (award_type in
                       ('reward', 'purchase_iap', 'spend_cosmetic', 'refund', 'adjustment')),
  source_event_id    text not null check (char_length(source_event_id) between 8 and 200),
  reason             text not null,
  created_at         timestamptz not null default now(),
  unique (user_id, source_event_id, award_type)
);
create index if not exists geopoints_ledger_user_idx on public.geopoints_ledger (user_id, created_at desc);

create table if not exists public.badge_definitions (
  slug            text primary key check (slug ~ '^[a-z0-9_]{2,60}$'),
  name            text not null,
  description     text not null,
  category_slug   text references public.subject_categories (slug),
  criteria        jsonb not null default '{}'::jsonb,
  -- Knowledge badges can never be bought.
  is_purchasable  boolean not null default false check (is_purchasable = false),
  created_at      timestamptz not null default now()
);

create table if not exists public.user_badges (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  badge_slug   text not null references public.badge_definitions (slug),
  earned_at    timestamptz not null default now(),
  primary key (user_id, badge_slug)
);

create table if not exists public.daily_challenges (
  id              uuid primary key default gen_random_uuid(),
  challenge_date  date not null unique,
  category_slug   text references public.subject_categories (slug),
  title           text not null,
  opens_at        timestamptz not null,
  closes_at       timestamptz not null,
  check (closes_at > opens_at)
);

create table if not exists public.daily_challenge_questions (
  daily_challenge_id uuid not null references public.daily_challenges (id) on delete cascade,
  question_id        uuid not null references public.questions (id),
  position           smallint not null,
  primary key (daily_challenge_id, question_id),
  unique (daily_challenge_id, position)
);

-- v1.3 A2: six league tiers, weekly UTC seasons, groups of up to 30, snapshot on close.
create table if not exists public.league_tiers (
  slug        text primary key check (slug ~ '^[a-z_]{3,30}$'),
  position    smallint not null unique check (position between 1 and 20),
  name        text not null unique
);

-- v1.2 inventory name kept as a read-only view over the tiers.
create or replace view public.leagues with (security_invoker = true) as
  select slug, name, position as tier from public.league_tiers;

create table if not exists public.league_scoring_rules (
  id                 uuid primary key default gen_random_uuid(),
  policy_version_id  uuid not null references public.game_policy_versions (id),
  rule_key           text not null check (rule_key in
                       ('daily_completion', 'daily_per_correct', 'battle_win', 'battle_draw', 'battle_loss')),
  points             smallint not null check (points >= 0),
  daily_limit        smallint check (daily_limit >= 0),
  unique (policy_version_id, rule_key)
);

create table if not exists public.league_seasons (
  id                 uuid primary key default gen_random_uuid(),
  starts_at          timestamptz not null unique,
  ends_at            timestamptz not null,
  status             text not null default 'scheduled' check (status in ('scheduled', 'active', 'closed')),
  policy_version_id  uuid references public.game_policy_versions (id),
  closed_at          timestamptz,
  -- Monday 00:00 UTC through Sunday 23:59:59 UTC.
  check (extract(isodow from starts_at at time zone 'utc') = 1
         and (starts_at at time zone 'utc')::time = '00:00'),
  check (ends_at = starts_at + interval '7 days' - interval '1 second')
);

create table if not exists public.league_groups (
  id            uuid primary key default gen_random_uuid(),
  season_id     uuid not null references public.league_seasons (id) on delete cascade,
  tier_slug     text not null references public.league_tiers (slug),
  group_number  integer not null check (group_number >= 1),
  capacity      smallint not null default 30 check (capacity between 1 and 30),
  unique (season_id, tier_slug, group_number)
);

create table if not exists public.league_memberships (
  season_id          uuid not null references public.league_seasons (id) on delete cascade,
  user_id            uuid not null references public.profiles (id) on delete cascade,
  group_id           uuid not null references public.league_groups (id),
  tier_slug          text not null references public.league_tiers (slug),
  league_points      integer not null default 0 check (league_points >= 0),
  daily_correct      integer not null default 0 check (daily_correct >= 0),
  -- When the member reached their current LP total (tie-breaker 3).
  lp_reached_at      timestamptz,
  joined_at          timestamptz not null default now(),
  primary key (season_id, user_id)
);
create index if not exists league_memberships_group_rank_idx
  on public.league_memberships (group_id, league_points desc, daily_correct desc, lp_reached_at, user_id);

-- Group capacity of 30 is enforced at write time.
create or replace function public.tg_league_group_capacity()
returns trigger language plpgsql as $$
begin
  if (select count(*) from public.league_memberships where group_id = new.group_id)
     > (select capacity from public.league_groups where id = new.group_id) then
    raise exception 'league group is full';
  end if;
  return null;
end $$;
drop trigger if exists league_group_capacity on public.league_memberships;
create constraint trigger league_group_capacity after insert or update of group_id on public.league_memberships
  deferrable initially deferred for each row execute function public.tg_league_group_capacity();

create table if not exists public.league_season_snapshots (
  season_id          uuid not null references public.league_seasons (id) on delete cascade,
  user_id            uuid not null references public.profiles (id) on delete cascade,
  group_id           uuid not null references public.league_groups (id),
  final_rank         integer not null check (final_rank >= 1),
  league_points      integer not null,
  was_active         boolean not null,
  movement           text not null check (movement in ('promote', 'relegate', 'stay')),
  from_tier          text not null references public.league_tiers (slug),
  to_tier            text not null references public.league_tiers (slug),
  policy_version_id  uuid references public.game_policy_versions (id),
  created_at         timestamptz not null default now(),
  primary key (season_id, user_id)
);

create table if not exists public.competition_attempts (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles (id) on delete cascade,
  mode                text not null check (mode in ('country_battle', 'data_battle', 'daily',
                        'category_challenge', 'map_challenge', 'flags', 'capitals')),
  category_slug       text references public.subject_categories (slug),
  daily_challenge_id  uuid references public.daily_challenges (id),
  league_season_id    uuid references public.league_seasons (id),
  status              text not null default 'in_progress'
                        check (status in ('in_progress', 'submitted', 'scored', 'void')),
  server_nonce        uuid not null default gen_random_uuid() unique,
  started_at          timestamptz not null default now(),
  submitted_at        timestamptz,
  score               integer check (score >= 0),
  check (mode <> 'daily' or daily_challenge_id is not null)
);
-- One daily attempt per user per day (replay protection).
create unique index if not exists competition_attempts_daily_once
  on public.competition_attempts (user_id, daily_challenge_id) where daily_challenge_id is not null;

create table if not exists public.competition_answers (
  attempt_id         uuid not null references public.competition_attempts (id) on delete cascade,
  question_id        uuid not null references public.questions (id),
  selected_position  smallint check (selected_position between 0 and 7),
  is_correct         boolean,
  answered_at        timestamptz not null default now(),
  server_elapsed_ms  integer check (server_elapsed_ms >= 0),
  primary key (attempt_id, question_id)
);

create table if not exists public.friendships (
  requester_id  uuid not null references public.profiles (id) on delete cascade,
  addressee_id  uuid not null references public.profiles (id) on delete cascade,
  status        text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at    timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);
create unique index if not exists friendships_pair_unique
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));

create table if not exists public.cosmetic_catalog (
  slug            text primary key check (slug ~ '^[a-z0-9_]{2,60}$'),
  name            text not null,
  kind            text not null check (kind in ('avatar_frame', 'avatar', 'theme_accent', 'title', 'emblem')),
  price_geopoints integer check (price_geopoints >= 0),
  is_active       boolean not null default true
);

create table if not exists public.user_cosmetics (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  cosmetic_slug  text not null references public.cosmetic_catalog (slug),
  acquired_at    timestamptz not null default now(),
  primary key (user_id, cosmetic_slug)
);

create table if not exists public.store_purchases (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.profiles (id) on delete cascade,
  product_id            text not null,
  platform              text not null check (platform in ('ios', 'android')),
  revenuecat_event_id   text not null unique,
  status                text not null check (status in ('purchased', 'refunded', 'cancelled')),
  received_at           timestamptz not null default now()
);

create table if not exists public.subscriptions (
  user_id               uuid primary key references public.profiles (id) on delete cascade,
  entitlement           text not null default 'premium',
  status                text not null check (status in ('active', 'grace', 'expired', 'cancelled', 'billing_issue')),
  expires_at            timestamptz,
  revenuecat_app_user_id text,
  updated_at            timestamptz not null default now()
);
