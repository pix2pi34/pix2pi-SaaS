#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_5_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.5.1 WEBSOCKET SERVER RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 runtime file"
check_file "internal/platform/realtime/websocket_runtime_test.go" "2-7.5.1 test file"
check_file "cmd/realtime-ws/realtime_ws_main.go" "2-7.5.1 service main file"
check_file "configs/faz2/realtime/websocket_runtime.v1.json" "2-7.5.1 config file"
check_file "docs/faz2/realtime/FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME.md" "2-7.5.1 documentation file"

check_grep "websocket.Upgrader" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 websocket upgrader"
check_grep "X-Tenant-ID|DefaultTenantHeader" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 tenant header enforcement"
check_grep "RequireTenant" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 require tenant config"
check_grep "channel" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 channel param"
check_grep "ActiveConnectionCount|activeCount" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 active connection counter"
check_grep "MessageTypePing|MessageTypePong" "internal/platform/realtime/websocket_runtime.go" "2-7.5.1 ping pong support"
check_grep "httptest.NewServer" "internal/platform/realtime/websocket_runtime_test.go" "2-7.5.1 httptest websocket tests"
check_grep "StatusUnauthorized" "internal/platform/realtime/websocket_runtime_test.go" "2-7.5.1 missing tenant rejection test"
check_grep "realtime_ws_main.go" "docs/faz2/realtime/FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME.md" "2-7.5.1 documented service main"

echo "===== FAZ 2-7.5.1 GO TEST ====="
if go test ./internal/platform/realtime ./cmd/realtime-ws; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.5.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.5.1 go test"
fi

echo "===== FAZ 2-7.5.1 WEBSOCKET SERVER RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_5_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_5_1_WEBSOCKET_SERVER_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_5_2_READY=NO"
  exit 1
fi
