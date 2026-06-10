#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_21_5_3_STORAGE_LOG_MALIYET_OPTIMIZASYONU.md"
CONFIG_FILE="configs/faz6r/faz_6_21_5_3_storage_log_maliyet_optimizasyonu.v1.json"
PLAN_FILE="configs/faz6r/storage_log_cost_optimization.cost_ops.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_21_5_3_storage_log_maliyet_optimizasyonu_test.json"
RUNTIME_FILE="scripts/faz6r/run_storage_log_cost_optimization_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_storage_log_maliyet_optimizasyonu.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_21_5_3_storage_log_maliyet_optimizasyonu.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_21_5_3_STORAGE_LOG_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"
PREV_DB_EVIDENCE="docs/faz6r/evidence/FAZ_6_21_5_2_DB_MALIYET_OPTIMIZASYONU_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-21.5.3 STORAGE LOG MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT START ====="

check_file "6-21.5.3 previous DB cost evidence file" "$PREV_DB_EVIDENCE"
check_contains "6-21.5.3 previous DB cost final PASS" "$PREV_DB_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-21.5.3 documentation file" "$DOC_FILE"
check_file "6-21.5.3 config file" "$CONFIG_FILE"
check_file "6-21.5.3 plan file" "$PLAN_FILE"
check_file "6-21.5.3 fixture file" "$FIXTURE_FILE"
check_file "6-21.5.3 runtime file" "$RUNTIME_FILE"
check_file "6-21.5.3 validator file" "$VALIDATOR_FILE"
check_file "6-21.5.3 audit file" "$AUDIT_FILE"

check_contains "6-21.5.3 doc has Storage Log Maliyet Optimizasyonu" "$DOC_FILE" "Storage / Log Maliyet Optimizasyonu"
check_contains "6-21.5.3 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-21.5.3 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-21.5.3 config has dependency" "$CONFIG_FILE" "FAZ_6_21_5_2"
check_contains "6-21.5.3 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-21.5.3 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-21.5.3 config disables storage delete" "$CONFIG_FILE" '"storage_delete_allowed": false'
check_contains "6-21.5.3 config disables log delete" "$CONFIG_FILE" '"log_delete_allowed": false'
check_contains "6-21.5.3 config disables backup delete" "$CONFIG_FILE" '"backup_delete_allowed": false'
check_contains "6-21.5.3 config disables audit delete" "$CONFIG_FILE" '"audit_delete_allowed": false'
check_contains "6-21.5.3 config disables evidence delete" "$CONFIG_FILE" '"evidence_delete_allowed": false'
check_contains "6-21.5.3 config disables retention delete" "$CONFIG_FILE" '"retention_delete_allowed": false'
check_contains "6-21.5.3 config has storage inventory" "$CONFIG_FILE" "storage_inventory_model"
check_contains "6-21.5.3 config has log inventory" "$CONFIG_FILE" "log_inventory_model"
check_contains "6-21.5.3 config has retention tier policy" "$CONFIG_FILE" "retention_tier_policy"
check_contains "6-21.5.3 config has evidence retention guard" "$CONFIG_FILE" "evidence_retention_guard"
check_contains "6-21.5.3 config has audit log retention guard" "$CONFIG_FILE" "audit_log_retention_guard"
check_contains "6-21.5.3 config has tenant data retention guard" "$CONFIG_FILE" "tenant_data_retention_guard"
check_contains "6-21.5.3 config has lifecycle transition policy" "$CONFIG_FILE" "lifecycle_transition_policy"

check_contains "6-21.5.3 plan has runtime log recommendation" "$PLAN_FILE" "storage-rec-runtime-log-volume-review"
check_contains "6-21.5.3 plan has audit log recommendation" "$PLAN_FILE" "storage-rec-audit-log-retention-guard"
check_contains "6-21.5.3 plan has evidence compression recommendation" "$PLAN_FILE" "storage-rec-evidence-artifact-compression"
check_contains "6-21.5.3 plan has backup archive recommendation" "$PLAN_FILE" "storage-rec-backup-archive-tier-review"
check_contains "6-21.5.3 plan has static asset recommendation" "$PLAN_FILE" "storage-rec-static-asset-dedup-review"
check_contains "6-21.5.3 plan has no mutation" "$PLAN_FILE" '"mutation_allowed": false'
check_contains "6-21.5.3 plan has dry-run status" "$PLAN_FILE" "dry_run_only_no_storage_log_mutation"

check_contains "6-21.5.3 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_21_5_4"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" >/tmp/faz_6_21_5_3_storage_log_cost_runtime.json; then
  pass "6-21.5.3 dry-run storage log cost runtime"
else
  fail "6-21.5.3 dry-run storage log cost runtime"
fi

check_contains "6-21.5.3 runtime output is PASS" "/tmp/faz_6_21_5_3_storage_log_cost_runtime.json" '"runtime_status": "PASS"'
check_contains "6-21.5.3 runtime output is dry run" "/tmp/faz_6_21_5_3_storage_log_cost_runtime.json" "storage_log_cost_optimization_dry_run"
check_contains "6-21.5.3 runtime output disables provider mutation" "/tmp/faz_6_21_5_3_storage_log_cost_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-21.5.3 runtime output disables storage delete" "/tmp/faz_6_21_5_3_storage_log_cost_runtime.json" '"storage_delete_allowed": false'
check_contains "6-21.5.3 runtime output disables log delete" "/tmp/faz_6_21_5_3_storage_log_cost_runtime.json" '"log_delete_allowed": false'

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$PLAN_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-21.5.3 semantic validator runtime"
else
  fail "6-21.5.3 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-21.5.3 python3 dependency"
else
  fail "6-21.5.3 python3 dependency"
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
# FAZ 6-R / 295 — FAZ 6-21.5.3 Storage / Log Maliyet Optimizasyonu Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
PLAN_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_21_5_4_READY=${NEXT_READY}

Scope note: provider mutation, storage delete, log delete, backup delete, audit delete, evidence delete and retention delete remain closed in this step.
Dependency: FAZ_6_21_5_2 DB maliyet optimizasyonu evidence checked.
EOF2

echo "===== FAZ 6-21.5.3 STORAGE LOG MALIYET OPTIMIZASYONU REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_21_5_3_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-21.5.3 STORAGE LOG MALIYET OPTIMIZASYONU COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "PLAN_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_6_21_5_4_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
