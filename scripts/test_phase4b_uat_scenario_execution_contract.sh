#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_uat_scenario_execution_contract.sh"
PY_SCRIPT="scripts/phase4b_uat_scenario_execution_contract.py"
REPORT="docs/phase4/16_3_uat_scenario_execution_contract_report.md"
MATRIX="docs/phase4/16_3_uat_execution_contract_matrix.tsv"
EXECUTION="docs/phase4/16_3_uat_execution_plan.tsv"
ACTORS="docs/phase4/16_3_uat_actor_matrix.tsv"
EVIDENCE="docs/phase4/16_3_uat_evidence_matrix.tsv"
BLOCKERS="docs/phase4/16_3_uat_blocker_policy.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ UAT execution wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ UAT execution python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_3_uat_scenario_execution_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ UAT execution contract script hata verdi"
  cat /tmp/pix2pi_16_3_uat_scenario_execution_contract.log || true
  sed -n '1,3200p' "$REPORT" || true
  exit 1
}

for required in \
  "UAT_SCENARIO_EXECUTION_CONTRACT=PASS" \
  "FAZ4B_16_3_FINAL_STATUS=PASS" \
  "UAT_PREVIOUS_16_2=PASS" \
  "UAT_EXECUTION_PLAN=PASS" \
  "UAT_ACTOR_MATRIX=PASS" \
  "UAT_EVIDENCE_MATRIX=PASS" \
  "UAT_BLOCKER_POLICY=PASS" \
  "UAT_NO_RUNTIME_CHANGE=PASS" \
  "UAT_NO_CONFIG_CHANGE=PASS" \
  "UAT_SECRET_SAFE=PASS" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DOCKER_COMPOSE_EXECUTED=NO" \
  "NGINX_RELOAD_EXECUTED=NO" \
  "FIREWALL_CHANGED=NO" \
  "PORT_CHANGED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "TENANT_CREATED=NO" \
  "USER_CREATED=NO" \
  "PASSWORD_CREATED=NO" \
  "TOKEN_CREATED=NO" \
  "UAT_EXECUTED=NO" \
  "REAL_SALE_CREATED=NO" \
  "REAL_STOCK_MUTATED=NO" \
  "REAL_ACCOUNTING_ENTRY_CREATED=NO" \
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
    sed -n '1,3200p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$EXECUTION" "$ACTORS" "$EVIDENCE" "$BLOCKERS"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_16_2 \
  uat_execution_plan \
  uat_actor_matrix \
  uat_evidence_matrix \
  uat_blocker_policy \
  tenant_rbac_coverage \
  audit_coverage \
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
  uat_role_permission_denied \
  uat_sale_cash_flow \
  uat_inventory_movement_validation \
  uat_sale_cancel_refund \
  uat_accounting_journal_check \
  uat_audit_trail_check \
  uat_no_raw_secret_payload \
  uat_go_no_go_decision
do
  grep -q "$scenario" "$EXECUTION" || {
    echo "TEST_FAIL ❌ UAT scenario eksik: $scenario"
    cat "$EXECUTION" || true
    exit 1
  }
done

for actor in \
  tenant_user \
  cashier \
  tenant_operator \
  accountant \
  tenant_admin \
  ops_admin \
  security_admin \
  project_owner
do
  grep -q "$actor" "$ACTORS" || {
    echo "TEST_FAIL ❌ actor eksik: $actor"
    cat "$ACTORS" || true
    exit 1
  }
done

for evidence in \
  tenant_access_evidence \
  permission_denied_evidence \
  sale_cash_flow_evidence \
  inventory_movement_evidence \
  accounting_journal_evidence \
  audit_trail_evidence \
  secret_safety_evidence \
  go_no_go_evidence
do
  grep -q "$evidence" "$EVIDENCE" || {
    echo "TEST_FAIL ❌ evidence eksik: $evidence"
    cat "$EVIDENCE" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$EXECUTION" "$ACTORS" "$EVIDENCE" "$BLOCKERS"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$EXECUTION" "$ACTORS" "$EVIDENCE" "$BLOCKERS"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$EXECUTION" "$ACTORS" "$EVIDENCE" "$BLOCKERS"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_UAT_SCENARIO_EXECUTION_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_UAT_EXECUTION_PLAN_TEST=PASS ✅"
echo "PHASE4B_UAT_ACTOR_MATRIX_TEST=PASS ✅"
echo "PHASE4B_UAT_EVIDENCE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_UAT_BLOCKER_POLICY_TEST=PASS ✅"
echo "PHASE4B_UAT_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_UAT_SECRET_TEST=PASS ✅"
