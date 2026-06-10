#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_pilot_uat_onboarding_baseline.sh"
PY_SCRIPT="scripts/phase4b_pilot_uat_onboarding_baseline.py"
REPORT="docs/phase4/16_1_pilot_uat_onboarding_baseline_report.md"
MATRIX="docs/phase4/16_1_pilot_uat_onboarding_baseline_matrix.tsv"
SCOPE="docs/phase4/16_1_pilot_scope_inventory.tsv"
UAT="docs/phase4/16_1_uat_scenario_catalog.tsv"
ONBOARDING="docs/phase4/16_1_onboarding_checklist.tsv"
ROLLOUT="docs/phase4/16_1_rollout_gate_matrix.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot baseline wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot baseline python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_1_pilot_uat_onboarding_baseline.log 2>&1 || {
  echo "TEST_FAIL ❌ pilot baseline script hata verdi"
  cat /tmp/pix2pi_16_1_pilot_uat_onboarding_baseline.log || true
  sed -n '1,2800p' "$REPORT" || true
  exit 1
}

for required in \
  "PILOT_UAT_ONBOARDING_BASELINE=PASS" \
  "FAZ4B_16_1_FINAL_STATUS=PASS" \
  "PILOT_PREVIOUS_FOUNDATION=PASS" \
  "PILOT_SCOPE_INVENTORY=PASS" \
  "PILOT_UAT_SCENARIO_CATALOG=PASS" \
  "PILOT_ONBOARDING_CHECKLIST=PASS" \
  "PILOT_ROLLOUT_GATE_MATRIX=PASS" \
  "PILOT_NO_RUNTIME_CHANGE=PASS" \
  "PILOT_NO_CONFIG_CHANGE=PASS" \
  "PILOT_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "UI_CODE_CHANGED=NO" \
  "API_ROUTE_CREATED=NO" \
  "API_IMPLEMENTATION_CHANGED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "NOTIFICATION_SENT=NO" \
  "CUSTOMER_PRIVATE_DATA_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO" \
  "TOKEN_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2800p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$SCOPE" "$UAT" "$ONBOARDING" "$ROLLOUT"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_foundation \
  pilot_scope_inventory \
  uat_scenario_catalog \
  onboarding_checklist \
  rollout_gate_matrix \
  no_runtime_change \
  no_config_change \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for scenario in \
  uat_login_tenant_access \
  uat_sale_cash_flow \
  uat_inventory_movement_validation \
  uat_accounting_journal_check \
  uat_go_no_go_decision
do
  grep -q "$scenario" "$UAT" || {
    echo "TEST_FAIL ❌ UAT scenario eksik: $scenario"
    cat "$UAT" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$SCOPE" "$UAT" "$ONBOARDING" "$ROLLOUT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$SCOPE" "$UAT" "$ONBOARDING" "$ROLLOUT"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$SCOPE" "$UAT" "$ONBOARDING" "$ROLLOUT"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_PILOT_UAT_ONBOARDING_BASELINE_TEST=PASS ✅"
echo "PHASE4B_PILOT_SCOPE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_UAT_SCENARIO_CATALOG_TEST=PASS ✅"
echo "PHASE4B_ONBOARDING_CHECKLIST_TEST=PASS ✅"
echo "PHASE4B_ROLLOUT_GATE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_PILOT_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_PILOT_SECRET_TEST=PASS ✅"
