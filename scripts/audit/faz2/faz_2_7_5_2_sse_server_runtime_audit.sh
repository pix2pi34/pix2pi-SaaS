#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_5_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_5_2_SSE_SERVER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.5.2 SSE SERVER RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/realtime/sse_runtime.go" "2-7.5.2 runtime file"
check_file "internal/platform/realtime/sse_runtime_test.go" "2-7.5.2 test file"
check_file "cmd/realtime-sse/realtime_sse_main.go" "2-7.5.2 service main file"
check_file "configs/faz2/realtime/sse_runtime.v1.json" "2-7.5.2 config file"
check_file "docs/faz2/realtime/FAZ_2_7_5_2_SSE_SERVER_RUNTIME.md" "2-7.5.2 documentation file"

check_grep "text/event-stream" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 SSE content type"
check_grep "X-Tenant-ID|DefaultTenantHeader" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 tenant header enforcement"
check_grep "RequireTenant" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 require tenant config"
check_grep "channel" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 channel param"
check_grep "HeartbeatIntervalSeconds|heartbeat" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 heartbeat support"
check_grep "event: %s|writeEvent" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 SSE event format writer"
check_grep "ActiveConnectionCount|activeCount" "internal/platform/realtime/sse_runtime.go" "2-7.5.2 active connection counter"
check_grep "StatusUnauthorized" "internal/platform/realtime/sse_runtime_test.go" "2-7.5.2 missing tenant rejection test"
check_grep "StatusBadRequest" "internal/platform/realtime/sse_runtime_test.go" "2-7.5.2 missing channel rejection test"
check_grep "event: welcome" "internal/platform/realtime/sse_runtime_test.go" "2-7.5.2 welcome event test"
check_grep "event: heartbeat" "internal/platform/realtime/sse_runtime_test.go" "2-7.5.2 heartbeat event test"
check_grep "realtime_sse_main.go" "docs/faz2/realtime/FAZ_2_7_5_2_SSE_SERVER_RUNTIME.md" "2-7.5.2 documented service main"

echo "===== FAZ 2-7.5.2 GO TEST ====="
if go test ./internal/platform/realtime ./cmd/realtime-sse; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.5.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.5.2 go test"
fi

echo "===== FAZ 2-7.5.2 SSE SERVER RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_5_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_5_2_SSE_SERVER_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_5_3_READY=NO"
  exit 1
fi
