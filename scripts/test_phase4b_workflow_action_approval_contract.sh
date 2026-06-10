#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_workflow_action_approval_contract.sh"
PY_SCRIPT="scripts/phase4b_workflow_action_approval_contract.py"
REPORT="docs/phase4/17_3_workflow_action_approval_contract_report.md"
MATRIX="docs/phase4/17_3_workflow_action_approval_contract_matrix.tsv"
ACTIONS="docs/phase4/17_3_workflow_action_catalog.tsv"
RULES="docs/phase4/17_3_workflow_approval_rule_catalog.tsv"
PERMISSIONS="docs/phase4/17_3_workflow_action_permission_matrix.tsv"
BINDINGS="docs/phase4/17_3_workflow_action_audit_realtime_binding.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow action approval wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ workflow action approval python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_17_3_workflow_action_approval_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ workflow action approval contract script hata verdi"
  cat /tmp/pix2pi_17_3_workflow_action_approval_contract.log || true
  sed -n '1,3000p' "$REPORT" || true
  exit 1
}

for required in \
  "WORKFLOW_ACTION_APPROVAL_CONTRACT=PASS" \
  "FAZ4B_17_3_FINAL_STATUS=PASS" \
  "WORKFLOW_ACTION_PREVIOUS_17_2=PASS" \
  "WORKFLOW_ACTION_CATALOG=PASS" \
  "WORKFLOW_APPROVAL_RULE_CATALOG=PASS" \
  "WORKFLOW_ACTION_PERMISSION_MATRIX=PASS" \
  "WORKFLOW_ACTION_AUDIT_REALTIME_BINDING=PASS" \
  "WORKFLOW_ACTION_NO_RUNTIME_CHANGE=PASS" \
  "WORKFLOW_ACTION_NO_CONFIG_CHANGE=PASS" \
  "WORKFLOW_ACTION_SECRET_SAFE=PASS" \
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
  "APPROVAL_RUNTIME_CHANGED=NO" \
  "ACTION_RUNTIME_CREATED=NO" \
  "EVENT_PUBLISHED=NO" \
  "EVENT_CONSUMED=NO" \
  "NOTIFICATION_SENT=NO" \
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
    sed -n '1,3000p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$ACTIONS" "$RULES" "$PERMISSIONS" "$BINDINGS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_17_2 \
  action_catalog \
  approval_rule_catalog \
  permission_matrix \
  audit_realtime_binding \
  idempotency_coverage \
  reason_policy \
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

for action in \
  start \
  pause \
  resume \
  request_approval \
  approve \
  reject \
  retry \
  cancel \
  complete \
  fail \
  assign_task \
  complete_task \
  notify \
  archive \
  external_resume \
  escalate_approval
do
  grep -q "$action" "$ACTIONS" || {
    echo "TEST_FAIL ❌ action eksik: $action"
    cat "$ACTIONS" || true
    exit 1
  }
done

for rule in \
  approver_role_required \
  cannot_approve_own_request \
  tenant_scope_required \
  reject_reason_required \
  idempotency_required \
  state_match_required \
  metadata_only_realtime
do
  grep -q "$rule" "$RULES" || {
    echo "TEST_FAIL ❌ approval rule eksik: $rule"
    cat "$RULES" || true
    exit 1
  }
done

for permission in \
  "workflow:execute" \
  "workflow:retry" \
  "workflow:cancel" \
  "approval:write" \
  "approval:escalate" \
  "task:assign" \
  "notification:send" \
  "realtime:read"
do
  grep -q "$permission" "$PERMISSIONS" || {
    echo "TEST_FAIL ❌ permission eksik: $permission"
    cat "$PERMISSIONS" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$ACTIONS" "$RULES" "$PERMISSIONS" "$BINDINGS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$ACTIONS" "$RULES" "$PERMISSIONS" "$BINDINGS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$ACTIONS" "$RULES" "$PERMISSIONS" "$BINDINGS"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_WORKFLOW_ACTION_APPROVAL_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_ACTION_CATALOG_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_APPROVAL_RULE_CATALOG_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_ACTION_PERMISSION_MATRIX_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_ACTION_AUDIT_REALTIME_BINDING_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_ACTION_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_WORKFLOW_ACTION_SECRET_TEST=PASS ✅"
