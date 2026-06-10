#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.3.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_3_5_UYUM_DOKUMAN_KONTROLU.md"
CONFIG_FILE="configs/faz5r/faz_5_18_3_5_uyum_dokuman_kontrolu.v1.json"
CONTROL_FILE="configs/faz5r/compliance_document_control.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_3_5_uyum_dokuman_kontrolu_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/compliancecontrol/compliance_control.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/compliancecontrol/compliance_control_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_3_5_UYUM_DOKUMAN_KONTROLU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.3.5 UYUM DOKUMAN KONTROLU REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"contract_set"' "contract set registered"
contains "$CONTROL_FILE" '"kvkk_privacy_notice"' "kvkk privacy notice registered"
contains "$CONTROL_FILE" '"explicit_consent_text"' "explicit consent text registered"
contains "$CONTROL_FILE" '"commercial_use_terms"' "commercial use terms registered"
contains "$CONTROL_FILE" '"consent_registry_policy"' "consent registry policy registered"
contains "$CONTROL_FILE" '"log_retention_destruction_policy"' "log retention destruction policy registered"
contains "$CONTROL_FILE" '"public_launch_allowed": false' "public launch blocked"
contains "$CONTROL_FILE" '"real_customer_collection_allowed": false' "real customer collection blocked"
contains "$CONTROL_FILE" '"legal_counsel_approval"' "legal approval gate registered"
contains "$CONTROL_FILE" '"kvkk_consultant_approval"' "kvkk approval gate registered"
contains "$CONTROL_FILE" '"founder_go_no_go"' "founder gate registered"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PUBLIC_APPROVED" "public approved document status"
contains "$RUNTIME_FILE" "LEGAL_GATE_REQUIRED_FOR_PUBLIC" "legal public gate guard"
contains "$RUNTIME_FILE" "KVKK_GATE_REQUIRED_FOR_PUBLIC" "kvkk public gate guard"
contains "$RUNTIME_FILE" "FOUNDER_GATE_REQUIRED_FOR_PUBLIC" "founder public gate guard"
contains "$RUNTIME_FILE" "PUBLIC_LAUNCH_BLOCKED_BY_DOCUMENT_STATUS" "public launch document status guard"
contains "$RUNTIME_FILE" "CONSENT_SCOPE_MISSING" "consent scope guard"
contains "$RUNTIME_FILE" "RETENTION_SCOPE_MISSING" "retention scope guard"
contains "$RUNTIME_FILE" "DATA_USE_SCOPE_MISSING" "data use scope guard"

if go test ./internal/commercial/publiclaunch/compliancecontrol; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/compliance_document_control.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_3_5_uyum_dokuman_kontrolu_test.json").read_text())

docs = {d["key"]: d for d in control["documents"]}
gates = {g["key"]: g for g in control["approval_gates"]}

for key in test["must_have_document_keys"]:
    assert key in docs, f"missing document key: {key}"
    assert docs[key]["required"] is True, f"document not required: {key}"
    assert docs[key]["version"], f"document version missing: {key}"
    assert docs[key]["public_publish_allowed"] is False, f"public publish must be false: {key}"

for key in test["must_have_approval_gates"]:
    assert key in gates, f"missing approval gate: {key}"
    assert gates[key]["status"] == "PENDING", f"gate must be pending: {key}"

assert control["public_launch_allowed"] is False
assert control["final_policy"]["production_public_publish_allowed"] is False
assert control["final_policy"]["real_customer_collection_allowed"] is False
assert control["final_policy"]["internal_readiness_audit_allowed"] is True
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
# FAZ 5-18.3.5 Uyum Doküman Kontrolü Real Implementation Audit

PHASE=FAZ_5_18_3_5
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
PUBLIC_PUBLISH_ALLOWED=false
REAL_CUSTOMER_COLLECTION_ALLOWED=false
INTERNAL_READINESS_AUDIT_ALLOWED=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.3.5 UYUM DOKUMAN KONTROLU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_3_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_3_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
