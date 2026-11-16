# GeoMaster — Master Integration & Complete Implementation Specification v1.3

**Status:** consolidated implementation contract; replaces v1.2 and any hypothetical `GeoMaster_Master_Integration_Prompt_v1.1.md`. No v1.1 *Master Integration* document is required.

**Inputs required:** this file, `GEOMASTER_STYLE_GUIDE.md` (the user's own design guide), `GeoMaster_520_Questions_and_Visuals.zip` (or its JSON and visual assets), and the existing source repository. The style guide has not been provided here: **do not fabricate its contents**. The previous `GeoMaster_AI_Coding_Agent_Prompt_v1.1.md` is optional historical background, **not a dependency**. If it exists, read it for compatibility but this v1.3 document wins for functional rules; style guide wins for appearance, subject to accessibility/security.

## A. Definitive decisions and configuration (new in v1.3)

The following numerical thresholds and mechanics are **new proposed v1.3 defaults**, not recovered September decisions. They are now explicitly authorized as initial implementation defaults, kept in versioned database configuration and adjustable by administrators. Never hardcode them into UI widgets.

### A1. XP and nine rank thresholds

Overall lifetime *verified* XP determines the rank; XP never decreases. Rank unlock is automatic and idempotent. **Rank thresholds are cumulative minimum XP**:

| Rank | Key | Cumulative XP | Legend |
|---|---|---:|---|
| Tourist | `tourist` | 0 | Marco Polo |
| Traveler | `traveler` | 500 | Ibn Battuta |
| Explorer | `explorer` | 1,500 | Zheng He |
| Navigator | `navigator` | 3,500 | Ferdinand Magellan |
| Cartographer | `cartographer` | 7,000 | Gerardus Mercator |
| Geographer | `geographer` | 12,000 | Alexander von Humboldt |
| World Expert | `world_expert` | 20,000 | Al-Biruni |
| Master Geographer | `master_geographer` | 32,000 | Eratosthenes |
| World Master | `world_master` | 50,000 | Leonardo da Vinci |

XP award rules, **first eligible completion per question per UTC day**: correct practice answer +10 XP; incorrect answer +2 XP for genuine completed attempts; completed 10-question lesson +20 XP once per lesson per UTC day; first daily challenge completion +30 XP once/day; daily perfect-score bonus +20 XP once/day. Cap practice XP to 300/day and total noncompetitive XP to 400/day; daily challenge awards are separate and capped at 50/day. Replays do not generate repeat awards for the same question/day. Admin-adjustable XP policies are versioned and ledgered; a change is prospective, never retroactively rewrite earned XP. Server must validate all permanent awards; offline practice rewards are provisional until synced and validated. No XP for simply opening a screen or purchasing anything. Level numbers, if shown, are cosmetic sublevels computed from a separately versioned formula and must not conflict with rank thresholds.

### A2. League system — fully specified

**League tiers (ascending):** `bronze`, `silver`, `gold`, `platinum`, `diamond`, `world_elite`. This is separate from the nine XP ranks and Hall of Legends. Seasons run **Monday 00:00 UTC through Sunday 23:59:59 UTC**. New players enter Bronze on first verified ranked participation. Use **groups of up to 30 players** within the same tier, assigned by backend deterministically and without reshuffling during a season; unfilled groups are allowed. No fabricated bots.

**League points (LP):** eligible daily challenge = +10 LP for completion plus +2 per correct answer (maximum 30 LP for a 10-question challenge); first 3 verified asynchronous ranked battles/day = +15 LP for win, +7 LP for draw, +3 LP for loss. A player may receive LP only once per daily challenge and for at most three battles/day. Practice, hints, purchases and unverified/offline play yield zero LP. Ranking sorts by LP descending, then verified daily-challenge correct answers descending, then earliest timestamp reaching final LP, then stable user ID. Record UTC timestamps and award idempotency keys.

**Season movement:** In groups with **10+ active participants** (active = at least one LP-earning activity), top 20% (ceil) promote one tier, bottom 20% (floor) relegate one tier; others remain. At most one tier change per season. In groups with fewer than 10 active participants, no relegation; promote top 1 if at least 3 active participants. Bronze cannot relegate; World Elite cannot promote. Inactive users (0 LP) are not eligible for promotion and do not count as active; they retain their tier and are excluded from bottom-percent calculations. Group ranks and promotions are snapshotted in a single idempotent server-side season-close transaction. For a tie across a boundary use the stated tie-breakers; never arbitrarily promote an extra tied player. Store season and scoring-policy version on every record. Daily and weekly boundaries always UTC. No monetary prize or wagering mechanics.

**Battle specification:** initial ranked mode is asynchronous, not live multiplayer. Opponents answer the same versioned 10-question set without receiving answers until their attempt is finalized; higher correct count wins, then shorter valid completion time, else draw. A player may complete a maximum of three LP-eligible battles per UTC day; subsequent battles are unranked. Avoid matching an account against itself, rate-limit retries and use server-validated timestamps. An unanswered/abandoned battle yields no LP. If there is insufficient reviewed content, keep ranked mode disabled and allow sandbox simulation only.

### A3. Definitive country scope

Exactly **195 country records**: **193 UN member states + Holy See and State of Palestine (UN non-member observer states)**. The separately supplied `GeoMaster_Country_Catalog_195_v1.3.json` is the **canonical explicit allowlist**; embed/copy it into the repository under `assets/data/` and create an idempotent seed migration. Its stable keys are ISO 3166-1 alpha-2/alpha-3; names are display labels and may change without changing IDs. **Do not add Taiwan, Kosovo, dependencies or territories to the 195 mastery denominator.** This is a content-scope convention, not a judgment on sovereignty or disputed status. Other places may appear as geographic/historical question topics, clearly labeled. Include source/provenance notes and support localized names, boundary/map-data caveats, and editorial review. For Palestine and Holy See, store the chosen code conventions and check map asset coverage; never silently drop either if an SVG map lacks it. Country mastery count must never exceed 195.

**Country mastery:** track per-country verified mastery score 0–100, distinct from subject mastery. Score = average of the last up to 10 verified, country-linked practice answers (correct=100, incorrect=0) with a minimum of 5 distinct question IDs across at least 2 distinct sessions on separate UTC dates; until minimum evidence, status is `learning`. `mastered` requires score >=80 and at least 5 distinct question IDs, at least 2 dates and at least 2 content types (e.g. map and capital/flag). For score decline below 80 after later reviewed practice, mark `review_due`, but keep lifetime mastered achievement separately for historical statistics; X/195 **current mastered** counts only `mastered`. Do not assign country mastery to unrelated astronomy/history questions without a legitimate country relation. Category mastery is separately measured by verified question accuracy and topic coverage, with clear versioned rules.

### A4. Category trophy tiers and mentors

Seven category guides and nine rank legends remain as in v1.2. **Category bronze:** 20 distinct verified correct questions in category, across >=2 subtopics. **Silver:** 75 distinct verified correct questions, >=4 subtopics, >=75% accuracy across last 50 verified attempts. **Gold:** 200 distinct verified correct questions, >=5 subtopics, >=85% accuracy across last 100 verified attempts, on >=5 different UTC dates. If category has insufficient approved question inventory, display trophy as `not_yet_available`, never award by repeating one item. Earned trophies remain earned; criteria changes require versioned award records. One `historical_people` record for Ibn Battuta, two separate roles. All trophies are cosmetic, not purchasable competitive boosts.

### A5. Content model and moderation

Use seven exact category slugs from v1.2. Each question has one primary category, optional secondary categories, era, region, difficulty 1–5, answer format, visual metadata/alt text, explanation, source citations/URLs and license status. Editorial states: `draft_unverified`, `needs_review`, `approved`, `rejected`, `retired`. Only `approved` questions with valid rights and references can be served in ranked games. All **520 supplied questions remain draft** on import; test-only mode may use them without granting permanent XP, LP or collectible unlocks. Do not silently promote them to approved. For ambiguous historical questions, require precise time frame and wording. For politics/economics, require data reference date, definition and source. Include audit and human review workflows.

### A6. Required database details and permissions

Use the complete table inventory from the v1.2 section below, plus `game_policy_versions`, `xp_rank_thresholds`, `league_tiers`, `league_groups`, `league_scoring_rules`, `league_season_snapshots`, `country_catalog_versions`, `user_country_mastery_evidence`, `category_trophy_rules`, `question_editorial_events`, and `award_idempotency_keys`. Key constraints: unique `(season_id,user_id)` membership; unique `(user_id,source_event_id,award_type)` ledger awards; unique `(question_id,revision)` revision; unique `(country_iso2)`; unique `(category_slug)`; unique `(historical_person_id,role_type,role_key)`. Define indices for player/season/category queries and enforce RLS on every exposed table. Public reads only for non-sensitive approved content and public profile fields; private progress restricted to owner; admin-only editing and approval; competitive answer keys never exposed pre-submit. Privileged scoring and league close run server-side in transactions with replay/race protection. Include migrations, seeds, rollback notes, tests and example environment file without secrets.

### A7. Concrete routes, offline sync and release

Flutter routes: `/onboarding`, `/home`, `/learn`, `/learn/:category`, `/quiz/:sessionId`, `/results/:sessionId`, `/compete`, `/compete/daily`, `/compete/battle/:id`, `/compete/leagues`, `/profile`, `/profile/hall`, `/profile/hall/:roleId`, `/profile/mastery`, `/countries/:iso2`, `/settings`, `/premium`. Four persistent tabs Home/Learn/Compete/Profile. Guest users may play sandbox learning locally; permanent awards/sync require account authentication. Use Drift local storage and an idempotent event outbox with UUID, source timestamp, schema/content version and server acknowledgment; do not trust client clocks for reward eligibility. Detect stale question revisions; never overwrite newer server progress with stale local values. Display offline/sync status and handle conflict/retry. Both Android and iOS launch together; if iOS signing unavailable, configure macOS CI and report blocked signing steps rather than claim success. App-store age/consent, account deletion, privacy policy, rights for portraits, and subscription restoration are required.

### A8. Implementation order and explicit no-missing-document rule

1. Read this v1.3 specification, the user-supplied style guide, question ZIP/JSON, and repo. **Never request `GeoMaster_Master_Integration_Prompt_v1.1.md`.** No XP/league/country specifications are missing: use A1–A3 and the country JSON.
2. Audit files and list blockers; the style guide is required for actual UI work, and bank assets required for import. Do not invent either.
3. Integrate design tokens, migrations, country allowlist, categories, ranks, leagues, Hall of Legends, editorial states.
4. Import 520 questions into draft sandbox; validate assets, category mapping, question integrity and run QA reports.
5. Build functional learning, offline sync, mastery and secure scoring, then ranked modes using approved content only.
6. Implement character guides, unlocks and collectible screens; integrate analytics/ads/premium only with consent and store compliance.
7. Run tests for rank boundaries (0,499,500,1499,1500,49999,50000), country count/uniqueness (195), promotion/relegation with small/large groups, duplicate award prevention, question review gating, import repeatability, RLS, offline replay and Android/iOS builds.

**Deliverables:** functional code, SQL migrations/seeds, updated README, QA reports, test results, change log, build instructions and unresolved issues. Work in milestones and do not claim unrun tests passed.

---

## B. Preserved v1.2 functional requirements (incorporated verbatim below)

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
