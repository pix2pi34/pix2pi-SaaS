#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_workflow_state_machine_contract.sh"
PY_SCRIPT="scripts/phase4b_workflow_state_machine_contract.py"
REPORT="docs/phase4/17_2_workflow_state_machine_contract_report.md"
MATRIX="docs/phase4/17_2_workflow_state_machine_contract_matrix.tsv"
STATES="docs/phase4/17_2_workflow_state_catalog.tsv"
TRANSITIONS="docs/phase4/17_2_workflow_transition_catalog.tsv"
PERMISSIONS="docs/phase4/17_2_workflow_state_permission_matrix.tsv"
INVARIANTS="docs/phase4/17_2_workflow_state_invariant_catalog.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow state machine wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow state machine python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_2_workflow_state_machine_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ workflow state machine contract script hata verdi"
  cat /tmp/pix2pi_17_2_workflow_state_machine_contract.log || true
  sed -n '1,2800p' "$REPORT" || true
  exit 1
}

for required in \
  "WORKFLOW_STATE_MACHINE_CONTRACT=PASS" \
  "FAZ4B_17_2_FINAL_STATUS=PASS" \
  "WORKFLOW_STATE_PREVIOUS_17_1=PASS" \
  "WORKFLOW_STATE_CATALOG=PASS" \
  "WORKFLOW_TRANSITION_CATALOG=PASS" \
  "WORKFLOW_STATE_PERMISSION_MATRIX=PASS" \
  "WORKFLOW_STATE_INVARIANT_CATALOG=PASS" \
  "WORKFLOW_STATE_NO_RUNTIME_CHANGE=PASS" \
  "WORKFLOW_STATE_NO_CONFIG_CHANGE=PASS" \
  "WORKFLOW_STATE_SECRET_SAFE=PASS" \
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
  "WEBSOCKET_SERVER_STARTED=NO" \
  "SSE_SERVER_STARTED=NO" \
  "WORKFLOW_RUNTIME_CHANGED=NO" \
  "WORKFLOW_ENGINE_CODE_CHANGED=NO" \
  "STATE_MACHINE_RUNTIME_CREATED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
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

for f in "$MATRIX" "$STATES" "$TRANSITIONS" "$PERMISSIONS" "$INVARIANTS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_17_1 \
  state_catalog \
  transition_catalog \
  permission_matrix \
  invariant_catalog \
  audit_coverage \
  approval_coverage \
  tenant_scope \
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

for state in draft active running waiting_approval completed failed cancelled archived; do
  grep -q "$state" "$STATES" || {
    echo "TEST_FAIL ❌ state eksik: $state"
    cat "$STATES" || true
    exit 1
  }
done

for transition in \
  activate_workflow \
  start_workflow \
  request_approval \
  approve_and_resume \
  reject_and_cancel \
  complete_workflow \
  fail_workflow \
  retry_failed_workflow \
  archive_completed
do
  grep -q "$transition" "$TRANSITIONS" || {
    echo "TEST_FAIL ❌ transition eksik: $transition"
    cat "$TRANSITIONS" || true
    exit 1
  }
done

for permission in \
  "workflow:read" \
  "workflow:write" \
  "workflow:execute" \
  "approval:write"
do
  grep -q "$permission" "$PERMISSIONS" || {
    echo "TEST_FAIL ❌ permission eksik: $permission"
    cat "$PERMISSIONS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$STATES" "$TRANSITIONS" "$PERMISSIONS" "$INVARIANTS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$STATES" "$TRANSITIONS" "$PERMISSIONS" "$INVARIANTS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$STATES" "$TRANSITIONS" "$PERMISSIONS" "$INVARIANTS"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_WORKFLOW_STATE_MACHINE_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_STATE_CATALOG_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_TRANSITION_CATALOG_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_PERMISSION_MATRIX_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_INVARIANT_CATALOG_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_STATE_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_STATE_SECRET_TEST=PASS ✅"
