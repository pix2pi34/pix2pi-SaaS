#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.8.4 QUOTA / RATE LIMIT RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 runtime file"
check_file "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 test file"
check_file "configs/faz2/public_api/quota_rate_limit_runtime.v1.json" "2-7.8.4 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME.md" "2-7.8.4 documentation file"

check_grep "QuotaRateLimitRuntime" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 QuotaRateLimitRuntime type"
check_grep "QuotaPolicy" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 quota policy model"
check_grep "QuotaUsageMeter" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 usage meter model"
check_grep "QuotaRateLimitDecision" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 rate limit decision model"
check_grep "CreatePolicy" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 create policy function"
check_grep "AllowRequest" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 allow request function"
check_grep "WindowSeconds|quotaWindow" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 window based limit"
check_grep "MaxRequests" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 max request limit"
check_grep "QuotaReasonLimitExceeded|ErrQuotaLimitExceeded" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 limit exceeded deny"
check_grep "ErrQuotaCrossTenant" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 tenant-safe quota guard"
check_grep "TenantUsageSnapshot" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 tenant-safe usage snapshot"
check_grep "SuspendPolicy|RevokePolicy" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.4 quota policy lifecycle"

check_grep "TestQuotaRateLimitRuntimeCreatesPolicy" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 create policy test"
check_grep "TestQuotaRateLimitRuntimeAllowsWithinLimitAndDeniesAfterLimit" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 allow and deny after limit test"
check_grep "TestQuotaRateLimitRuntimeRejectsMissingTenant" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 missing tenant test"
check_grep "TestQuotaRateLimitRuntimeRejectsEnvironmentMismatchPolicy" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 environment policy guard test"
check_grep "TestQuotaRateLimitRuntimeTenantSafePolicyAccess" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 tenant-safe policy access test"
check_grep "TestQuotaRateLimitRuntimeTenantUsageSnapshotIsFiltered" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 tenant usage snapshot test"
check_grep "TestQuotaRateLimitRuntimeSuspendedPolicyDeniesUsage" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 inactive policy deny test"
check_grep "TestQuotaRateLimitRuntimeResolvesPolicyWithoutExplicitPolicyID" "internal/platform/publicapi/runtime/quota_rate_limit_runtime_test.go" "2-7.8.4 implicit policy resolution test"

echo "===== FAZ 2-7.8.4 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.4 go test"
fi

echo "===== FAZ 2-7.8.4 QUOTA / RATE LIMIT RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_4_QUOTA_RATE_LIMIT_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_5_READY=NO"
  exit 1
fi
