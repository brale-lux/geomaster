-- Editorial path: approval needs evidence, revisions are versioned, ranked never answered client-side.
insert into auth.users (id, email) values ('00000000-0000-0000-0000-0000000000ed', 'editor@example.test')
on conflict do nothing;
update profiles set app_role = 'editor' where id = '00000000-0000-0000-0000-0000000000ed';

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000ed', false);
do $$ declare qid uuid; rev int; begin
  select id into qid from questions where external_id = 'GM-0302';
  begin perform review_question(qid, 'approve', null); raise exception 'approved without evidence';
  exception when check_violation then null; end;
  rev := propose_question_revision(qid, jsonb_build_object(
    'prompt', 'How many member states did the United Nations have in 2026?',
    'explanation', 'The UN had 193 member states in 2026; South Sudan (2011) was the most recent to join.',
    'options', jsonb_build_array('193', '195', '191', '197'), 'correct_position', 0,
    'period_label', '2026'), 'Fix lower-case acronym and add reference year');
  assert rev = 2, 'second revision';
  perform approve_question_revision(qid, rev, 'UN member states list, un.org, checked 2026-11-16');
  assert (select editorial_status from questions where id = qid) = 'approved', 'approved';
  assert (select current_revision from questions where id = qid) = 2, 'revision applied';
  assert (select count(*) from question_revisions where question_id = qid) = 2, 'history kept';
end $$;
reset role;
do $$ declare qid uuid; begin
  select id into qid from questions where external_id = 'GM-0302';
  assert (select prompt from questions where id = qid) like 'How many member states did the United Nations%', 'prompt updated';
  assert (select snapshot ->> 'prompt' from question_revisions where question_id = qid and revision_number = 1)
    like 'How many un member states%', 'original wording preserved in history';
  update questions set ranked_eligible = true where id = qid;  -- allowed now that it is approved
end $$;
-- Ranked content is never answered by the client-facing checker.
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);
do $$ declare qid uuid; begin
  select id into qid from questions where external_id = 'GM-0302';
  assert (select count(*) from questions) = 1, 'player now sees the one approved question';
  begin perform check_sandbox_answer(qid, 0::smallint); raise exception 'ranked answer leaked';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
-- A re-import must not overwrite the approved correction (reported as a conflict instead).
do $$ declare r jsonb; begin
  r := import_question_bank(jsonb_build_object(
    'content_version', (select jsonb_build_object('version_key', version_key, 'source_sha256', source_sha256)
                        from content_versions limit 1),
    'questions', jsonb_build_array(jsonb_build_object('external_id', 'GM-0302', 'content_hash', repeat('0', 64)))));
  assert (r ->> 'conflict_count')::int = 1 and (r ->> 'inserted')::int = 0, 'conflict reported, not overwritten';
  assert (select current_revision from questions where external_id = 'GM-0302') = 2, 'correction kept';
end $$;
