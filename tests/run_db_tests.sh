#!/usr/bin/env bash
# Spins up a throwaway local Postgres, applies the Supabase stub + all migrations TWICE
# (idempotency), runs the question import TWICE (no duplicates), then runs the SQL test files.
#
#   tests/run_db_tests.sh [path/to/GeoMaster_520_Questions_and_Visuals.zip]
#
# Requires Postgres 15+ server binaries (initdb, pg_ctl) and psql on PATH, or PG_BIN set.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP="${1:-$ROOT/content/raw/geomaster-test-2026-11-plus20/GeoMaster_520_Questions_and_Visuals.zip}"
PG_BIN="${PG_BIN:-$(dirname "$(command -v pg_ctl 2>/dev/null || ls -d /usr/lib/postgresql/*/bin/pg_ctl | sort -V | tail -1)")}"
PORT="${PGTEST_PORT:-54329}"
WORK="$(mktemp -d)"
chmod 755 "$WORK"
RUN_AS=()
if [ "$(id -u)" = "0" ]; then RUN_AS=(runuser -u postgres --); chown postgres "$WORK"; fi

cleanup() { "${RUN_AS[@]}" "$PG_BIN/pg_ctl" -D "$WORK/data" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT

"${RUN_AS[@]}" "$PG_BIN/initdb" -D "$WORK/data" -U postgres -A trust >/dev/null
"${RUN_AS[@]}" "$PG_BIN/pg_ctl" -D "$WORK/data" -o "-p $PORT -k $WORK -c listen_addresses=''" -w start >/dev/null
export PGOPTIONS="-c client_min_messages=warning"
export DATABASE_URL="postgresql://postgres@/postgres?host=$WORK&port=$PORT"
PSQL=(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1)

echo "== Postgres $("${PSQL[@]}" -tAc 'show server_version')"
"${PSQL[@]}" -f "$ROOT/tests/sql/00_supabase_stub.sql"

for pass in 1 2; do
  for f in "$ROOT"/supabase/migrations/*.sql; do
    "${PSQL[@]}" --single-transaction -f "$f" >/dev/null
  done
  echo "== migrations applied (pass $pass)"
done

OUT="$WORK/reports"
for pass in 1 2; do
  python3 -I "$ROOT/tool/import_questions.py" import --zip "$ZIP" --database-url "$DATABASE_URL" \
    --out "$OUT" --assets-out "$WORK/assets" --archive "$WORK/raw" | tail -1
  cp "$OUT/import_result.json" "$WORK/import_result_$pass.json"
done
python3 -I - "$WORK/import_result_1.json" "$WORK/import_result_2.json" <<'EOF'
import json, sys
a, b = (json.load(open(p)) for p in sys.argv[1:])
assert a["inserted"] == 520 and a["unchanged"] == 0 and a["conflict_count"] == 0, a
assert b["inserted"] == 0 and b["unchanged"] == 520 and b["conflict_count"] == 0, b
print("== re-import is a no-op (520 inserted, then 520 unchanged)")
EOF

fail=0
for f in "$ROOT"/tests/sql/[1-9]*.sql; do
  if "${PSQL[@]}" -f "$f" >/dev/null 2>"$WORK/err"; then
    echo "PASS $(basename "$f")"
  else
    echo "FAIL $(basename "$f")"; cat "$WORK/err"; fail=1
  fi
done
exit $fail
