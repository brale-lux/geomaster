# Changelog

## Unreleased

### Country flags (2026-11-17)
- All 195 flags fetched from Wikimedia Commons (`tool/fetch_flags.py`) at their true proportions, sanitised,
  with per-file licence, author and restriction tags (`assets/flags/MANIFEST.json`, `country_flag_assets`).
- Afghanistan uses the 2013–2021 tricolour flown at the UN, per the owner's decision.
- National-symbol legal review is tracked per flag (`national_symbol_review = 'pending'`).

### Cultural accuracy (2026-11-17)
- Recorded the owner's depiction requirements for Ibn Battuta, Zheng He, Al-Biruni and Hypatia
  (`historical_people.depiction_brief`, `docs/CULTURAL_ACCURACY.md`).
- Edited their interim SVGs: removed South Asian cues (turban jewels, forehead ornament), Ming round collar
  and rank badge for Zheng He, and added the Rihla manuscript, an astrolabe and a papyrus scroll.
- Updated their biographies (Amazigh background and Marinid Morocco; Ming diplomat; Khwarazm and the
  Persianate tradition; Greek-speaking Roman Alexandria). Expert review is still pending.

### Art pack (2026-11-16)
- Added the owner's Claude Design SVG pack under `assets/art/` (characters, trophies, Pip, brand, icons, flags),
  validated against the SVG safety allow-list and checksummed.
- `tool/generate_art_seed.py` wires character busts, trophy medal folders and the 7 mockup flags into the
  database with provenance; CI fails if generated seeds drift from the files.
- "Explorer's Journal" uses the route-map medal art; the Pathfinder bust is used only on Ibn Battuta's guide role.

### v1.3 specification update (2026-11-16)
- Adopted the v1.3 development package: XP rank thresholds (0 → 50,000), versioned game policies,
  six league tiers with weekly UTC seasons, groups of up to 30, LP scoring rules and an idempotent
  season-close with promotion/relegation snapshots.
- Seeded the canonical 195-country allowlist (193 UN members + Holy See + State of Palestine) from
  `assets/data/GeoMaster_Country_Catalog_195_v1.3.json`, with a hard cap of 195 counted countries.
- Country mastery now follows v1.3 A3 (score 0–100, `learning`/`mastered`/`review_due`, evidence table).
- Category trophy tiers follow v1.3 A4 (20/75/200 distinct correct, subtopic, accuracy and date rules)
  and report `not_yet_available` when approved inventory is too small.
- Editorial state `in_review` renamed `needs_review`; every status change is logged in `question_editorial_events`.
- Ledgers use `(user_id, source_event_id, award_type)` uniqueness plus `award_idempotency_keys`; XP is never negative.
- Style guide and tokens updated to the owner's new version: Ibn Battuta's "The Pathfinder" guide outfit
  (`visual_variant = 'guide'`) and route icon. Category and trophy names stay as in v1.3 (owner's decision).
- Question SVG provenance recorded as drawn with Claude Design; font OFL licences added.

### Initial data foundation
- Supabase schema, RLS, Hall of Legends seeds, 520-question draft import, QA report and tests.
