#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_3_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
GO_TEST_STATUS="NOT_RUN"

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

check_file() {
  local file="$1"
  local label="$2"
  if [ -s "$file" ]; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

echo "===== FAZ 2-7.3.4 TENANT-AWARE JOB DISPATCH RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 runtime file"
check_file "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 test file"
check_file "configs/faz2/ops_runtime/tenant_aware_job_dispatch_runtime.v1.json" "2-7.3.4 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME.md" "2-7.3.4 documentation file"

check_grep "TenantAwareJobDispatchRuntime" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 TenantAwareJobDispatchRuntime type"
check_grep "TenantAwareJobDispatchRequest" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 dispatch request model"
check_grep "TenantAwareJobRecord" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 job record model"
check_grep "TenantAwareJobDispatchDecision" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 dispatch decision model"
check_grep "DispatchJob" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 dispatch job function"
check_grep "MarkDispatched" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 mark dispatched function"
check_grep "GetJob" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 get job function"
check_grep "ListTenantJobs" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 tenant job list function"
check_grep "ListTenantQueueJobs" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 tenant queue job list function"
check_grep "JobDispatchTypeWebhookDelivery" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 webhook delivery job type"
check_grep "JobDispatchTypeEmailDelivery" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 email delivery job type"
check_grep "JobDispatchTypeReportBuild" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 report build job type"
check_grep "JobDispatchStateQueued" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 queued state"
check_grep "JobDispatchStateDispatched" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 dispatched state"
check_grep "ErrJobDispatchCrossTenant" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 tenant-safe job guard"
check_grep "tenantDedupeKey" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 tenant scoped dedupe key"
check_grep "NewTenantAwareJobID" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.4 job id generator"

check_grep "TestTenantAwareJobDispatchRuntimeDispatchesJob" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 dispatch job test"
check_grep "TestTenantAwareJobDispatchRuntimeUsesDefaults" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 defaults test"
check_grep "TestTenantAwareJobDispatchRuntimeMarksDispatched" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 mark dispatched test"
check_grep "TestTenantAwareJobDispatchRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 missing tenant test"
check_grep "TestTenantAwareJobDispatchRuntimeRejectsInvalidJobType" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 invalid job type test"
check_grep "TestTenantAwareJobDispatchRuntimeRejectsInvalidPriority" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 invalid priority test"
check_grep "TestTenantAwareJobDispatchRuntimeRejectsMissingPayload" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 missing payload test"
check_grep "TestTenantAwareJobDispatchRuntimeRejectsDuplicateDedupeKey" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 duplicate dedupe test"
check_grep "TestTenantAwareJobDispatchRuntimeDedupeIsTenantScoped" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 tenant scoped dedupe test"
check_grep "TestTenantAwareJobDispatchRuntimeTenantSafeAccess" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 tenant safe access test"
check_grep "TestTenantAwareJobDispatchRuntimeMarkDispatchedCrossTenantDenied" "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime_test.go" "2-7.3.4 cross tenant mark dispatched test"

echo "===== FAZ 2-7.3.4 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.3.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.3.4 go test"
fi

echo "===== FAZ 2-7.3.4 TENANT-AWARE JOB DISPATCH RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_3_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_3_4_TENANT_AWARE_JOB_DISPATCH_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_3_5_READY=NO"
  exit 1
fi
