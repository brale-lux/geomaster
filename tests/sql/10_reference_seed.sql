-- Reference data: 7 categories, 9 ranks, 15 distinct people, 16 roles, Ibn Battuta twice.
do $$ begin
  assert (select count(*) from subject_categories) = 7, 'expected 7 categories';
  assert (select count(*) from rank_definitions) = 9, 'expected 9 ranks';
  assert (select string_agg(display_name, ',' order by position) from rank_definitions)
    = 'Tourist,Traveler,Explorer,Navigator,Cartographer,Geographer,World Expert,Master Geographer,World Master',
    'rank order';
  assert (select count(*) from historical_people) = 15, 'expected 15 distinct people';
  assert (select count(*) from character_roles) = 16, 'expected 16 roles';
  assert (select count(*) from character_roles where role_type = 'rank_legend') = 9, '9 rank legends';
  assert (select count(*) from character_roles where role_type = 'category_guide') = 7, '7 guides';
  assert (select count(*) from category_guide_assignments) = 7, '7 guide assignments';
  assert (select count(*) from trophy_definitions) = 16, '16 trophy definitions';
  assert (select count(*) from trophy_definitions where tiered) = 7, '7 tiered category trophies';
  assert (select count(*) from character_roles c join historical_people p on p.id = c.person_id
          where p.slug = 'ibn_battuta') = 2, 'Ibn Battuta holds two roles on one person row';
  assert exists (select 1 from character_roles c join historical_people p on p.id = c.person_id
                 where p.slug = 'ibn_battuta' and c.role_type = 'category_guide'
                   and c.category_slug = 'explorers_pioneers_discoverers' and c.guide_title = 'The Pathfinder'),
    'Ibn Battuta guides Explorers';
  assert exists (select 1 from character_roles c join historical_people p on p.id = c.person_id
                 where p.slug = 'ibn_battuta' and c.rank_slug = 'traveler'), 'Ibn Battuta is Traveler legend';
  assert (select biography from historical_people where slug = 'ferdinand_magellan') like '%Elcano%',
    'Magellan bio credits Elcano';
  assert not exists (select 1 from historical_people where biography_status = 'approved'),
    'bios stay draft until reviewed';
  assert (select count(*) from character_art_assets where is_placeholder) = 16, 'placeholder art per role';
  assert (select style_token_key from subject_categories where slug = 'politics_world_affairs') = 'politics_world',
    'style token alias kept';
  assert (select style_token_key from subject_categories where slug = 'explorers_pioneers_discoverers') = 'travel_cultures',
    'Pathfinder token alias';
  assert (select string_agg(c.visual_variant, ',' order by c.role_type) from character_roles c
          join historical_people p on p.id = c.person_id where p.slug = 'ibn_battuta') = 'guide,legend',
    'Ibn Battuta outfit per role';
  assert (select icon_key from trophy_definitions where slug = 'explorers_journal') = 'route', 'Pathfinder trophy icon';
end $$;

-- v1.3 policies, thresholds, leagues, trophy rules.
do $$ begin
  assert (select count(*) from game_policy_versions where is_active) = 5, 'five active policies';
  assert (select string_agg(t.rank_slug || ':' || t.min_verified_xp, ',' order by t.min_verified_xp)
          from xp_rank_thresholds t where t.policy_version_id = active_policy_id('xp_ranks'))
    = 'tourist:0,traveler:500,explorer:1500,navigator:3500,cartographer:7000,geographer:12000,'
      'world_expert:20000,master_geographer:32000,world_master:50000', 'v1.3 rank thresholds';
  assert (select string_agg(slug, ',' order by position) from league_tiers)
    = 'bronze,silver,gold,platinum,diamond,world_elite', 'six league tiers';
  assert (select count(*) from leagues) = 6, 'leagues view';
  assert (select points from league_scoring_rules where rule_key = 'battle_win') = 15, 'battle win LP';
  assert (select min_distinct_correct from category_trophy_rules where tier = 'gold') = 200, 'gold rule';
  assert (select (config ->> 'practice_daily_cap')::int from game_policy_versions
          where policy_key = 'xp_awards' and is_active) = 300, 'practice cap';
end $$;

-- v1.3 A3: exactly 195 countries, unique keys, Holy See + Palestine, no Taiwan/Kosovo.
do $$ begin
  assert (select count(*) from country_catalog) = 195, '195 countries';
  assert (select count(*) from country_catalog where counts_toward_195) = 195, '195 counted';
  assert (select count(distinct iso3) from country_catalog) = 195, 'unique iso3';
  assert (select count(*) from country_catalog where un_status = 'un_member') = 193, '193 UN members';
  assert (select string_agg(iso2, ',' order by iso2) from country_catalog where un_status = 'un_observer') = 'PS,VA',
    'observer states';
  assert not exists (select 1 from country_catalog where iso2 in ('TW', 'XK')), 'denominator excludes TW/XK';
  assert (select country_count from country_catalog_versions) = 195, 'catalog version';
end $$;
-- The 196th counted country is refused.
do $$ begin
  begin
    insert into country_catalog (iso2, iso3, name, un_status, catalog_version_id)
    values ('XK', 'XKX', 'Kosovo', 'un_observer', (select id from country_catalog_versions limit 1));
    set constraints all immediate;
    raise exception 'should have failed';
  exception when raise_exception then
    if sqlerrm = 'should have failed' then raise; end if;
  end;
end $$;

-- Art pack (Claude Design): every role, trophy and the 7 mockup flags are wired up.
do $$ begin
  assert (select count(*) from character_art_assets where variant = 'bust' and bundle_path is not null
          and sha256 is not null and license_status = 'ai_generated_assigned'
          and provenance like 'ai_generated:claude_design%') = 16, 'art for all 16 roles';
  assert (select bundle_path from character_art_assets a join character_roles c on c.id = a.character_role_id
          where c.role_type = 'category_guide' and c.category_slug = 'explorers_pioneers_discoverers')
    like '%ibn-battuta-pathfinder.svg', 'Pathfinder outfit on the guide role';
  assert (select bundle_path from character_art_assets a join character_roles c on c.id = a.character_role_id
          where c.role_type = 'rank_legend' and c.rank_slug = 'traveler')
    like '%rank-2-traveler-ibn-battuta.svg', 'rank outfit on the legend role';
  assert (select count(*) from character_art_assets where cultural_review_status = 'pending') = 5,
    'cultural review pending for Ibn Battuta (x2), Zheng He, Al-Biruni, Hypatia';
  assert (select count(*) from trophy_definitions where art_bundle_dir is not null) = 16, 'trophy art';
  assert (select art_bundle_dir from trophy_definitions where slug = 'explorers_journal')
    = 'assets/art/trophies/golden-route-map', 'Explorer''s Journal uses the route-map medal';
  assert (select count(*) from country_catalog where flag_asset_status = 'sourced'
          and flag_asset_path = 'assets/flags/' || lower(iso2) || '.svg') = 195, 'all 195 flags sourced';
  assert (select count(*) from country_flag_assets where license = 'Public domain') = 194, '194 public domain';
  assert (select license from country_flag_assets where country_iso2 = 'OM') = 'OGL-om 1.0', 'Oman licence recorded';
  assert (select commons_title from country_flag_assets where country_iso2 = 'AF') like '%Afghanistan (2013%', 'AF tricolour';
  assert not exists (select 1 from country_flag_assets where 'terrorism' = any(restrictions)), 'no terrorism-tagged flag';
  assert (select count(*) from country_flag_assets where 'insignia' = any(restrictions)) > 150, 'insignia tags kept';
  assert not exists (select 1 from country_flag_assets where national_symbol_review <> 'pending'), 'legal review pending';
  assert not exists (select 1 from country_catalog where map_shape_status <> 'missing'), 'no map shapes yet';
end $$;

-- Cultural-accuracy requirements recorded; expert review still pending (never auto-approved).
do $$ begin
  assert (select count(*) from historical_people where depiction_brief is not null) = 4, 'four briefs';
  assert (select depiction_brief from historical_people where slug = 'zheng_he') like '%avoiding Qing%', 'Zheng He brief';
  assert (select biography from historical_people where slug = 'ibn_battuta') like '%Amazigh%Marinid%Rihla%', 'Ibn Battuta bio';
  assert not exists (select 1 from character_art_assets where cultural_review_status = 'approved'), 'no self-approval';
end $$;
