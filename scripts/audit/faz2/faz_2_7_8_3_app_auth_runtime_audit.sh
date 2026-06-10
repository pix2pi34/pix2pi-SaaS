#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_3_APP_AUTH_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.8.3 APP AUTH RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 runtime file"
check_file "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 test file"
check_file "configs/faz2/public_api/app_auth_runtime.v1.json" "2-7.8.3 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_3_APP_AUTH_RUNTIME.md" "2-7.8.3 documentation file"

check_grep "AppAuthRuntime" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 AppAuthRuntime type"
check_grep "AppRegistration" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 app registration model"
check_grep "AppAPIKeyRelation" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 app api key relation model"
check_grep "RegisterApp" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 register app function"
check_grep "LinkAPIKey" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 API key app relation function"
check_grep "ValidateAppAuth" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 app auth validation function"
check_grep "ErrAppAuthCrossTenant" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 tenant-safe ownership guard"
check_grep "ErrAppAuthEnvironmentMismatch" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 environment guard"
check_grep "deriveEffectiveAppScopes|EffectiveScopes" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 scope inheritance"
check_grep "ErrAppAuthScopeNotAllowed" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 scope deny guard"
check_grep "SuspendApp|RevokeApp" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 app lifecycle guard"
check_grep "ListTenantApps" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.3 tenant filtered app list"

check_grep "TestAppAuthRuntimeRegistersApp" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 register app test"
check_grep "TestAppAuthRuntimeLinksAPIKeyToApp" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 link API key test"
check_grep "TestAppAuthRuntimeRejectsCrossTenantAPIKeyRelation" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 cross tenant relation test"
check_grep "TestAppAuthRuntimeRejectsEnvironmentMismatch" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 environment mismatch test"
check_grep "TestAppAuthRuntimeRejectsAPIKeyScopeOutsideAppAllowedScopes" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 scope inheritance deny test"
check_grep "TestAppAuthRuntimeValidatesAppAuth" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 app auth validation test"
check_grep "TestAppAuthRuntimeTenantSafeAppListAndGet" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 tenant-safe app list/get test"
check_grep "TestAppAuthRuntimeSuspendedAppCannotValidate" "internal/platform/publicapi/runtime/app_auth_runtime_test.go" "2-7.8.3 suspended app validation deny test"

echo "===== FAZ 2-7.8.3 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.3 go test"
fi

echo "===== FAZ 2-7.8.3 APP AUTH RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_3_APP_AUTH_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_4_READY=NO"
  exit 1
fi
