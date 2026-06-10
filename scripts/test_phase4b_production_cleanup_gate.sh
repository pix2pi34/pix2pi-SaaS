#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_production_cleanup_gate.sh"
PY_SCRIPT="scripts/phase4b_production_cleanup_gate.py"
REPORT="docs/phase4/20_1_production_cleanup_report.md"
MATRIX="docs/phase4/20_1_production_cleanup_matrix.tsv"
INVENTORY="docs/phase4/20_1_production_cleanup_inventory.tsv"
POLICY="docs/phase4/20_1_production_cleanup_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ production cleanup wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ production cleanup python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_20_1_production_cleanup_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ production cleanup gate script hata verdi"
  cat /tmp/pix2pi_20_1_production_cleanup_gate.log || true
  sed -n '1,2200p' "$REPORT" || true
  exit 1
}

for required in \
  "PRODUCTION_CLEANUP_GATE=PASS" \
  "FAZ4B_20_1_FINAL_STATUS=PASS" \
  "PRODUCTION_CLEANUP_PREVIOUS_21=PASS" \
  "PRODUCTION_CLEANUP_BASELINE=PASS" \
  "PRODUCTION_CLEANUP_INVENTORY=PASS" \
  "PRODUCTION_CLEANUP_MIGRATION_CHAIN=PASS" \
  "PRODUCTION_CLEANUP_NO_DELETE=PASS" \
  "PRODUCTION_CLEANUP_NO_MOVE=PASS" \
  "PRODUCTION_CLEANUP_NO_DEPLOY=PASS" \
  "PRODUCTION_CLEANUP_SECRET_SAFE=PASS" \
  "FILE_DELETE_EXECUTED=NO" \
  "FILE_MOVE_EXECUTED=NO" \
  "FILE_PERMISSION_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "DEPLOY_EXECUTED=NO" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_21 \
  baseline \
  inventory \
  migration_chain \
  cleanup_candidates \
  potential_secret_paths \
  no_delete \
  no_move \
  no_deploy \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "path" \
  "category" \
  "risk" \
  "note"
do
  grep -q "$header" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory header eksik: $header"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_PRODUCTION_CLEANUP_GATE_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_CLEANUP_BASELINE_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_CLEANUP_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_CLEANUP_MIGRATION_CHAIN_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_CLEANUP_NO_DELETE_TEST=PASS ✅"
echo "PHASE4B_PRODUCTION_CLEANUP_SECRET_TEST=PASS ✅"
