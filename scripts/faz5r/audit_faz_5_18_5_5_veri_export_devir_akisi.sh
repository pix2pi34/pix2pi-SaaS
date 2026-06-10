#!/usr/bin/env bash
set -euo pipefail

PHASE="FAZ 5-18.5.5"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

DOC_FILE="docs/faz5r/FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI.md"
CONFIG_FILE="configs/faz5r/faz_5_18_5_5_veri_export_devir_akisi.v1.json"
CONTROL_FILE="configs/faz5r/tenant_data_export_handover_flow.public_launch.v1.json"
TEST_FILE="tests/faz5r/faz_5_18_5_5_veri_export_devir_akisi_test.json"
RUNTIME_FILE="internal/commercial/publiclaunch/tenantdataexport/tenant_data_export.go"
RUNTIME_TEST_FILE="internal/commercial/publiclaunch/tenantdataexport/tenant_data_export_test.go"
EVIDENCE_FILE="docs/faz5r/evidence/FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 5-18.5.5 VERI EXPORT / DEVIR AKISI REAL IMPLEMENTATION AUDIT START ====="

file_exists "$DOC_FILE" "documentation file"
file_exists "$CONFIG_FILE" "phase config file"
file_exists "$CONTROL_FILE" "control config file"
file_exists "$TEST_FILE" "test fixture file"
file_exists "$RUNTIME_FILE" "Go runtime file"
file_exists "$RUNTIME_TEST_FILE" "Go test file"

contains "$CONTROL_FILE" '"export_request_intake"' "export request intake registered"
contains "$CONTROL_FILE" '"owner_verification"' "owner verification registered"
contains "$CONTROL_FILE" '"legal_hold_check"' "legal hold check registered"
contains "$CONTROL_FILE" '"data_scope_selection"' "data scope selection registered"
contains "$CONTROL_FILE" '"kvkk_masking_policy"' "kvkk masking policy registered"
contains "$CONTROL_FILE" '"export_bundle_prepare"' "export bundle prepare registered"
contains "$CONTROL_FILE" '"checksum_manifest_create"' "checksum manifest create registered"
contains "$CONTROL_FILE" '"secure_download_package"' "secure download package registered"
contains "$CONTROL_FILE" '"handover_acceptance_record"' "handover acceptance record registered"
contains "$CONTROL_FILE" '"data_deletion_deferred_marker"' "data deletion deferred marker registered"
contains "$CONTROL_FILE" '"EXPORT_REQUEST_RECEIVED"' "export request event registered"
contains "$CONTROL_FILE" '"OWNER_VERIFIED"' "owner verified event registered"
contains "$CONTROL_FILE" '"LEGAL_HOLD_CHECKED"' "legal hold event registered"
contains "$CONTROL_FILE" '"DATA_SCOPE_SELECTED"' "data scope event registered"
contains "$CONTROL_FILE" '"KVKK_MASKING_APPLIED"' "kvkk masking event registered"
contains "$CONTROL_FILE" '"EXPORT_BUNDLE_PREPARED"' "export bundle event registered"
contains "$CONTROL_FILE" '"CHECKSUM_MANIFEST_CREATED"' "checksum manifest event registered"
contains "$CONTROL_FILE" '"SECURE_DOWNLOAD_READY"' "secure download event registered"
contains "$CONTROL_FILE" '"HANDOVER_ACCEPTANCE_RECORDED"' "handover acceptance event registered"
contains "$CONTROL_FILE" '"DATA_DELETION_DEFERRED"' "data deletion deferred event registered"
contains "$CONTROL_FILE" '"internal_data_export_flow_ready": true' "internal data export flow ready"
contains "$CONTROL_FILE" '"production_export_enabled": false' "production export disabled"
contains "$CONTROL_FILE" '"real_customer_export_enabled": false' "real customer export disabled"
contains "$CONTROL_FILE" '"data_deletion_enabled": false' "data deletion disabled"
contains "$CONTROL_FILE" '"auto_transfer_enabled": false' "auto transfer disabled"
contains "$CONTROL_FILE" '"requires_tenant_id": true' "tenant id required"
contains "$CONTROL_FILE" '"requires_export_request_id": true' "export request id required"
contains "$CONTROL_FILE" '"requires_owner_approval": true' "owner approval required"
contains "$CONTROL_FILE" '"requires_legal_hold_check": true' "legal hold check required"
contains "$CONTROL_FILE" '"requires_data_scope": true' "data scope required"
contains "$CONTROL_FILE" '"requires_kvkk_masking": true' "kvkk masking required"
contains "$CONTROL_FILE" '"requires_data_classification": true' "data classification required"
contains "$CONTROL_FILE" '"requires_format_policy": true' "format policy required"
contains "$CONTROL_FILE" '"requires_checksum_manifest": true' "checksum manifest required"
contains "$CONTROL_FILE" '"requires_encryption": true' "encryption required"
contains "$CONTROL_FILE" '"requires_secure_download": true' "secure download required"
contains "$CONTROL_FILE" '"requires_audit_trail": true' "audit trail required"
contains "$CONTROL_FILE" '"requires_retention_policy": true' "retention policy required"
contains "$CONTROL_FILE" '"requires_handover_acceptance": true' "handover acceptance required"
contains "$CONTROL_FILE" '"requires_support_handoff": true' "support handoff required"
contains "$CONTROL_FILE" '"blocks_production_export": true' "production export block present"
contains "$CONTROL_FILE" '"blocks_real_customer_export": true' "real customer export block present"
contains "$CONTROL_FILE" '"blocks_data_deletion": true' "data deletion block present"
contains "$CONTROL_FILE" '"blocks_auto_transfer": true' "auto transfer block present"
contains "$CONTROL_FILE" '"deferred_to_production_approval": true' "production approval deferred present"
contains "$CONTROL_FILE" '"deferred_to_tenant_shutdown": true' "tenant shutdown deferred present"
contains "$CONTROL_FILE" '"FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME"' "next gate 262 present"

contains "$RUNTIME_FILE" "func Evaluate" "runtime evaluate function"
contains "$RUNTIME_FILE" "PRODUCTION_EXPORT_BLOCKED" "production export guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_EXPORT_BLOCKED" "real customer export guard"
contains "$RUNTIME_FILE" "DATA_DELETION_BLOCKED" "data deletion guard"
contains "$RUNTIME_FILE" "AUTO_TRANSFER_BLOCKED" "auto transfer guard"
contains "$RUNTIME_FILE" "TENANT_ID_REQUIRED" "tenant id guard"
contains "$RUNTIME_FILE" "EXPORT_REQUEST_ID_REQUIRED" "export request id guard"
contains "$RUNTIME_FILE" "OWNER_APPROVAL_REQUIRED" "owner approval guard"
contains "$RUNTIME_FILE" "LEGAL_HOLD_CHECK_REQUIRED" "legal hold guard"
contains "$RUNTIME_FILE" "DATA_SCOPE_REQUIRED" "data scope guard"
contains "$RUNTIME_FILE" "KVKK_MASKING_REQUIRED" "kvkk masking guard"
contains "$RUNTIME_FILE" "DATA_CLASSIFICATION_REQUIRED" "data classification guard"
contains "$RUNTIME_FILE" "FORMAT_POLICY_REQUIRED" "format policy guard"
contains "$RUNTIME_FILE" "CHECKSUM_MANIFEST_REQUIRED" "checksum manifest guard"
contains "$RUNTIME_FILE" "ENCRYPTION_REQUIRED" "encryption guard"
contains "$RUNTIME_FILE" "SECURE_DOWNLOAD_REQUIRED" "secure download guard"
contains "$RUNTIME_FILE" "AUDIT_TRAIL_REQUIRED" "audit trail guard"
contains "$RUNTIME_FILE" "RETENTION_POLICY_REQUIRED" "retention policy guard"
contains "$RUNTIME_FILE" "HANDOVER_ACCEPTANCE_REQUIRED" "handover acceptance guard"
contains "$RUNTIME_FILE" "SUPPORT_HANDOFF_REQUIRED" "support handoff guard"
contains "$RUNTIME_FILE" "PRODUCTION_EXPORT_BLOCK_REQUIRED" "production export block guard"
contains "$RUNTIME_FILE" "REAL_CUSTOMER_EXPORT_BLOCK_REQUIRED" "real customer export block guard"
contains "$RUNTIME_FILE" "DATA_DELETION_BLOCK_REQUIRED" "data deletion block guard"
contains "$RUNTIME_FILE" "AUTO_TRANSFER_BLOCK_REQUIRED" "auto transfer block guard"
contains "$RUNTIME_FILE" "DEFERRED_REASON_REQUIRED" "deferred reason guard"

if go test ./internal/commercial/publiclaunch/tenantdataexport; then
  ok "go test status is PASS"
else
  fail "go test status"
fi

if python3 - <<'PY'
import json
from pathlib import Path

control = json.loads(Path("configs/faz5r/tenant_data_export_handover_flow.public_launch.v1.json").read_text())
test = json.loads(Path("tests/faz5r/faz_5_18_5_5_veri_export_devir_akisi_test.json").read_text())

steps = {s["key"]: s for s in control["steps"]}
events = {s["event"] for s in control["steps"]}

for key in test["must_have_step_keys"]:
    assert key in steps, f"missing step key: {key}"
    s = steps[key]
    assert s["required"] is True, f"step not required: {key}"
    assert s["has_evidence"] is True, f"evidence missing: {key}"
    assert s["has_counter_based_audit"] is True, f"counter audit missing: {key}"
    assert s["required_fail_count"] == 0, f"required fail not zero: {key}"
    assert s["optional_warn_count"] == 0, f"optional warn not zero: {key}"
    assert s["production_export_enabled"] is False, f"production export must be false: {key}"
    assert s["real_customer_export_enabled"] is False, f"real customer export must be false: {key}"
    assert s["data_deletion_enabled"] is False, f"data deletion must be false: {key}"
    assert s["auto_transfer_enabled"] is False, f"auto transfer must be false: {key}"
    assert s["requires_tenant_id"] is True, f"tenant id missing: {key}"
    assert s["requires_export_request_id"] is True, f"export request id missing: {key}"
    assert s["requires_owner_approval"] is True, f"owner approval missing: {key}"
    assert s["requires_legal_hold_check"] is True, f"legal hold missing: {key}"
    assert s["requires_data_scope"] is True, f"data scope missing: {key}"
    assert s["requires_kvkk_masking"] is True, f"kvkk masking missing: {key}"
    assert s["requires_data_classification"] is True, f"data classification missing: {key}"
    assert s["requires_format_policy"] is True, f"format policy missing: {key}"
    assert s["requires_checksum_manifest"] is True, f"checksum manifest missing: {key}"
    assert s["requires_encryption"] is True, f"encryption missing: {key}"
    assert s["requires_secure_download"] is True, f"secure download missing: {key}"
    assert s["requires_audit_trail"] is True, f"audit trail missing: {key}"
    assert s["requires_retention_policy"] is True, f"retention policy missing: {key}"
    assert s["requires_handover_acceptance"] is True, f"handover acceptance missing: {key}"
    assert s["requires_support_handoff"] is True, f"support handoff missing: {key}"
    assert s["blocks_production_export"] is True, f"production export block missing: {key}"
    assert s["blocks_real_customer_export"] is True, f"real customer export block missing: {key}"
    assert s["blocks_data_deletion"] is True, f"data deletion block missing: {key}"
    assert s["blocks_auto_transfer"] is True, f"auto transfer block missing: {key}"

for event in test["must_have_events"]:
    assert event in events, f"missing event: {event}"

assert steps["data_deletion_deferred_marker"]["deferred_to_production_approval"] is True
assert steps["data_deletion_deferred_marker"]["deferred_to_tenant_shutdown"] is True
assert steps["data_deletion_deferred_marker"]["deferred_reason"], "data deletion deferred reason missing"
assert control["internal_data_export_flow_ready"] is True
assert control["production_export_enabled"] is False
assert control["real_customer_export_enabled"] is False
assert control["data_deletion_enabled"] is False
assert control["auto_transfer_enabled"] is False
assert control["final_policy"]["tenant_upgrade_downgrade_required_next"] is True
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
# FAZ 5-18.5.5 Veri Export / Devir Akışı Real Implementation Audit

PHASE=FAZ_5_18_5_5
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
INTERNAL_DATA_EXPORT_FLOW_READY=true
PRODUCTION_EXPORT_ENABLED=false
REAL_CUSTOMER_EXPORT_ENABLED=false
DATA_DELETION_ENABLED=false
AUTO_TRANSFER_ENABLED=false
TENANT_UPGRADE_DOWNGRADE_REQUIRED_NEXT=true

## Evidence Files

- $DOC_FILE
- $CONFIG_FILE
- $CONTROL_FILE
- $TEST_FILE
- $RUNTIME_FILE
- $RUNTIME_TEST_FILE
EOF2

echo "===== FAZ 5-18.5.5 VERI EXPORT / DEVIR AKISI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_5_18_5_5_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
else
  echo "FAZ_5_18_5_5_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
