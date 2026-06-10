#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.1 SERVICE REGISTRATION ENDPOINT REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 runtime file"
check_file "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 test file"
check_file "configs/faz2/ops_runtime/service_registration_endpoint.v1.json" "2-7.1.1 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT.md" "2-7.1.1 documentation file"

check_grep "ServiceRegistrationEndpointRuntime" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 ServiceRegistrationEndpointRuntime type"
check_grep "ServiceRegistrationEndpointRequest" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 endpoint request model"
check_grep "ServiceRegistrationEndpointResponse" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 endpoint response model"
check_grep "ServiceRegistrationEndpointDecision" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 endpoint decision model"
check_grep "ServeHTTP" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 HTTP handler"
check_grep "HandleRegistrationRequest" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 registration request handler"
check_grep "RegisterOrUpdateInstance" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 instance register bridge"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 metadata persistence bridge"
check_grep "X-Tenant-ID" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 tenant header enforcement"
check_grep "ErrServiceRegistrationEndpointCrossTenant" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 cross tenant registration guard"
check_grep "ErrServiceRegistrationEndpointMissingRegistry" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 missing registry guard"
check_grep "writeServiceRegistrationEndpointJSON" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 JSON response writer"
check_grep "ServiceRegistrationEndpointPath" "internal/platform/ops/runtime/service_registration_endpoint_runtime.go" "2-7.1.1 endpoint path constant"

check_grep "TestServiceRegistrationEndpointRegistersInstanceAndMetadata" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 register instance and metadata test"
check_grep "TestServiceRegistrationEndpointRejectsMissingTenantHeader" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 missing tenant header test"
check_grep "TestServiceRegistrationEndpointRejectsCrossTenantBody" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 cross tenant body test"
check_grep "TestServiceRegistrationEndpointRejectsInvalidMethod" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 invalid method test"
check_grep "TestServiceRegistrationEndpointRejectsInvalidPath" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 invalid path test"
check_grep "TestServiceRegistrationEndpointRejectsMissingRegistry" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 missing registry test"
check_grep "TestServiceRegistrationEndpointRejectsInvalidBody" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 invalid body test"
check_grep "TestServiceRegistrationEndpointRejectsRegisterValidationFailure" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 register validation failure test"
check_grep "TestServiceRegistrationEndpointSupportsBodyTenantFallbackWhenConfigured" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 body tenant fallback test"
check_grep "TestServiceRegistrationEndpointUpdatesExistingInstance" "internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go" "2-7.1.1 update existing instance test"

echo "===== FAZ 2-7.1.1 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.1 go test"
fi

echo "===== FAZ 2-7.1.1 SERVICE REGISTRATION ENDPOINT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_1_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_1_2_READY=NO"
  exit 1
fi
