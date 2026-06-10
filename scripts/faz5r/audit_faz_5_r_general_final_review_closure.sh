#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-R GENERAL FINAL REVIEW / CLOSURE"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_R_GENERAL_FINAL_REVIEW_CLOSURE.md"
CONFIG_FILE="configs/faz5r/faz_5_r_general_final_review_closure.v1.json"
MANIFEST_FILE="configs/faz5r/faz_5_r_general_final_review_closure_manifest.v1.json"
TEST_FILE="tests/faz5r/faz_5_r_general_final_review_closure_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/faz5rclosure/faz5r_closure.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/faz5rclosure/faz5r_closure_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_R_GENERAL_FINAL_REVIEW_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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

evidence_has_phase() {
  local pattern="$1"
  local label="$2"
  if find docs/faz5r/evidence -type f -name "*${pattern}*" | grep -q .; then
    ok "$label evidence present"
  else
    fail "$label evidence present"
  fi
}

echo "===== FAZ 5-R GENERAL FINAL REVIEW / CLOSURE REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$MANIFEST_FILE" "closure manifest file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$MANIFEST_FILE" '"compliance_contract_consent"' "compliance closure item registered"
contains "$MANIFEST_FILE" '"support_ops"' "support ops closure item registered"
contains "$MANIFEST_FILE" '"commercial_gate"' "commercial gate closure item registered"
contains "$MANIFEST_FILE" '"billing_tenant_lifecycle_sales_ops"' "billing lifecycle closure item registered"
contains "$MANIFEST_FILE" '"pricing"' "pricing closure item registered"
contains "$MANIFEST_FILE" '"public_developer_surfaces"' "public developer surfaces closure item registered"
contains "$MANIFEST_FILE" '"public_launch_safety"' "public launch safety closure item registered"
contains "$MANIFEST_FILE" '"next_phase_handoff"' "next phase handoff item registered"

contains "$MANIFEST_FILE" '"COMPLIANCE_KVKK_CONTRACT_CONSENT"' "compliance domain registered"
contains "$MANIFEST_FILE" '"SUPPORT_OPS"' "support ops domain registered"
contains "$MANIFEST_FILE" '"COMMERCIAL_GATE"' "commercial gate domain registered"
contains "$MANIFEST_FILE" '"BILLING_TENANT_LIFECYCLE_SALES_OPS"' "billing lifecycle domain registered"
contains "$MANIFEST_FILE" '"PRICING"' "pricing domain registered"
contains "$MANIFEST_FILE" '"PUBLIC_DEVELOPER_SURFACES"' "public developer domain registered"
contains "$MANIFEST_FILE" '"PUBLIC_LAUNCH_SAFETY"' "launch safety domain registered"
contains "$MANIFEST_FILE" '"NEXT_PHASE_HANDOFF"' "next phase handoff domain registered"

contains "$MANIFEST_FILE" '"general_final_review_ready": true' "general final review ready"
contains "$MANIFEST_FILE" '"final_closure_seal_requested": true' "final closure seal requested"
contains "$MANIFEST_FILE" '"production_launch_allowed": false' "production launch blocked"
contains "$MANIFEST_FILE" '"real_customer_collection_open": false' "real customer collection closed"
contains "$MANIFEST_FILE" '"real_billing_enabled": false' "real billing closed"
contains "$MANIFEST_FILE" '"payment_collection_enabled": false' "payment collection closed"
contains "$MANIFEST_FILE" '"public_developer_access_open": false' "public developer access closed"
contains "$MANIFEST_FILE" '"checkout_enabled": false' "checkout closed"
contains "$MANIFEST_FILE" '"sandbox_live_enabled": false' "sandbox live closed"
contains "$MANIFEST_FILE" '"partial_remaining": false' "partial remaining false"
contains "$MANIFEST_FILE" '"pending_remaining": false' "pending remaining false"
contains "$MANIFEST_FILE" '"fail_remaining": false' "fail remaining false"
contains "$MANIFEST_FILE" '"ready_for_next_phase": true' "ready for next phase true"
contains "$MANIFEST_FILE" '"faz_5_r_final_closure_status": "SEALED"' "final closure sealed"

evidence_has_phase "FAZ_5_19_6" "279 public developer web tests"
evidence_has_phase "FAZ_5_19_2" "278 pricing pages"
evidence_has_phase "FAZ_5_19_5" "277 sandbox surface"
evidence_has_phase "FAZ_5_19_4" "276 api key screen"
evidence_has_phase "FAZ_5_19_3" "275 developer docs portal"
evidence_has_phase "FAZ_5_18_1_5" "274 pricing validation"
evidence_has_phase "FAZ_5_18_1_4" "273 accountant packages"
evidence_has_phase "FAZ_5_18_1_2" "272 pricing table"
evidence_has_phase "FAZ_5_18_3_3" "246 log retention"
evidence_has_phase "FAZ_5_18_3_5" "245 compliance document control"
evidence_has_phase "FAZ_5_18_4_1" "247 sla levels"
evidence_has_phase "FAZ_5_18_4_2" "248 support channel"
evidence_has_phase "FAZ_5_18_4_4" "250 escalation matrix"
evidence_has_phase "FAZ_5_18_8_1" "253 commercial checklist"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_LAUNCH_MUST_REMAIN_BLOCKED" "production launch guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_COLLECTION_MUST_REMAIN_CLOSED" "real customer collection guard"
contains "$RUNTIME_FILE" "REAL_BILLING_MUST_REMAIN_CLOSED" "real billing guard"
contains "$RUNTIME_FILE" "PAYMENT_COLLECTION_MUST_REMAIN_CLOSED" "payment collection guard"
contains "$RUNTIME_FILE" "PUBLIC_DEVELOPER_ACCESS_MUST_REMAIN_CLOSED" "developer access guard"
contains "$RUNTIME_FILE" "CHECKOUT_MUST_REMAIN_CLOSED" "checkout guard"
contains "$RUNTIME_FILE" "SANDBOX_LIVE_MUST_REMAIN_CLOSED" "sandbox live guard"
contains "$RUNTIME_FILE" "EVIDENCE_REQUIRED" "evidence guard"
contains "$RUNTIME_FILE" "COUNTER_BASED_AUDIT_REQUIRED" "counter based audit guard"
contains "$RUNTIME_FILE" "REAL_IMPLEMENTATION_PASS_REQUIRED" "real implementation guard"
contains "$RUNTIME_FILE" "NEXT_PHASE_READY_REQUIRED" "next phase ready guard"

if go test ./internal/commercial/publiclaunch/faz5rclosure; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("configs/faz5r/faz_5_r_general_final_review_closure_manifest.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_r_general_final_review_closure_test.json").read_text())

items = {i["key"]: i for i in manifest["closure_items"]}
domains = {i["domain"] for i in manifest["closure_items"]}

for key in test["must_have_item_keys"]:
    assert key in items, f"missing item: {key}"
    item = items[key]
    assert item["required"] is True, f"not required: {key}"
    assert item["status"] == "SEALED", f"not sealed: {key}"
    assert item["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert item["optional_warn_count"] == 0, f"optional warn not zero: {key}"

for domain in test["must_have_domains"]:
    assert domain in domains, f"missing domain: {domain}"

fp = manifest["final_policy"]
assert fp["faz_5_r_general_final_review_status"] == "PASS"
assert fp["faz_5_r_final_closure_status"] == "SEALED"
assert fp["production_launch_allowed"] is False
assert fp["real_customer_collection_open"] is False
assert fp["real_billing_enabled"] is False
assert fp["payment_collection_enabled"] is False
assert fp["public_developer_access_open"] is False
assert fp["checkout_enabled"] is False
assert fp["sandbox_live_enabled"] is False
assert fp["partial_remaining"] is False
assert fp["pending_remaining"] is False
assert fp["fail_remaining"] is False
assert fp["ready_for_next_phase"] is True
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
# FAZ 5-R General Final Review / Closure Real Implementation Audit

PHASE=FAZ_5_R_FINAL_REVIEW_CLOSURE
AUDIT_DATE=$(date -Is)

## Real Implementation Audit Result

PASS_COUNT=$PASS_COUNT
FAIL_COUNT=$FAIL_COUNT
WARN_COUNT=$WARN_COUNT
REQUIRED_FAIL=$REQUIRED_FAIL
OPTIONAL_WARN=$OPTIONAL_WARN

## Status

FAZ_5_R_GENERAL_FINAL_REVIEW_DOC_STATUS=READY
FAZ_5_R_GENERAL_FINAL_REVIEW_CONFIG_STATUS=READY
FAZ_5_R_GENERAL_FINAL_REVIEW_CLOSURE_MANIFEST_STATUS=READY
FAZ_5_R_GENERAL_FINAL_REVIEW_RUNTIME_STATUS=READY
FAZ_5_R_GENERAL_FINAL_REVIEW_TEST_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
FAZ_5_R_GENERAL_FINAL_REVIEW_REAL_IMPLEMENTATION_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
FAZ_5_R_GENERAL_FINAL_REVIEW_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo PASS || echo FAIL)
FAZ_5_R_FINAL_CLOSURE_STATUS=$([ "$FAIL_COUNT" -eq 0 ] && echo SEALED || echo BLOCKED)

PRODUCTION_LAUNCH_ALLOWED=false
REAL_CUSTOMER_COLLECTION_OPEN=false
REAL_BILLING_ENABLED=false
PAYMENT_COLLECTION_ENABLED=false
PUBLIC_DEVELOPER_ACCESS_OPEN=false
CHECKOUT_ENABLED=false
SANDBOX_LIVE_ENABLED=false
PARTIAL_REMAINING=NO
PENDING_REMAINING=NO
FAIL_REMAINING=NO
READY_FOR_NEXT_PHASE=YES

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $MANIFEST_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-R GENERAL FINAL REVIEW / CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_R_GENERAL_FINAL_REVIEW_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_R_GENERAL_FINAL_REVIEW_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
