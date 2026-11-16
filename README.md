# GeoMaster

**Master the World — X/195.** A geography and world-knowledge quiz for Android and iOS, built with
Flutter and Supabase.

This repository currently contains the **data foundation**: the Supabase schema with row-level security,
reference data for the seven subject categories and the Hall of Legends, and a validated import of the
520-question **draft** test bank. The Flutter app is the next phase. See
[`docs/INTEGRATION_AUDIT.md`](docs/INTEGRATION_AUDIT.md) for what was found, what is missing and the plan.

## Layout

| Path | What it is |
|---|---|
| `design/` | Your style guide, design tokens and Flutter theme, copied verbatim. The source of truth for all visuals. |
| `docs/` | Integration prompt v1.2 and the integration audit. |
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
python3 -m unittest discover -s tests -p 'test_*.py'   # validator: 14 tests
tests/run_db_tests.sh                                  # needs Postgres 15+ binaries (initdb, pg_ctl, psql)
```

`run_db_tests.sh` starts a temporary Postgres with a small Supabase stand-in (`tests/sql/00_supabase_stub.sql`),
applies all migrations twice, imports the bank twice, and checks seeds, import counts, RLS, the editorial path,
rank/trophy unlocks and offline-sync idempotency. CI runs both on every push and pull request.

## Asset licensing

The 27 question SVGs came with the test package without author or licence metadata. They are recorded with
`license_status = 'pending_review'` and a `[PLACEHOLDER]` attribution until you confirm their origin.
Hall of Legends portraits are placeholder records only; no historical images are used or scraped.

## Status

| Phase | State |
|---|---|
| A. Audit | Done (`docs/INTEGRATION_AUDIT.md`) |
| B. Foundation | Database done; Flutter app, theme wiring and mobile CI not started |
| C. Test content | Import, QA report and sandbox RPCs done; Storage upload and sandbox UI not started |
| D–F | Not started |
