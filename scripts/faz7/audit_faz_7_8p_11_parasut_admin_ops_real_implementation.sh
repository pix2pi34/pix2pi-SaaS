#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_11_PARASUT_ADMIN_OPS_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_11_parasut_admin_ops_audit.env"

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

echo "# FAZ 7-8P.11 Paraşüt Admin Ops Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.11 PARASUT ADMIN OPS REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.0.1 Documentation artifact"
check_file "configs/faz7/parasut_admin_ops.v1.json" "7-8P.11.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_admin_ops.go" "7-8P.11.0.3 Admin ops code"
check_file "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "7-8P.11.0.4 Admin ops test code"

check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "FAZ 7-8P.11 Paraşüt Connector Admin / Ops / Manual Review Readiness" "7-8P.11.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.1 Manual Review Queue Contract" "7-8P.11.1.0 Scope doc manual review queue"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.2 Tenant-Safe Admin List / Read" "7-8P.11.2.0 Scope doc tenant safe admin"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.3 Ops Action Contract" "7-8P.11.3.0 Scope doc ops action"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.4 Audit Trail / Observability" "7-8P.11.4.0 Scope doc audit observability"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.5 Retry / Provider Gate Safety" "7-8P.11.5.0 Scope doc retry provider gate"
check_grep "docs/faz7/FAZ_7_8P_11_PARASUT_ADMIN_OPS_MANUAL_REVIEW_READINESS.md" "7-8P.11.6 Final Closure" "7-8P.11.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_admin_ops.v1.json" '"provider_key": "parasut"' "7-8P.11.0.6 Config provider key"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"real_provider_api_enabled": false' "7-8P.11.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"real_erp_write_enabled": false' "7-8P.11.0.8 Config real ERP write disabled"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"real_webhook_endpoint_enabled": false' "7-8P.11.0.9 Config real webhook endpoint disabled"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"real_retry_job_enabled": false' "7-8P.11.0.10 Config real retry job disabled"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS"' "7-8P.11.0.11 Config dependency on E2E dry-run"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"initial_status": "OPEN"' "7-8P.11.1.1 Config initial status open"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"tenant_scoped_list": true' "7-8P.11.2.1 Config tenant scoped list"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"cross_tenant_read_rejected": true' "7-8P.11.2.2 Config cross tenant read rejected"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"ASSIGN": true' "7-8P.11.3.1 Config assign action"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"RETRY": true' "7-8P.11.3.2 Config retry action"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"IGNORE": true' "7-8P.11.3.3 Config ignore action"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"RESOLVE": true' "7-8P.11.3.4 Config resolve action"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"REJECT": true' "7-8P.11.3.5 Config reject action"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"admin_action_audit_event": true' "7-8P.11.4.1 Config admin action audit"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"queue_metric_snapshot": true' "7-8P.11.4.2 Config queue metrics"
check_grep "configs/faz7/parasut_admin_ops.v1.json" '"retry_action_only_requests_retry": true' "7-8P.11.5.1 Config retry only requests retry"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "type ParasutAdminReviewItem struct" "7-8P.11.1.2 Code review item model"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "type ParasutAdminReviewCreateRequest struct" "7-8P.11.1.3 Code review create request"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "NewInMemoryParasutAdminOpsReviewQueue" "7-8P.11.1.4 Code review queue constructor"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "EnqueueReview" "7-8P.11.1.5 Code enqueue review"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminReviewStatusOpen" "7-8P.11.1.6 Code open initial status"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ListByTenant" "7-8P.11.2.3 Code tenant list"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ReadByTenant" "7-8P.11.2.4 Code tenant read"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "cross-tenant review read rejected" "7-8P.11.2.5 Code cross tenant read guard"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminReviewListFilter" "7-8P.11.2.6 Code list filter"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "type ParasutAdminOpsAction string" "7-8P.11.3.6 Code action enum"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ApplyAction" "7-8P.11.3.7 Code apply action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminOpsActionAssign" "7-8P.11.3.8 Code assign action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminOpsActionRetry" "7-8P.11.3.9 Code retry action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminOpsActionIgnore" "7-8P.11.3.10 Code ignore action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminOpsActionResolve" "7-8P.11.3.11 Code resolve action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "ParasutAdminOpsActionReject" "7-8P.11.3.12 Code reject action"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "terminal review item cannot be changed" "7-8P.11.3.13 Code invalid transition guard"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "RecordParasutAdminOpsActionAudit" "7-8P.11.4.3 Code admin action audit"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "Snapshot" "7-8P.11.4.4 Code queue snapshot"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "RetryRequested" "7-8P.11.4.5 Code retry requested metric"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "Resolved" "7-8P.11.4.6 Code resolved metric"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "Ignored" "7-8P.11.4.7 Code ignored metric"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "Rejected" "7-8P.11.4.8 Code rejected metric"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real retry job must remain disabled" "7-8P.11.5.2 Code real retry job blocker"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real provider API must remain disabled" "7-8P.11.5.3 Code real provider API blocker"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real ERP write must remain disabled" "7-8P.11.5.4 Code real ERP write blocker"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real webhook endpoint must remain disabled" "7-8P.11.5.5 Code real webhook blocker"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "EvaluateParasutAdminOpsReadinessGate" "7-8P.11.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "PARASUT_ADMIN_OPS_MANUAL_REVIEW_READY_WITH_REAL_API_ERP_WEBHOOK_CLOSED" "7-8P.11.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real_retry_job_must_remain_false_in_admin_ops_phase" "7-8P.11.6.3 Code final real retry blocker"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real_provider_api_must_remain_false_in_admin_ops_phase" "7-8P.11.6.4 Code final real API blocker"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops.go" "real_erp_write_must_remain_false_in_admin_ops_phase" "7-8P.11.6.5 Code final real ERP blocker"

check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutManualReviewQueueContract_7_8P_11_1" "7-8P.11.1.12 Test manual review queue"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutTenantSafeAdminListRead_7_8P_11_2" "7-8P.11.2.8 Test tenant safe admin read"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutOpsActionContract_7_8P_11_3" "7-8P.11.3.14 Test ops action contract"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutAuditTrailObservability_7_8P_11_4" "7-8P.11.4.9 Test audit observability"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutRetryProviderGateSafety_7_8P_11_5" "7-8P.11.5.6 Test retry provider gate"
check_grep "internal/platform/integrations/runtime/parasut_admin_ops_test.go" "TestParasutAdminOpsFinalClosure_7_8P_11_6" "7-8P.11.6.6 Test final closure"

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

echo "===== 7-8P.11 PARASUT ADMIN OPS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_11_PARASUT_ADMIN_OPS_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
