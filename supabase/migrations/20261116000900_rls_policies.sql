-- GeoMaster 0900: row-level security. Every public table has RLS enabled.
-- Pattern:
--   * reference/catalog tables: readable by anon + authenticated, writable by service role only;
--   * user-owned tables: users read their own rows; writes go through server functions,
--     except a few self-service tables (settings, device tokens, friendships);
--   * question_answer_keys, import_runs, store_purchases: no client policies at all.
-- service_role bypasses RLS in Supabase.

do $$
declare t text;
begin
  foreach t in array array[
    'profiles', 'user_settings', 'device_tokens', 'subject_categories', 'subject_subcategories',
    'question_topics', 'question_topic_links', 'country_catalog', 'country_facts', 'content_versions',
    'questions', 'question_options', 'question_answer_keys', 'question_assets', 'question_asset_links',
    'question_sources', 'question_reviews', 'question_revisions', 'import_runs',
    'lessons', 'lesson_questions', 'user_learning_sessions', 'user_answers', 'country_mastery',
    'subject_mastery', 'review_schedule', 'xp_ledger', 'geopoints_ledger', 'badge_definitions',
    'user_badges', 'daily_challenges', 'daily_challenge_questions', 'competition_attempts',
    'competition_answers', 'league_tiers', 'league_seasons', 'league_memberships', 'friendships',
    'league_groups', 'league_scoring_rules', 'league_season_snapshots', 'game_policy_versions',
    'award_idempotency_keys', 'xp_rank_thresholds', 'category_trophy_rules', 'country_catalog_versions',
    'user_country_mastery_evidence', 'question_editorial_events',
    'historical_people', 'character_roles', 'rank_definitions', 'category_guide_assignments',
    'trophy_definitions', 'user_trophies', 'mentor_dialogue', 'character_art_assets',
    'cosmetic_catalog', 'user_cosmetics', 'store_purchases', 'subscriptions']
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Helper to (re)create a policy idempotently.
create or replace function pg_temp.policy(p_table text, p_name text, p_cmd text, p_roles text,
                                          p_using text, p_check text default null)
returns void language plpgsql as $$
begin
  execute format('drop policy if exists %I on public.%I', p_name, p_table);
  execute format('create policy %I on public.%I for %s to %s %s %s', p_name, p_table, p_cmd, p_roles,
                 case when p_using is not null then 'using (' || p_using || ')' else '' end,
                 case when p_check is not null then 'with check (' || p_check || ')' else '' end);
end $$;

-- Public catalogs.
select pg_temp.policy(t, 'catalog_read', 'select', 'anon, authenticated', 'true')
from unnest(array['subject_categories', 'subject_subcategories', 'question_topics', 'country_catalog',
                  'rank_definitions', 'historical_people', 'character_roles', 'category_guide_assignments',
                  'trophy_definitions', 'badge_definitions', 'league_tiers', 'league_seasons',
                  'cosmetic_catalog', 'content_versions', 'game_policy_versions', 'xp_rank_thresholds',
                  'category_trophy_rules', 'league_scoring_rules', 'league_groups',
                  'country_catalog_versions']) as t;

select pg_temp.policy('country_facts', 'approved_facts_read', 'select', 'anon, authenticated',
                      'editorial_status = ''approved'' or public.is_editor()');
select pg_temp.policy('mentor_dialogue', 'approved_dialogue_read', 'select', 'anon, authenticated',
                      'editorial_status = ''approved'' or public.is_content_tester()');
select pg_temp.policy('character_art_assets', 'art_read', 'select', 'anon, authenticated', 'true');
select pg_temp.policy('lessons', 'lessons_read', 'select', 'anon, authenticated',
                      'editorial_status = ''approved'' or public.is_content_tester()');
select pg_temp.policy('lesson_questions', 'lesson_questions_read', 'select', 'authenticated',
                      'exists (select 1 from public.lessons l where l.id = lesson_id
                               and (l.editorial_status = ''approved'' or public.is_content_tester()))');

-- Questions: players see approved content only; testers/editors also see drafts.
-- Answer keys are never in these tables.
select pg_temp.policy('questions', 'questions_read', 'select', 'authenticated',
                      'editorial_status = ''approved'' or public.is_content_tester()');
select pg_temp.policy(t, 'question_child_read', 'select', 'authenticated',
                      'exists (select 1 from public.questions q where q.id = question_id
                               and (q.editorial_status = ''approved'' or public.is_content_tester()))')
from unnest(array['question_options', 'question_asset_links', 'question_topic_links',
                  'question_sources']) as t;
select pg_temp.policy('question_assets', 'assets_read', 'select', 'authenticated', 'true');
select pg_temp.policy(t, 'editor_read', 'select', 'authenticated', 'public.is_editor()')
from unnest(array['question_reviews', 'question_revisions', 'question_editorial_events']) as t;

-- Profiles: own row; public leaderboard fields come from a view/function later.
select pg_temp.policy('profiles', 'own_profile_read', 'select', 'authenticated', 'id = auth.uid()');
select pg_temp.policy('profiles', 'own_profile_update', 'update', 'authenticated',
                      'id = auth.uid()', 'id = auth.uid()');
-- Column-level: players may change cosmetic/profile text only, never role, XP or rank.
revoke update on public.profiles from anon, authenticated;
grant update (username, display_name, avatar_cosmetic, active_mentor_role) on public.profiles to authenticated;

select pg_temp.policy('user_settings', 'own_settings_read', 'select', 'authenticated', 'user_id = auth.uid()');
select pg_temp.policy('user_settings', 'own_settings_update', 'update', 'authenticated',
                      'user_id = auth.uid()', 'user_id = auth.uid()');

select pg_temp.policy('device_tokens', 'own_tokens_read', 'select', 'authenticated', 'user_id = auth.uid()');
select pg_temp.policy('device_tokens', 'own_tokens_insert', 'insert', 'authenticated', null, 'user_id = auth.uid()');
select pg_temp.policy('device_tokens', 'own_tokens_delete', 'delete', 'authenticated', 'user_id = auth.uid()');

-- Read-own tables (writes via server functions only).
select pg_temp.policy(t, 'own_rows_read', 'select', 'authenticated', 'user_id = auth.uid()')
from unnest(array['user_learning_sessions', 'user_answers', 'country_mastery', 'subject_mastery',
                  'review_schedule', 'xp_ledger', 'geopoints_ledger', 'user_badges', 'user_trophies',
                  'user_cosmetics', 'competition_attempts', 'subscriptions', 'league_memberships',
                  'league_season_snapshots', 'user_country_mastery_evidence']) as t;
select pg_temp.policy('competition_answers', 'own_attempt_answers_read', 'select', 'authenticated',
                      'exists (select 1 from public.competition_attempts a where a.id = attempt_id
                               and a.user_id = auth.uid() and a.status in (''submitted'', ''scored''))');

-- Daily challenges: metadata is public once open; the question list only after the window closes.
select pg_temp.policy('daily_challenges', 'daily_read', 'select', 'authenticated', 'opens_at <= now()');
select pg_temp.policy('daily_challenge_questions', 'daily_questions_after_close', 'select', 'authenticated',
                      'exists (select 1 from public.daily_challenges d where d.id = daily_challenge_id
                               and d.closes_at <= now())');

-- Friendships.
select pg_temp.policy('friendships', 'friendship_read', 'select', 'authenticated',
                      'auth.uid() in (requester_id, addressee_id)');
select pg_temp.policy('friendships', 'friendship_request', 'insert', 'authenticated', null,
                      'requester_id = auth.uid() and status = ''pending''');
select pg_temp.policy('friendships', 'friendship_respond', 'update', 'authenticated',
                      'addressee_id = auth.uid()', 'addressee_id = auth.uid()');
select pg_temp.policy('friendships', 'friendship_remove', 'delete', 'authenticated',
                      'auth.uid() in (requester_id, addressee_id)');

-- Defence in depth: clients get no table privileges on secrets/audit tables at all.
revoke all on public.question_answer_keys, public.import_runs, public.store_purchases,
              public.award_idempotency_keys from anon, authenticated;
grant select on public.leagues to anon, authenticated;
