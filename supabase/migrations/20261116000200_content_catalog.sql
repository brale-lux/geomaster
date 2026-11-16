-- GeoMaster 0200: subject categories, topics, countries, content versions.

create table if not exists public.subject_categories (
  slug            text primary key check (slug ~ '^[a-z][a-z0-9_]{2,40}$'),
  display_name    text not null unique,
  description     text not null,
  sort_order      smallint not null unique check (sort_order between 1 and 99),
  -- Key used in design_tokens.json where it differs from the slug (e.g. politics_world).
  style_token_key text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

create table if not exists public.subject_subcategories (
  id             uuid primary key default gen_random_uuid(),
  category_slug  text not null references public.subject_categories (slug) on update cascade,
  slug           text not null check (slug ~ '^[a-z0-9_]{1,60}$'),
  display_name   text not null,
  sort_order     smallint not null default 100,
  created_at     timestamptz not null default now(),
  unique (category_slug, slug)
);

create table if not exists public.question_topics (
  id            uuid primary key default gen_random_uuid(),
  topic_kind    text not null check (topic_kind in
                  ('topic', 'region', 'era', 'person', 'space_object', 'country', 'secondary_category')),
  slug          text not null check (slug ~ '^[a-z0-9_]{1,80}$'),
  display_name  text not null,
  unique (topic_kind, slug)
);

-- v1.3 A3: the 195-country allowlist is versioned data (193 UN members + Holy See + State of Palestine).
create table if not exists public.country_catalog_versions (
  id              uuid primary key default gen_random_uuid(),
  version_key     text not null unique,
  definition      text not null,
  source_filename text not null,
  source_sha256   text not null check (source_sha256 ~ '^[0-9a-f]{64}$'),
  country_count   smallint not null check (country_count = 195),
  provenance_note text not null,
  imported_at     timestamptz not null default now()
);

create table if not exists public.country_catalog (
  iso2            char(2) primary key check (iso2 ~ '^[A-Z]{2}$'),
  iso3            char(3) not null unique check (iso3 ~ '^[A-Z]{3}$'),
  -- Display label only; may change without changing the ISO key.
  name            text not null unique,
  un_status       text not null check (un_status in ('un_member', 'un_observer')),
  catalog_version_id uuid not null references public.country_catalog_versions (id),
  capital         text,
  region          text,
  subregion       text,
  -- Counts toward "Master the World - X/195". Territories/dependencies are never in this table.
  counts_toward_195 boolean not null default true,
  flag_asset_path text,
  -- 'mockup' = simplified design-canvas flag; replace with an official/public-domain set before release.
  flag_asset_status text not null default 'missing' check (flag_asset_status in ('missing', 'mockup', 'official')),
  -- Map shapes are placeholders until licensed boundary data (e.g. Natural Earth) is imported.
  map_shape_status text not null default 'missing'
                     check (map_shape_status in ('missing', 'placeholder', 'licensed')),
  created_at      timestamptz not null default now()
);

-- The mastery denominator can never exceed 195.
create or replace function public.tg_country_catalog_max_195()
returns trigger language plpgsql as $$
begin
  if (select count(*) from public.country_catalog where counts_toward_195) > 195 then
    raise exception 'country_catalog would exceed 195 counted countries';
  end if;
  return null;
end $$;
drop trigger if exists country_catalog_max_195 on public.country_catalog;
create constraint trigger country_catalog_max_195 after insert or update on public.country_catalog
  deferrable initially deferred for each row execute function public.tg_country_catalog_max_195();

create table if not exists public.content_versions (
  id              uuid primary key default gen_random_uuid(),
  version_key     text not null unique check (version_key ~ '^[A-Za-z0-9._-]{1,80}$'),
  schema_version  text,
  status          text not null,
  question_count  integer not null check (question_count >= 0),
  source_filename text,
  source_sha256   text not null check (source_sha256 ~ '^[0-9a-f]{64}$'),
  package_sha256  text check (package_sha256 ~ '^[0-9a-f]{64}$'),
  archive_path    text,
  metrics         jsonb not null default '{}'::jsonb,
  imported_at     timestamptz not null default now()
);

create table if not exists public.country_facts (
  id               uuid primary key default gen_random_uuid(),
  country_iso2     char(2) not null references public.country_catalog (iso2) on update cascade,
  fact_key         text not null check (fact_key ~ '^[a-z0-9_]{1,60}$'),
  value_text       text,
  value_numeric    numeric,
  unit             text,
  reference_year   smallint check (reference_year between 1000 and 2100),
  source_citation  text,
  editorial_status text not null default 'draft_unverified'
                     check (editorial_status in ('draft_unverified', 'needs_review', 'approved', 'rejected', 'retired')),
  content_version_id uuid references public.content_versions (id),
  check (value_text is not null or value_numeric is not null),
  unique nulls not distinct (country_iso2, fact_key, reference_year)
);
