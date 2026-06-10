#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_go_no_go_rollout_gate.sh"
PY_SCRIPT="scripts/phase4b_go_no_go_rollout_gate.py"
REPORT="docs/phase4/16_5_go_no_go_rollout_gate_report.md"
MATRIX="docs/phase4/16_5_go_no_go_rollout_gate_matrix.tsv"
DECISION="docs/phase4/16_5_go_no_go_decision_matrix.tsv"
BLOCKER="docs/phase4/16_5_rollout_blocker_policy.tsv"
SECURITY="docs/phase4/16_5_security_tenant_gate.tsv"
BUSINESS="docs/phase4/16_5_business_chain_gate.tsv"
SUPPORT="docs/phase4/16_5_support_incident_gate.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ go/no-go rollout wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ go/no-go rollout python executable degil"
  exit 1
fi

bash -n "$SCRIPT"
python3 -m py_compile "$PY_SCRIPT"

bash "$SCRIPT" . >/tmp/pix2pi_16_5_go_no_go_rollout_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ go/no-go rollout gate script hata verdi"
  cat /tmp/pix2pi_16_5_go_no_go_rollout_gate.log || true
  sed -n '1,3600p' "$REPORT" || true
  exit 1
}

for required in \
  "GO_NO_GO_ROLLOUT_GATE=PASS" \
  "FAZ4B_16_5_FINAL_STATUS=PASS" \
  "GO_NO_GO_PREVIOUS_16_4=PASS" \
  "GO_NO_GO_DECISION_MATRIX=PASS" \
  "GO_NO_GO_BLOCKER_POLICY=PASS" \
  "GO_NO_GO_SECURITY_TENANT_GATE=PASS" \
  "GO_NO_GO_BUSINESS_CHAIN_GATE=PASS" \
  "GO_NO_GO_SUPPORT_INCIDENT_GATE=PASS" \
  "GO_NO_GO_NO_RUNTIME_CHANGE=PASS" \
  "GO_NO_GO_NO_CONFIG_CHANGE=PASS" \
  "GO_NO_GO_SECRET_SAFE=PASS" \
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
    sed -n '1,3600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$DECISION" "$BLOCKER" "$SECURITY" "$BUSINESS" "$SUPPORT"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_16_4 \
  go_no_go_decision_matrix \
  rollout_blocker_policy \
  security_tenant_gate \
  business_chain_gate \
  support_incident_gate \
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

for decision in \
  foundation_closed \
  pilot_tenant_ready \
  pilot_data_ready \
  security_rbac_checked \
  tenant_isolation_checked \
  secret_safety_checked \
  sales_stock_accounting_chain_ready \
  audit_evidence_ready \
  support_loop_ready \
  final_go_no_go_signed
do
  grep -q "$decision" "$DECISION" || {
    echo "TEST_FAIL ❌ decision gate eksik: $decision"
    cat "$DECISION" || true
    exit 1
  }
done

for blocker in \
  tenant_access_failed \
  rbac_bypass_or_wrong_access \
  tenant_isolation_failed \
  secret_or_raw_payload_leak \
  sale_flow_failed \
  stock_movement_mismatch \
  accounting_journal_wrong \
  audit_missing \
  support_loop_missing \
  go_no_go_not_signed
do
  grep -q "$blocker" "$BLOCKER" || {
    echo "TEST_FAIL ❌ blocker policy eksik: $blocker"
    cat "$BLOCKER" || true
    exit 1
  }
done

for security in \
  auth_login_gate \
  rbac_denied_gate \
  tenant_isolation_gate \
  audit_trail_gate \
  secret_safety_gate \
  customer_private_data_gate
do
  grep -q "$security" "$SECURITY" || {
    echo "TEST_FAIL ❌ security gate eksik: $security"
    cat "$SECURITY" || true
    exit 1
  }
done

for business in \
  product_catalog_ready \
  opening_stock_ready \
  cash_sale_ready \
  stock_decrease_ready \
  refund_cancel_ready \
  negative_stock_guard_ready \
  tdhp_journal_ready
do
  grep -q "$business" "$BUSINESS" || {
    echo "TEST_FAIL ❌ business gate eksik: $business"
    cat "$BUSINESS" || true
    exit 1
  }
done

for support in \
  support_channel_ready \
  incident_template_ready \
  escalation_owner_ready \
  pilot_feedback_loop_ready \
  ops_console_readiness_ready \
  rollback_contact_ready
do
  grep -q "$support" "$SUPPORT" || {
    echo "TEST_FAIL ❌ support gate eksik: $support"
    cat "$SUPPORT" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$DECISION" "$BLOCKER" "$SECURITY" "$BUSINESS" "$SUPPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$DECISION" "$BLOCKER" "$SECURITY" "$BUSINESS" "$SUPPORT"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$DECISION" "$BLOCKER" "$SECURITY" "$BUSINESS" "$SUPPORT"; then
  echo "TEST_FAIL ❌ token rapora basildi"
  exit 1
fi

echo "PHASE4B_GO_NO_GO_ROLLOUT_GATE_TEST=PASS ✅"
echo "PHASE4B_GO_NO_GO_DECISION_MATRIX_TEST=PASS ✅"
echo "PHASE4B_ROLLOUT_BLOCKER_POLICY_TEST=PASS ✅"
echo "PHASE4B_SECURITY_TENANT_GATE_TEST=PASS ✅"
echo "PHASE4B_BUSINESS_CHAIN_GATE_TEST=PASS ✅"
echo "PHASE4B_SUPPORT_INCIDENT_GATE_TEST=PASS ✅"
echo "PHASE4B_GO_NO_GO_NO_RUNTIME_CHANGE_TEST=PASS ✅"
echo "PHASE4B_GO_NO_GO_SECRET_TEST=PASS ✅"
