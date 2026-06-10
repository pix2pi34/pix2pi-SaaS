#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.6 REGISTRY RUNTIME INTEGRATION TESTS REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.6 instance metadata runtime file"
check_file "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.6 stale cleanup runtime file"
check_file "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.6 registry visibility runtime file"
check_file "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final integration test file"
check_file "configs/faz2/ops_runtime/registry_runtime_integration_tests.v1.json" "2-7.1.6 final closure config"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS.md" "2-7.1.6 final closure documentation"

check_grep "TestRegistryRuntimeFinalIntegrationFlow" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 registry runtime E2E final test"
check_grep "TestRegistryRuntimeFinalCrossTenantDenyFlow" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 cross tenant final test"
check_grep "TestRegistryRuntimeFinalDenyCases" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 deny cases final test"

check_grep "InstanceMetadataRuntime" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.6 instance metadata runtime implemented"
check_grep "StaleInstanceCleanupRuntime" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.6 stale cleanup runtime implemented"
check_grep "RegistryVisibilityRuntime" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.6 registry visibility runtime implemented"

check_grep "ErrInstanceMetadataCrossTenant" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.6 metadata cross tenant guard"
check_grep "ErrRegistryVisibilityCrossTenantDenied" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.6 registry visibility cross tenant guard"
check_grep "ServiceInstanceStatusStale" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.6 stale status marker"
check_grep "InstanceMetadataVisibilityInternal" "internal/platform/ops/runtime/stale_instance_cleanup_runtime.go" "2-7.1.6 internal metadata cleanup bridge"

check_grep "RegisterOrUpdateInstance" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test uses instance registration"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test uses metadata upsert"
check_grep "ListVisibleRegistry" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test uses registry visibility"
check_grep "RunCleanup" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test uses stale cleanup"
check_grep "ListTenantInstances" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test uses tenant instance list"

check_grep "ErrInstanceMetadataMissingService" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test checks missing service deny"
check_grep "ErrStaleInstanceCleanupMissingRegistry" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test checks cleanup missing registry deny"
check_grep "ErrRegistryVisibilityInvalidScope" "internal/platform/ops/runtime/registry_runtime_integration_final_test.go" "2-7.1.6 final test checks invalid visibility scope deny"

echo "===== FAZ 2-7.1.6 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.6 go test"
fi

echo "===== FAZ 2-7.1.6 REGISTRY RUNTIME INTEGRATION TESTS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_1_REGISTRY_RUNTIME_INTEGRATION_READY=YES"
  echo "FAZ_2_7_1_1_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_1_REGISTRY_RUNTIME_INTEGRATION_READY=NO"
  echo "FAZ_2_7_1_1_READY=NO"
  exit 1
fi
