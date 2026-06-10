#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }

check_file() {
  local label="$1"; local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label file_missing=${file}"; fi
}

check_grep() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then pass "$label"; else fail "$label pattern_missing=${pattern}"; fi
}

echo "===== 173 — FAZ 3-12.7 ACCOUNTANT PORTAL TESTS REAL IMPLEMENTATION AUDIT START ====="

REPORT_FILE="web/faz3/accountant-portal/portal-tests/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/accountant_portal_tests.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS.md"
TEST_SCRIPT="scripts/faz3/faz_3_12_7_accountant_portal_tests_suite.sh"

check_file "173 accountant portal tests report HTML file" "$REPORT_FILE"
check_file "173 accountant portal tests config file" "$CONFIG_FILE"
check_file "173 accountant portal tests documentation file" "$DOC_FILE"
check_file "173 accountant portal tests suite script file" "$TEST_SCRIPT"

check_grep "173 report phase marker" "$REPORT_FILE" "FAZ_3_12_7"
check_grep "173 report screen marker" "$REPORT_FILE" "ACCOUNTANT_PORTAL_TESTS_REPORT"
check_grep "173 report title surface" "$REPORT_FILE" "Muhasebeci Portal Testleri"
check_grep "173 report 167 coverage" "$REPORT_FILE" "167.*Export Workspace"
check_grep "173 report 168 coverage" "$REPORT_FILE" "168.*Çok Firmalı"
check_grep "173 report 169 coverage" "$REPORT_FILE" "169.*Firma Değiştirici"
check_grep "173 report 170 coverage" "$REPORT_FILE" "170.*Firma Bazlı"
check_grep "173 report 171 coverage" "$REPORT_FILE" "171.*Abonelik"
check_grep "173 report 172 coverage" "$REPORT_FILE" "172.*Portal Audit"
check_grep "173 report cross tenant closed" "$REPORT_FILE" "Cross Tenant: CLOSED"
check_grep "173 report production false" "$REPORT_FILE" "Production: FALSE"
check_grep "173 report read only policy" "$REPORT_FILE" "READ-ONLY|Canlı aksiyon yok"
check_grep "173 report live closed policy" "$REPORT_FILE" "Real billing: CLOSED|Real external delivery: CLOSED|Audit delete/mutation: CLOSED"

check_grep "173 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "173 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/portal-tests/\""
check_grep "173 config report file" "$CONFIG_FILE" "\"report_file\": \"web/faz3/accountant-portal/portal-tests/index.html\""
check_grep "173 config test script" "$CONFIG_FILE" "faz_3_12_7_accountant_portal_tests_suite.sh"
check_grep "173 config audit script" "$CONFIG_FILE" "faz_3_12_7_accountant_portal_tests_audit.sh"
check_grep "173 config 167 coverage" "$CONFIG_FILE" "\"screen_167_export_workspace\""
check_grep "173 config 168 coverage" "$CONFIG_FILE" "\"screen_168_multi_company_workspace\""
check_grep "173 config 169 coverage" "$CONFIG_FILE" "\"screen_169_company_switcher\""
check_grep "173 config 170 coverage" "$CONFIG_FILE" "\"screen_170_company_permissions\""
check_grep "173 config 171 coverage" "$CONFIG_FILE" "\"screen_171_subscription_status\""
check_grep "173 config 172 coverage" "$CONFIG_FILE" "\"screen_172_audit_history\""
check_grep "173 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "173 config readonly tests true" "$CONFIG_FILE" "\"accountant_portal_tests_are_static_and_readonly\": true"
check_grep "173 config cross tenant false" "$CONFIG_FILE" "\"cross_tenant_access_allowed\": false"
check_grep "173 config real billing false" "$CONFIG_FILE" "\"real_billing_allowed\": false"
check_grep "173 config real payment collection false" "$CONFIG_FILE" "\"real_payment_collection_allowed\": false"
check_grep "173 config real invoice issue false" "$CONFIG_FILE" "\"real_invoice_issue_allowed\": false"
check_grep "173 config external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "173 config audit delete false" "$CONFIG_FILE" "\"audit_delete_allowed\": false"
check_grep "173 config audit mutation false" "$CONFIG_FILE" "\"audit_mutation_allowed\": false"
check_grep "173 config previous gate" "$CONFIG_FILE" "FAZ_3_12_6_PORTAL_AUDIT_HISTORY"
check_grep "173 config next gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"

echo "===== 173 — RUN ACCOUNTANT PORTAL TEST SUITE FROM AUDIT ====="
if "$TEST_SCRIPT"; then
  pass "173 accountant portal test suite execution"
else
  fail "173 accountant portal test suite execution"
fi

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_access_allowed\"[[:space:]]*:[[:space:]]*true|\"real_billing_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_collection_allowed\"[[:space:]]*:[[:space:]]*true|\"real_invoice_issue_allowed\"[[:space:]]*:[[:space:]]*true|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "173 live policy accountant portal tests guard"
else
  pass "173 live policy accountant portal tests guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 173 — FAZ 3-12.7 — Accountant Portal Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_1_READY=${NEXT_READY}

## Scope

- 167 Excel / PDF / TDHP export workspace
- 168 Multi company workspace
- 169 Company switcher
- 170 Company based permission screen
- 171 Subscription status view
- 172 Portal audit history
- Route/config/evidence coverage
- Tenant/accountant/firm-scope guard coverage
- Audit hash / evidence trace coverage
- Closed live policy coverage

## Live Policy

- Production approved: FALSE
- Cross tenant access: CLOSED
- Real billing: CLOSED
- Real payment collection: CLOSED
- Real invoice issue: CLOSED
- Real external delivery: CLOSED
- Audit delete: CLOSED
- Audit mutation: CLOSED
- UI actions are navigation/evidence only.

## Audit Notes

Final status is derived from real screen/config/doc files, real suite execution, and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 173 — FAZ 3-12.7 ACCOUNTANT PORTAL TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
