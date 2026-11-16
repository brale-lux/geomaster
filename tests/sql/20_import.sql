-- Import results: 520 rows, all draft, nothing ranked, original 500 + 20 explorers preserved.
do $$ begin
  assert (select count(*) from questions) = 520, '520 questions';
  assert (select count(distinct external_id) from questions) = 520, 'unique ids';
  assert (select min(external_id) from questions) = 'GM-0001' and (select max(external_id) from questions) = 'GM-0520', 'id range';
  assert (select count(*) from questions where cohort = 'original_500') = 500, 'original 500';
  assert (select count(*) from questions where cohort = 'explorers_plus20'
          and primary_category_slug = 'explorers_pioneers_discoverers') = 20, '20 explorer questions';
  assert (select count(distinct primary_category_slug) from questions) = 7, 'all 7 categories present';
  assert not exists (select 1 from questions where editorial_status = 'approved' or ranked_eligible),
    'nothing verified or ranked after import';
  assert (select count(*) from question_options) = 2080, '4 options each';
  assert (select count(*) from question_answer_keys) = 520, 'one answer key each';
  assert (select count(*) from question_asset_links) = 27, '27 visual questions linked';
  assert (select count(*) from question_assets where sanitized and license_status = 'pending_review') = 27,
    'assets sanitised, licence pending (not invented)';
  assert not exists (select 1 from question_sources where is_verified), 'source hints are not verified citations';
  assert (select count(*) from question_revisions where status = 'original_import') = 520, 'revision 1 snapshot';
  assert (select count(*) from content_versions) = 1, 'one content version';
  assert (select count(*) from import_runs) = 2, 'two runs logged';
  assert (select inserted from import_runs order by started_at desc limit 1) = 0, 'second run inserted nothing';
end $$;
-- Spot-check GM-0001 against the source JSON.
do $$ declare v text; p int; begin
  select o.option_text, k.correct_position into v, p
  from questions q join question_answer_keys k on k.question_id = q.id
  join question_options o on o.question_id = q.id and o.position = k.correct_position
  where q.external_id = 'GM-0001';
  assert v = 'Black Sea' and p = 0, 'GM-0001 answer preserved';
end $$;
-- Ranked eligibility requires approval (check constraint).
do $$ begin
  begin
    update questions set ranked_eligible = true where external_id = 'GM-0002';
    raise exception 'should have failed';
  exception when check_violation then null; end;
end $$;
