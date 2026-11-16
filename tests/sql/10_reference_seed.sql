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
end $$;
