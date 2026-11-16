-- GeoMaster 0300: questions, options, answer keys, assets, sources, reviews, revisions.
--
-- Security model for answers:
--   * question_options holds only option text (safe to read).
--   * question_answer_keys holds the correct position and has NO client policies, so
--     anon/authenticated can never select it. Answers reach clients only through
--     SECURITY DEFINER functions that refuse ranked-eligible content.

create table if not exists public.questions (
  id                    uuid primary key default gen_random_uuid(),
  external_id           text not null unique check (external_id ~ '^GM-[0-9]{4}$'),
  content_version_id    uuid not null references public.content_versions (id),
  primary_category_slug text not null references public.subject_categories (slug) on update cascade,
  subcategory_id        uuid references public.subject_subcategories (id),
  question_type         text not null default 'multiple_choice'
                          check (question_type in ('multiple_choice', 'true_false', 'map_pin', 'flag', 'ordering')),
  prompt                text not null check (char_length(prompt) between 10 and 600),
  explanation           text not null check (char_length(explanation) between 10 and 2000),
  difficulty            smallint not null check (difficulty between 1 and 5),
  language              text not null default 'en',
  period_label          text,
  reference_year        smallint check (reference_year between -5000 and 2100),
  region_label          text,
  cohort                text not null default 'other'
                          check (cohort in ('original_500', 'explorers_plus20', 'other')),
  editorial_status      text not null default 'draft_unverified'
                          check (editorial_status in
                            ('draft_unverified', 'needs_review', 'approved', 'rejected', 'quarantined', 'retired')),
  -- Only approved content may ever be used in ranked/daily play.
  ranked_eligible       boolean not null default false,
  qa_flags              jsonb not null default '[]'::jsonb check (jsonb_typeof(qa_flags) = 'array'),
  source_content_hash   text not null check (source_content_hash ~ '^[0-9a-f]{64}$'),
  current_revision      integer not null default 1 check (current_revision >= 1),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  constraint ranked_requires_approval check (not ranked_eligible or editorial_status = 'approved')
);
create index if not exists questions_category_difficulty_idx
  on public.questions (primary_category_slug, difficulty);
create index if not exists questions_status_idx on public.questions (editorial_status);
create index if not exists questions_subcategory_idx on public.questions (subcategory_id);

drop trigger if exists set_updated_at on public.questions;
create trigger set_updated_at before update on public.questions
  for each row execute function public.tg_set_updated_at();

create table if not exists public.question_options (
  id           uuid primary key default gen_random_uuid(),
  question_id  uuid not null references public.questions (id) on delete cascade,
  position     smallint not null check (position between 0 and 7),
  option_text  text not null check (char_length(btrim(option_text)) between 1 and 300),
  unique (question_id, position)
);
create unique index if not exists question_options_unique_text
  on public.question_options (question_id, lower(btrim(option_text)));

create table if not exists public.question_answer_keys (
  question_id       uuid primary key references public.questions (id) on delete cascade,
  correct_position  smallint not null,
  foreign key (question_id, correct_position)
    references public.question_options (question_id, position) deferrable initially deferred
);

create table if not exists public.question_assets (
  id              uuid primary key default gen_random_uuid(),
  storage_bucket  text not null default 'question-assets',
  storage_path    text not null unique check (storage_path !~ '\.\.' and storage_path !~ '^/'),
  bundle_path     text check (bundle_path ~ '^assets/[A-Za-z0-9_./-]+$' and bundle_path !~ '\.\.'),
  mime_type       text not null check (mime_type in ('image/svg+xml', 'image/png', 'image/webp')),
  sha256          text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  byte_size       integer not null check (byte_size between 1 and 5242880),
  width           integer,
  height          integer,
  alt_text        text,
  alt_text_status text not null default 'missing'
                    check (alt_text_status in ('missing', 'auto_from_svg_text', 'human_written', 'reviewed')),
  attribution     text,
  license         text,
  license_status  text not null default 'pending_review'
                    check (license_status in ('pending_review', 'original_work_confirmed', 'licensed',
                                              'public_domain', 'ai_generated_assigned', 'rejected')),
  provenance      text,
  sanitized       boolean not null default false,
  content_version_id uuid references public.content_versions (id),
  created_at      timestamptz not null default now()
);

create table if not exists public.question_asset_links (
  question_id  uuid not null references public.questions (id) on delete cascade,
  asset_id     uuid not null references public.question_assets (id),
  role         text not null default 'prompt' check (role in ('prompt', 'explanation', 'option')),
  position     smallint not null default 0,
  primary key (question_id, asset_id, role)
);
create index if not exists question_asset_links_asset_idx on public.question_asset_links (asset_id);

create table if not exists public.question_topic_links (
  question_id  uuid not null references public.questions (id) on delete cascade,
  topic_id     uuid not null references public.question_topics (id),
  primary key (question_id, topic_id)
);
create index if not exists question_topic_links_topic_idx on public.question_topic_links (topic_id);

create table if not exists public.question_sources (
  id           uuid primary key default gen_random_uuid(),
  question_id  uuid not null references public.questions (id) on delete cascade,
  source_type  text not null check (source_type in ('source_hint', 'citation', 'dataset', 'book', 'web')),
  citation     text not null,
  url          text check (url is null or url ~ '^https://'),
  accessed_on  date,
  -- A source hint from the draft bank is never a verified citation.
  is_verified  boolean not null default false,
  added_by     uuid references public.profiles (id),
  created_at   timestamptz not null default now(),
  check (not (source_type = 'source_hint' and is_verified))
);
create unique index if not exists question_sources_hint_unique
  on public.question_sources (question_id) where source_type = 'source_hint';

create table if not exists public.question_revisions (
  id               uuid primary key default gen_random_uuid(),
  question_id      uuid not null references public.questions (id) on delete cascade,
  revision_number  integer not null check (revision_number >= 1),
  snapshot         jsonb not null,
  change_summary   text not null,
  status           text not null default 'proposed'
                     check (status in ('original_import', 'proposed', 'approved', 'rejected', 'superseded')),
  proposed_by      uuid references public.profiles (id),
  decided_by       uuid references public.profiles (id),
  decided_at       timestamptz,
  evidence         text,
  created_at       timestamptz not null default now(),
  unique (question_id, revision_number),
  check (status <> 'approved' or (evidence is not null and char_length(evidence) >= 10))
);

create table if not exists public.question_reviews (
  id               uuid primary key default gen_random_uuid(),
  question_id      uuid not null references public.questions (id) on delete cascade,
  revision_number  integer not null,
  reviewer_id      uuid references public.profiles (id),
  decision         text not null check (decision in ('approve', 'request_changes', 'reject', 'quarantine', 'retire')),
  evidence         text,
  notes            text,
  created_at       timestamptz not null default now(),
  check (decision <> 'approve' or (evidence is not null and char_length(evidence) >= 10))
);
create index if not exists question_reviews_question_idx on public.question_reviews (question_id);

-- v1.3 A6: append-only audit of every editorial state change.
create table if not exists public.question_editorial_events (
  id               bigint generated always as identity primary key,
  question_id      uuid not null references public.questions (id) on delete cascade,
  revision_number  integer not null,
  from_status      text,
  to_status        text not null,
  actor_id         uuid references public.profiles (id),
  note             text,
  created_at       timestamptz not null default now()
);
create index if not exists question_editorial_events_q_idx on public.question_editorial_events (question_id, created_at);

create or replace function public.tg_question_editorial_event()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.editorial_status is distinct from old.editorial_status then
    insert into question_editorial_events (question_id, revision_number, from_status, to_status, actor_id, note)
    values (new.id, new.current_revision, case when tg_op = 'UPDATE' then old.editorial_status end,
            new.editorial_status, auth.uid(), case when tg_op = 'INSERT' then 'imported' end);
  end if;
  return new;
end $$;
drop trigger if exists question_editorial_event on public.questions;
create trigger question_editorial_event after insert or update of editorial_status on public.questions
  for each row execute function public.tg_question_editorial_event();

create table if not exists public.import_runs (
  id                 uuid primary key default gen_random_uuid(),
  content_version_id uuid not null references public.content_versions (id),
  started_at         timestamptz not null default now(),
  inserted           integer not null,
  unchanged          integer not null,
  conflicts          integer not null,
  result             jsonb not null
);
