# GeoMaster integration audit (Phase A)

> **Update 2026-11-16 (v1.3):** the owner supplied the v1.3 development package, which supersedes v1.2
> and replaces the missing v1.1 document, plus an updated style guide. See §8 below; §1–§7 describe the
> first pass and are kept for history.

Date: 2026-11-16. Scope of this pass, as agreed: repository audit, database integration and
question-bank import. Phases B (Flutter foundation/UI) and D–F are not started.

## 1. Inputs

| Input | Status | Notes |
|---|---|---|
| `GeoMaster_Master_Integration_Prompt_v1.2.md` | Found | Copied verbatim to `docs/`. Functional baseline for this work. |
| `GEOMASTER_STYLE_GUIDE.md` (v1.0) | Found | Copied verbatim to `design/`. Not modified. Authoritative for all visuals. |
| `design_tokens.json` (1.0.0) | Found | Copied verbatim to `design/`. |
| `geomaster_theme.dart` | Found | Copied verbatim to `design/`; becomes the Flutter theme in Phase B. |
| `GeoMaster_AI_Coding_Agent_Prompt_v1.1.md` | **Missing** | Not in the project files or any repository. Per v1.2 §0 the v1.2 prompt is used as the functional baseline. Values that only v1.1 would define are marked as placeholders below. |
| `GeoMaster_520_Questions_and_Visuals.zip` | Found | 30 entries: JSON, CSV, `README_ADDENDUM.txt`, 27 SVGs. No traversal, symlink or encrypted entries. Archived unchanged in `content/raw/geomaster-test-2026-11-plus20/` with `SHA256SUMS`. |
| JSON vs CSV | Reconciled | 520 rows in both; every field matches row-for-row. JSON treated as canonical. |

## 2. Repository

`brale-lux/geomaster` was empty (no commits) when this work started, so there was no existing app,
schema, test or document to preserve. The only other repository on the account, `brale-lux/bokako`,
is an unrelated Next.js storefront and was not touched.

## 3. Style guide: tokens and components found

* Two themes: `GeoTheme.dark()` "Game show" (default) and `GeoTheme.light()` "Playful".
* Brand colours (navy family, teal `#19B891`, gold `#F4C35C`, `tealInk` for teal text on light),
  feedback (alert orange `#C2410C`), mastery status colours, bronze/silver/gold trophy tiers,
  signature gradients.
* Type scale, radii, spacing, hard-drop elevation, motion durations with a reduced-motion fade.
* Components: buttons, A–D answer bar, question panel, lifelines (practice only), timer ring, HUD,
  4-tab bottom navigation, category tiles, progress, podium, results, avatars, hex plate shape.
* Hall of Legends character style (chibi busts, locked silhouettes, pedestal, hex trophy medal)
  with per-character visual cues.

No UI was built in this pass, so no visual decisions were made. The DB stores only data keys
(`icon_key`, `style_token_key`) that the Phase B Flutter code will map to these tokens.

## 4. Conflicts found and how they were handled

| # | Conflict | Resolution |
|---|---|---|
| 1 | `design_tokens.json` uses category key `politics_world`; v1.2 requires slug `politics_world_affairs`. | DB slug follows v1.2 (non-visual precedence). `subject_categories.style_token_key` stores `politics_world` so the UI can find the token. Style files not edited. |
| 2 | Style guide and tokens list **6** category guides; v1.2 requires **7** (Ibn Battuta, "The Pathfinder", Explorers category, trophy "Explorer's Journal"). | Seeded 7 per v1.2. **Needs your input before Phase E art:** the style guide has no visual cues row or token entry for the Pathfinder role. Ibn Battuta's rank-legend cues (white turban, dark beard, green robe) are the obvious fallback, but I have not assumed it. |
| 3 | Rank XP thresholds, league tiers, the 195-country list and XP/GeoPoints values would come from v1.1, which is missing. | Rank thresholds seeded as clearly-labelled placeholders (0 / 1k / 3k / 7k / 15k / 30k / 60k / 120k / 250k) stored as data. Leagues and countries **not** seeded. |
| 4 | v1.2 asks for "Explorer's Journal" for Explorers; rank legend trophy is "Golden Travel Journal". Both use a journal icon. | Kept as two distinct trophy rows on two distinct roles of one person row, as v1.2 specifies. |

## 5. Question bank

* Root: `schema_version` 1.1, `content_version` `geomaster-test-2026-11-plus20`, `status` DRAFT_UNVERIFIED, `question_count` 520.
* Every question has exactly the 15 fields v1.2 §6 expects. All `multiple_choice`, `en`, `draft_unverified`.
* 520 unique IDs, GM-0001..GM-0520 contiguous. GM-0501..0520 are all Explorers, Pioneers & Discoverers.
* By category: Geography & Nature 110, History & Civilizations 100, Economics & Trade 85, Space & Astronomy 85,
  Politics & World Affairs 70, Connected World 50, Explorers 20.
* Difficulty: 1→36, 2→256, 3→197, 4→31, 5→0.
* 27 visual questions, 27 SVGs, all referenced, all pass the SVG allow-list (no script, events,
  external references, DOCTYPE/entities, foreignObject or image elements).
* Correct-answer position is skewed toward A (172 / 121 / 122 / 105); the app should shuffle option order at display time.
* **0 hard errors, 0 quarantined, 18 editorial warnings** (see `reports/QA_REPORT.md`):
  4 time-sensitive prompts without a reference year, 6 lower-case acronyms (`un`, `eu`, `us`),
  4 prompts that contain the answer text, 4 explorer questions with "discovered" wording to review.
* Missing metadata, recorded as explicit placeholders, not invented: SVG licence (`pending_review`),
  author/attribution (`[PLACEHOLDER]`). Alt text is auto-derived from each SVG's own text labels and flagged `auto_from_svg_text`.

## 6. Migration impact

Greenfield: nine idempotent migrations in `supabase/migrations/` create every entity listed in v1.2 §5
(plus `daily_challenge_questions` and `import_runs`), with foreign keys, unique and check constraints,
indexes and RLS on all 50 tables. Running them twice is a no-op (tested).

## 7. Plan for the next phases

1. **Phase B:** Flutter app skeleton (Riverpod, go_router, Drift) using `design/geomaster_theme.dart`
   as the single theme source; 4-tab shell; Supabase client with anon key only; Android + iOS CI.
2. **Phase C (remaining):** upload sanitised SVGs to the `question-assets` Storage bucket; Flutter sandbox
   screen over `get_sandbox_questions` / `check_sandbox_answer`; editor review screen over the editorial RPCs.
3. Then D (gameplay, offline sync), E (Hall of Legends UI and art), F (monetisation and release).

Blocking items for later phases: the v1.1 prompt (or confirmation to proceed without it), a Supabase
project and its credentials, and a decision on the Pathfinder visual cues.

## 8. v1.3 update

| Earlier blocker | Resolution |
|---|---|
| v1.1 prompt missing | v1.3 says it is not a dependency and defines the missing values. Copied to `docs/`. |
| Rank XP thresholds were placeholders | Now v1.3 A1: 0 / 500 / 1,500 / 3,500 / 7,000 / 12,000 / 20,000 / 32,000 / 50,000, in `xp_rank_thresholds` under a versioned `xp_ranks` policy. |
| Leagues not seeded | Six tiers (bronze → world_elite), scoring rules, groups of ≤ 30, weekly Monday-to-Sunday UTC seasons, and `close_league_season()` implementing A2 promotion/relegation. |
| 195 countries not seeded | Seeded from the v1.3 allowlist JSON (`assets/data/`), validated: 195 unique ISO codes, 193 members + VA + PS, no TW/XK. A trigger refuses a 196th counted country. |
| No visual cues for the 7th guide | New style guide row: Ibn Battuta guide form (gold turban, sand cloak, teal sash), token key `travel_cultures`, icon `route`. |
| SVG licence unknown | Owner confirmed Claude Design origin; recorded in `docs/ASSET_PROVENANCE.md` and on each asset row. |

**Conflict found and resolved by the owner:** the new style guide labels the 7th guide's category "Travel & Cultures"
with trophy "Golden Route Map", while v1.3 keeps him on Explorers, Pioneers & Discoverers with "Explorer's Journal".
The owner chose the v1.3 names; the style guide's outfit and route icon are used for the art. `subject_categories.style_token_key`
maps `explorers_pioneers_discoverers` to the `travel_cultures` token entry.

**Kept beyond v1.3's list:** the `quarantined` editorial state (from v1.2 §6) for import failures. No question is currently quarantined.

**Art pack (added later the same day):** 124 SVGs are now in `assets/art/` and wired into the database (see `docs/ASSET_PROVENANCE.md`).

**Still open:** flags are simplified mockups; character depictions of four figures need a cultural-accuracy review. Map shapes stay placeholders until licensed data (e.g. Natural Earth) is imported. There is no Supabase project yet.
XP daily caps and LP awarding are stored as policy data; the scoring functions that apply them belong to Phase D.
