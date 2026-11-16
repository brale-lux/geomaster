# Changelog

## Unreleased

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
