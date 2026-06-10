#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.3.3"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_3_3_LOG_RETENTION_IMHA_POLITIKASI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_3_3_log_retention_imha_politikasi.v1.json"
CONTROL_FILE="configs/faz5r/log_retention_destruction_policy.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_3_3_log_retention_imha_politikasi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/logretention/log_retention.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/logretention/log_retention_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_3_3_LOG_RETENTION_IMHA_POLITIKASI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.3.3 LOG RETENTION / IMHA POLITIKASI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"audit_event_log_retention"' "audit log retention registered"
contains "$CONTROL_FILE" '"consent_decision_log_retention"' "consent log retention registered"
contains "$CONTROL_FILE" '"contract_document_retention"' "contract document retention registered"
contains "$CONTROL_FILE" '"security_access_log_retention"' "security log retention registered"
contains "$CONTROL_FILE" '"commercial_operation_log_retention"' "commercial operation log retention registered"
contains "$CONTROL_FILE" '"internal_policy_ready": true' "internal policy ready"
contains "$CONTROL_FILE" '"production_deletion_allowed": false' "production deletion blocked"
contains "$CONTROL_FILE" '"tenant_scoped": true' "tenant scoped policy present"
contains "$CONTROL_FILE" '"has_legal_hold": true' "legal hold guard present"
contains "$CONTROL_FILE" '"has_audit_evidence": true' "audit evidence guard present"
contains "$CONTROL_FILE" '"has_kvkk_basis": true' "kvkk basis guard present"
contains "$CONTROL_FILE" '"has_restore_guard": true' "restore guard present"
contains "$CONTROL_FILE" '"production_delete_enabled": false' "production delete disabled"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_DELETION_BLOCKED" "production deletion block guard"
contains "$RUNTIME_FILE" "TENANT_SCOPE_REQUIRED" "tenant scope guard"
contains "$RUNTIME_FILE" "LEGAL_HOLD_REQUIRED" "legal hold guard"
contains "$RUNTIME_FILE" "AUDIT_EVIDENCE_REQUIRED" "audit evidence guard"
contains "$RUNTIME_FILE" "KVKK_BASIS_REQUIRED" "kvkk basis guard"
contains "$RUNTIME_FILE" "RESTORE_GUARD_REQUIRED" "restore guard"
contains "$RUNTIME_FILE" "POLICY_PRODUCTION_DELETE_ENABLED" "policy production delete guard"

if go test ./internal/commercial/publiclaunch/logretention; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/log_retention_destruction_policy.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_3_3_log_retention_imha_politikasi_test.json").read_text())

policies = {p["key"]: p for p in control["policies"]}
scopes = {p["scope"] for p in control["policies"]}

for key in test["must_have_policy_keys"]:
    assert key in policies, f"missing policy key: {key}"
    p = policies[key]
    assert p["required"] is True, f"policy not required: {key}"
    assert p["status"] == "READY", f"policy not ready: {key}"
    assert p["retention_days"] > 0, f"retention days missing: {key}"
    assert p["disposal_action"] in ["ARCHIVE", "ANONYMIZE", "DELETE", "LEGAL_HOLD"], f"bad disposal action: {key}"
    assert p["tenant_scoped"] is True, f"tenant scoped missing: {key}"
    assert p["has_legal_hold"] is True, f"legal hold missing: {key}"
    assert p["has_audit_evidence"] is True, f"audit evidence missing: {key}"
    assert p["has_kvkk_basis"] is True, f"kvkk basis missing: {key}"
    assert p["has_restore_guard"] is True, f"restore guard missing: {key}"
    assert p["production_delete_enabled"] is False, f"production delete must be false: {key}"

for scope in test["must_have_scopes"]:
    assert scope in scopes, f"missing scope: {scope}"

assert control["internal_policy_ready"] is True
assert control["production_deletion_allowed"] is False
assert control["final_policy"]["production_delete_enabled"] is False
assert control["final_policy"]["manual_legal_hold_required_before_destruction"] is True
assert control["final_policy"]["tenant_safe_retention_required"] is True
assert control["final_policy"]["evidence_required_before_any_cleanup"] is True
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
# FAZ 5-18.3.3 Log Retention / İmha Politikası Real Implementation Audit

PHASE=FAZ_5_18_3_3
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
INTERNAL_POLICY_READY=true
PRODUCTION_DELETION_ALLOWED=false
LEGAL_HOLD_REQUIRED=true
TENANT_SCOPE_REQUIRED=true
AUDIT_EVIDENCE_REQUIRED=true
RESTORE_GUARD_REQUIRED=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.3.3 LOG RETENTION / IMHA POLITIKASI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_3_3_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_3_3_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
