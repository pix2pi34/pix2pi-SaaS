#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_5_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.5.3 TENANT-SAFE CHANNEL AUTH RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 channel auth runtime file"
check_file "internal/platform/realtime/channel_auth_runtime_test.go" "2-7.5.3 channel auth test file"
check_file "internal/platform/realtime/websocket_runtime.go" "2-7.5.3 websocket bridge file"
check_file "internal/platform/realtime/sse_runtime.go" "2-7.5.3 SSE bridge file"
check_file "configs/faz2/realtime/channel_auth_runtime.v1.json" "2-7.5.3 config file"
check_file "docs/faz2/realtime/FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME.md" "2-7.5.3 documentation file"

check_grep "ChannelAuthRuntime" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 ChannelAuthRuntime type"
check_grep "AuthorizeChannel" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 AuthorizeChannel function"
check_grep "NormalizeTenantChannelKey" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 normalized tenant channel key"
check_grep "CHANNEL_AUTH_CROSS_TENANT_CHANNEL|ChannelAuthReasonCrossTenantChannel" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 cross-tenant deny reason"
check_grep "CHANNEL_AUTH_INVALID_CHANNEL_NAME|ChannelAuthReasonInvalidChannelName" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 invalid channel deny reason"
check_grep "CHANNEL_AUTH_FORBIDDEN_SYSTEM_ZONE|ChannelAuthReasonForbiddenSystemZone" "internal/platform/realtime/channel_auth_runtime.go" "2-7.5.3 forbidden system zone deny reason"
check_grep "ChannelAuthorizer|AuthorizeChannel" "internal/platform/realtime/websocket_runtime.go" "2-7.5.3 websocket channel auth bridge"
check_grep "ChannelAuthorizer|AuthorizeChannel" "internal/platform/realtime/sse_runtime.go" "2-7.5.3 SSE channel auth bridge"
check_grep "StatusForbidden" "internal/platform/realtime/channel_auth_runtime_test.go" "2-7.5.3 forbidden channel tests"
check_grep "tenant:tenant_8:orders" "internal/platform/realtime/channel_auth_runtime_test.go" "2-7.5.3 cross tenant test case"
check_grep "auth_decision|auth_reason" "internal/platform/realtime/websocket_runtime.go" "2-7.5.3 websocket audit decision fields"
check_grep "auth_decision|auth_reason" "internal/platform/realtime/sse_runtime.go" "2-7.5.3 SSE audit decision fields"

echo "===== FAZ 2-7.5.3 GO TEST ====="
if go test ./internal/platform/realtime ./cmd/realtime-ws ./cmd/realtime-sse; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.5.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.5.3 go test"
fi

echo "===== FAZ 2-7.5.3 TENANT-SAFE CHANNEL AUTH RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_5_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_5_3_TENANT_SAFE_CHANNEL_AUTH_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_5_4_READY=NO"
  exit 1
fi
