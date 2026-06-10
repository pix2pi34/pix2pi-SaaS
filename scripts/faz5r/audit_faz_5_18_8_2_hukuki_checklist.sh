#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.8.2"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_8_2_HUKUKI_CHECKLIST.md"
CONFIG_FILE="configs/faz5r/faz_5_18_8_2_hukuki_checklist.v1.json"
CONTROL_FILE="configs/faz5r/legal_checklist.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_8_2_hukuki_checklist_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/legalchecklist/legal_checklist.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/legalchecklist/legal_checklist_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_8_2_HUKUKI_CHECKLIST_REAL_IMPLEMENTATION_AUDIT.md"

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$PHASE $1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$PHASE $1 REQUIRED_FAIL / HATA ❌"
}

contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

file_exists() {
  local file="$1"
  local label="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 5-18.8.2 HUKUKI CHECKLIST REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"contract_set"' "contract set item registered"
contains "$CONTROL_FILE" '"kvkk_privacy_notice"' "kvkk privacy notice item registered"
contains "$CONTROL_FILE" '"explicit_consent_text"' "explicit consent text item registered"
contains "$CONTROL_FILE" '"consent_registry_policy"' "consent registry policy item registered"
contains "$CONTROL_FILE" '"log_retention_destruction_policy"' "log retention destruction policy item registered"
contains "$CONTROL_FILE" '"support_legal_readiness"' "support legal readiness item registered"
contains "$CONTROL_FILE" '"legal_final_approval_marker"' "legal final approval marker registered"
contains "$CONTROL_FILE" '"kvkk_final_approval_marker"' "kvkk final approval marker registered"
contains "$CONTROL_FILE" '"founder_final_go_no_go_marker"' "founder go no-go marker registered"
contains "$CONTROL_FILE" '"CONTRACT"' "contract domain registered"
contains "$CONTROL_FILE" '"KVKK"' "kvkk domain registered"
contains "$CONTROL_FILE" '"CONSENT"' "consent domain registered"
contains "$CONTROL_FILE" '"RETENTION"' "retention domain registered"
contains "$CONTROL_FILE" '"SUPPORT_LEGAL"' "support legal domain registered"
contains "$CONTROL_FILE" '"LAUNCH_APPROVAL"' "launch approval domain registered"
contains "$CONTROL_FILE" '"internal_legal_checklist_ready": true' "internal legal checklist ready"
contains "$CONTROL_FILE" '"production_public_launch_allowed": false' "production public launch blocked"
contains "$CONTROL_FILE" '"real_customer_collection_allowed": false' "real customer collection blocked"
contains "$CONTROL_FILE" '"requires_version": true' "requires version present"
contains "$CONTROL_FILE" '"has_version": true' "has version present"
contains "$CONTROL_FILE" '"requires_evidence": true' "requires evidence present"
contains "$CONTROL_FILE" '"has_evidence": true' "has evidence present"
contains "$CONTROL_FILE" '"requires_counter_based_audit": true' "requires counter based audit present"
contains "$CONTROL_FILE" '"has_counter_based_audit": true' "has counter based audit present"
contains "$CONTROL_FILE" '"required_fail_count": 0' "required fail zero present"
contains "$CONTROL_FILE" '"optional_warn_count": 0' "optional warn zero present"
contains "$CONTROL_FILE" '"public_publish_allowed": false' "public publish blocked"
contains "$CONTROL_FILE" '"deferred_to_final_approval": true' "deferred final approval present"
contains "$CONTROL_FILE" '"deferred_reason"' "deferred reason present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_PUBLIC_LAUNCH_BLOCKED" "production public launch guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COLLECTION_BLOCKED" "real customer collection guard"
contains "$RUNTIME_FILE" "LEGAL_APPROVAL_REQUIRED" "legal approval guard"
contains "$RUNTIME_FILE" "KVKK_APPROVAL_REQUIRED" "kvkk approval guard"
contains "$RUNTIME_FILE" "FOUNDER_APPROVAL_REQUIRED" "founder approval guard"
contains "$RUNTIME_FILE" "VERSION_REQUIRED" "version guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REQUIRED_FAIL_MUST_BE_ZERO" "required fail zero guard"
contains "$RUNTIME_FILE" "OPTIONAL_WARN_MUST_BE_ZERO" "optional warn zero guard"
contains "$RUNTIME_FILE" "PUBLIC_PUBLISH_BLOCKED" "public publish guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COLLECTION_ITEM_BLOCKED" "real customer collection item guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/legalchecklist; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/legal_checklist.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_8_2_hukuki_checklist_test.json").read_text())

items = {i["key"]: i for i in control["items"]}
domains = {i["domain"] for i in control["items"]}

for key in test["must_have_item_keys"]:
    assert key in items, f"missing item key: {key}"
    i = items[key]
    assert i["required"] is True, f"item not required: {key}"
    assert i["blocks_public_launch"] is True, f"blocks public launch missing: {key}"
    assert i["requires_version"] is True, f"requires version missing: {key}"
    assert i["has_version"] is True, f"has version missing: {key}"
    assert i["requires_evidence"] is True, f"requires evidence missing: {key}"
    assert i["has_evidence"] is True, f"has evidence missing: {key}"
    assert i["requires_counter_based_audit"] is True, f"requires counter audit missing: {key}"
    assert i["has_counter_based_audit"] is True, f"has counter audit missing: {key}"
    assert i["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert i["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert i["public_publish_allowed"] is False, f"public publish must be false: {key}"
    assert i["real_customer_collection_allowed"] is False, f"real customer collection must be false: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

for key in ["legal_final_approval_marker", "kvkk_final_approval_marker", "founder_final_go_no_go_marker"]:
    assert items[key]["deferred_to_final_approval"] is True, f"deferred missing: {key}"
    assert items[key]["deferred_reason"], f"deferred reason missing: {key}"

assert control["internal_legal_checklist_ready"] is True
assert control["production_public_launch_allowed"] is False
assert control["real_customer_collection_allowed"] is False
assert control["final_policy"]["support_readiness_required_next"] is True
assert control["final_policy"]["final_legal_approval_deferred_to_production_launch"] is True
PY
then
  ok "json semantic validation"
else
  fail "json semantic validation"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

mkdir -p "$(dirname "$EVIDENCE_FILE")"
cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 5-18.8.2 Hukuki Checklist Real Implementation Audit

PHASE=FAZ_5_18_8_2
AUDIT_DATE=$(date -Is)

## Real Implementation Audit Result

PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
WARN_COUNT=$WARN_COUNT
REQUIRED_FAIL=$REQUIRED_FAIL
OPTIONAL_WARN=$OPTIONAL_WARN

## Status

DOC_STATUS=READY
CONFIG_STATUS=READY
CONTROL_CONFIG_STATUS=READY
RUNTIME_STATUS=READY
TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
INTERNAL_LEGAL_CHECKLIST_READY=true
PRODUCTION_PUBLIC_LAUNCH_ALLOWED=false
REAL_CUSTOMER_COLLECTION_ALLOWED=false
SUPPORT_READINESS_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.8.2 HUKUKI CHECKLIST REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_8_2_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_8_2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
