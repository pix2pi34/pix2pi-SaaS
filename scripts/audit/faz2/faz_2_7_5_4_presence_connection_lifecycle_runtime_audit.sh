#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_5_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.5.4 PRESENCE / CONNECTION LIFECYCLE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/realtime/presence_runtime.go" "2-7.5.4 presence runtime file"
check_file "internal/platform/realtime/presence_runtime_test.go" "2-7.5.4 presence test file"
check_file "internal/platform/realtime/websocket_runtime.go" "2-7.5.4 websocket bridge file"
check_file "internal/platform/realtime/sse_runtime.go" "2-7.5.4 SSE bridge file"
check_file "configs/faz2/realtime/presence_connection_lifecycle_runtime.v1.json" "2-7.5.4 config file"
check_file "docs/faz2/realtime/FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME.md" "2-7.5.4 documentation file"

check_grep "NewConnectionID" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 connection ID generator"
check_grep "PresenceRuntime" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 PresenceRuntime type"
check_grep "Connect\\(" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 connect lifecycle"
check_grep "Heartbeat\\(" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 heartbeat lifecycle"
check_grep "Disconnect\\(" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 disconnect lifecycle"
check_grep "ErrPresenceCrossTenant" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 cross tenant guard"
check_grep "CountTenantConnections" "internal/platform/realtime/presence_runtime.go" "2-7.5.4 tenant-safe connection count"
check_grep "presenceRuntime|PresenceConnectionCount" "internal/platform/realtime/websocket_runtime.go" "2-7.5.4 websocket lifecycle bridge"
check_grep "presenceRuntime|PresenceConnectionCount" "internal/platform/realtime/sse_runtime.go" "2-7.5.4 SSE lifecycle bridge"
check_grep "connection_id|presence_status" "internal/platform/realtime/websocket_runtime.go" "2-7.5.4 websocket welcome presence fields"
check_grep "connection_id|presence_status" "internal/platform/realtime/sse_runtime.go" "2-7.5.4 SSE welcome presence fields"
check_grep "ErrPresenceCrossTenant" "internal/platform/realtime/presence_runtime_test.go" "2-7.5.4 cross tenant test"
check_grep "WelcomeIncludesPresenceConnectionID" "internal/platform/realtime/presence_runtime_test.go" "2-7.5.4 bridge welcome tests"

echo "===== FAZ 2-7.5.4 GO TEST ====="
if go test ./internal/platform/realtime ./cmd/realtime-ws ./cmd/realtime-sse; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.5.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.5.4 go test"
fi

echo "===== FAZ 2-7.5.4 PRESENCE / CONNECTION LIFECYCLE RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_5_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_5_4_PRESENCE_CONNECTION_LIFECYCLE_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_5_5_READY=NO"
  exit 1
fi
