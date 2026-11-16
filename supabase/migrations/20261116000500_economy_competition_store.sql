-- GeoMaster 0500: XP/GeoPoints ledgers, badges, daily challenges, competition, leagues,
-- friendships, cosmetics, purchases, subscriptions. All award tables are append-only ledgers
-- written by server code with idempotency keys.

create table if not exists public.xp_ledger (
  id               bigint generated always as identity primary key,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  amount           integer not null check (amount <> 0 and abs(amount) <= 100000),
  reason           text not null,
  source_type      text not null check (source_type in
                     ('learn', 'review', 'daily', 'ranked', 'battle', 'achievement', 'adjustment')),
  source_id        uuid,
  is_verified      boolean not null default false,
  idempotency_key  text not null check (char_length(idempotency_key) between 8 and 200),
  created_at       timestamptz not null default now(),
  unique (user_id, idempotency_key)
);
create index if not exists xp_ledger_user_idx on public.xp_ledger (user_id, created_at desc);

create table if not exists public.geopoints_ledger (
  id               bigint generated always as identity primary key,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  amount           integer not null check (amount <> 0 and abs(amount) <= 1000000),
  reason           text not null,
  source_type      text not null check (source_type in
                     ('reward', 'purchase_iap', 'spend_cosmetic', 'refund', 'adjustment')),
  source_id        uuid,
  idempotency_key  text not null check (char_length(idempotency_key) between 8 and 200),
  created_at       timestamptz not null default now(),
  unique (user_id, idempotency_key)
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

create table if not exists public.leagues (
  slug        text primary key,
  name        text not null unique,
  tier        smallint not null unique check (tier between 1 and 20)
);

create table if not exists public.league_seasons (
  id          uuid primary key default gen_random_uuid(),
  starts_at   timestamptz not null,
  ends_at     timestamptz not null,
  status      text not null default 'scheduled' check (status in ('scheduled', 'active', 'closed')),
  check (ends_at > starts_at),
  unique (starts_at)
);

create table if not exists public.league_memberships (
  season_id    uuid not null references public.league_seasons (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  league_slug  text not null references public.leagues (slug),
  verified_xp  integer not null default 0 check (verified_xp >= 0),
  primary key (season_id, user_id)
);
create index if not exists league_memberships_rank_idx
  on public.league_memberships (season_id, league_slug, verified_xp desc);

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
