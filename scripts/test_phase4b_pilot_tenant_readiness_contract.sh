#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_pilot_tenant_readiness_contract.sh"
PY_SCRIPT="scripts/phase4b_pilot_tenant_readiness_contract.py"
REPORT="docs/phase4/16_2_pilot_tenant_readiness_contract_report.md"
MATRIX="docs/phase4/16_2_pilot_tenant_readiness_contract_matrix.tsv"
READINESS="docs/phase4/16_2_pilot_tenant_readiness_catalog.tsv"
ROLES="docs/phase4/16_2_pilot_role_permission_matrix.tsv"
OWNERS="docs/phase4/16_2_pilot_onboarding_owner_matrix.tsv"
EVIDENCE="docs/phase4/16_2_pilot_evidence_acceptance_matrix.tsv"
TRAINING="docs/phase4/16_2_pilot_training_support_plan.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot tenant readiness wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ pilot tenant readiness python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_2_pilot_tenant_readiness_contract.log 2>&1 || {
  echo "TEST_FAIL ❌ pilot tenant readiness script hata verdi"
  cat /tmp/pix2pi_16_2_pilot_tenant_readiness_contract.log || true
  sed -n '1,3000p' "$REPORT" || true
  exit 1
}

for required in \
  "PILOT_TENANT_READINESS_CONTRACT=PASS" \
  "FAZ4B_16_2_FINAL_STATUS=PASS" \
  "PILOT_TENANT_PREVIOUS_16_1=PASS" \
  "PILOT_TENANT_READINESS_CATALOG=PASS" \
  "PILOT_ROLE_PERMISSION_MATRIX=PASS" \
  "PILOT_ONBOARDING_OWNER_MATRIX=PASS" \
  "PILOT_EVIDENCE_ACCEPTANCE_MATRIX=PASS" \
  "PILOT_TRAINING_SUPPORT_PLAN=PASS" \
  "PILOT_TENANT_NO_RUNTIME_CHANGE=PASS" \
  "PILOT_TENANT_NO_CONFIG_CHANGE=PASS" \
  "PILOT_TENANT_SECRET_SAFE=PASS" \
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
    sed -n '1,3000p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$READINESS" "$ROLES" "$OWNERS" "$EVIDENCE" "$TRAINING"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_16_1 \
  tenant_readiness_catalog \
  role_permission_matrix \
  onboarding_owner_matrix \
  evidence_acceptance_matrix \
  training_support_plan \
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

for role in \
  tenant_admin \
  cashier \
  tenant_operator \
  accountant \
  tenant_approver \
  support_agent \
  ops_admin \
  security_admin \
  project_owner \
  trainer
do
  grep -q "$role" "$ROLES" || {
    echo "TEST_FAIL ❌ role eksik: $role"
    cat "$ROLES" || true
    exit 1
  }
done

for evidence in \
  tenant_identity_evidence \
  role_permission_evidence \
  tenant_isolation_evidence \
  sales_flow_evidence \
  inventory_movement_evidence \
  accounting_mapping_evidence \
  go_no_go_evidence
do
  grep -q "$evidence" "$EVIDENCE" || {
    echo "TEST_FAIL ❌ evidence eksik: $evidence"
    cat "$EVIDENCE" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$READINESS" "$ROLES" "$OWNERS" "$EVIDENCE" "$TRAINING"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$READINESS" "$ROLES" "$OWNERS" "$EVIDENCE" "$TRAINING"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$READINESS" "$ROLES" "$OWNERS" "$EVIDENCE" "$TRAINING"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_PILOT_TENANT_READINESS_CONTRACT_TEST=PASS ✅"
echo "PHASE4B_PILOT_TENANT_READINESS_CATALOG_TEST=PASS ✅"
echo "PHASE4B_PILOT_ROLE_PERMISSION_MATRIX_TEST=PASS ✅"
echo "PHASE4B_PILOT_ONBOARDING_OWNER_MATRIX_TEST=PASS ✅"
echo "PHASE4B_PILOT_EVIDENCE_ACCEPTANCE_MATRIX_TEST=PASS ✅"
echo "PHASE4B_PILOT_TRAINING_SUPPORT_PLAN_TEST=PASS ✅"
echo "PHASE4B_PILOT_TENANT_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_PILOT_TENANT_SECRET_TEST=PASS ✅"
