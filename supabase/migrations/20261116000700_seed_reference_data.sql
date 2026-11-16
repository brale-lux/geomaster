-- GeoMaster 0700: reference seed data (idempotent upserts).
-- 7 categories, 9 ranks, 15 distinct historical people, 16 roles (9 rank legends + 7 guides),
-- 7 guide assignments, 16 trophy definitions.
-- Biographies are short draft educational summaries (biography_status = draft_unverified)
-- pending editorial review; they contain no quotations.

insert into public.subject_categories (slug, display_name, description, sort_order, style_token_key) values
  ('geography_nature', 'Geography & Nature',
   'Countries, capitals, flags, rivers, mountains, lakes, seas, oceans, deserts, islands, climate, landforms, maps and natural landmarks.', 1, 'geography_nature'),
  ('history_civilizations', 'History & Civilizations',
   'Ancient, medieval and modern periods, empires, changing borders, kingdoms, wars, treaties, historical coins and currencies, trade routes and timelines.', 2, 'history_civilizations'),
  ('economics_trade', 'Economics & Trade',
   'GDP, inflation, monetary systems, historical and present currencies, resources, industries, commerce, trade routes and economic institutions.', 3, 'economics_trade'),
  ('politics_world_affairs', 'Politics & World Affairs',
   'Political systems, institutions, constitutions, treaties, historical geopolitics and political geography, framed factually and without partisanship.', 4, 'politics_world'),
  ('space_astronomy', 'Space & Astronomy',
   'Planets, dwarf planets, moons, comets, asteroids, stars, galaxies, constellations, nebulae, discoveries and missions.', 5, 'space_astronomy'),
  ('explorers_pioneers_discoverers', 'Explorers, Pioneers & Discoverers',
   'Explorers and travellers, navigators, astronomers, scientific and spaceflight pioneers, cartographers, and who recorded which discoveries, when and how.', 6, 'explorers_pioneers_discoverers'),
  ('connected_world', 'Connected World',
   'Interdisciplinary questions linking geography, history, trade, coinage, politics, space discoveries and exploration.', 7, 'connected_world')
on conflict (slug) do update set
  display_name = excluded.display_name, description = excluded.description,
  sort_order = excluded.sort_order, style_token_key = excluded.style_token_key;

-- XP thresholds are placeholders (v1.1 prompt unavailable); tune as data, not code.
insert into public.rank_definitions (slug, position, display_name, min_verified_xp) values
  ('tourist', 1, 'Tourist', 0),
  ('traveler', 2, 'Traveler', 1000),
  ('explorer', 3, 'Explorer', 3000),
  ('navigator', 4, 'Navigator', 7000),
  ('cartographer', 5, 'Cartographer', 15000),
  ('geographer', 6, 'Geographer', 30000),
  ('world_expert', 7, 'World Expert', 60000),
  ('master_geographer', 8, 'Master Geographer', 120000),
  ('world_master', 9, 'World Master', 250000)
on conflict (slug) do nothing;

insert into public.historical_people
  (slug, display_name, lifespan_label, era_label, historical_region, contribution_summary, biography, source_notes)
values
  ('marco_polo', 'Marco Polo', 'c. 1254 – 1324', 'Late medieval', 'Venice; Yuan-dynasty China; Silk Road',
   'Venetian merchant whose travel account described Asia to European readers.',
   'Marco Polo travelled overland to the court of the Yuan dynasty in the late 13th century. The book of his travels, written down with Rustichello da Pisa, became one of the best-known European descriptions of Asia. Historians debate some details of the account.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('ibn_battuta', 'Ibn Battuta', '1304 – c. 1368/69', 'Late medieval', 'Morocco; North Africa, Middle East, South and East Asia, West Africa',
   'Moroccan traveller whose Rihla records some three decades of journeys across Afro-Eurasia.',
   'Ibn Battuta left Tangier in 1325 on pilgrimage and kept travelling for about thirty years, through North and West Africa, the Middle East, Central and South Asia and possibly China. His account, the Rihla, was dictated to the scholar Ibn Juzayy. Some passages are debated by historians.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('zheng_he', 'Zheng He', '1371 – c. 1433/35', 'Ming dynasty', 'Ming China; Indian Ocean',
   'Ming admiral who commanded seven large maritime expeditions across the Indian Ocean.',
   'Zheng He commanded the Ming treasure fleets on seven voyages between 1405 and 1433, reaching Southeast Asia, India, the Arabian Peninsula and the East African coast. The voyages were diplomatic and commercial as well as naval.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('ferdinand_magellan', 'Ferdinand Magellan', 'c. 1480 – 1521', 'Age of Sail', 'Portugal; Spain; Pacific Ocean',
   'Led the Spanish expedition of 1519–1522 that became the first circumnavigation; he died before it was completed.',
   'Ferdinand Magellan, a Portuguese navigator sailing for Spain, led the expedition that left in 1519 and passed through the strait now named after him into the Pacific. Magellan was killed in the Philippines in 1521, so he did not personally complete the circumnavigation; Juan Sebastián Elcano brought the remaining ship back to Spain in 1522.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('gerardus_mercator', 'Gerardus Mercator', '1512 – 1594', 'Renaissance', 'Flanders; Duisburg',
   'Cartographer known for the 1569 world map projection that bears his name and for popularising the word "atlas".',
   'Gerardus Mercator was a Flemish cartographer and globe maker. His 1569 world map introduced a projection that keeps compass bearings as straight lines, useful for navigation, while enlarging areas far from the equator.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('alexander_von_humboldt', 'Alexander von Humboldt', '1769 – 1859', 'Enlightenment / 19th century', 'Prussia; the Americas',
   'Naturalist and explorer whose travels in the Americas shaped modern physical geography and ecology.',
   'Alexander von Humboldt travelled through Spanish America from 1799 to 1804, measuring climate, altitude and plant life. His work linked these observations into a picture of nature as an interconnected system.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('al_biruni', 'Al-Biruni', '973 – c. 1050', 'Islamic Golden Age', 'Khwarazm; Ghazni; South Asia',
   'Scholar of astronomy, mathematics and geography who estimated the Earth''s radius and wrote a major study of India.',
   'Abu Rayhan al-Biruni worked in Central Asia and at the Ghaznavid court. He wrote on astronomy, mathematics, geodesy and comparative culture, including a method for estimating the Earth''s radius from a mountain-top observation and a detailed study of India.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('eratosthenes', 'Eratosthenes', 'c. 276 – c. 194 BCE', 'Hellenistic', 'Cyrene; Alexandria',
   'Greek scholar who estimated the Earth''s circumference and helped found geography as a discipline.',
   'Eratosthenes of Cyrene was chief librarian at Alexandria. He estimated the Earth''s circumference by comparing the Sun''s angle at Syene and Alexandria, and is credited with using the word "geography".',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('leonardo_da_vinci', 'Leonardo da Vinci', '1452 – 1519', 'Italian Renaissance', 'Florence; Milan; France',
   'Artist, engineer and observer of nature whose notebooks include maps, anatomy and studies of water and landscape.',
   'Leonardo da Vinci was a painter, engineer and investigator of the natural world. Alongside his art he produced detailed maps, such as a plan of Imola, and notebook studies of rivers, geology and flight.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('strabo', 'Strabo', 'c. 64 BCE – c. 24 CE', 'Roman era', 'Amaseia (Pontus); Rome; Alexandria',
   'Greek geographer whose Geographica describes the known world of his time.',
   'Strabo was a Greek geographer and historian from Amaseia in Asia Minor. His Geographica, in seventeen books, describes the peoples and places of the world known to Greeks and Romans of the early Roman Empire.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('herodotus', 'Herodotus', 'c. 484 – c. 425 BCE', 'Classical Greece', 'Halicarnassus; Athens; Thurii',
   'Greek writer of the Histories, often called the first historian.',
   'Herodotus of Halicarnassus wrote the Histories, an inquiry into the Greco-Persian Wars that also describes the geography and customs of many peoples. Some of his reports are based on hearsay, which he often notes himself.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('adam_smith', 'Adam Smith', '1723 – 1790', 'Scottish Enlightenment', 'Scotland',
   'Moral philosopher and economist, author of The Wealth of Nations (1776).',
   'Adam Smith was a Scottish philosopher whose 1776 book An Inquiry into the Nature and Causes of the Wealth of Nations analysed the division of labour, markets and trade, and became a founding text of modern economics.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('aristotle', 'Aristotle', '384 – 322 BCE', 'Classical Greece', 'Stagira; Athens',
   'Greek philosopher whose Politics compared constitutions and forms of government.',
   'Aristotle studied at Plato''s Academy and later founded the Lyceum in Athens. In the Politics he and his students compared the constitutions of many Greek city-states and classified forms of government.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('galileo_galilei', 'Galileo Galilei', '1564 – 1642', 'Scientific Revolution', 'Pisa; Padua; Florence',
   'Astronomer and physicist who used the telescope to observe Jupiter''s four largest moons in 1610.',
   'Galileo Galilei improved the telescope and in 1610 published observations of the Moon''s surface, many new stars, and four moons orbiting Jupiter. His support for a Sun-centred system led to his trial by the Roman Inquisition in 1633.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.'),
  ('hypatia_of_alexandria', 'Hypatia of Alexandria', 'c. 350/370 – 415 CE', 'Late antiquity', 'Alexandria (Roman Egypt)',
   'Mathematician, astronomer and philosopher who taught in Alexandria.',
   'Hypatia taught mathematics, astronomy and Neoplatonic philosophy in Alexandria and is associated with commentaries on earlier mathematical and astronomical works. She was killed by a mob in 415 CE during political and religious conflict in the city.',
   '[EDITORIAL] Verify against a scholarly encyclopedia entry before approval.')
on conflict (slug) do nothing;

-- Rank legends (9).
insert into public.character_roles (person_id, role_type, rank_slug)
select p.id, 'rank_legend', r.rank_slug
from (values ('tourist', 'marco_polo'), ('traveler', 'ibn_battuta'), ('explorer', 'zheng_he'),
             ('navigator', 'ferdinand_magellan'), ('cartographer', 'gerardus_mercator'),
             ('geographer', 'alexander_von_humboldt'), ('world_expert', 'al_biruni'),
             ('master_geographer', 'eratosthenes'), ('world_master', 'leonardo_da_vinci'))
     as r(rank_slug, person_slug)
join public.historical_people p on p.slug = r.person_slug
where not exists (select 1 from public.character_roles c
                  where c.role_type = 'rank_legend' and c.rank_slug = r.rank_slug);

-- Category guides (7).
insert into public.character_roles (person_id, role_type, category_slug, guide_title)
select p.id, 'category_guide', g.category_slug, g.title
from (values ('geography_nature', 'strabo', 'The Atlas Keeper'),
             ('history_civilizations', 'herodotus', 'The Timekeeper'),
             ('economics_trade', 'adam_smith', 'The Market Sage'),
             ('politics_world_affairs', 'aristotle', 'The Statesman'),
             ('space_astronomy', 'galileo_galilei', 'The Stargazer'),
             ('connected_world', 'hypatia_of_alexandria', 'The Knowledge Weaver'),
             ('explorers_pioneers_discoverers', 'ibn_battuta', 'The Pathfinder'))
     as g(category_slug, person_slug, title)
join public.historical_people p on p.slug = g.person_slug
where not exists (select 1 from public.character_roles c
                  where c.role_type = 'category_guide' and c.person_id = p.id
                    and c.category_slug = g.category_slug);

insert into public.category_guide_assignments (category_slug, character_role_id)
select c.category_slug, c.id from public.character_roles c
where c.role_type = 'category_guide'
on conflict (category_slug) do nothing;

-- Trophies: 9 rank trophies (single) + 7 category trophies (bronze/silver/gold).
insert into public.trophy_definitions (slug, character_role_id, name, icon_key, tiered, unlock_rule)
select t.slug, c.id, t.name, t.icon, false,
       jsonb_build_object('type', 'rank_reached', 'rank_slug', t.key)
from (values ('travelers_compass', 'tourist', 'Traveler''s Compass', 'compass'),
             ('golden_travel_journal', 'traveler', 'Golden Travel Journal', 'journal'),
             ('treasure_fleet_ship', 'explorer', 'Treasure Fleet Ship', 'ship'),
             ('ocean_astrolabe', 'navigator', 'Ocean Astrolabe', 'astrolabe'),
             ('golden_world_atlas', 'cartographer', 'Golden World Atlas', 'atlas'),
             ('earths_ecosystem_globe', 'geographer', 'Earth''s Ecosystem Globe', 'globe'),
             ('celestial_globe', 'world_expert', 'Celestial Globe', 'celestial'),
             ('golden_earth_sphere', 'master_geographer', 'Golden Earth Sphere', 'sphere'),
             ('crown_of_knowledge', 'world_master', 'Crown of Knowledge', 'crown'))
     as t(slug, key, name, icon)
join public.character_roles c on c.role_type = 'rank_legend' and c.rank_slug = t.key
on conflict (slug) do nothing;

insert into public.trophy_definitions (slug, character_role_id, name, icon_key, tiered, unlock_rule)
select t.slug, c.id, t.name, t.icon, true,
       jsonb_build_object('type', 'category_performance', 'category_slug', t.key,
                          'tiers', jsonb_build_object(
                            'bronze', jsonb_build_object('min_verified_correct', 25, 'min_accuracy', 0.6),
                            'silver', jsonb_build_object('min_verified_correct', 100, 'min_accuracy', 0.75),
                            'gold', jsonb_build_object('min_verified_correct', 250, 'min_accuracy', 0.85)))
from (values ('golden_atlas', 'geography_nature', 'Golden Atlas', 'atlas'),
             ('scroll_of_ages', 'history_civilizations', 'Scroll of Ages', 'scroll'),
             ('golden_balance', 'economics_trade', 'Golden Balance', 'balance'),
             ('pillars_of_wisdom', 'politics_world_affairs', 'Pillars of Wisdom', 'pillars'),
             ('celestial_telescope', 'space_astronomy', 'Celestial Telescope', 'telescope'),
             ('orb_of_knowledge', 'connected_world', 'Orb of Knowledge', 'orb'),
             ('explorers_journal', 'explorers_pioneers_discoverers', 'Explorer''s Journal', 'journal'))
     as t(slug, key, name, icon)
join public.category_guide_assignments a on a.category_slug = t.key
join public.character_roles c on c.id = a.character_role_id
on conflict (slug) do nothing;

-- Placeholder art records: visibly placeholders, no portraits, licensing pending.
insert into public.character_art_assets (person_id, character_role_id, variant, is_placeholder, alt_text)
select c.person_id, c.id, 'bust', true,
       '[PLACEHOLDER] Stylised illustration of ' || p.display_name || ' to come. Not a likeness.'
from public.character_roles c join public.historical_people p on p.id = c.person_id
where not exists (select 1 from public.character_art_assets a where a.character_role_id = c.id);

-- League tiers are intentionally not seeded yet: names/tiers come from the v1.1 spec (missing).
