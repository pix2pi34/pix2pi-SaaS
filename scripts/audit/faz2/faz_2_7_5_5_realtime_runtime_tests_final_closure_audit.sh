#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_5_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.5.5 REALTIME RUNTIME TESTS FINAL CLOSURE AUDIT START ====="

check_file "internal/platform/realtime/websocket_runtime.go" "2-7.5.5 websocket runtime file"
check_file "internal/platform/realtime/sse_runtime.go" "2-7.5.5 SSE runtime file"
check_file "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.5 channel auth runtime file"
check_file "internal/platform/realtime/presence_runtime.go" "2-7.5.5 presence runtime file"
check_file "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 final test file"
check_file "cmd/realtime-ws/realtime_ws_main.go" "2-7.5.5 websocket service main"
check_file "cmd/realtime-sse/realtime_sse_main.go" "2-7.5.5 SSE service main"
check_file "configs/faz2/realtime/realtime_runtime_tests_final_closure.v1.json" "2-7.5.5 final closure config"
check_file "docs/faz2/realtime/FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_FINAL_CLOSURE.md" "2-7.5.5 final closure documentation"

check_grep "TestRealtimeFinalWebSocketTenantAuthPresencePingPong" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 websocket final test"
check_grep "TestRealtimeFinalWebSocketCrossTenantDenied" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 websocket cross-tenant deny final test"
check_grep "TestRealtimeFinalSSETenantAuthPresenceWelcomeHeartbeat" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 SSE final test"
check_grep "TestRealtimeFinalSSECrossTenantDenied" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 SSE cross-tenant deny final test"
check_grep "TestRealtimeFinalPresenceTenantIsolation" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 presence tenant isolation final test"
check_grep "TestRealtimeFinalChannelPolicyNormalization" "internal/platform/realtime/realtime_runtime_final_test.go" "2-7.5.5 channel policy final test"

check_grep "websocket.Upgrader" "internal/platform/realtime/websocket_runtime.go" "2-7.5.5 websocket upgrader implemented"
check_grep "text/event-stream" "internal/platform/realtime/sse_runtime.go" "2-7.5.5 SSE stream implemented"
check_grep "AuthorizeChannel" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.5 channel auth implemented"
check_grep "ErrPresenceCrossTenant" "internal/platform/realtime/presence_runtime.go" "2-7.5.5 tenant-safe presence implemented"
check_grep "PresenceConnectionCount" "internal/platform/realtime/websocket_runtime.go" "2-7.5.5 websocket presence bridge"
check_grep "PresenceConnectionCount" "internal/platform/realtime/sse_runtime.go" "2-7.5.5 SSE presence bridge"

echo "===== FAZ 2-7.5.5 GO TEST ====="
if go test ./internal/platform/realtime ./cmd/realtime-ws ./cmd/realtime-sse; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.5.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.5.5 go test"
fi

echo "===== FAZ 2-7.5.5 REALTIME RUNTIME TESTS FINAL CLOSURE AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_5_REALTIME_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_1_READY=YES"
  exit 0
else
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_5_5_REALTIME_RUNTIME_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_5_REALTIME_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_1_READY=NO"
  exit 1
fi
