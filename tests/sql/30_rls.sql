-- RLS: players see no drafts and never answer keys; testers get the sandbox.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'player@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'tester@example.test'),
  ('00000000-0000-0000-0000-00000000000c', 'other@example.test')
on conflict do nothing;
update profiles set app_role = 'tester' where id = '00000000-0000-0000-0000-00000000000b';

-- Player.
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);
do $$ begin
  assert (select count(*) from questions) = 0, 'player sees no draft questions';
  assert (select count(*) from question_options) = 0, 'player sees no draft options';
  assert (select count(*) from subject_categories) = 7, 'player sees categories';
  assert (select count(*) from profiles) = 1, 'player sees only own profile';
  begin perform * from question_answer_keys; raise exception 'answer keys readable';
  exception when insufficient_privilege then null; end;
  begin perform * from get_sandbox_questions(); raise exception 'player reached sandbox';
  exception when insufficient_privilege then null; end;
  begin perform public.import_question_bank('{}'); raise exception 'player ran import';
  exception when insufficient_privilege then null; end;
  begin perform public.award_xp('00000000-0000-0000-0000-00000000000a', 999999, 'x', 'adjustment', 'cheat-0001');
    raise exception 'player awarded xp';
  exception when insufficient_privilege then null; end;
  begin update profiles set app_role = 'admin' where id = auth.uid(); raise exception 'role escalation';
  exception when insufficient_privilege then null; end;
  begin update profiles set total_verified_xp = 1e6 where id = auth.uid(); raise exception 'xp edit';
  exception when insufficient_privilege then null; end;
  begin insert into xp_ledger (user_id, amount, reason, source_type, idempotency_key)
        values (auth.uid(), 5000, 'x', 'learn', 'cheat-0002'); raise exception 'ledger insert';
  exception when insufficient_privilege then null; end;
end $$;
update profiles set display_name = 'Pip fan' where id = auth.uid();
update profiles set display_name = 'hijack' where id = '00000000-0000-0000-0000-00000000000b';
reset role;
do $$ begin
  assert (select display_name from profiles where id = '00000000-0000-0000-0000-00000000000a') = 'Pip fan', 'own update';
  assert (select display_name from profiles where id = '00000000-0000-0000-0000-00000000000b') is null, 'no cross-user update';
end $$;

-- Tester sandbox.
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000b', false);
do $$ declare r jsonb; qid uuid; begin
  assert (select count(*) from questions) = 520, 'tester sees all drafts';
  assert (select count(*) from get_sandbox_questions(null, null, 100, 0)) = 100, 'page size';
  assert (select count(*) from get_sandbox_questions('explorers_pioneers_discoverers', null, 100, 0)) = 20, 'explorers';
  assert (select asset_bundle_path from get_sandbox_questions(null, null, 1, 0)) = 'assets/questions/river_1.svg', 'visual';
  select id into qid from questions where external_id = 'GM-0001';
  r := check_sandbox_answer(qid, 0::smallint);
  assert (r ->> 'is_correct')::boolean and r ->> 'editorial_status' = 'draft_unverified', 'sandbox answer check';
  r := check_sandbox_answer(qid, 1::smallint);
  assert not (r ->> 'is_correct')::boolean, 'wrong answer detected';
  begin perform * from question_answer_keys; raise exception 'tester read keys table';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
