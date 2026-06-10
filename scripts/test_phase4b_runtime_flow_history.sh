#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_runtime_flow_history.sh"
PY_SCRIPT="scripts/phase4b_runtime_flow_history.py"
REPORT="docs/phase4/19_1_runtime_flow_history_report.md"
INVENTORY="docs/phase4/19_1_runtime_flow_history_inventory.tsv"
MATRIX="docs/phase4/19_1_runtime_flow_history_matrix.tsv"
UP_FILE="db/migrations/20260428_191001_panel_runtime_flow_history.up.sql"
DOWN_FILE="db/migrations/20260428_191001_panel_runtime_flow_history.down.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ runtime flow history wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ runtime flow history python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_19_1_runtime_flow_history.log 2>&1 || {
  echo "TEST_FAIL ❌ runtime flow history script hata verdi"
  cat /tmp/pix2pi_19_1_runtime_flow_history.log || true
  sed -n '1,1400p' "$REPORT" || true
  exit 1
}

for required in \
  "RUNTIME_FLOW_HISTORY=PASS" \
  "FAZ4B_19_1_FINAL_STATUS=PASS" \
  "PREVIOUS_18_FINAL_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_MIGRATION_PAIR=PASS" \
  "RUNTIME_FLOW_HISTORY_SCHEMA_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_TABLE_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_TENANT_SAFETY_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_TRACE_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_RUNTIME_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_ERROR_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_PANEL_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_INDEX_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_DOWN_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_RISK_STATUS=PASS" \
  "RUNTIME_FLOW_HISTORY_CHAIN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "PANEL_RUNTIME_HISTORY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1400p' "$REPORT" || true
    exit 1
  }
done

for f in "$INVENTORY" "$MATRIX" "$UP_FILE" "$DOWN_FILE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for table in \
  runtime_flow_runs \
  runtime_flow_steps \
  runtime_flow_events \
  runtime_flow_snapshots \
  runtime_flow_error_links \
  runtime_flow_timeline_views
do
  grep -q "$table" "$UP_FILE" || {
    echo "TEST_FAIL ❌ up migration table eksik: $table"
    exit 1
  }

  grep -q "$table" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory table eksik: $table"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "tenant_id text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ tenant_id not null yok"
  exit 1
}

grep -q "request_id text" "$UP_FILE" || {
  echo "TEST_FAIL ❌ request_id yok"
  exit 1
}

grep -q "correlation_id text" "$UP_FILE" || {
  echo "TEST_FAIL ❌ correlation_id yok"
  exit 1
}

grep -q "panel_visibility text NOT NULL" "$UP_FILE" || {
  echo "TEST_FAIL ❌ panel_visibility yok"
  exit 1
}

if grep -Ei "ALTER SYSTEM|docker|systemctl|psql " "$UP_FILE"; then
  echo "TEST_FAIL ❌ up migration icinde sistem tokeni var"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$INVENTORY" "$MATRIX"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_RUNTIME_FLOW_HISTORY_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_FLOW_HISTORY_TENANT_SAFETY_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_FLOW_HISTORY_MIGRATION_PAIR_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_FLOW_HISTORY_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_RUNTIME_FLOW_HISTORY_SECRET_TEST=PASS ✅"
