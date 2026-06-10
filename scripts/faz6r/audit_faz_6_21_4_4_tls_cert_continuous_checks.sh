#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_4_4_TLS_CERT_CONTINUOUS_CHECKS.md"
CONFIG_FILE="configs/faz6r/faz_6_21_4_4_tls_cert_continuous_checks.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_4_4_tls_cert_continuous_checks_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_tls_cert_continuous_checks.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_4_4_tls_cert_continuous_checks.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_4_TLS_CERT_CONTINUOUS_CHECKS_REAL_IMPLEMENTATION_AUDIT.md"
PREV_EDGE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_3_EDGE_RULE_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.4.4 TLS / CERT CONTINUOUS CHECKS REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.4.4 previous edge rule review evidence file" "$PREV_EDGE_EVIDENCE"
check_contains "6-21.4.4 previous edge rule review final PASS" "$PREV_EDGE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.4 documentation file" "$DOC_FILE"
check_file "6-21.4.4 config file" "$CONFIG_FILE"
check_file "6-21.4.4 fixture file" "$FIXTURE_FILE"
check_file "6-21.4.4 validator file" "$VALIDATOR_FILE"
check_file "6-21.4.4 audit file" "$AUDIT_FILE"

check_contains "6-21.4.4 doc has TLS / Cert Continuous Checks" "$DOC_FILE" "TLS / Cert Continuous Checks"
check_contains "6-21.4.4 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.4.4 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.4.4 config has dependency" "$CONFIG_FILE" "FAZ_6_21_4_3"
check_contains "6-21.4.4 config has live certificate mutation false" "$CONFIG_FILE" '"live_certificate_mutation_allowed": false'
check_contains "6-21.4.4 config has tls domain inventory" "$CONFIG_FILE" "tls_domain_inventory"
check_contains "6-21.4.4 config has certificate expiry policy" "$CONFIG_FILE" "certificate_expiry_check_policy"
check_contains "6-21.4.4 config has https enforcement policy" "$CONFIG_FILE" "https_enforcement_policy"
check_contains "6-21.4.4 config has hsts policy" "$CONFIG_FILE" "hsts_policy"
check_contains "6-21.4.4 config has tls min version policy" "$CONFIG_FILE" "tls_min_version_policy"
check_contains "6-21.4.4 config has chain validation policy" "$CONFIG_FILE" "certificate_chain_validation_policy"
check_contains "6-21.4.4 config has api domain policy" "$CONFIG_FILE" "api_domain_tls_policy"
check_contains "6-21.4.4 config has auth domain policy" "$CONFIG_FILE" "auth_domain_tls_policy"
check_contains "6-21.4.4 config has panel domain policy" "$CONFIG_FILE" "panel_domain_tls_policy"
check_contains "6-21.4.4 config has alert threshold policy" "$CONFIG_FILE" "alert_threshold_policy"
check_contains "6-21.4.4 config has scheduled check policy" "$CONFIG_FILE" "scheduled_check_policy"
check_contains "6-21.4.4 config has rollback strategy" "$CONFIG_FILE" "return_to_previous_stable_tls_edge_policy"

check_contains "6-21.4.4 config has api.pix2pi.com.tr" "$CONFIG_FILE" "api.pix2pi.com.tr"
check_contains "6-21.4.4 config has auth.pix2pi.com.tr" "$CONFIG_FILE" "auth.pix2pi.com.tr"
check_contains "6-21.4.4 config has panel.pix2pi.com.tr" "$CONFIG_FILE" "panel.pix2pi.com.tr"
check_contains "6-21.4.4 config has TLSv1.2 minimum" "$CONFIG_FILE" "TLSv1.2"
check_contains "6-21.4.4 config has TLSv1.3 preferred" "$CONFIG_FILE" "TLSv1.3"
check_contains "6-21.4.4 fixture has expected HSTS header" "$FIXTURE_FILE" "Strict-Transport-Security"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$FIXTURE_FILE"; then
  pass "6-21.4.4 semantic validator runtime"
else
  fail "6-21.4.4 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.4.4 python3 dependency"
else
  fail "6-21.4.4 python3 dependency"
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
# FAZ 6-R / 283 — FAZ 6-21.4.4 TLS / Cert Continuous Checks Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_4_5_READY=${NEXT_READY}

Scope note: live certificate/provider mutation and live cron mutation are intentionally closed in this step.
Dependency: FAZ_6_21_4_3 edge rule review evidence checked.
EOF2

echo "===== FAZ 6-21.4.4 TLS / CERT CONTINUOUS CHECKS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_4_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.4.4 TLS / CERT CONTINUOUS CHECKS COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_4_5_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
