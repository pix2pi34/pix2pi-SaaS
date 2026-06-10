#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.1 SERVICE STATUS PANEL CONNECTION REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 runtime file"
check_file "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 test file"
check_file "configs/faz2/ops_runtime/service_status_panel_connection.v1.json" "2-7.2.1 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION.md" "2-7.2.1 documentation file"

check_grep "ServiceStatusPanelConnectionRuntime" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 ServiceStatusPanelConnectionRuntime type"
check_grep "ServiceStatusPanelRequest" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 panel request model"
check_grep "ServiceStatusPanelEntry" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 panel entry model"
check_grep "ServiceStatusPanelSnapshot" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 panel snapshot model"
check_grep "ServiceStatusPanelDecision" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 panel decision model"
check_grep "BuildPanelSnapshot" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 build panel snapshot function"
check_grep "ListVisibleRegistry" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 registry visibility bridge"
check_grep "DetectStaleInstances" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 stale cleanup bridge"
check_grep "restart_action_id" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 restart action metadata bridge"
check_grep "isolate_quarantine_action_state" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 quarantine metadata bridge"
check_grep "maintenance_mode_state" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 maintenance metadata bridge"
check_grep "incident_action_log_id" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 incident metadata bridge"
check_grep "buildServiceStatusPanelTags" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 mission control panel tags"
check_grep "ErrServiceStatusPanelCrossTenant" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 cross tenant panel guard"
check_grep "isServiceStatusPanelScopeValid" "internal/platform/ops/runtime/service_status_panel_connection_runtime.go" "2-7.2.1 scope validation helper"

check_grep "TestServiceStatusPanelConnectionRuntimeBuildsPanelSnapshot" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 build panel snapshot test"
check_grep "TestServiceStatusPanelConnectionRuntimeTenantScopeCrossTenantDenied" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 cross tenant panel test"
check_grep "TestServiceStatusPanelConnectionRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 missing tenant test"
check_grep "TestServiceStatusPanelConnectionRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 missing registry test"
check_grep "TestServiceStatusPanelConnectionRuntimeRejectsMissingVisibility" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 missing visibility test"
check_grep "TestServiceStatusPanelConnectionRuntimeRejectsInvalidScope" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 invalid scope test"
check_grep "TestServiceStatusPanelConnectionRuntimeStaleBridge" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 stale bridge test"
check_grep "TestBuildServiceStatusPanelTags" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 panel tags test"
check_grep "TestIsServiceStatusPanelScopeValid" "internal/platform/ops/runtime/service_status_panel_connection_runtime_test.go" "2-7.2.1 scope validation test"

echo "===== FAZ 2-7.2.1 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.1 go test"
fi

echo "===== FAZ 2-7.2.1 SERVICE STATUS PANEL CONNECTION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_3_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_1_SERVICE_STATUS_PANEL_CONNECTION_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_3_4_READY=NO"
  exit 1
fi
