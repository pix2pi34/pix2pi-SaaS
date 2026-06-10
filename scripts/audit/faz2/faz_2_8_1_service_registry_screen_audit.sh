#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.1 SERVICE REGISTRY SCREEN REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 runtime file"
check_file "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 test file"
check_file "web/ops-console/service-registry/index.html" "2-8.1 html screen file"
check_file "configs/faz2/ops_console/service_registry_screen.v1.json" "2-8.1 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_1_SERVICE_REGISTRY_SCREEN.md" "2-8.1 documentation file"

check_grep "ServiceRegistryScreenConsoleRuntime" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 console runtime type"
check_grep "ServiceRegistryScreenEntry" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 service entry model"
check_grep "ServiceRegistryScreenSnapshot" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 snapshot model"
check_grep "UpsertService" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 upsert service function"
check_grep "BuildSnapshot" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 build snapshot function"
check_grep "ServiceRegistryScreenStatusHealthy" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 healthy status"
check_grep "ServiceRegistryScreenStatusDegraded" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 degraded status"
check_grep "ServiceRegistryScreenStatusDown" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 down status"
check_grep "ServiceRegistryScreenStatusMaintenance" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 maintenance status"
check_grep "ServiceRegistryScreenVisibilityTenant" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 tenant visibility"
check_grep "ServiceRegistryScreenVisibilityPlatform" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 platform visibility"
check_grep "ServiceRegistryScreenVisibilityInternal" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 internal visibility"
check_grep "ErrServiceRegistryScreenCrossTenant" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 cross tenant guard"
check_grep "isServiceRegistryHeartbeatStale" "internal/platform/ops/console/service_registry_screen_console.go" "2-8.1 stale heartbeat helper"

check_grep "TestServiceRegistryScreenConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 build snapshot test"
check_grep "TestServiceRegistryScreenConsoleRuntimeTenantViewerHidesInternal" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 tenant viewer hides internal test"
check_grep "TestServiceRegistryScreenConsoleRuntimeStatusFilter" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 status filter test"
check_grep "TestServiceRegistryScreenConsoleRuntimeVisibilityFilter" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 visibility filter test"
check_grep "TestServiceRegistryScreenConsoleRuntimeDetectsStaleHeartbeat" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 stale heartbeat test"
check_grep "TestServiceRegistryScreenConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 missing tenant test"
check_grep "TestServiceRegistryScreenConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 cross tenant viewer test"
check_grep "TestServiceRegistryScreenConsoleRuntimeRejectsInvalidStatus" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 invalid status test"
check_grep "TestServiceRegistryScreenConsoleRuntimeRejectsInvalidVisibility" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 invalid visibility test"
check_grep "TestServiceRegistryScreenConsoleRuntimeRejectsMissingRequiredFields" "internal/platform/ops/console/service_registry_screen_console_test.go" "2-8.1 missing required fields test"

check_grep "Service Registry" "web/ops-console/service-registry/index.html" "2-8.1 html title"
check_grep "Tenant:" "web/ops-console/service-registry/index.html" "2-8.1 tenant indicator"
check_grep "Registered Services" "web/ops-console/service-registry/index.html" "2-8.1 registered services metric"
check_grep "Healthy" "web/ops-console/service-registry/index.html" "2-8.1 healthy metric"
check_grep "Degraded" "web/ops-console/service-registry/index.html" "2-8.1 degraded metric"
check_grep "Maintenance" "web/ops-console/service-registry/index.html" "2-8.1 maintenance metric"
check_grep "Service Instances" "web/ops-console/service-registry/index.html" "2-8.1 service instances table"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_1_SERVICE_REGISTRY_SCREEN.md" "2-8.1 responsive documentation trace"

echo "===== FAZ 2-8.1 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.1 go test"
fi

echo "===== FAZ 2-8.1 SERVICE REGISTRY SCREEN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_TEST_STATUS=PASS"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_FINAL_STATUS=PASS"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_2_READY=YES"
  exit 0
else
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_2_READY=NO"
  exit 1
fi
