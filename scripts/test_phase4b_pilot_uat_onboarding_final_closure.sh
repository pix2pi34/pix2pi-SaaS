#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_pilot_uat_onboarding_final_closure.sh"
PY_SCRIPT="scripts/phase4b_pilot_uat_onboarding_final_closure.py"
REPORT="docs/phase4/16_7_pilot_uat_onboarding_final_closure_report.md"
MATRIX="docs/phase4/16_7_pilot_uat_onboarding_final_closure_matrix.tsv"
INVENTORY="docs/phase4/16_7_pilot_uat_onboarding_final_closure_inventory.tsv"
CLOSURE="docs/phase4/16_pilot_uat_onboarding_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot final closure wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot final closure python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_7_pilot_uat_onboarding_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ pilot final closure script hata verdi"
  cat /tmp/pix2pi_16_7_pilot_uat_onboarding_final_closure.log || true
  sed -n '1,4200p' "$REPORT" || true
  exit 1
}

for required in \
  "PILOT_UAT_ONBOARDING_FINAL_CLOSURE=PASS" \
  "FAZ4B_16_7_FINAL_STATUS=PASS" \
  "FAZ4B_16_FINAL_STATUS=PASS" \
  "PILOT_FINAL_BASELINE=PASS" \
  "PILOT_FINAL_TENANT_READINESS=PASS" \
  "PILOT_FINAL_UAT_EXECUTION=PASS" \
  "PILOT_FINAL_DATA_READINESS=PASS" \
  "PILOT_FINAL_GO_NO_GO=PASS" \
  "PILOT_FINAL_TESTS=PASS" \
  "PILOT_FINAL_ARTIFACT_COVERAGE=PASS" \
  "PILOT_FINAL_NO_RUNTIME_CHANGE=PASS" \
  "PILOT_FINAL_NO_CONFIG_CHANGE=PASS" \
  "PILOT_FINAL_SECRET_SAFE=PASS" \
  "PILOT_FINAL_GATE_FAILURE_COUNT=0" \
  "PILOT_FINAL_NO_CHANGE_FAILURE_COUNT=0" \
  "PILOT_FINAL_ARTIFACT_MISSING_COUNT=0" \
  "PILOT_FINAL_METRIC_MISSING_COUNT=0" \
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
  "TENANT_CREATED=NO" \
  "USER_CREATED=NO" \
  "PASSWORD_CREATED=NO" \
  "TOKEN_CREATED=NO" \
  "UAT_EXECUTED=NO" \
  "SAMPLE_DATA_INSERTED=NO" \
  "REAL_CUSTOMER_DATA_CREATED=NO" \
  "REAL_PRODUCT_CREATED=NO" \
  "REAL_STOCK_MUTATED=NO" \
  "REAL_SALE_CREATED=NO" \
  "REAL_ACCOUNTING_ENTRY_CREATED=NO" \
  "DATA_IMPORT_EXECUTED=NO" \
  "FILE_EXPORT_EXECUTED=NO" \
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
    sed -n '1,4200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$CLOSURE"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

grep -q "FAZ4B_16_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure report final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

for gate in \
  baseline \
  tenant_readiness \
  uat_execution \
  data_readiness \
  go_no_go \
  pilot_tests \
  artifact_coverage \
  no_runtime_change \
  no_config_change \
  secret_safe \
  metric_evidence
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for block in \
  "16.1" \
  "16.2" \
  "16.3" \
  "16.4" \
  "16.5" \
  "16.6"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

for note in \
  "REAL_PILOT_TENANT_CREATION_REQUIRED=YES" \
  "REAL_USER_ROLE_ASSIGNMENT_REQUIRED=YES" \
  "REAL_SAMPLE_DATA_IMPORT_OR_ENTRY_REQUIRED=YES" \
  "REAL_UAT_EXECUTION_REQUIRED=YES" \
  "REAL_GO_NO_GO_SIGNOFF_REQUIRED=YES"
do
  grep -q "$note" "$CLOSURE" || {
    echo "TEST_FAIL ❌ production note eksik: $note"
    cat "$CLOSURE" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_16_7_PILOT_UAT_ONBOARDING_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4B_16_FINAL_STATUS_TEST=PASS ✅"
echo "PHASE4B_16_PILOT_FINAL_ARTIFACT_TEST=PASS ✅"
echo "PHASE4B_16_PILOT_FINAL_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_16_PILOT_FINAL_NO_CONFIG_CHANGE_TEST=PASS ✅"
echo "PHASE4B_16_PILOT_FINAL_SECRET_TEST=PASS ✅"
