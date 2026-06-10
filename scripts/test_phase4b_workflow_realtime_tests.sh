#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_workflow_realtime_tests.sh"
PY_SCRIPT="scripts/phase4b_workflow_realtime_tests.py"
REPORT="docs/phase4/17_6_workflow_realtime_tests_report.md"
MATRIX="docs/phase4/17_6_workflow_realtime_tests_matrix.tsv"
INVENTORY="docs/phase4/17_6_workflow_realtime_tests_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow realtime tests wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow realtime tests python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_6_workflow_realtime_tests.log 2>&1 || {
  echo "TEST_FAIL ❌ workflow realtime tests script hata verdi"
  cat /tmp/pix2pi_17_6_workflow_realtime_tests.log || true
  sed -n '1,3600p' "$REPORT" || true
  exit 1
}

for required in \
  "WORKFLOW_REALTIME_TESTS=PASS" \
  "FAZ4B_17_6_FINAL_STATUS=PASS" \
  "WORKFLOW_TEST_BASELINE=PASS" \
  "WORKFLOW_TEST_STATE_MACHINE=PASS" \
  "WORKFLOW_TEST_ACTION_APPROVAL=PASS" \
  "WORKFLOW_TEST_REALTIME_CHANNEL=PASS" \
  "WORKFLOW_TEST_UI_API_PLAN=PASS" \
  "WORKFLOW_TEST_ARTIFACT_COVERAGE=PASS" \
  "WORKFLOW_TEST_NO_RUNTIME_CHANGE=PASS" \
  "WORKFLOW_TEST_NO_CONFIG_CHANGE=PASS" \
  "WORKFLOW_TEST_SECRET_SAFE=PASS" \
  "WORKFLOW_TEST_GATE_FAILURE_COUNT=0" \
  "WORKFLOW_TEST_NO_CHANGE_FAILURE_COUNT=0" \
  "WORKFLOW_TEST_ARTIFACT_MISSING_COUNT=0" \
  "WORKFLOW_TEST_METRIC_MISSING_COUNT=0" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "UI_CODE_CHANGED=NO" \
  "FRONTEND_FILE_CREATED=NO" \
  "API_ROUTE_CREATED=NO" \
  "API_IMPLEMENTATION_CHANGED=NO" \
  "DTO_CODE_CREATED=NO" \
  "HANDLER_CODE_CREATED=NO" \
  "MIDDLEWARE_CHANGED=NO" \
  "WEBSOCKET_SERVER_STARTED=NO" \
  "SSE_SERVER_STARTED=NO" \
  "REALTIME_RUNTIME_CHANGED=NO" \
  "WORKFLOW_RUNTIME_CHANGED=NO" \
  "APPROVAL_RUNTIME_CHANGED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "NOTIFICATION_SENT=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "RAW_PAYLOAD_PRINTED=NO" \
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

for f in "$MATRIX" "$INVENTORY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  baseline \
  state_machine \
  action_approval \
  realtime_channel \
  ui_api_plan \
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
  "17.1" \
  "17.2" \
  "17.3" \
  "17.4" \
  "17.5"
do
  grep -q "$block" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory block eksik: $block"
    cat "$INVENTORY" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_WORKFLOW_REALTIME_TESTS_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_BASELINE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_STATE_MACHINE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_ACTION_APPROVAL_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_REALTIME_CHANNEL_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_UI_API_PLAN_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_ARTIFACT_COVERAGE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TEST_SECRET_TEST=PASS ✅"
