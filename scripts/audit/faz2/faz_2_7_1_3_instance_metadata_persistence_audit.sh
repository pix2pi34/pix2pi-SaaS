#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.3 INSTANCE METADATA PERSISTENCE REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 runtime file"
check_file "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 test file"
check_file "configs/faz2/ops_runtime/instance_metadata_persistence.v1.json" "2-7.1.3 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE.md" "2-7.1.3 documentation file"

check_grep "InstanceMetadataRuntime" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 InstanceMetadataRuntime type"
check_grep "ServiceInstanceRecord" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 service instance record model"
check_grep "InstanceMetadataRecord" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 instance metadata record model"
check_grep "RegisterOrUpdateInstance" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 register update instance function"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 metadata upsert function"
check_grep "GetMetadata" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 metadata get function"
check_grep "ListMetadataForInstance" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 metadata list for instance function"
check_grep "ListTenantVisibleMetadata" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 tenant visible metadata filter"
check_grep "ListTenantInstances" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 tenant instances filter"
check_grep "ErrInstanceMetadataCrossTenant" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 cross tenant metadata guard"
check_grep "InstanceMetadataVisibilityTenant" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 visibility model"
check_grep "ServiceInstanceStatusHealthy" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 instance status model"
check_grep "NewServiceInstanceID" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 instance id generator"
check_grep "NewInstanceMetadataID" "internal/platform/ops/runtime/instance_metadata_runtime.go" "2-7.1.3 metadata id generator"

check_grep "TestInstanceMetadataRuntimeRegistersInstance" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 register instance test"
check_grep "TestInstanceMetadataRuntimeUpsertsMetadata" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 upsert metadata test"
check_grep "TestInstanceMetadataRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 missing tenant test"
check_grep "TestInstanceMetadataRuntimeRejectsMissingService" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 missing service test"
check_grep "TestInstanceMetadataRuntimeRejectsInvalidVisibility" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 invalid visibility test"
check_grep "TestInstanceMetadataRuntimeRejectsUnregisteredInstance" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 unregistered instance test"
check_grep "TestInstanceMetadataRuntimeRejectsCrossTenantMetadataAccess" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 cross tenant metadata access test"
check_grep "TestInstanceMetadataRuntimeListsTenantScopedMetadata" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 tenant scoped metadata list test"
check_grep "TestInstanceMetadataRuntimeListsTenantInstances" "internal/platform/ops/runtime/instance_metadata_runtime_test.go" "2-7.1.3 tenant instances list test"

echo "===== FAZ 2-7.1.3 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.3 go test"
fi

echo "===== FAZ 2-7.1.3 INSTANCE METADATA PERSISTENCE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_1_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_3_INSTANCE_METADATA_PERSISTENCE_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_1_4_READY=NO"
  exit 1
fi
