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
                     check (editorial_status in ('draft_unverified', 'in_review', 'approved', 'retired')),
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

create table if not exists public.country_mastery (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  country_iso2     char(2) not null references public.country_catalog (iso2),
  mastery_points   integer not null default 0 check (mastery_points >= 0),
  status           text not null default 'new' check (status in ('new', 'learning', 'familiar', 'mastered')),
  mastered_at      timestamptz,
  updated_at       timestamptz not null default now(),
  primary key (user_id, country_iso2)
);

create table if not exists public.subject_mastery (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  category_slug    text not null references public.subject_categories (slug) on update cascade,
  answered         integer not null default 0 check (answered >= 0),
  correct          integer not null default 0 check (correct >= 0 and correct <= answered),
  mastery_points   integer not null default 0 check (mastery_points >= 0),
  status           text not null default 'new' check (status in ('new', 'learning', 'familiar', 'mastered')),
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
