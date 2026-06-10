#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_7_PARASUT_DATA_MAPPING_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_7_parasut_data_mapping_audit.env"

mkdir -p "$(dirname "$AUDIT_EVIDENCE_FILE")"

: > "$AUDIT_EVIDENCE_FILE"

record_pass() {
  local label="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$label IMPLEMENTED_OR_PRESENT / OK ✅"
  echo "- $label IMPLEMENTED_OR_PRESENT / OK" >> "$AUDIT_EVIDENCE_FILE"
}

record_fail() {
  local label="$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$label REQUIRED_FAIL / MISSING ❌"
  echo "- $label REQUIRED_FAIL / MISSING" >> "$AUDIT_EVIDENCE_FILE"
}

check_file() {
  local path="$1"
  local label="$2"
  if [ -f "$path" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_grep() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

echo "# FAZ 7-8P.7 Paraşüt Data Mapping Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.7 PARASUT DATA MAPPING REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.0.1 Documentation artifact"
check_file "configs/faz7/parasut_data_mapping.v1.json" "7-8P.7.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_data_mapping.go" "7-8P.7.0.3 Data mapping code"
check_file "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "7-8P.7.0.4 Data mapping test code"

check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "FAZ 7-8P.7 Paraşüt Data Mapping / ERP Sync Contract Readiness" "7-8P.7.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.1 Source Data Contract" "7-8P.7.1.0 Scope doc source data"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.2 Customer Mapping Contract" "7-8P.7.2.0 Scope doc customer mapping"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.3 Product Mapping Contract" "7-8P.7.3.0 Scope doc product mapping"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.4 Invoice Mapping Contract" "7-8P.7.4.0 Scope doc invoice mapping"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.5 Conflict / Duplicate / Idempotency Contract" "7-8P.7.5.0 Scope doc conflict"
check_grep "docs/faz7/FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS.md" "7-8P.7.6 ERP Write Contract Dry-Run / Final Closure" "7-8P.7.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_data_mapping.v1.json" '"provider_key": "parasut"' "7-8P.7.0.6 Config provider key"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"real_provider_api_enabled": false' "7-8P.7.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"real_erp_write_enabled": false' "7-8P.7.0.8 Config real ERP write disabled"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS"' "7-8P.7.0.9 Config dependency on API client"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"external_object_id_required": true' "7-8P.7.1.1 Config external object ID required"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"tax_number_required": true' "7-8P.7.2.1 Config tax number required"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"sku_required": true' "7-8P.7.3.1 Config SKU required"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"invoice_number_required": true' "7-8P.7.4.1 Config invoice number required"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"idempotent_sync_key_required": true' "7-8P.7.4.2 Config idempotent sync key required"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"same_sync_key_duplicate_safe": true' "7-8P.7.5.1 Config duplicate safe"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"cross_tenant_mapping_rejected": true' "7-8P.7.5.2 Config cross tenant rejected"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"dry_run_only": true' "7-8P.7.6.1 Config ERP dry-run only"
check_grep "configs/faz7/parasut_data_mapping.v1.json" '"real_erp_write_status": "CLOSED_UNTIL_SYNC_WORKER_MODULE"' "7-8P.7.6.2 Config real ERP write closed"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "type ParasutSourceBase struct" "7-8P.7.1.2 Code source base model"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "type ParasutCustomerSource struct" "7-8P.7.1.3 Code customer source model"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "type ParasutProductSource struct" "7-8P.7.1.4 Code product source model"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "type ParasutInvoiceSource struct" "7-8P.7.1.5 Code invoice source model"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "validateParasutSourceBase" "7-8P.7.1.6 Code source base validator"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "BuildParasutCustomerERPSync" "7-8P.7.2.2 Code customer mapping builder"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "TaxNumber" "7-8P.7.2.3 Code tax number field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "erp_customer" "7-8P.7.2.4 Code ERP customer key"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "BuildParasutProductERPSync" "7-8P.7.3.2 Code product mapping builder"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "SKU" "7-8P.7.3.3 Code SKU field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "VATRate" "7-8P.7.3.4 Code VAT rate field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "erp_product" "7-8P.7.3.5 Code ERP product key"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "BuildParasutInvoiceERPSync" "7-8P.7.4.3 Code invoice mapping builder"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "InvoiceNumber" "7-8P.7.4.4 Code invoice number field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "CustomerExternalID" "7-8P.7.4.5 Code customer external ID field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "AmountMinor" "7-8P.7.4.6 Code amount minor field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "VATAmountMinor" "7-8P.7.4.7 Code VAT amount minor field"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "validateParasutInvoiceLine" "7-8P.7.4.8 Code invoice line validator"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "BuildParasutSyncKey" "7-8P.7.5.3 Code sync key builder"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "EvaluateParasutSyncConflict" "7-8P.7.5.4 Code conflict evaluator"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "same_sync_key_duplicate_safe" "7-8P.7.5.5 Code duplicate safe reason"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "cross_tenant_mapping_rejected" "7-8P.7.5.6 Code cross tenant conflict"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "object_type_mismatch_rejected" "7-8P.7.5.7 Code object type conflict"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "type ParasutERPWriteContractRequest struct" "7-8P.7.6.3 Code ERP write contract request"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "BuildParasutERPWriteDryRunContract" "7-8P.7.6.4 Code ERP write dry-run builder"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "real erp write must remain disabled" "7-8P.7.6.5 Code real ERP write blocker"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "RecordParasutMappingAudit" "7-8P.7.6.6 Code mapping audit bridge"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "EvaluateParasutDataMappingReadinessGate" "7-8P.7.6.7 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "PARASUT_DATA_MAPPING_ERP_SYNC_DRY_RUN_READY_WITH_REAL_API_CLOSED" "7-8P.7.6.8 Code final decision"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "real_provider_api_must_remain_false_in_data_mapping_phase" "7-8P.7.6.9 Code real provider API blocker"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping.go" "real_erp_write_must_remain_false_in_data_mapping_phase" "7-8P.7.6.10 Code real ERP write blocker"

check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutSourceDataContract_7_8P_7_1" "7-8P.7.1.10 Test source data contract"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutCustomerMappingContract_7_8P_7_2" "7-8P.7.2.8 Test customer mapping"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutProductMappingContract_7_8P_7_3" "7-8P.7.3.9 Test product mapping"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutInvoiceMappingContract_7_8P_7_4" "7-8P.7.4.11 Test invoice mapping"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutConflictDuplicateIdempotencyContract_7_8P_7_5" "7-8P.7.5.8 Test conflict idempotency"
check_grep "internal/platform/integrations/runtime/parasut_data_mapping_test.go" "TestParasutERPWriteDryRunFinalClosure_7_8P_7_6" "7-8P.7.6.11 Test final closure"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_STATUS="PASS"
else
  REAL_STATUS="FAIL"
fi

{
  echo "AUDIT_PASS_COUNT=$PASS_COUNT"
  echo "AUDIT_FAIL_COUNT=$FAIL_COUNT"
  echo "AUDIT_REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "AUDIT_OPTIONAL_WARN=$OPTIONAL_WARN"
  echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
  echo "AUDIT_REAL_STATUS=$REAL_STATUS"
} > "$AUDIT_ENV_FILE"

echo "===== 7-8P.7 PARASUT DATA MAPPING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_7_PARASUT_DATA_MAPPING_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
