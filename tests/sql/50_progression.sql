-- v1.3 A1: rank boundaries 0, 499, 500, 1499, 1500, 49999, 50000.
do $$ begin
  assert rank_for_xp(0) = 'tourist' and rank_for_xp(499) = 'tourist', '0/499 tourist';
  assert rank_for_xp(500) = 'traveler' and rank_for_xp(1499) = 'traveler', '500/1499 traveler';
  assert rank_for_xp(1500) = 'explorer', '1500 explorer';
  assert rank_for_xp(49999) = 'master_geographer', '49999 master geographer';
  assert rank_for_xp(50000) = 'world_master', '50000 world master';
end $$;

-- Rank legends unlock from verified XP only; awards are idempotent; XP never decreases.
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; begin
  assert (select rank_slug from profiles where id = u) = 'tourist', 'starts as tourist';
  perform sync_user_rank(u);
  assert (select count(*) from user_trophies where user_id = u) = 1, 'tourist trophy on first sync';
  assert award_xp(u, 499, 'practice_correct', 'evt-test-000001', 'practice'), 'first award applies';
  assert (select rank_slug from profiles where id = u) = 'tourist', 'still tourist at 499';
  assert award_xp(u, 1, 'practice_correct', 'evt-test-000002', 'practice'), 'second award';
  assert (select rank_slug from profiles where id = u) = 'traveler', 'traveler at 500';
  assert not award_xp(u, 1, 'practice_correct', 'evt-test-000002', 'practice'), 'replay ignored';
  assert (select total_verified_xp from profiles where id = u) = 500, 'xp counted once';
  assert award_xp(u, 1000, 'daily_complete', 'evt-test-000003', 'x'), 'same id different event ok';
  assert (select rank_slug from profiles where id = u) = 'explorer', 'explorer at 1500';
  assert (select count(*) from user_trophies where user_id = u) = 3, 'three rank legends unlocked';
  assert not exists (select 1 from user_trophies ut join trophy_definitions t on t.id = ut.trophy_id
                     where ut.user_id = u and t.slug = 'ocean_astrolabe'), 'navigator legend still locked';
  begin
    insert into xp_ledger (user_id, amount, award_type, source_event_id, reason)
    values (u, -10, 'practice_correct', 'evt-test-neg-01', 'x');
    raise exception 'negative xp accepted';
  exception when check_violation then null; end;
end $$;

-- Category trophies: unavailable without approved inventory; sandbox/draft answers never count.
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; r jsonb; begin
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id, is_provisional)
  select u, q.id, 0, true, 'sandbox', now(), gen_random_uuid(), false
  from questions q where q.primary_category_slug = 'geography_nature';
  r := award_category_trophies(u, 'geography_nature');
  assert r = '{"bronze": "not_yet_available", "silver": "not_yet_available", "gold": "not_yet_available"}'::jsonb, r::text;
  assert not exists (select 1 from user_trophies ut join trophy_definitions t on t.id = ut.trophy_id
                     where t.slug = 'golden_atlas'), 'no category trophy';
end $$;

-- Bronze rule (20 distinct correct across >= 2 subtopics) on approved content, in a rolled-back sandbox.
begin;
update questions set editorial_status = 'approved' where primary_category_slug = 'geography_nature';
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; r jsonb; begin
  -- 19 distinct correct in one subtopic: not met.
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id, is_provisional)
  select u, q.id, 0, true, 'learn', now(), gen_random_uuid(), false
  from questions q join subject_subcategories s on s.id = q.subcategory_id
  where q.primary_category_slug = 'geography_nature' and s.slug = 'capitals' order by q.external_id limit 19;
  r := award_category_trophies(u, 'geography_nature');
  assert r ->> 'bronze' = 'not_met', 'bronze not met at 19: ' || r::text;
  -- 20th distinct correct in a second subtopic: bronze earned; silver/gold not met.
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id, is_provisional)
  select u, q.id, 0, true, 'learn', now(), gen_random_uuid(), false
  from questions q join subject_subcategories s on s.id = q.subcategory_id
  where q.primary_category_slug = 'geography_nature' and s.slug = 'rivers' order by q.external_id limit 1;
  r := award_category_trophies(u, 'geography_nature');
  assert r ->> 'bronze' = 'earned' and r ->> 'silver' = 'not_met' and r ->> 'gold' = 'not_yet_available', r::text;
end $$;
rollback;

-- Offline sync is idempotent per client_answer_id.
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; c uuid := gen_random_uuid(); q uuid; begin
  select id into q from questions limit 1;
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id)
  values (u, q, 0, true, 'learn', now(), c);
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id)
  values (u, q, 0, true, 'learn', now(), c) on conflict (user_id, client_answer_id) do nothing;
  assert (select count(*) from user_answers where client_answer_id = c) = 1, 'no duplicate on resync';
end $$;
