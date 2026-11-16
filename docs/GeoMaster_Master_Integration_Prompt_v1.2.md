# GeoMaster — Master Integration & Implementation Prompt v1.2

You are my senior Flutter/Dart architect, Supabase/PostgreSQL engineer, mobile UI implementer, educational game designer, content-pipeline engineer and QA lead. **Integrate three project inputs into one working, tested Android+iOS app**: (A) the existing GeoMaster product/engineering prompt, (B) my independently created `GEOMASTER_STYLE_GUIDE.md`, and (C) my 520-question testing bank and accompanying visuals. Implement the **seven-category** knowledge system and **GeoMaster Hall of Legends** described below. Do not merely summarize these files: implement the application incrementally, test it, and report what works.

## 0. Read these files before editing code

Find and read in full, in this priority order:
1. `GEOMASTER_STYLE_GUIDE.md` — **authoritative visual design specification**. It is a user-authored file and is NOT reproduced in this prompt. If it is missing, stop before any visual/UI implementation and ask me for it. Never invent its contents.
2. `GeoMaster_AI_Coding_Agent_Prompt_v1.1.md` (or the latest original GeoMaster prompt in the repository) — baseline product architecture and rules. If unavailable, use this document as the functional baseline and explicitly report the missing file.
3. `GeoMaster_520_Questions_and_Visuals.zip` and/or `GeoMaster_520_Test_Questions.json`, `GeoMaster_520_Test_Questions.csv` — **520 draft test questions**, including original IDs `GM-0001` through `GM-0520`, and SVG visuals. Prefer the ZIP as the asset package and JSON as canonical structured data; reconcile counts and checksums if both are provided. If absent, report and do not fabricate data.
4. Existing repository source code, migrations, environment templates, tests and documentation. Inspect before modifying; preserve functioning features.

**Conflict precedence:** explicit requirements in this v1.2 prompt > style guide for all visual matters > v1.1 prompt for existing functional architecture > existing code where compatible. For nonvisual behavior, v1.2 > v1.1. If the style guide conflicts with accessibility, platform security or app-store compliance, document the conflict and implement a safe accessible solution. Never overwrite the style guide; implement it via centralized tokens/components so future edits are easy.

First produce a short **integration audit**: files found/missing, current stack and functionality, design guide tokens and components discovered, schema of the question bank, migration impact, conflicts and execution plan. Then proceed phase by phase; ask only about genuinely blocking missing files/credentials or decisions.

## 1. Preserve the original GeoMaster concept

- Product: **GeoMaster** — balanced learning and competition, launching on **Android and iOS together**.
- Tagline/progress: **Master the World — X/195**, with country mastery independent of mastery in other subjects.
- Four primary bottom tabs: **Home / Learn / Compete / Profile**.
- Original gameplay: **Map Challenge, Flags, Capitals, Country Battle, Data Battle, Daily World Challenge**.
- Separate systems: XP/levels, country mastery, subject mastery, weekly leagues/rankings, GeoPoints wallet, streaks, badges, cosmetics and avatar ranks. No pay-to-win or purchasable knowledge badges.
- Nine original player ranks, in order: **Tourist, Traveler, Explorer, Navigator, Cartographer, Geographer, World Expert, Master Geographer, World Master**.
- Original stack: Flutter/Dart, Supabase Auth/Postgres/RLS/Storage/Edge Functions, local SQLite/Drift, Firebase Analytics/Crashlytics/opt-in Messaging, AdMob (consent-gated), RevenueCat, GitHub Actions. Prefer Riverpod and go_router unless existing architecture strongly warrants an alternative.
- Offline learning with later sync; competitive answers and score validation remain server-authoritative.

## 2. Seven main subject categories (mandatory)

Keep these seven first-class categories, with stable slugs, display names, subcategories, filters and independent mastery:

1. `geography_nature` — **Geography & Nature**: countries, capitals, flags, rivers, mountains, ranges, lakes, seas, oceans, deserts, islands, climate, landforms, maps and natural landmarks.
2. `history_civilizations` — **History & Civilizations**: ancient/medieval/modern periods, empires, changing borders, kingdoms, wars, treaties, historical coins/currencies, trade routes and timelines.
3. `economics_trade` — **Economics & Trade**: GDP, inflation, monetary systems, historical and present currencies, resources, industries, commerce, trade routes, economic institutions; date/metric/source required for dynamic comparisons.
4. `politics_world_affairs` — **Politics & World Affairs**: political systems, institutions, constitutions, treaties, historical geopolitics and political geography; factual, nonpartisan framing.
5. `space_astronomy` — **Space & Astronomy**: planets, dwarf planets, moons, comets, asteroids, stars, galaxies, constellations, nebulae, discoveries and missions.
6. `explorers_pioneers_discoverers` — **Explorers, Pioneers & Discoverers**: explorers/travelers, voyagers/navigators, astronomers/space discoverers, scientific pioneers, spaceflight pioneers, cartographers and their discoveries. Include questions about *who* discovered a planet, moon, river source, region, etc., and *when/how*; distinguish Indigenous or prior knowledge from later European records; avoid unqualified 'discovered' claims where inappropriate.
7. `connected_world` — **Connected World**: interdisciplinary questions connecting present-day geography with historical borders, rivers and trade, medieval coinage and regional politics, space discoveries and historical chronology, economics and exploration.

Questions may have a primary category and multiple secondary tags, but **only one primary category** for quotas and progression. A question on Galileo's discovery of Jupiter's moons may primarily belong to Explorers/Pioneers and secondarily Space/Astronomy. Add region, era, difficulty (1–5), topic, type and optional person/space-object tags.

**Question quality:** four plausible options for multiple choice, one defensible answer, informative explanation, source/provenance and editorial status. Historical questions must specify the time frame and distinguish formal political membership from military occupation; medieval currency questions must specify region/period and avoid claiming uniform monetary systems. Time-sensitive political/economic questions need a reference year, measure and credible source. Do not infer factual verification from an AI-generated explanation.

## 3. GeoMaster Hall of Legends (mandatory)

Implement **two distinct historical-character collections**: 9 rank legends and 7 category guides. Keep them separate from ordinary question subjects and avoid confusion when the same person appears elsewhere.

### 3a. Rank legends (9 unlockable trophies)

| Rank | Historical figure | Trophy |
|---|---|---|
| Tourist | Marco Polo | Traveler's Compass |
| Traveler | Ibn Battuta | Golden Travel Journal |
| Explorer | Zheng He | Treasure Fleet Ship |
| Navigator | Ferdinand Magellan | Ocean Astrolabe |
| Cartographer | Gerardus Mercator | Golden World Atlas |
| Geographer | Alexander von Humboldt | Earth's Ecosystem Globe |
| World Expert | Al-Biruni | Celestial Globe |
| Master Geographer | Eratosthenes | Golden Earth Sphere |
| World Master | Leonardo da Vinci | Crown of Knowledge |

Unlock based on validated overall rank progression; show biography, dates, historical region, historical contribution and collectible trophy. Explain that Magellan led but did not personally complete the first circumnavigation (Elcano completed it). Historical portrayals must be clearly stylized and educational, not presented as verified likenesses or real quotes.

### 3b. Category guides (7 mentors)

| Category | Figure | Guide title | Trophy |
|---|---|---|---|
| Geography & Nature | Strabo | The Atlas Keeper | Golden Atlas |
| History & Civilizations | Herodotus | The Timekeeper | Scroll of Ages |
| Economics & Trade | Adam Smith | The Market Sage | Golden Balance |
| Politics & World Affairs | Aristotle | The Statesman | Pillars of Wisdom |
| Space & Astronomy | Galileo Galilei | The Stargazer | Celestial Telescope |
| Connected World | Hypatia of Alexandria | The Knowledge Weaver | Orb of Knowledge |
| Explorers, Pioneers & Discoverers | Ibn Battuta | The Pathfinder | Explorer's Journal |

Ibn Battuta intentionally serves as both the Traveler rank legend and Explorers category mentor: **one historical-person record with two distinct character roles/collectibles**, not duplicate people. If the user later prefers another guide, make the assignment data-driven.

**Hall of Legends UI:** accessible from Profile and contextual category pages; separate `Rank Legends` and `Category Guides` tabs; locked/unlocked states; character portrait, biography, associated achievements, bronze/silver/gold category trophy tiers, collectible detail pages and optional mentor dialogue during lessons. Rank legends unlock via rank; category trophies unlock via verified category performance. Mentor hints must not reveal competitive answers. No fabricated historical quotes. Voice/animation is optional later; MVP supports portrait, short educational dialogue and simple animations.

**Art direction:** `GEOMASTER_STYLE_GUIDE.md` controls colors, fonts, spacing, cards, icons, illustrations and dark/light themes. Historical portraits should be original consistent stylized illustrations or properly licensed assets, with attribution/license records and fallbacks. **Do not scrape copyrighted images or assume web images are free to reuse.** Provide placeholder artwork where rights or assets are unavailable, without pretending placeholders are authentic portraits.

## 4. Screen map and user flows

- Onboarding: goals, language, privacy, age-appropriate settings, account/guest mode.
- Home: X/195 countries, subject mastery highlights, XP/streak, daily challenge, resume learning, league position, featured guide.
- Learn: **seven** subject tiles, subcategories, geography/era/difficulty filters, guide portraits, lessons and review queue.
- Question player: text/visual multiple choice, flag/map, diagrams, explanations, zoomable visuals, accessible text fallback; appropriate question formats and source context.
- Results: accuracy, verified XP, subject mastery, country mastery where applicable, badges and next-step CTA.
- Compete: Country Battle, Data Battle, mixed daily challenge, category challenges, weekly league, fair leaderboards.
- Profile: rank legend, achievements, GeoPoints, cosmetics, **Hall of Legends** entry and collections.
- Hall of Legends: collection overview, rank legends, category guides, locked/unlocked trophies, detail and biography.
- Country detail/world mastery map; category mastery dashboard; premium/store; settings, accessibility, consent, export and delete.

Implement navigation and UI using the style guide's actual components, not invented mockups. Responsive phone layouts, dynamic text sizes, screen-reader labels, reduced motion, high contrast, light/dark themes and Android/iOS safe areas are mandatory.

## 5. Database and trusted game logic

Create idempotent, versioned Supabase SQL migrations, RLS and indexes. Adapt to existing schema rather than blindly replacing it. Minimum entities:

- `profiles`, `user_settings`, `device_tokens`.
- `subject_categories`, `subject_subcategories`, `question_topics`, `question_topic_links`.
- `country_catalog`, `country_facts`, `content_versions`.
- `questions`, `question_options`, `question_assets`, `question_asset_links`, `question_sources`, `question_reviews`, `question_revisions`.
- `lessons`, `lesson_questions`, `user_learning_sessions`, `user_answers`, `country_mastery`, `subject_mastery`, `review_schedule`.
- `xp_ledger`, `geopoints_ledger`, `badge_definitions`, `user_badges`.
- `daily_challenges`, `competition_attempts`, `competition_answers`, `leagues`, `league_seasons`, `league_memberships`, `friendships`.
- `historical_people` (unique person), `character_roles` (rank_legend/category_guide), `rank_definitions`, `category_guide_assignments`, `trophy_definitions`, `user_trophies`, `mentor_dialogue`, `character_art_assets`.
- `cosmetic_catalog`, `user_cosmetics`, `store_purchases`, `subscriptions`.

Use normalized keys, unique constraints, check constraints and foreign keys. Seed seven categories, nine ranks, 15 unique historical people where applicable (the two Ibn Battuta roles share one record; total distinct people should be calculated from actual names), 16 role assignments (9+7), and trophy definitions. Historical content must have editorial status and source metadata. Note that exact distinct person count is **15** because Ibn Battuta is assigned twice.

**Security:** never expose active ranked-game answer keys to the client before submission; enforce user-scoped RLS; use server-side scoring, idempotent XP/currency awards, rate limits and replay protection; validate RevenueCat webhooks and entitlement states; never put service-role secrets in the app. Separate provisional offline XP from verified ranked outcomes. Content editorial status must gate live ranked use.

## 6. Import and validate the 520-question test bank

Expected JSON shape: root object with `schema_version`, `content_version`, `status`, `question_count`, `questions`. Each question contains `id` (`GM-0001`..`GM-0520`), `category`, `subcategory`, `question`, `options` (array of four), `correct_option` (zero-based), `correct_answer`, `explanation`, `difficulty` (1–5), `visual_asset` (nullable path such as `assets/river_1.svg`), `period`, `source_hint`, `review_status` (`draft_unverified`), `language`, `question_type`.

Tasks:
1. Inspect ZIP structure and JSON before import; inventory all visual paths and ensure no ZIP traversal or unsafe SVG content.
2. Verify exactly **520 unique IDs**, with original 500 preserved and 20 new explorer questions (`GM-0501`..`GM-0520`). Do not delete or overwrite the first 500; preserve IDs, question wording and answers unless a reviewed correction is explicitly approved.
3. Map original category strings to stable slugs; ensure all seven categories appear. Import image references, alt text and attribution metadata; use explicit placeholders for missing metadata, not invented licensing.
4. Validate four nonempty unique choices, zero-based correct index, matching `correct_answer`, explanation, difficulty, duplicate/near-duplicate prompts, visual path existence, consistent type, UTF-8, escaping, and date-sensitive facts. Produce a **QA report** and a reject/quarantine list.
5. Import via an idempotent, transactional seed command (e.g. `dart run tool/import_questions.dart` or a well-documented Python/SQL script). Preserve original raw JSON in a versioned archive. No duplicate rows on rerun.
6. **Draft test content only:** create a development/test mode where all 520 questions can be played and visuals inspected, but do not silently mark as verified or put them into production ranked games. A source hint is not a verified citation.
7. Build an admin/editorial path for approving corrected questions with evidence and version history. Avoid revealing answer keys in public read endpoints for competitive content.
8. Show import metrics by category, difficulty, visual/nonvisual, approved/draft, errors, and original/new question cohorts.

## 7. Build order and deliverables

**Phase A — Audit:** inspect inputs, produce integration matrix, verify style-guide availability, inspect current repository and 520 bank; list blockers.

**Phase B — Foundation:** integrate style tokens and reusable components, Flutter routing/state management, Supabase migrations/RLS, content models, CI and tests.

**Phase C — Test content:** secure idempotent import, visual asset pipeline, QA reports, 520-question sandbox and answer explanations.

**Phase D — Gameplay:** Home/Learn/Compete/Profile, seven subject flows, original geography modes, offline lessons/sync, mastery and trusted scoring.

**Phase E — Hall of Legends:** historical-person catalog, 9 rank legends, 7 category mentors, trophy rules, Hall screens, biographies, unlock tests and placeholder/licensed art.

**Phase F — Monetization & release:** AdMob/consent, RevenueCat/restore, Firebase, accessibility, localization readiness, privacy/data deletion, Android+iOS beta builds and app-store checklists.

At the end of each phase provide: files changed, schema migrations, screenshots or running previews where possible, commands run, test results, unresolved issues and next actions. Never claim a build passed if it was not executed. If iOS build requires a macOS runner unavailable locally, clearly report that limitation and configure CI appropriately.

## 8. Definition of done

- The existing app and design guide have been integrated without destroying existing work.
- Seven categories are visible and selectable; both country and subject mastery are tracked separately.
- 520 questions import once, re-import without duplication, and remain draft-only until verified.
- Visual questions load safely with alt text, fallback and zoom where appropriate.
- Home/Learn/Compete/Profile work on Android and iOS targets.
- Hall of Legends contains 9 rank legends + 7 category guides, with correct role assignments, historically responsible biographies, and earned-only unlocks.
- Offline learning syncs safely; ranked scores, XP and GeoPoints are server-authoritative.
- Automated tests cover import, migration, category mapping, trophy unlocks, answer validation, RLS and offline sync; CI is configured for both platforms.
- README explains local setup, env variables, seed command, test commands, asset licensing and release workflow.

**Start now:** read the named files, audit the repository and present a concrete implementation plan; then execute Phase B and Phase C first. Do not redesign the UI from scratch or replace the user's style guide with your own aesthetics.
