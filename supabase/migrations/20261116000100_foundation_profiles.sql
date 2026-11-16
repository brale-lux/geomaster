-- GeoMaster 0100: foundation, profiles, settings, device tokens.
-- Idempotent: safe to run more than once. Targets Supabase (Postgres 15+).

create schema if not exists extensions;

-- Generic updated_at trigger.
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create table if not exists public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  username            text unique check (username ~ '^[A-Za-z0-9_]{3,24}$'),
  display_name        text check (char_length(display_name) <= 40),
  avatar_cosmetic     text,
  -- 'tester' may play draft content in the sandbox; 'editor' may review; set by admins only.
  app_role            text not null default 'player'
                        check (app_role in ('player', 'tester', 'editor', 'admin')),
  rank_slug           text not null default 'tourist',
  total_verified_xp   bigint not null default 0 check (total_verified_xp >= 0),
  countries_mastered  smallint not null default 0 check (countries_mastered between 0 and 195),
  is_guest            boolean not null default false,
  active_mentor_role  uuid,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

drop trigger if exists set_updated_at on public.profiles;
create trigger set_updated_at before update on public.profiles
  for each row execute function public.tg_set_updated_at();

create table if not exists public.user_settings (
  user_id                 uuid primary key references public.profiles (id) on delete cascade,
  theme                   text not null default 'dark' check (theme in ('dark', 'light', 'system')),
  language                text not null default 'en' check (language ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  reduce_motion           boolean not null default false,
  high_contrast           boolean not null default false,
  text_scale              numeric(3, 2) not null default 1.00 check (text_scale between 0.8 and 2.0),
  analytics_consent       boolean not null default false,
  ads_personalised_consent boolean not null default false,
  push_opt_in             boolean not null default false,
  sound_enabled           boolean not null default true,
  updated_at              timestamptz not null default now()
);

drop trigger if exists set_updated_at on public.user_settings;
create trigger set_updated_at before update on public.user_settings
  for each row execute function public.tg_set_updated_at();

create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  platform    text not null check (platform in ('ios', 'android')),
  token       text not null unique check (char_length(token) between 16 and 4096),
  created_at  timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

-- Role helpers. SECURITY DEFINER so RLS policies can call them without recursion.
create or replace function public.current_app_role()
returns text language sql stable security definer set search_path = public as $$
  select coalesce((select app_role from public.profiles where id = auth.uid()), 'anon')
$$;

create or replace function public.is_content_tester()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_app_role() in ('tester', 'editor', 'admin')
$$;

create or replace function public.is_editor()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_app_role() in ('editor', 'admin')
$$;

-- Create profile + settings when an auth user is created.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, is_guest)
  values (new.id, coalesce((new.raw_user_meta_data ->> 'is_guest')::boolean, false))
  on conflict (id) do nothing;
  insert into public.user_settings (user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
