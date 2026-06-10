#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_dir() {
  local label="$1"
  local dir="$2"

  if [ -d "$dir" ]; then
    pass "$label"
  else
    fail "$label dir_missing=${dir}"
  fi
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_go_files() {
  local label="$1"
  local dir="$2"
  local pattern="$3"

  if find "$dir" -maxdepth 1 -type f -name "$pattern" | grep -q .; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

check_grep_dir() {
  local label="$1"
  local dir="$2"
  local pattern="$3"

  if [ -d "$dir" ] && grep -RqiE "$pattern" "$dir"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 129-FIX-V2 — FAZ 3-10.1.2 ACCOUNT PLAN LIVE VERSION SWITCH REAL IMPLEMENTATION AUDIT START ====="

DIR="internal/erp/turkiye/tdhp/accountswitch"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH.md"

check_dir "129 account switch package directory" "$DIR"
check_go_files "129 account switch runtime go file" "$DIR" "*.go"
check_go_files "129 account switch test go file" "$DIR" "*_test.go"
check_file "129 account switch documentation file" "$DOC_FILE"

check_grep_dir "129 package declaration" "$DIR" "package[[:space:]]+accountswitch"
check_grep_dir "129 version concept" "$DIR" "version"
check_grep_dir "129 switch concept" "$DIR" "switch|activate|active"
check_grep_dir "129 tenant guard trace" "$DIR" "tenant"
check_grep_dir "129 correlation trace" "$DIR" "correlation"
check_grep_dir "129 idempotency trace" "$DIR" "idempotency"
check_grep_dir "129 account plan trace" "$DIR" "account|tdhp|hesap"
check_grep_dir "129 test function trace" "$DIR" "func[[:space:]]+Test"

if go test ./internal/erp/turkiye/tdhp/accountswitch; then
  pass "129 account switch go test status"
else
  fail "129 account switch go test status"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 129-FIX-V2 — FAZ 3-10.1.2 — Account Plan Live Version Switch Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_3_READY=${NEXT_READY}

## Scope

- Existing accountswitch package verified
- Runtime Go files verified
- Test Go files verified
- Documentation artifact verified
- Version/switch/account-plan traces verified
- Tenant/correlation/idempotency traces verified
- Go test executed

## Audit Notes

This FIX creates missing evidence from existing runtime/test implementation.
Final status is derived from real files, grep checks and Go test counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 129-FIX-V2 — COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
