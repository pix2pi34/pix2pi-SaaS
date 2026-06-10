#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_ui_api_implementation_plan.sh"
PY_SCRIPT="scripts/phase4b_ui_api_implementation_plan.py"
REPORT="docs/phase4/17_5_ui_api_implementation_plan_report.md"
MATRIX="docs/phase4/17_5_ui_api_implementation_plan_matrix.tsv"
UI="docs/phase4/17_5_ui_page_implementation_plan.tsv"
API="docs/phase4/17_5_api_endpoint_implementation_plan.tsv"
PERMS="docs/phase4/17_5_ui_api_permission_mapping.tsv"
SEQ="docs/phase4/17_5_implementation_sequence.tsv"
TESTS="docs/phase4/17_5_ui_api_test_plan.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ ui api implementation plan wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ ui api implementation plan python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_5_ui_api_implementation_plan.log 2>&1 || {
  echo "TEST_FAIL ❌ ui api implementation plan script hata verdi"
  cat /tmp/pix2pi_17_5_ui_api_implementation_plan.log || true
  sed -n '1,3400p' "$REPORT" || true
  exit 1
}

for required in \
  "UI_API_IMPLEMENTATION_PLAN=PASS" \
  "FAZ4B_17_5_FINAL_STATUS=PASS" \
  "UI_API_PREVIOUS_17_4=PASS" \
  "UI_PAGE_IMPLEMENTATION_PLAN=PASS" \
  "API_ENDPOINT_IMPLEMENTATION_PLAN=PASS" \
  "UI_API_PERMISSION_MAPPING=PASS" \
  "UI_API_SEQUENCE_PLAN=PASS" \
  "UI_API_TEST_PLAN=PASS" \
  "UI_API_NO_RUNTIME_CHANGE=PASS" \
  "UI_API_NO_CONFIG_CHANGE=PASS" \
  "UI_API_SECRET_SAFE=PASS" \
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
    sed -n '1,3400p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$UI" "$API" "$PERMS" "$SEQ" "$TESTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_17_4 \
  ui_page_plan \
  api_endpoint_plan \
  permission_mapping \
  sequence_plan \
  test_plan \
  audit_coverage \
  realtime_mapping \
  tenant_platform_split \
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

for page in \
  workflow_dashboard \
  workflow_detail \
  approval_center \
  task_center \
  ops_workflow_console \
  security_workflow_console
do
  grep -q "$page" "$UI" || {
    echo "TEST_FAIL ❌ UI page eksik: $page"
    cat "$UI" || true
    exit 1
  }
done

for endpoint in \
  "/api/v1/workflow-instances" \
  "/api/v1/workflow-instances/{id}/actions" \
  "/api/v1/approvals" \
  "/api/v1/approvals/{id}/approve" \
  "/api/v1/approvals/{id}/reject" \
  "/api/v1/realtime/events" \
  "/api/v1/realtime/ws" \
  "/ops/v1/workflow" \
  "/ops/v1/security/tenant-isolation"
do
  grep -q "$endpoint" "$API" || {
    echo "TEST_FAIL ❌ API endpoint eksik: $endpoint"
    cat "$API" || true
    exit 1
  }
done

for permission in \
  "workflow:read" \
  "workflow:execute" \
  "approval:write" \
  "task:read" \
  "realtime:read" \
  "ops:read" \
  "security:read"
do
  grep -q "$permission" "$PERMS" || {
    echo "TEST_FAIL ❌ permission eksik: $permission"
    cat "$PERMS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$UI" "$API" "$PERMS" "$SEQ" "$TESTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$UI" "$API" "$PERMS" "$SEQ" "$TESTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$UI" "$API" "$PERMS" "$SEQ" "$TESTS"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_UI_API_IMPLEMENTATION_PLAN_TEST=PASS ✅"
echo "PHASE4B_UI_PAGE_IMPLEMENTATION_PLAN_TEST=PASS ✅"
echo "PHASE4B_API_ENDPOINT_IMPLEMENTATION_PLAN_TEST=PASS ✅"
echo "PHASE4B_UI_API_PERMISSION_MAPPING_TEST=PASS ✅"
echo "PHASE4B_UI_API_SEQUENCE_PLAN_TEST=PASS ✅"
echo "PHASE4B_UI_API_TEST_PLAN_TEST=PASS ✅"
echo "PHASE4B_UI_API_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_UI_API_SECRET_TEST=PASS ✅"
