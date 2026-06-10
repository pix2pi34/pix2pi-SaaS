#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.5 TENANT-AWARE REGISTRY VISIBILITY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 runtime file"
check_file "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 test file"
check_file "configs/faz2/ops_runtime/tenant_aware_registry_visibility_runtime.v1.json" "2-7.1.5 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME.md" "2-7.1.5 documentation file"

check_grep "RegistryVisibilityRuntime" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 RegistryVisibilityRuntime type"
check_grep "RegistryVisibilityRequest" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 visibility request model"
check_grep "RegistryVisibilityEntry" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 visibility entry model"
check_grep "RegistryVisibilityResult" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 visibility result model"
check_grep "RegistryVisibilityDecision" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 visibility decision model"
check_grep "ListVisibleRegistry" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 list visible registry function"
check_grep "CanView" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 can view helper"
check_grep "CheckVisibility" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 check visibility helper"
check_grep "RegistryVisibilityScopeTenant" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 tenant visibility scope"
check_grep "RegistryVisibilityScopePlatform" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 platform visibility scope"
check_grep "RegistryVisibilityScopeInternal" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 internal visibility scope"
check_grep "ErrRegistryVisibilityCrossTenantDenied" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 cross tenant registry visibility guard"
check_grep "metadataVisibilitiesForScope" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 metadata visibility matrix"
check_grep "registryVisibilityMetadataAllowed" "internal/platform/ops/runtime/registry_visibility_runtime.go" "2-7.1.5 metadata visibility helper"

check_grep "TestRegistryVisibilityRuntimeTenantScopeFiltersTenantMetadata" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 tenant scope metadata test"
check_grep "TestRegistryVisibilityRuntimePlatformScopeIncludesPlatformMetadata" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 platform scope metadata test"
check_grep "TestRegistryVisibilityRuntimeInternalScopeIncludesInternalMetadata" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 internal scope metadata test"
check_grep "TestRegistryVisibilityRuntimeRejectsCrossTenantTenantScope" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 cross tenant tenant scope test"
check_grep "TestRegistryVisibilityRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 missing tenant test"
check_grep "TestRegistryVisibilityRuntimeRejectsMissingViewer" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 missing viewer test"
check_grep "TestRegistryVisibilityRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 missing registry test"
check_grep "TestRegistryVisibilityRuntimeRejectsInvalidScope" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 invalid scope test"
check_grep "TestRegistryVisibilityRuntimeDoesNotLeakOtherTenantInstances" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 no other tenant leakage test"
check_grep "TestRegistryVisibilityRuntimeCanView" "internal/platform/ops/runtime/registry_visibility_runtime_test.go" "2-7.1.5 can view test"

echo "===== FAZ 2-7.1.5 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.5 go test"
fi

echo "===== FAZ 2-7.1.5 TENANT-AWARE REGISTRY VISIBILITY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_1_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_5_TENANT_AWARE_REGISTRY_VISIBILITY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_1_6_READY=NO"
  exit 1
fi
