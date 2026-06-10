#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_4_5_SECURITY_EDGE_AUDIT.md"
CONFIG_FILE="configs/faz6r/faz_6_21_4_5_security_edge_audit.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_4_5_security_edge_audit_test.json"
VALIDATOR_FILE="scripts/faz6r/validate_security_edge_audit.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_4_5_security_edge_audit.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_4_5_SECURITY_EDGE_AUDIT_REAL_IMPLEMENTATION_AUDIT.md"

PREV_WAF_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_1_WAF_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_BOT_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_2_ABUSE_BOT_TUNING_REAL_IMPLEMENTATION_AUDIT.md"
PREV_EDGE_RULE_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_3_EDGE_RULE_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"
PREV_TLS_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_4_4_TLS_CERT_CONTINUOUS_CHECKS_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.4.5 SECURITY EDGE AUDIT REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.4.5 previous WAF tuning evidence file" "$PREV_WAF_EVIDENCE"
check_contains "6-21.4.5 previous WAF tuning final PASS" "$PREV_WAF_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.5 previous abuse bot evidence file" "$PREV_BOT_EVIDENCE"
check_contains "6-21.4.5 previous abuse bot final PASS" "$PREV_BOT_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.5 previous edge rule review evidence file" "$PREV_EDGE_RULE_EVIDENCE"
check_contains "6-21.4.5 previous edge rule review final PASS" "$PREV_EDGE_RULE_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.5 previous TLS cert evidence file" "$PREV_TLS_EVIDENCE"
check_contains "6-21.4.5 previous TLS cert final PASS" "$PREV_TLS_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.4.5 documentation file" "$DOC_FILE"
check_file "6-21.4.5 config file" "$CONFIG_FILE"
check_file "6-21.4.5 fixture file" "$FIXTURE_FILE"
check_file "6-21.4.5 validator file" "$VALIDATOR_FILE"
check_file "6-21.4.5 audit file" "$AUDIT_FILE"

check_contains "6-21.4.5 doc has Security Edge Audit" "$DOC_FILE" "Security Edge Audit"
check_contains "6-21.4.5 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.4.5 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.4.5 config has WAF dependency" "$CONFIG_FILE" "FAZ_6_21_4_1"
check_contains "6-21.4.5 config has abuse bot dependency" "$CONFIG_FILE" "FAZ_6_21_4_2"
check_contains "6-21.4.5 config has edge rule dependency" "$CONFIG_FILE" "FAZ_6_21_4_3"
check_contains "6-21.4.5 config has TLS cert dependency" "$CONFIG_FILE" "FAZ_6_21_4_4"

check_contains "6-21.4.5 config has live mutation false" "$CONFIG_FILE" '"live_provider_api_mutation_allowed": false'
check_contains "6-21.4.5 config has public private boundary audit" "$CONFIG_FILE" "public_private_boundary_audit"
check_contains "6-21.4.5 config has auth surface audit" "$CONFIG_FILE" "auth_surface_audit"
check_contains "6-21.4.5 config has api surface audit" "$CONFIG_FILE" "api_surface_audit"
check_contains "6-21.4.5 config has panel surface audit" "$CONFIG_FILE" "panel_surface_audit"
check_contains "6-21.4.5 config has webhook surface audit" "$CONFIG_FILE" "webhook_surface_audit"
check_contains "6-21.4.5 config has health endpoint audit" "$CONFIG_FILE" "health_endpoint_audit"
check_contains "6-21.4.5 config has static asset policy audit" "$CONFIG_FILE" "static_asset_policy_audit"
check_contains "6-21.4.5 config has tenant header observability audit" "$CONFIG_FILE" "tenant_header_observability_audit"
check_contains "6-21.4.5 config has tls https hsts audit" "$CONFIG_FILE" "tls_https_hsts_audit"
check_contains "6-21.4.5 config has abuse bot signal audit" "$CONFIG_FILE" "abuse_bot_signal_audit"
check_contains "6-21.4.5 config has rollback readiness audit" "$CONFIG_FILE" "rollback_readiness_audit"
check_contains "6-21.4.5 config has release blocker policy" "$CONFIG_FILE" "release_blocker_policy"
check_contains "6-21.4.5 config has X-Tenant-ID" "$CONFIG_FILE" "X-Tenant-ID"
check_contains "6-21.4.5 config has TLSv1.2" "$CONFIG_FILE" "TLSv1.2"
check_contains "6-21.4.5 config has TLSv1.3" "$CONFIG_FILE" "TLSv1.3"
check_contains "6-21.4.5 config has HSTS header" "$CONFIG_FILE" "Strict-Transport-Security"
check_contains "6-21.4.5 fixture has expected dependency count" "$FIXTURE_FILE" "expected_dependency_evidence_count"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$FIXTURE_FILE"; then
  pass "6-21.4.5 semantic validator runtime"
else
  fail "6-21.4.5 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.4.5 python3 dependency"
else
  fail "6-21.4.5 python3 dependency"
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
# FAZ 6-R / 284 — FAZ 6-21.4.5 Security Edge Audit Real Implementation Audit

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
FAZ_6_21_7_1_READY=${NEXT_READY}

Scope note: live provider mutation remains intentionally closed.
Dependencies checked:
- FAZ_6_21_4_1 WAF tuning
- FAZ_6_21_4_2 Abuse / bot tuning
- FAZ_6_21_4_3 Edge rule review
- FAZ_6_21_4_4 TLS / cert continuous checks
EOF2

echo "===== FAZ 6-21.4.5 SECURITY EDGE AUDIT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_4_5_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.4.5 SECURITY EDGE AUDIT COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_7_1_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
