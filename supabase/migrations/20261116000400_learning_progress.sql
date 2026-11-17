-- GeoMaster 0400: lessons, sessions, answers, mastery (country and subject kept separate), review queue.

create table if not exists public.lessons (
  id               uuid primary key default gen_random_uuid(),
  slug             text not null unique check (slug ~ '^[a-z0-9_-]{2,80}$'),
  category_slug    text not null references public.subject_categories (slug) on update cascade,
  subcategory_id   uuid references public.subject_subcategories (id),
  title            text not null,
  description      text,
  difficulty       smallint not null default 1 check (difficulty between 1 and 5),
  sort_order       integer not null default 100,
  editorial_status text not null default 'draft_unverified'
                     check (editorial_status in ('draft_unverified', 'needs_review', 'approved', 'retired')),
  created_at       timestamptz not null default now()
);

create table if not exists public.lesson_questions (
  lesson_id    uuid not null references public.lessons (id) on delete cascade,
  question_id  uuid not null references public.questions (id),
  position     smallint not null,
  primary key (lesson_id, question_id),
  unique (lesson_id, position)
);

create table if not exists public.user_learning_sessions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  mode           text not null check (mode in ('learn', 'review', 'sandbox', 'map_challenge', 'flags', 'capitals')),
  category_slug  text references public.subject_categories (slug),
  lesson_id      uuid references public.lessons (id),
  started_at     timestamptz not null default now(),
  ended_at       timestamptz,
  -- Client-generated id so offline sessions sync exactly once.
  client_session_id uuid not null,
  unique (user_id, client_session_id)
);

create table if not exists public.user_answers (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  session_id         uuid references public.user_learning_sessions (id) on delete set null,
  question_id        uuid not null references public.questions (id),
  selected_position  smallint not null check (selected_position between 0 and 7),
  is_correct         boolean not null,
  mode               text not null check (mode in ('learn', 'review', 'sandbox')),
  answered_at        timestamptz not null,
  synced_at          timestamptz not null default now(),
  -- XP earned offline is provisional until the server verifies it.
  is_provisional     boolean not null default true,
  client_answer_id   uuid not null,
  unique (user_id, client_answer_id)
);
create index if not exists user_answers_user_question_idx on public.user_answers (user_id, question_id);

-- v1.3 A3: per-country verified score 0-100 from the last 10 country-linked verified answers.
-- X/195 counts only status = 'mastered'; first_mastered_at keeps the lifetime achievement.
create table if not exists public.country_mastery (
  user_id            uuid not null references public.profiles (id) on delete cascade,
  country_iso2       char(2) not null references public.country_catalog (iso2),
  score              smallint not null default 0 check (score between 0 and 100),
  status             text not null default 'not_started'
                       check (status in ('not_started', 'learning', 'mastered', 'review_due')),
  first_mastered_at  timestamptz,
  policy_version_id  uuid,
  updated_at         timestamptz not null default now(),
  primary key (user_id, country_iso2)
);
create index if not exists country_mastery_mastered_idx on public.country_mastery (user_id) where status = 'mastered';

create table if not exists public.user_country_mastery_evidence (
  id               bigint generated always as identity primary key,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  country_iso2     char(2) not null references public.country_catalog (iso2),
  question_id      uuid not null references public.questions (id),
  user_answer_id   uuid not null unique references public.user_answers (id) on delete cascade,
  session_id       uuid references public.user_learning_sessions (id) on delete set null,
  content_type     text not null check (content_type in ('map', 'capital', 'flag', 'fact', 'other')),
  is_correct       boolean not null,
  answered_on_utc  date not null,
  created_at       timestamptz not null default now()
);
create index if not exists ucme_user_country_idx
  on public.user_country_mastery_evidence (user_id, country_iso2, created_at desc);

create table if not exists public.subject_mastery (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  category_slug    text not null references public.subject_categories (slug) on update cascade,
  answered         integer not null default 0 check (answered >= 0),
  correct          integer not null default 0 check (correct >= 0 and correct <= answered),
  mastery_points   integer not null default 0 check (mastery_points >= 0),
  status           text not null default 'not_started'
                     check (status in ('not_started', 'learning', 'practicing', 'mastered')),
  updated_at       timestamptz not null default now(),
  primary key (user_id, category_slug)
);

create table if not exists public.review_schedule (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  question_id    uuid not null references public.questions (id) on delete cascade,
  due_at         timestamptz not null,
  interval_days  numeric(6, 2) not null default 1 check (interval_days > 0),
  ease           numeric(4, 2) not null default 2.5 check (ease between 1.3 and 4.0),
  repetitions    integer not null default 0,
  primary key (user_id, question_id)
);
create index if not exists review_schedule_due_idx on public.review_schedule (user_id, due_at);
