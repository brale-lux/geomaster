-- Rank legends unlock from verified XP only; awards are idempotent; category tiers need verified answers.
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; begin
  assert (select rank_slug from profiles where id = u) = 'tourist', 'starts as tourist';
  perform sync_user_rank(u);
  assert (select count(*) from user_trophies where user_id = u) = 1, 'tourist trophy on first sync';
  assert award_xp(u, 3500, 'lesson', 'learn', 'test-award-0001'), 'first award applies';
  assert not award_xp(u, 3500, 'lesson', 'learn', 'test-award-0001'), 'replay ignored';
  assert (select total_verified_xp from profiles where id = u) = 3500, 'xp counted once';
  assert (select rank_slug from profiles where id = u) = 'explorer', 'rank explorer at 3500';
  assert (select count(*) from user_trophies where user_id = u) = 3, 'three rank legends unlocked';
  assert not exists (select 1 from user_trophies ut join trophy_definitions t on t.id = ut.trophy_id
                     where ut.user_id = u and t.slug = 'ocean_astrolabe'), 'navigator legend still locked';
  -- Draft/provisional answers never earn category trophies.
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id, is_provisional)
  select u, q.id, 0, true, 'sandbox', now(), gen_random_uuid(), false
  from questions q where q.primary_category_slug = 'geography_nature';
  assert cardinality(award_category_trophies(u, 'geography_nature')) = 0, 'sandbox answers earn nothing';
end $$;
-- Offline sync is idempotent per client_answer_id.
do $$ declare u uuid := '00000000-0000-0000-0000-00000000000c'; c uuid := gen_random_uuid(); q uuid; begin
  select id into q from questions limit 1;
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id)
  values (u, q, 0, true, 'learn', now(), c);
  insert into user_answers (user_id, question_id, selected_position, is_correct, mode, answered_at, client_answer_id)
  values (u, q, 0, true, 'learn', now(), c) on conflict (user_id, client_answer_id) do nothing;
  assert (select count(*) from user_answers where client_answer_id = c) = 1, 'no duplicate on resync';
end $$;
