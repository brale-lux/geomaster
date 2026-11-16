-- v1.3 A2: weekly UTC seasons, groups of <= 30, promotion/relegation for large and small groups.
insert into auth.users (id, email)
select ('00000000-0000-0000-0001-' || lpad(n::text, 12, '0'))::uuid, 'l' || n || '@example.test'
from generate_series(1, 70) n on conflict do nothing;

-- Seasons must start Monday 00:00 UTC and last exactly one week.
do $$ begin
  begin
    insert into league_seasons (starts_at, ends_at) values ('2026-11-17T00:00:00Z', '2026-11-23T23:59:59Z');
    raise exception 'tuesday season accepted';
  exception when check_violation then null; end;
end $$;

insert into league_seasons (id, starts_at, ends_at, status, policy_version_id)
values ('00000000-0000-0000-0002-000000000001', '2026-11-16T00:00:00Z', '2026-11-22T23:59:59Z', 'active',
        (select active_policy_id('league_scoring')));
insert into league_groups (id, season_id, tier_slug, group_number) values
  ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000001', 'bronze', 1),
  ('00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-000000000001', 'silver', 1),
  ('00000000-0000-0000-0003-000000000003', '00000000-0000-0000-0002-000000000001', 'gold', 1),
  ('00000000-0000-0000-0003-000000000004', '00000000-0000-0000-0002-000000000001', 'world_elite', 1),
  ('00000000-0000-0000-0003-000000000005', '00000000-0000-0000-0002-000000000001', 'platinum', 1);

-- helper: user n
create or replace function pg_temp.u(n int) returns uuid language sql as
  $$ select ('00000000-0000-0000-0001-' || lpad(n::text, 12, '0'))::uuid $$;
create or replace function pg_temp.join_group(g text, tier text, first int, last int, lp int[], inactive int)
returns void language sql as $$
  insert into league_memberships (season_id, user_id, group_id, tier_slug, league_points, daily_correct, lp_reached_at)
  select '00000000-0000-0000-0002-000000000001', pg_temp.u(n), g::uuid, tier,
         case when n - first < inactive then 0 else lp[n - first - inactive + 1] end, 0,
         '2026-11-20T00:00:00Z'::timestamptz + (n || ' minutes')::interval
  from generate_series(first, last) n
$$;

-- Bronze: 12 active + 2 inactive  -> promote ceil(2.4)=3, Bronze cannot relegate.
select pg_temp.join_group('00000000-0000-0000-0003-000000000001', 'bronze', 1, 14,
                          array[10,20,30,40,50,60,70,80,90,100,110,120], 2);
-- Silver: 10 active + 1 inactive  -> promote 2, relegate 2; inactive member stays.
select pg_temp.join_group('00000000-0000-0000-0003-000000000002', 'silver', 15, 25,
                          array[10,20,30,40,50,60,70,80,90,100], 1);
-- Gold: 4 active (small group)    -> promote top 1, no relegation.
select pg_temp.join_group('00000000-0000-0000-0003-000000000003', 'gold', 26, 29, array[5,15,25,35], 0);
-- World Elite: 5 active            -> cannot promote, small group so no relegation.
select pg_temp.join_group('00000000-0000-0000-0003-000000000004', 'world_elite', 30, 34, array[5,6,7,8,9], 0);
-- Platinum: 2 active (fewer than 3) -> nobody moves. Tie on LP broken by daily_correct.
select pg_temp.join_group('00000000-0000-0000-0003-000000000005', 'platinum', 35, 36, array[40,40], 0);
update league_memberships set daily_correct = 9 where user_id = pg_temp.u(36);

-- Group capacity 30.
do $$ begin
  begin
    insert into league_memberships (season_id, user_id, group_id, tier_slug)
    select '00000000-0000-0000-0002-000000000001', pg_temp.u(n), '00000000-0000-0000-0003-000000000005', 'platinum'
    from generate_series(37, 66) n where pg_temp.u(n) in (select id from profiles);
    set constraints all immediate;
    raise exception 'group overfilled';
  exception when raise_exception then
    if sqlerrm = 'group overfilled' then raise; end if;
  end;
end $$;

do $$ declare r jsonb; s text := '00000000-0000-0000-0002-000000000001'; begin
  r := close_league_season(s::uuid);
  assert r ->> 'status' = 'closed' and (r ->> 'snapshots')::int = 36, r::text;
  -- Bronze
  assert (select count(*) from league_season_snapshots where group_id = '00000000-0000-0000-0003-000000000001'
          and movement = 'promote' and to_tier = 'silver') = 3, 'bronze promotes 3';
  assert not exists (select 1 from league_season_snapshots where from_tier = 'bronze' and movement = 'relegate'),
    'bronze never relegates';
  assert (select movement from league_season_snapshots where user_id = pg_temp.u(14)) = 'promote', 'top bronze promoted';
  assert (select movement from league_season_snapshots where user_id = pg_temp.u(1)) = 'stay'
     and not (select was_active from league_season_snapshots where user_id = pg_temp.u(1)), 'inactive stays';
  -- Silver
  assert (select count(*) from league_season_snapshots where from_tier = 'silver' and movement = 'promote') = 2, 'silver +2';
  assert (select count(*) from league_season_snapshots where from_tier = 'silver' and movement = 'relegate'
          and to_tier = 'bronze') = 2, 'silver -2';
  assert (select movement from league_season_snapshots where user_id = pg_temp.u(15)) = 'stay',
    'inactive silver member is not relegated';
  assert (select movement from league_season_snapshots where user_id = pg_temp.u(16)) = 'relegate', 'lowest active relegated';
  -- Gold (small)
  assert (select string_agg(movement, ',' order by final_rank) from league_season_snapshots
          where from_tier = 'gold') = 'promote,stay,stay,stay', 'small group promotes top 1 only';
  -- World Elite
  assert not exists (select 1 from league_season_snapshots where from_tier = 'world_elite' and movement <> 'stay'),
    'world elite stays';
  -- Platinum (2 active): no movement; tie broken by daily_correct.
  assert not exists (select 1 from league_season_snapshots where from_tier = 'platinum' and movement <> 'stay'), 'tiny group';
  assert (select final_rank from league_season_snapshots where user_id = pg_temp.u(36)) = 1, 'tie-break daily_correct';
  -- Idempotent close.
  r := close_league_season(s::uuid);
  assert r ->> 'status' = 'already_closed' and (r ->> 'snapshots')::int = 36, 'second close is a no-op';
end $$;
