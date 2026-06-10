#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_1_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.1.2 RUNTIME HEARTBEAT / HEALTH PUSH-PULL REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 runtime file"
check_file "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 test file"
check_file "configs/faz2/ops_runtime/runtime_heartbeat_health_push_pull.v1.json" "2-7.1.2 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL.md" "2-7.1.2 documentation file"

check_grep "RuntimeHeartbeatHealthRuntime" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 RuntimeHeartbeatHealthRuntime type"
check_grep "RuntimeHeartbeatPushRequest" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 heartbeat push request model"
check_grep "RuntimeHeartbeatPushResponse" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 heartbeat push response model"
check_grep "RuntimeHealthSnapshotResponse" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 health snapshot response model"
check_grep "RuntimeHealthDecision" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 health decision model"
check_grep "ServeHTTP" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 HTTP handler"
check_grep "HandleHeartbeatPush" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 heartbeat push handler"
check_grep "HandleHealthSnapshot" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 health snapshot handler"
check_grep "RuntimeHeartbeatEndpointPath" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 heartbeat endpoint path"
check_grep "RuntimeHealthSnapshotPath" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 health snapshot endpoint path"
check_grep "RegisterOrUpdateInstance" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 instance status update bridge"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 last heartbeat metadata bridge"
check_grep "ListVisibleRegistry" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 registry visibility bridge"
check_grep "DetectStaleInstances" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 stale cleanup bridge"
check_grep "ErrRuntimeHealthCrossTenant" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 cross tenant heartbeat guard"
check_grep "last_heartbeat_at" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 last heartbeat model"
check_grep "health_status" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime.go" "2-7.1.2 health status metadata model"

check_grep "TestRuntimeHeartbeatHealthRuntimePushHeartbeatRegistersInstance" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 heartbeat registers instance test"
check_grep "TestRuntimeHeartbeatHealthRuntimePullHealthSnapshot" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 health snapshot test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 missing tenant test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsCrossTenantBody" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 cross tenant body test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsInvalidMethod" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 invalid method test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsInvalidBody" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 invalid body test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsMissingService" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 missing service test"
check_grep "TestRuntimeHeartbeatHealthRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 missing registry test"
check_grep "TestRuntimeHeartbeatHealthRuntimeHealthSnapshotRejectsCrossTenantTenantScope" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 snapshot cross tenant test"
check_grep "TestRuntimeHeartbeatHealthRuntimeBodyTenantFallback" "internal/platform/ops/runtime/runtime_heartbeat_health_runtime_test.go" "2-7.1.2 body tenant fallback test"

echo "===== FAZ 2-7.1.2 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.1.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.1.2 go test"
fi

echo "===== FAZ 2-7.1.2 RUNTIME HEARTBEAT / HEALTH PUSH-PULL REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_TEST_STATUS=PASS"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_FINAL_STATUS=PASS"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_1_2_RUNTIME_HEARTBEAT_HEALTH_PUSH_PULL_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_2_READY=NO"
  exit 1
fi
