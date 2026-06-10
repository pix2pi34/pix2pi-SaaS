#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_6_4_OPERASYONEL_ILETISIM_PLANI.md"
CONFIG_FILE="configs/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani.v1.json"
PLAN_FILE="configs/faz6r/operational_communication_plan.dr_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_6_4_operasyonel_iletisim_plani_test.json"
RUNTIME_FILE="scripts/faz6r/run_operational_communication_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_operasyonel_iletisim_plani.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_6_4_operasyonel_iletisim_plani.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_6_4_OPERASYONEL_ILETISIM_PLANI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_REGIONAL_OUTAGE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_6_3_BOLGESEL_KESINTI_SENARYOSU_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  if [ -f "$2" ]; then pass "$1"; else fail "$1 missing"; fi
}

check_contains(){
  if [ -f "$2" ] && grep -q "$3" "$2"; then pass "$1"; else fail "$1 missing pattern $3"; fi
}

echo "===== FAZ 6-21.6.4 OPERASYONEL ILETISIM PLANI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.6.4 previous regional outage evidence file" "$PREV_REGIONAL_OUTAGE_EVIDENCE"
check_contains "6-21.6.4 previous regional outage final PASS" "$PREV_REGIONAL_OUTAGE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.6.4 documentation file" "$DOC_FILE"
check_file "6-21.6.4 config file" "$CONFIG_FILE"
check_file "6-21.6.4 plan file" "$PLAN_FILE"
check_file "6-21.6.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.6.4 runtime file" "$RUNTIME_FILE"
check_file "6-21.6.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.6.4 audit file" "$AUDIT_FILE"

check_contains "6-21.6.4 doc has Operasyonel Iletisim Plani" "$DOC_FILE" "Operasyonel İletişim Planı"
check_contains "6-21.6.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.6.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.6.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_6_3"
check_contains "6-21.6.4 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.6.4 config disables customer notification" "$CONFIG_FILE" '"real_customer_notification_enabled": false'
check_contains "6-21.6.4 config disables status page" "$CONFIG_FILE" '"real_status_page_enabled": false'
check_contains "6-21.6.4 config disables email" "$CONFIG_FILE" '"real_email_enabled": false'
check_contains "6-21.6.4 config disables sms" "$CONFIG_FILE" '"real_sms_enabled": false'
check_contains "6-21.6.4 config disables phone call" "$CONFIG_FILE" '"real_phone_call_enabled": false'
check_contains "6-21.6.4 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.6.4 config has stakeholder matrix" "$CONFIG_FILE" "stakeholder_matrix"
check_contains "6-21.6.4 config has severity mapping" "$CONFIG_FILE" "severity_communication_mapping"
check_contains "6-21.6.4 config has internal update policy" "$CONFIG_FILE" "internal_update_policy"
check_contains "6-21.6.4 config has customer update policy" "$CONFIG_FILE" "customer_update_policy"
check_contains "6-21.6.4 config has status page policy" "$CONFIG_FILE" "status_page_policy"
check_contains "6-21.6.4 config has business owner approval" "$CONFIG_FILE" "business_owner_approval_policy"
check_contains "6-21.6.4 config has security owner approval" "$CONFIG_FILE" "security_owner_approval_policy"
check_contains "6-21.6.4 config has next update cadence" "$CONFIG_FILE" "next_update_cadence_policy"

check_contains "6-21.6.4 plan has internal channel" "$PLAN_FILE" "internal_incident_room"
check_contains "6-21.6.4 plan has customer draft channel" "$PLAN_FILE" "customer_update_draft"
check_contains "6-21.6.4 plan has status page draft channel" "$PLAN_FILE" "status_page_draft"
check_contains "6-21.6.4 plan has support macro draft" "$PLAN_FILE" "support_macro_draft"
check_contains "6-21.6.4 plan has record only mode" "$PLAN_FILE" "record_only_no_real_send"
check_contains "6-21.6.4 plan has P0 template" "$PLAN_FILE" "internal-p0-initial"
check_contains "6-21.6.4 plan has customer impact template" "$PLAN_FILE" "customer-impact-initial"
check_contains "6-21.6.4 plan has security impact template" "$PLAN_FILE" "security-impact-internal"

check_contains "6-21.6.4 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_6_5"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_6_4_operational_comm_runtime.json; then
  pass "6-21.6.4 dry-run communication runtime"
else
  fail "6-21.6.4 dry-run communication runtime"
fi

check_contains "6-21.6.4 runtime output is PASS" "/tmp/faz_6_21_6_4_operational_comm_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.6.4 runtime output is dry run" "/tmp/faz_6_21_6_4_operational_comm_runtime.json" "operational_communication_dry_run"
check_contains "6-21.6.4 runtime output disables provider mutation" "/tmp/faz_6_21_6_4_operational_comm_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.6.4 runtime output record only" "/tmp/faz_6_21_6_4_operational_comm_runtime.json" "DRY_RUN_COMMUNICATION_RECORD"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.6.4 semantic validator runtime"
else
  fail "6-21.6.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.6.4 python3 dependency"
else
  fail "6-21.6.4 python3 dependency"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 6-R / 291 — FAZ 6-21.6.4 Operasyonel İletişim Planı Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
PLAN_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_6_5_READY=${NEXT_READY}

Scope note: real customer notification, status page, email, SMS, phone call and provider mutation remain closed in this step.
Dependency: FAZ_6_21_6_3 bölgesel kesinti senaryosu evidence checked.
EOF2

echo "===== FAZ 6-21.6.4 OPERASYONEL ILETISIM PLANI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_6_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.6.4 OPERASYONEL ILETISIM PLANI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_6_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
