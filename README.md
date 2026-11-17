# GeoMaster

**Master the World — X/195.** A geography and world-knowledge quiz for Android and iOS, built with
Flutter and Supabase.

This repository currently contains the **data foundation** for spec v1.3: the Supabase schema with row-level
security, versioned game policies (rank thresholds, XP awards, leagues, mastery, trophies), the 195-country
allowlist, reference data for the seven subject categories and the Hall of Legends, and a validated import of the
520-question **draft** test bank. The Flutter app is the next phase. See
[`docs/INTEGRATION_AUDIT.md`](docs/INTEGRATION_AUDIT.md) for what was found, what is missing and the plan.

## Layout

| Path | What it is |
|---|---|
| `design/` | Your style guide, design tokens and Flutter theme, copied verbatim. The source of truth for all visuals. |
| `docs/` | Spec v1.3 (current) and v1.2, the integration audit and asset provenance. |
| `assets/data/` | Canonical 195-country allowlist (v1.3). Regenerate its seed with `tool/generate_country_seed.py`. |
| `assets/art/` | Claude Design SVG art: characters, trophies, Pip, brand, icons, mockup flags. Regenerate its seed with `tool/generate_art_seed.py`. |
| `assets/flags/` | All 195 national flags from Wikimedia Commons with a licence manifest. Refresh with `tool/fetch_flags.py`, then `tool/generate_flag_seed.py`. |
| `assets/fonts/licenses/` | OFL licence texts for Source Sans 3, Fredoka and Nunito. |
| `supabase/migrations/` | Idempotent, versioned SQL migrations (schema, seeds, server functions, RLS). |
| `tool/import_questions.py` | Question-bank validator and importer (Python 3.10+, standard library only). |
| `content/raw/<version>/` | The original question package, unmodified, with `SHA256SUMS`. |
| `content/assets/questions/` | Sanitised SVG visuals, ready for the Flutter bundle and Supabase Storage. |
| `reports/` | QA report, quarantine list and machine-readable metrics from the last validation. |
| `tests/` | Validator unit tests and a database test suite that runs on a throwaway local Postgres. |

## Database setup (Supabase)

```bash
# with the Supabase CLI, linked to your project
supabase db push            # applies supabase/migrations in order
```

Or apply each file in `supabase/migrations/` in name order with `psql`. Every migration is idempotent.

### Environment variables

Copy `.env.example` to `.env` (git-ignored). The app only ever gets `SUPABASE_URL` and
`SUPABASE_ANON_KEY`. `SUPABASE_DB_URL` is for the import tool and must never ship in the app.

## Question-bank import

```bash
# Validate only: writes reports/, sanitised SVGs and the raw archive. Touches no database.
python3 -I tool/import_questions.py validate --zip path/to/GeoMaster_520_Questions_and_Visuals.zip

# Validate and import in one transaction.
python3 -I tool/import_questions.py import --zip path/to/GeoMaster_520_Questions_and_Visuals.zip \
  --database-url "$SUPABASE_DB_URL"
```

What the import guarantees:

* **Idempotent.** Questions are keyed by their original ID (GM-0001…). A second run inserts nothing.
  If a stored question differs from the incoming file (for example after an approved correction), it is
  **not overwritten**; the run reports a conflict instead.
* **Transactional.** Any error rolls the whole import back.
* **Draft only.** Every question is imported as `draft_unverified`, or `quarantined` if it fails a hard
  check. Nothing is marked verified, and nothing is `ranked_eligible`. A source hint is stored as an
  unverified hint, not a citation.
* **Safe visuals.** ZIP entries are checked for path traversal, symlinks and size. SVGs must pass a strict
  allow-list (no scripts, event handlers, external references, entities or embedded HTML).
* **Answer keys stay server-side.** Correct answers live in `question_answer_keys`, which clients cannot read.

### Playing the draft questions (test mode)

Set a user's `profiles.app_role` to `tester` (from the Supabase dashboard or SQL as an admin). Testers can
call `get_sandbox_questions(category, difficulty, limit, offset)` and `check_sandbox_answer(question_id, position)`.
Regular players see no draft content at all.

### Editorial review

Editors (`app_role = 'editor'`) can `propose_question_revision`, `approve_question_revision` (evidence required)
and `review_question`. Every change is kept in `question_revisions`; the original imported wording stays in revision 1.
Only `approved` questions can be marked `ranked_eligible`.

## Tests

```bash
python3 -m unittest discover -s tests -p 'test_*.py'   # validator, art and flags: 17 tests
tests/run_db_tests.sh                                  # needs Postgres 15+ binaries (initdb, pg_ctl, psql)
```

`run_db_tests.sh` starts a temporary Postgres with a small Supabase stand-in (`tests/sql/00_supabase_stub.sql`),
applies all migrations twice, imports the bank twice, and checks seeds, the 195-country catalog, import counts, RLS,
the editorial path, rank boundaries (0/499/500/1499/1500/49999/50000), duplicate-award prevention, category trophy
tiers, league promotion/relegation for large and small groups, and offline-sync idempotency. CI runs both on every push and pull request.

## Asset licensing

The SVG artwork was drawn with Claude Design; the 27 question SVGs are recorded as `ai_generated_assigned`
with a provenance note. Map shapes are placeholders until licensed data (e.g. Natural Earth) is imported.
Fonts are SIL OFL 1.1. No web portraits or photos are used. Details: [`docs/ASSET_PROVENANCE.md`](docs/ASSET_PROVENANCE.md).

## Game rules live in the database

Rank thresholds, XP award amounts and caps, league scoring, country-mastery and trophy rules are rows in
`game_policy_versions` and its child tables, not constants in code. To change one, insert a new version and
switch `is_active`; earned XP and trophies are never rewritten.

## Status

| Phase | State |
|---|---|
| A. Audit | Done (`docs/INTEGRATION_AUDIT.md`) |
| B. Foundation | Database done (v1.3); Flutter app, theme wiring and mobile CI not started |
| C. Test content | Import, QA report and sandbox RPCs done; Storage upload and sandbox UI not started |
| D–F | Not started |
