#!/usr/bin/env bash
set -euo pipefail

PHASE_SLUG="faz_5_18_3_4_consent_registry_runtime"
DOC_FILE="docs/faz5r/FAZ_5_18_3_4_CONSENT_REGISTRY_RUNTIME.md"
CONFIG_FILE="configs/faz5r/${PHASE_SLUG}.v1.json"
TEST_FILE="tests/faz5r/${PHASE_SLUG}_test.json"
GO_DIR="internal/commercial/publiclaunch/consent"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 MISSING_OR_INVALID / HATA ❌"
}

check_file() {
  local label="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"

  if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 5-18.3.4 CONSENT REGISTRY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "5-18.3.4 documentation file" "$DOC_FILE"
check_file "5-18.3.4 config file" "$CONFIG_FILE"
check_file "5-18.3.4 test fixture file" "$TEST_FILE"
check_file "5-18.3.4 Go runtime file" "$GO_DIR/consent_registry.go"
check_file "5-18.3.4 Go test file" "$GO_DIR/consent_registry_test.go"

if go test ./internal/commercial/publiclaunch/consent; then
  pass "5-18.3.4 go test status is PASS"
else
  fail "5-18.3.4 go test status"
fi

if python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

assert data["phase"] == "FAZ 5-R"
assert data["step_no"] == 244
assert data["step_code"] == "FAZ_5_18_3_4"
assert data["public_publish_allowed"] is False
assert data["core_product_allowed"] is True
assert data["data_monetization_guarded"] is True
assert data["commercial_benefit_guarded"] is True
assert data["runtime_required"] is True

required_fields = set(data["required_fields"])
for field in [
    "tenant_id",
    "user_id",
    "consent_scope",
    "consent_status",
    "document_version",
    "accepted_at",
    "revoked_at",
    "ip_address",
    "user_agent",
    "channel",
    "evidence_hash",
    "correlation_id",
]:
    assert field in required_fields, field

scopes = set(data["consent_scopes"])
assert len(scopes) == 7
for scope in [
    "DATA_SUPPORTED_PLAN_TERMS",
    "PERSONAL_DATA_COMMERCIAL_RECOMMENDATION",
    "SPONSORED_OFFER_PERSONALIZATION",
    "ANONYMIZED_AGGREGATED_INSIGHT",
    "AI_DECISION_SUPPORT",
    "COMMERCIAL_ELECTRONIC_MESSAGE",
    "NON_ESSENTIAL_COOKIES",
]:
    assert scope in scopes, scope

gates = data["feature_gates"]
assert gates["core_product"]["requires_consent"] is False
assert gates["core_product"]["default_allowed"] is True
assert gates["data_supported_plan"]["requires_scope"] == "DATA_SUPPORTED_PLAN_TERMS"
assert gates["commercial_electronic_message"]["requires_scope"] == "COMMERCIAL_ELECTRONIC_MESSAGE"
assert gates["non_essential_cookies"]["requires_scope"] == "NON_ESSENTIAL_COOKIES"

PY
then
  pass "5-18.3.4 config semantic validation"
else
  fail "5-18.3.4 config semantic validation"
fi

if python3 - "$TEST_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

expected = data["expected"]
assert data["step_no"] == 244
assert data["step_code"] == "FAZ_5_18_3_4"
assert expected["core_product_allowed_without_consent"] is True
assert expected["data_supported_plan_blocked_without_consent"] is True
assert expected["restricted_paid_route_when_declined"] is True
assert expected["feature_gate_integration"] is True
assert expected["evidence_hash_required"] is True
assert expected["tenant_scoped"] is True
assert expected["user_scoped"] is True
assert expected["revocation_blocks_feature"] is True
assert expected["required_scope_count"] == 7

PY
then
  pass "5-18.3.4 test fixture semantic validation"
else
  fail "5-18.3.4 test fixture semantic validation"
fi

check_grep "5-18.3.4 runtime has consent decision type" "type ConsentDecision" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime has accept function" "func (r \\*Registry) Accept" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime has decline function" "func (r \\*Registry) Decline" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime has revoke function" "func (r \\*Registry) Revoke" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime has evidence hash" "evidenceHash" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime has feature gate decision" "FeatureGateDecision" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime core product allowed" "core product is allowed separately" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 runtime restricted paid route" "RESTRICTED_PAID_OR_DISABLED" "$GO_DIR/consent_registry.go"
check_grep "5-18.3.4 test core product allowed" "TestCoreProductAllowedWithoutConsent" "$GO_DIR/consent_registry_test.go"
check_grep "5-18.3.4 test data supported blocked" "TestDataSupportedPlanBlockedWithoutConsent" "$GO_DIR/consent_registry_test.go"
check_grep "5-18.3.4 test revoke blocks feature" "TestRevokeBlocksFeatureAgain" "$GO_DIR/consent_registry_test.go"
check_grep "5-18.3.4 documentation feature gate behavior" "Feature Gate Davranışı" "$DOC_FILE"
check_grep "5-18.3.4 documentation core product distinction" "Core Product Ayrımı" "$DOC_FILE"
check_grep "5-18.3.4 documentation audit fields" "evidence_hash" "$DOC_FILE"

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  DOC_STATUS="READY"
  CONFIG_STATUS="READY"
  CODE_STATUS="READY"
  RUNTIME_STATUS="READY"
  TEST_STATUS="PASS"
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  DOC_STATUS="BLOCKED"
  CONFIG_STATUS="BLOCKED"
  CODE_STATUS="BLOCKED"
  RUNTIME_STATUS="BLOCKED"
  TEST_STATUS="FAIL"
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat <<RESULT

===== FAZ 5-18.3.4 CONSENT REGISTRY RUNTIME REAL IMPLEMENTATION AUDIT RESULT =====
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${AUDIT_EVIDENCE_FILE:-docs/faz5r/evidence/FAZ_5_18_3_4_CONSENT_REGISTRY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}
FAZ_5_18_3_4_DOC_STATUS=${DOC_STATUS}
FAZ_5_18_3_4_CONFIG_STATUS=${CONFIG_STATUS}
FAZ_5_18_3_4_CODE_STATUS=${CODE_STATUS}
FAZ_5_18_3_4_RUNTIME_STATUS=${RUNTIME_STATUS}
FAZ_5_18_3_4_TEST_STATUS=${TEST_STATUS}
FAZ_5_18_3_4_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FAZ_5_18_3_4_FINAL_STATUS=${FINAL_STATUS}
FAZ_5_18_3_5_READY=${NEXT_READY}
RESULT

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  exit 0
fi

exit 1
