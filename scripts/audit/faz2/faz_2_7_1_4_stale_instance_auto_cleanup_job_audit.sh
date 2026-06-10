#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.4 STALE INSTANCE AUTO-CLEANUP JOB REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 runtime file"
check_file "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 test file"
check_file "configs/faz2/ops_runtime/stale_instance_auto_cleanup_job.v1.json" "2-7.1.4 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB.md" "2-7.1.4 documentation file"

check_grep "StaleInstanceCleanupRuntime" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 StaleInstanceCleanupRuntime type"
check_grep "StaleInstanceCleanupRequest" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup request model"
check_grep "StaleInstanceCleanupResult" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup result model"
check_grep "StaleInstanceCleanupDecision" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup decision model"
check_grep "DetectStaleInstances" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 stale detection function"
check_grep "RunCleanup" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup runner function"
check_grep "StaleAfterSeconds" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 heartbeat age threshold model"
check_grep "ServiceInstanceStatusStale" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 stale marker bridge"
check_grep "CleanupMetadataVisibilities" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup metadata visibility guard"
check_grep "ErrStaleInstanceCleanupMissingTenant" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 missing tenant guard"
check_grep "ErrStaleInstanceCleanupMissingRegistry" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 registry bridge guard"
check_grep "instanceLastSeenAt" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 last seen parser"
check_grep "cleanupVisibilityAllowed" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.4 cleanup visibility helper"

check_grep "TestStaleInstanceCleanupRuntimeDetectsStaleInstances" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 detect stale test"
check_grep "TestStaleInstanceCleanupRuntimeMarksStaleAndDeletesInternalMetadata" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 mark stale and cleanup metadata test"
check_grep "TestStaleInstanceCleanupRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 missing tenant test"
check_grep "TestStaleInstanceCleanupRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 missing registry test"
check_grep "TestStaleInstanceCleanupRuntimeRejectsInvalidThreshold" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 invalid threshold test"
check_grep "TestStaleInstanceCleanupRuntimeTenantSafeCleanup" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 tenant safe cleanup test"
check_grep "TestCleanupVisibilityAllowed" "internal/platform/ops/runtime/stale_instance_cleanup_runtime_test.go" "2-7.1.4 cleanup visibility test"

echo "===== FAZ 2-7.1.4 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.4 go test"
fi

echo "===== FAZ 2-7.1.4 STALE INSTANCE AUTO-CLEANUP JOB REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_1_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_4_STALE_INSTANCE_AUTO_CLEANUP_JOB_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_1_5_READY=NO"
  exit 1
fi
