#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_3_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.3.6 JOB ENGINE INTEGRATION TESTS REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/tenant_aware_job_dispatch_runtime.go" "2-7.3.6 tenant aware job dispatch runtime file"
check_file "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.6 job audit log persistence runtime file"
check_file "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final integration test file"
check_file "configs/faz2/ops_runtime/job_engine_integration_tests.v1.json" "2-7.3.6 final closure config"
check_file "docs/faz2/ops_runtime/FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS.md" "2-7.3.6 final closure documentation"

check_grep "TestJobEngineIntegrationFinalDispatchAuditLifecycle" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 dispatch audit lifecycle final test"
check_grep "TestJobEngineIntegrationFinalTenantDedupeBoundary" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 tenant dedupe boundary final test"
check_grep "TestJobEngineIntegrationFinalCrossTenantAccessDenied" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 cross tenant access denied final test"
check_grep "TestJobEngineIntegrationFinalDenyCases" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 deny cases final test"

check_grep "DispatchJob" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test uses dispatch runtime"
check_grep "MarkDispatched" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test uses mark dispatched"
check_grep "RecordFromJob" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test uses record from job audit bridge"
check_grep "RecordJobAuditLog" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test uses direct audit record"
check_grep "ListJobAuditLogs" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks job audit list"
check_grep "ListTenantJobs" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks tenant job list"
check_grep "ListTenantQueueJobs" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks tenant queue list"
check_grep "ErrJobDispatchDuplicateDedupe" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks duplicate dedupe guard"
check_grep "ErrJobDispatchCrossTenant" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks job cross tenant guard"
check_grep "ErrJobAuditCrossTenant" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks audit cross tenant guard"
check_grep "ErrJobDispatchMissingTenant" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks missing tenant deny"
check_grep "ErrJobDispatchInvalidJobType" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks invalid job type deny"
check_grep "ErrJobAuditInvalidEventType" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks invalid audit event deny"
check_grep "ErrJobAuditMissingMessage" "internal/platform/ops/runtime/job_engine_integration_final_test.go" "2-7.3.6 final test checks missing audit message deny"

echo "===== FAZ 2-7.3.6 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.3.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.3.6 go test"
fi

echo "===== FAZ 2-7.3.6 JOB ENGINE INTEGRATION TESTS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_3_JOB_ENGINE_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_4_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_3_6_JOB_ENGINE_INTEGRATION_TESTS_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_3_JOB_ENGINE_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_4_2_READY=NO"
  exit 1
fi
