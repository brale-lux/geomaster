-- GeoMaster 0800: trusted server functions.
--   import_question_bank   : idempotent, transactional question-bank import (service role only)
--   review_question / propose_question_revision / approve_question_revision : editorial path
--   get_sandbox_questions / check_sandbox_answer : draft-content test mode (testers only)
--   sync_user_rank / award_xp / award_category_trophy : earned-only progression (service role)

-- ---------------------------------------------------------------- import

create or replace function public.import_question_bank(payload jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_cv          jsonb := payload -> 'content_version';
  v_cv_id       uuid;
  v_existing_sha text;
  v_asset       jsonb;
  v_q           jsonb;
  v_qid         uuid;
  v_hash        text;
  v_subcat_id   uuid;
  v_asset_id    uuid;
  v_inserted    int := 0;
  v_unchanged   int := 0;
  v_conflicts   jsonb := '[]'::jsonb;
  v_opt         text;
  v_pos         int;
  v_result      jsonb;
begin
  if v_cv is null or jsonb_typeof(payload -> 'questions') <> 'array' then
    raise exception 'payload must contain content_version and questions[]';
  end if;

  -- Content version: same key must always mean the same source bytes.
  select id, source_sha256 into v_cv_id, v_existing_sha
  from content_versions where version_key = v_cv ->> 'version_key';
  if v_cv_id is null then
    insert into content_versions (version_key, schema_version, status, question_count, source_filename,
                                  source_sha256, package_sha256, archive_path, metrics)
    values (v_cv ->> 'version_key', v_cv ->> 'schema_version', v_cv ->> 'status',
            (v_cv ->> 'question_count')::int, v_cv ->> 'source_filename', v_cv ->> 'source_sha256',
            v_cv ->> 'package_sha256', v_cv ->> 'archive_path', coalesce(v_cv -> 'metrics', '{}'))
    returning id into v_cv_id;
  elsif v_existing_sha <> v_cv ->> 'source_sha256' then
    raise exception 'content version % already imported from different source bytes (% vs %)',
      v_cv ->> 'version_key', v_existing_sha, v_cv ->> 'source_sha256';
  end if;

  -- Assets.
  for v_asset in select * from jsonb_array_elements(coalesce(payload -> 'assets', '[]')) loop
    insert into question_assets (storage_path, bundle_path, mime_type, sha256, byte_size, width, height,
                                 alt_text, alt_text_status, attribution, license, license_status, provenance,
                                 sanitized, content_version_id)
    values (v_asset ->> 'storage_path', v_asset ->> 'bundle_path', 'image/svg+xml', v_asset ->> 'sha256',
            (v_asset ->> 'byte_size')::int, (v_asset ->> 'width')::int, (v_asset ->> 'height')::int,
            v_asset ->> 'alt_text', v_asset ->> 'alt_text_status', v_asset ->> 'attribution',
            v_asset ->> 'license', v_asset ->> 'license_status', v_asset ->> 'provenance', true, v_cv_id)
    on conflict (storage_path) do nothing;
    if exists (select 1 from question_assets
               where storage_path = v_asset ->> 'storage_path' and sha256 <> v_asset ->> 'sha256') then
      v_conflicts := v_conflicts || jsonb_build_object('asset', v_asset ->> 'storage_path',
                                                       'reason', 'stored asset has different bytes');
    end if;
  end loop;

  -- Questions.
  for v_q in select * from jsonb_array_elements(payload -> 'questions') loop
    v_hash := v_q ->> 'content_hash';
    select id into v_qid from questions where external_id = v_q ->> 'external_id';

    if v_qid is not null then
      if (select source_content_hash from questions where id = v_qid) = v_hash then
        v_unchanged := v_unchanged + 1;
      else
        -- Never overwrite stored wording/answers; corrections go through the editorial path.
        v_conflicts := v_conflicts || jsonb_build_object('external_id', v_q ->> 'external_id',
                         'reason', 'stored question differs from incoming; not overwritten');
      end if;
      continue;
    end if;

    insert into subject_subcategories (category_slug, slug, display_name)
    values (v_q ->> 'category_slug', v_q ->> 'subcategory_slug', v_q ->> 'subcategory_name')
    on conflict (category_slug, slug) do nothing;
    select id into v_subcat_id from subject_subcategories
    where category_slug = v_q ->> 'category_slug' and slug = v_q ->> 'subcategory_slug';

    insert into questions (external_id, content_version_id, primary_category_slug, subcategory_id,
                           question_type, prompt, explanation, difficulty, language, period_label,
                           cohort, editorial_status, ranked_eligible, qa_flags, source_content_hash)
    values (v_q ->> 'external_id', v_cv_id, v_q ->> 'category_slug', v_subcat_id,
            v_q ->> 'question_type', v_q ->> 'prompt', v_q ->> 'explanation',
            (v_q ->> 'difficulty')::smallint, v_q ->> 'language', v_q ->> 'period_label',
            v_q ->> 'cohort',
            -- Import can only ever produce draft or quarantined rows.
            case when v_q ->> 'editorial_status' = 'quarantined' then 'quarantined' else 'draft_unverified' end,
            false, coalesce(v_q -> 'qa_flags', '[]'), v_hash)
    returning id into v_qid;

    v_pos := 0;
    for v_opt in select jsonb_array_elements_text(v_q -> 'options') loop
      insert into question_options (question_id, position, option_text) values (v_qid, v_pos, v_opt);
      v_pos := v_pos + 1;
    end loop;
    insert into question_answer_keys (question_id, correct_position)
    values (v_qid, (v_q ->> 'correct_position')::smallint);

    if coalesce(v_q ->> 'source_hint', '') <> '' then
      insert into question_sources (question_id, source_type, citation, is_verified)
      values (v_qid, 'source_hint', v_q ->> 'source_hint', false);
    end if;

    if v_q ->> 'visual_file' is not null then
      select id into v_asset_id from question_assets
      where storage_path = (v_cv ->> 'version_key') || '/' || (v_q ->> 'visual_file');
      if v_asset_id is null then
        raise exception 'question % references missing asset %', v_q ->> 'external_id', v_q ->> 'visual_file';
      end if;
      insert into question_asset_links (question_id, asset_id, role) values (v_qid, v_asset_id, 'prompt');
    end if;

    insert into question_revisions (question_id, revision_number, snapshot, change_summary, status)
    values (v_qid, 1, v_q - 'qa_flags', 'Original import from ' || (v_cv ->> 'version_key'), 'original_import');

    v_inserted := v_inserted + 1;
  end loop;

  v_result := jsonb_build_object('content_version', v_cv ->> 'version_key', 'inserted', v_inserted,
                                 'unchanged', v_unchanged, 'conflict_count', jsonb_array_length(v_conflicts),
                                 'conflicts', v_conflicts);
  insert into import_runs (content_version_id, inserted, unchanged, conflicts, result)
  values (v_cv_id, v_inserted, v_unchanged, jsonb_array_length(v_conflicts), v_result);
  return v_result;
end $$;

-- ---------------------------------------------------------------- editorial path

create or replace function public.review_question(p_question_id uuid, p_decision text, p_evidence text,
                                                  p_notes text default null)
returns text language plpgsql security definer set search_path = public as $$
declare v_status text; v_rev int;
begin
  if not public.is_editor() then raise exception 'editor role required' using errcode = '42501'; end if;
  select current_revision into v_rev from questions where id = p_question_id for update;
  if v_rev is null then raise exception 'question not found'; end if;
  insert into question_reviews (question_id, revision_number, reviewer_id, decision, evidence, notes)
  values (p_question_id, v_rev, auth.uid(), p_decision, p_evidence, p_notes);
  v_status := case p_decision when 'approve' then 'approved' when 'reject' then 'rejected'
                when 'quarantine' then 'quarantined' when 'retire' then 'retired' else 'needs_review' end;
  update questions set editorial_status = v_status,
                       ranked_eligible = case when v_status = 'approved' then ranked_eligible else false end
  where id = p_question_id;
  return v_status;
end $$;

create or replace function public.propose_question_revision(p_question_id uuid, p_snapshot jsonb,
                                                            p_change_summary text)
returns integer language plpgsql security definer set search_path = public as $$
declare v_next int;
begin
  if not public.is_editor() then raise exception 'editor role required' using errcode = '42501'; end if;
  if jsonb_array_length(p_snapshot -> 'options') <> 4
     or (p_snapshot ->> 'correct_position')::int not between 0 and 3 then
    raise exception 'snapshot needs 4 options and correct_position 0..3';
  end if;
  select coalesce(max(revision_number), 0) + 1 into v_next from question_revisions where question_id = p_question_id;
  insert into question_revisions (question_id, revision_number, snapshot, change_summary, status, proposed_by)
  values (p_question_id, v_next, p_snapshot, p_change_summary, 'proposed', auth.uid());
  return v_next;
end $$;

create or replace function public.approve_question_revision(p_question_id uuid, p_revision int, p_evidence text)
returns void language plpgsql security definer set search_path = public as $$
declare r question_revisions; i int;
begin
  if not public.is_editor() then raise exception 'editor role required' using errcode = '42501'; end if;
  select * into r from question_revisions
  where question_id = p_question_id and revision_number = p_revision and status = 'proposed' for update;
  if r.id is null then raise exception 'no proposed revision % for question', p_revision; end if;

  update question_revisions set status = 'superseded'
  where question_id = p_question_id and status = 'approved';
  update question_revisions set status = 'approved', decided_by = auth.uid(), decided_at = now(),
                                evidence = p_evidence
  where id = r.id;

  update questions set prompt = r.snapshot ->> 'prompt', explanation = r.snapshot ->> 'explanation',
                       difficulty = coalesce((r.snapshot ->> 'difficulty')::smallint, difficulty),
                       period_label = coalesce(r.snapshot ->> 'period_label', period_label),
                       current_revision = p_revision, editorial_status = 'approved'
  where id = p_question_id;
  -- Two passes so reordering options never trips the per-question unique-text index.
  update question_options set option_text = '__rev_tmp_' || position::text where question_id = p_question_id;
  for i in 0..3 loop
    update question_options set option_text = r.snapshot -> 'options' ->> i
    where question_id = p_question_id and position = i;
  end loop;
  update question_answer_keys set correct_position = (r.snapshot ->> 'correct_position')::smallint
  where question_id = p_question_id;
  insert into question_reviews (question_id, revision_number, reviewer_id, decision, evidence)
  values (p_question_id, p_revision, auth.uid(), 'approve', p_evidence);
end $$;

-- ---------------------------------------------------------------- draft sandbox (testers only)

create or replace function public.get_sandbox_questions(p_category text default null,
                                                        p_difficulty smallint default null,
                                                        p_limit int default 20, p_offset int default 0)
returns table (question_id uuid, external_id text, category_slug text, subcategory text, prompt text,
               options jsonb, difficulty smallint, period_label text, editorial_status text,
               asset_bundle_path text, asset_alt_text text, qa_flags jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_content_tester() then
    raise exception 'sandbox is limited to content testers' using errcode = '42501';
  end if;
  return query
  select q.id, q.external_id, q.primary_category_slug, s.display_name, q.prompt,
         (select jsonb_agg(o.option_text order by o.position) from question_options o where o.question_id = q.id),
         q.difficulty, q.period_label, q.editorial_status, a.bundle_path, a.alt_text, q.qa_flags
  from questions q
  left join subject_subcategories s on s.id = q.subcategory_id
  left join question_asset_links l on l.question_id = q.id and l.role = 'prompt'
  left join question_assets a on a.id = l.asset_id
  where q.editorial_status in ('draft_unverified', 'needs_review', 'approved', 'quarantined')
    and (p_category is null or q.primary_category_slug = p_category)
    and (p_difficulty is null or q.difficulty = p_difficulty)
  order by q.external_id
  limit least(greatest(p_limit, 1), 100) offset greatest(p_offset, 0);
end $$;

-- Answer check for practice/sandbox. Never answers ranked-eligible content.
create or replace function public.check_sandbox_answer(p_question_id uuid, p_selected smallint)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_q questions; v_correct smallint;
begin
  select * into v_q from questions where id = p_question_id;
  if v_q.id is null then raise exception 'question not found'; end if;
  if v_q.ranked_eligible then
    raise exception 'ranked content is scored server-side only' using errcode = '42501';
  end if;
  if v_q.editorial_status <> 'approved' and not public.is_content_tester() then
    raise exception 'draft content is limited to content testers' using errcode = '42501';
  end if;
  select correct_position into v_correct from question_answer_keys where question_id = p_question_id;
  return jsonb_build_object('is_correct', p_selected = v_correct, 'correct_position', v_correct,
                            'explanation', v_q.explanation, 'editorial_status', v_q.editorial_status);
end $$;

-- ---------------------------------------------------------------- progression (service role only)

create or replace function public.active_policy_id(p_key text)
returns uuid language sql stable security definer set search_path = public as $$
  select id from game_policy_versions where policy_key = p_key and is_active
$$;

-- Permanent XP award. Idempotent on (user, source_event_id, award_type); amounts are positive
-- (XP never decreases). Daily caps and per-question-per-day eligibility are enforced by the
-- scoring function that calls this (Phase D), using the active 'xp_awards' policy.
create or replace function public.award_xp(p_user uuid, p_amount int, p_award_type text,
                                           p_source_event_id text, p_reason text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_rows int;
begin
  insert into award_idempotency_keys (user_id, source_event_id, award_type)
  values (p_user, p_source_event_id, 'xp:' || p_award_type)
  on conflict do nothing;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then return false; end if;  -- replay: already awarded
  insert into xp_ledger (user_id, amount, award_type, source_event_id, reason, is_verified, policy_version_id)
  values (p_user, p_amount, p_award_type, p_source_event_id, p_reason, true, active_policy_id('xp_awards'));
  update profiles set total_verified_xp = total_verified_xp + p_amount where id = p_user;
  perform public.sync_user_rank(p_user);
  return true;
end $$;

-- Rank = highest threshold of the active 'xp_ranks' policy <= lifetime verified XP.
-- Rank legends unlock automatically for every rank reached (earned-only, idempotent).
create or replace function public.rank_for_xp(p_xp bigint)
returns text language sql stable security definer set search_path = public as $$
  select t.rank_slug from xp_rank_thresholds t
  where t.policy_version_id = active_policy_id('xp_ranks') and t.min_verified_xp <= p_xp
  order by t.min_verified_xp desc limit 1
$$;

create or replace function public.sync_user_rank(p_user uuid)
returns text language plpgsql security definer set search_path = public as $$
declare v_xp bigint; v_rank text; v_policy uuid := active_policy_id('xp_ranks');
begin
  select total_verified_xp into v_xp from profiles where id = p_user;
  if v_xp is null then raise exception 'profile not found'; end if;
  v_rank := rank_for_xp(v_xp);
  update profiles set rank_slug = v_rank where id = p_user and rank_slug is distinct from v_rank;
  insert into user_trophies (user_id, trophy_id, tier, unlock_source, policy_version_id)
  select p_user, tr.id, 'standard', 'rank:' || t.rank_slug, v_policy
  from xp_rank_thresholds t
  join character_roles c on c.role_type = 'rank_legend' and c.rank_slug = t.rank_slug
  join trophy_definitions tr on tr.character_role_id = c.id
  where t.policy_version_id = v_policy and t.min_verified_xp <= v_xp
  on conflict do nothing;
  return v_rank;
end $$;

-- v1.3 A4 category trophy tiers, from verified, non-sandbox answers on approved questions.
-- Returns per-tier state: earned / eligible_now / not_met / not_yet_available.
create or replace function public.award_category_trophies(p_user uuid, p_category text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_def trophy_definitions; v_policy uuid := active_policy_id('category_trophies');
  r category_trophy_rules; v_inventory int; v_correct int; v_subtopics int; v_dates int;
  v_acc numeric; v_state text; v_out jsonb := '{}'::jsonb;
begin
  select t.* into v_def from trophy_definitions t
  join category_guide_assignments a on a.character_role_id = t.character_role_id
  where a.category_slug = p_category;
  if v_def.id is null then raise exception 'no guide trophy for %', p_category; end if;

  select count(*) into v_inventory from questions
  where primary_category_slug = p_category and editorial_status = 'approved';

  -- Distinct correctly answered questions, distinct subtopics among them, distinct UTC dates.
  select count(distinct ua.question_id), count(distinct q.subcategory_id),
         count(distinct (ua.answered_at at time zone 'utc')::date)
  into v_correct, v_subtopics, v_dates
  from user_answers ua join questions q on q.id = ua.question_id
  where ua.user_id = p_user and ua.is_correct and not ua.is_provisional and ua.mode <> 'sandbox'
    and q.primary_category_slug = p_category and q.editorial_status = 'approved';

  for r in select * from category_trophy_rules where policy_version_id = v_policy
           order by min_distinct_correct loop
    if exists (select 1 from user_trophies where user_id = p_user and trophy_id = v_def.id and tier = r.tier) then
      v_state := 'earned';
    elsif v_inventory < r.min_distinct_correct then
      v_state := 'not_yet_available';  -- never award by repeating one item
    else
      v_acc := null;
      if r.accuracy_window is not null then
        select avg(case when x.is_correct then 1.0 else 0.0 end) into v_acc from (
          select ua.is_correct from user_answers ua join questions q on q.id = ua.question_id
          where ua.user_id = p_user and not ua.is_provisional and ua.mode <> 'sandbox'
            and q.primary_category_slug = p_category and q.editorial_status = 'approved'
          order by ua.answered_at desc limit r.accuracy_window) x;
      end if;
      if v_correct >= r.min_distinct_correct and v_subtopics >= r.min_subtopics
         and (r.min_accuracy is null or coalesce(v_acc, 0) >= r.min_accuracy)
         and (r.min_distinct_utc_dates is null or v_dates >= r.min_distinct_utc_dates) then
        insert into user_trophies (user_id, trophy_id, tier, unlock_source, policy_version_id)
        values (p_user, v_def.id, r.tier, 'category:' || p_category, v_policy) on conflict do nothing;
        v_state := 'earned';
      else
        v_state := 'not_met';
      end if;
    end if;
    v_out := v_out || jsonb_build_object(r.tier, v_state);
  end loop;
  return v_out;
end $$;

-- v1.3 A2 season close: one idempotent transaction; snapshots every member's final rank and move.
create or replace function public.close_league_season(p_season uuid)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_season league_seasons; g record; v_cfg jsonb; v_active int; v_promote int; v_relegate int;
  v_top int; v_snapshots int;
begin
  select * into v_season from league_seasons where id = p_season for update;
  if v_season.id is null then raise exception 'season not found'; end if;
  if v_season.status = 'closed' then
    return jsonb_build_object('status', 'already_closed',
      'snapshots', (select count(*) from league_season_snapshots where season_id = p_season));
  end if;
  select config into v_cfg from game_policy_versions
  where id = coalesce(v_season.policy_version_id, active_policy_id('league_scoring'));
  select max(position) into v_top from league_tiers;

  for g in select lg.id, lg.tier_slug, t.position as tier_pos
           from league_groups lg join league_tiers t on t.slug = lg.tier_slug
           where lg.season_id = p_season loop
    select count(*) into v_active from league_memberships where group_id = g.id and league_points > 0;
    if v_active >= (v_cfg ->> 'min_active_for_percent')::int then
      v_promote := ceil(v_active * (v_cfg ->> 'promote_fraction')::numeric);
      v_relegate := floor(v_active * (v_cfg ->> 'relegate_fraction')::numeric);
    else
      v_promote := case when v_active >= (v_cfg ->> 'min_active_for_small_group_promotion')::int then 1 else 0 end;
      v_relegate := 0;
    end if;
    if g.tier_pos = v_top then v_promote := 0; end if;   -- World Elite cannot promote
    if g.tier_pos = 1 then v_relegate := 0; end if;       -- Bronze cannot relegate

    insert into league_season_snapshots (season_id, user_id, group_id, final_rank, league_points, was_active,
                                         movement, from_tier, to_tier, policy_version_id)
    select p_season, m.user_id, g.id, m.overall_rank, m.league_points, m.active,
           case when m.active and m.active_rank <= v_promote then 'promote'
                when m.active and m.active_rank > v_active - v_relegate then 'relegate'
                else 'stay' end,
           g.tier_slug,
           case when m.active and m.active_rank <= v_promote
                  then (select slug from league_tiers where position = g.tier_pos + 1)
                when m.active and m.active_rank > v_active - v_relegate
                  then (select slug from league_tiers where position = g.tier_pos - 1)
                else g.tier_slug end,
           coalesce(v_season.policy_version_id, active_policy_id('league_scoring'))
    from (
      select lm.user_id, lm.league_points, lm.league_points > 0 as active,
             row_number() over w as overall_rank,
             -- Ranks among active members only; inactive members are excluded from the percentages.
             case when lm.league_points > 0 then
               row_number() over (partition by lm.league_points > 0
                                  order by lm.league_points desc, lm.daily_correct desc,
                                           lm.lp_reached_at nulls last, lm.user_id) end as active_rank
      from league_memberships lm where lm.group_id = g.id
      window w as (order by lm.league_points desc, lm.daily_correct desc, lm.lp_reached_at nulls last, lm.user_id)
    ) m
    on conflict (season_id, user_id) do nothing;
  end loop;

  update league_seasons set status = 'closed', closed_at = now() where id = p_season;
  select count(*) into v_snapshots from league_season_snapshots where season_id = p_season;
  return jsonb_build_object('status', 'closed', 'snapshots', v_snapshots);
end $$;

-- ---------------------------------------------------------------- execute privileges

revoke all on function public.import_question_bank(jsonb) from public, anon, authenticated;
revoke all on function public.award_xp(uuid, int, text, text, text) from public, anon, authenticated;
revoke all on function public.close_league_season(uuid) from public, anon, authenticated;
grant execute on function public.close_league_season(uuid) to service_role;
revoke all on function public.sync_user_rank(uuid) from public, anon, authenticated;
revoke all on function public.award_category_trophies(uuid, text) from public, anon, authenticated;
grant execute on function public.import_question_bank(jsonb) to service_role;
grant execute on function public.award_xp(uuid, int, text, text, text) to service_role;
grant execute on function public.sync_user_rank(uuid) to service_role;
grant execute on function public.award_category_trophies(uuid, text) to service_role;

revoke all on function public.review_question(uuid, text, text, text) from public, anon;
revoke all on function public.propose_question_revision(uuid, jsonb, text) from public, anon;
revoke all on function public.approve_question_revision(uuid, int, text) from public, anon;
revoke all on function public.get_sandbox_questions(text, smallint, int, int) from public, anon;
revoke all on function public.check_sandbox_answer(uuid, smallint) from public, anon;
grant execute on function public.review_question(uuid, text, text, text) to authenticated;
grant execute on function public.propose_question_revision(uuid, jsonb, text) to authenticated;
grant execute on function public.approve_question_revision(uuid, int, text) to authenticated;
grant execute on function public.get_sandbox_questions(text, smallint, int, int) to authenticated;
grant execute on function public.check_sandbox_answer(uuid, smallint) to authenticated;
