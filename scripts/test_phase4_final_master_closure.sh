#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_final_master_closure.sh"
PY_SCRIPT="scripts/phase4_final_master_closure.py"
REPORT="docs/phase4/19_phase4_final_master_closure_report.md"
INVENTORY="docs/phase4/19_phase4_final_master_closure_inventory.tsv"
TRANSITION="docs/phase4/19_phase4_to_phase5_transition_gate.tsv"
MASTER="docs/phase4/phase4_final_master_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ final master closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ final master closure python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_19_phase4_final_master_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ phase4 final master closure hata verdi"
  cat /tmp/pix2pi_19_phase4_final_master_closure.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "PHASE4_FINAL_MASTER_CLOSURE=PASS" \
  "FAZ4_FINAL_STATUS=PASS" \
  "FAZ5_TRANSITION_GATE=READY_WITH_DEFERRED_ACTIONS" \
  "BLOCK_14_3_STATUS=PASS" \
  "BLOCK_14_4_STATUS=PASS" \
  "BLOCK_14_5_STATUS=PASS" \
  "BLOCK_15_STATUS=PASS" \
  "BLOCK_16_STATUS=PASS" \
  "BLOCK_17_STATUS=PASS" \
  "BLOCK_18_STATUS=PASS" \
  "GATEWAY_REPORTING_RUNTIME_IMPORT_COUNT=1" \
  "GATEWAY_REPORTING_RUNTIME_REGISTER_CALL_COUNT=1" \
  "REPORTING_GO_TEST_SUITE=PASS" \
  "API_GATEWAY_GO_TEST_STATUS=PASS" \
  "RUNTIME_RESTART_EXECUTED=NO" \
  "GATEWAY_CONFIG_CHANGED=NO" \
  "NGINX_CONFIG_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1000p' "$REPORT" || true
    exit 1
  }
done

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory yok"
  exit 1
fi

if [ ! -f "$TRANSITION" ]; then
  echo "TEST_FAIL ❌ transition gate yok"
  exit 1
fi

if [ ! -f "$MASTER" ]; then
  echo "TEST_FAIL ❌ master closure report yok"
  exit 1
fi

grep -q "FAZ4_FINAL_STATUS=PASS" "$MASTER" || {
  echo "TEST_FAIL ❌ master report FAZ4 PASS yok"
  cat "$MASTER" || true
  exit 1
}

grep -q "FAZ5_TRANSITION_GATE=READY_WITH_DEFERRED_ACTIONS" "$MASTER" || {
  echo "TEST_FAIL ❌ master report Faz5 gate yok"
  cat "$MASTER" || true
  exit 1
}

grep -q "phase4_final_status" "$TRANSITION" || {
  echo "TEST_FAIL ❌ transition phase4 final yok"
  cat "$TRANSITION" || true
  exit 1
}

grep -q "faz5_transition_gate" "$TRANSITION" || {
  echo "TEST_FAIL ❌ transition faz5 gate yok"
  cat "$TRANSITION" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$TRANSITION" "$MASTER"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "Bearer smoke-token" "$REPORT" "$INVENTORY" "$TRANSITION" "$MASTER"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$TRANSITION" "$MASTER"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_FINAL_MASTER_CLOSURE_TEST=PASS ✅"
echo "PHASE4_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4_TO_PHASE5_TRANSITION_GATE_TEST=PASS ✅"
echo "PHASE4_FINAL_GO_TEST=PASS ✅"
echo "PHASE4_FINAL_SECRET_TEST=PASS ✅"
