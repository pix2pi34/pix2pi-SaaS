#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_final_master_closure.sh"
PY_SCRIPT="scripts/phase4b_final_master_closure.py"
REPORT="docs/phase4/faz4b_final_master_closure_report.md"
MATRIX="docs/phase4/faz4b_final_master_closure_matrix.tsv"
INVENTORY="docs/phase4/faz4b_final_master_closure_inventory.tsv"
TRANSITION="docs/phase4/faz4b_to_faz5_transition_readiness.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ FAZ 4B final master wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ FAZ 4B final master python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_faz4b_final_master_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ FAZ 4B final master closure script hata verdi"
  cat /tmp/pix2pi_faz4b_final_master_closure.log || true
  sed -n '1,3600p' "$REPORT" || true
  exit 1
}

for required in \
  "FAZ4B_FINAL_MASTER_CLOSURE=PASS" \
  "FAZ4B_FINAL_MASTER_STATUS=PASS" \
  "FAZ5_TRANSITION_READY=YES" \
  "FAZ4B_BLOCK_14_STATUS=PASS" \
  "FAZ4B_BLOCK_15_STATUS=PASS" \
  "FAZ4B_BLOCK_16_STATUS=PASS" \
  "FAZ4B_BLOCK_17_STATUS=PASS" \
  "FAZ4B_BLOCK_18_STATUS=PASS" \
  "FAZ4B_BLOCK_19_STATUS=PASS" \
  "FAZ4B_BLOCK_20_STATUS=PASS" \
  "FAZ4B_BLOCK_21_STATUS=PASS" \
  "FAZ4B_BLOCK_22_STATUS=PASS" \
  "FAZ4B_ARTIFACT_COVERAGE=PASS" \
  "FAZ4B_NO_RUNTIME_CHANGE=PASS" \
  "FAZ4B_NO_CONFIG_CHANGE=PASS" \
  "FAZ4B_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "ROLLOUT_EXECUTED=NO" \
  "GO_LIVE_SWITCHED=NO" \
  "PRODUCTION_TRAFFIC_CHANGED=NO" \
  "TENANT_ENABLED_FOR_LIVE=NO" \
  "REAL_CUSTOMER_NOTIFIED=NO" \
  "DB_MUTATION=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO" \
  "TOKEN_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,3600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$TRANSITION"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for block in 14 15 16 17 18 19 20 21 22; do
  grep -q "block_${block}" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix block eksik: $block"
    cat "$MATRIX" || true
    exit 1
  }

  grep -q "^${block}" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

grep -q "FAZ5_TRANSITION_READY=YES" "$TRANSITION" || {
  echo "TEST_FAIL ❌ FAZ5 transition ready yok"
  cat "$TRANSITION" || true
  exit 1
}

grep -q "NEXT_STEP=FAZ5_SCOPE_AND_MASTER_PLAN" "$TRANSITION" || {
  echo "TEST_FAIL ❌ FAZ5 next step yok"
  cat "$TRANSITION" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$TRANSITION"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$TRANSITION"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$TRANSITION"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_FINAL_MASTER_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_ALL_BLOCKS_14_TO_22_TEST=PASS ✅"
echo "PHASE4B_FINAL_MASTER_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_FINAL_MASTER_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_FINAL_MASTER_NO_CONFIG_CHANGE_TEST=PASS ✅"
echo "PHASE4B_FINAL_MASTER_SECRET_TEST=PASS ✅"
echo "FAZ5_TRANSITION_READY_TEST=PASS ✅"
