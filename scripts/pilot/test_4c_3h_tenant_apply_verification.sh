#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_3h_tenant_apply_verification.sh"
REPORT_FILE="reports/pilot/faz4c/4c_3h_tenant_apply_verification_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3h_tenant_apply_verification_test_report.md"

echo "===== 4C-3H TENANT APPLY VERIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$RUN_SCRIPT" ] || fail "Verification script yok: $RUN_SCRIPT"
pass "Verification script var"

[ -x "$RUN_SCRIPT" ] || fail "Verification script executable degil"
pass "Verification script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-3H report yok: $REPORT_FILE"
pass "4C-3H report var"

grep -q "4C_3H_TENANT_VERIFICATION_STATUS=PASS" "$REPORT_FILE" || fail "Tenant verification PASS degil"
pass "Tenant verification PASS"

grep -q "4C_3H_SCHEMA_COUNT=1" "$REPORT_FILE" || fail "Schema count 1 degil"
pass "Schema count 1"

grep -q "4C_3H_TENANT_COUNT_BY_SLUG=1" "$REPORT_FILE" || fail "Tenant count by slug 1 degil"
pass "Tenant count by slug 1"

grep -q "4C_3H_TENANT_COUNT_BY_CODE=1" "$REPORT_FILE" || fail "Tenant count by code 1 degil"
pass "Tenant count by code 1"

grep -q "4C_3H_DUPLICATE_TENANT_COUNT=1" "$REPORT_FILE" || fail "Duplicate tenant count 1 degil"
pass "Duplicate tenant count 1"

grep -q "4C_3H_CODE_CAST_STATUS=PASS" "$REPORT_FILE" || fail "Code cast PASS degil"
pass "Code cast PASS"

grep -q "4C_3H_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_3I_READY=YES" "$REPORT_FILE" || fail "4C-3I ready YES yok"
pass "4C-3I ready YES"

SCHEMA_COUNT="$(grep '^4C_3H_SCHEMA_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
TENANT_COUNT="$(grep '^4C_3H_TENANT_COUNT_BY_SLUG=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
DUP_COUNT="$(grep '^4C_3H_DUPLICATE_TENANT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
SMOKE_STATUS="$(grep '^4C_3H_SEARCH_PATH_SMOKE_STATUS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3H Tenant Apply Verification Test Report

Step: 4C-3H
Blok: Tenant Apply Verification / Isolation Smoke Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3H_TEST_STATUS=PASS
4C_3H_TENANT_VERIFICATION_STATUS=PASS
4C_3H_SCHEMA_COUNT=$SCHEMA_COUNT
4C_3H_TENANT_COUNT_BY_SLUG=$TENANT_COUNT
4C_3H_DUPLICATE_TENANT_COUNT=$DUP_COUNT
4C_3H_SEARCH_PATH_SMOKE_STATUS=$SMOKE_STATUS
4C_3H_DB_WRITE_APPLIED=NO
4C_3I_READY=YES

## Sonuç

Tenant verification smoke test tamamlandı.
Kalıcı DB yazma yapılmadı.
Sonraki adım: 4C-3I Tenant Setup Final Closure.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3H TEST SONUCU ====="
echo "4C_3H_TEST_STATUS=PASS ✅"
echo "4C_3H_TENANT_VERIFICATION_STATUS=PASS ✅"
echo "4C_3H_SCHEMA_COUNT=$SCHEMA_COUNT ✅"
echo "4C_3H_TENANT_COUNT_BY_SLUG=$TENANT_COUNT ✅"
echo "4C_3H_DUPLICATE_TENANT_COUNT=$DUP_COUNT ✅"
echo "4C_3H_SEARCH_PATH_SMOKE_STATUS=$SMOKE_STATUS"
echo "4C_3H_DB_WRITE_APPLIED=NO ✅"
echo "4C_3I_READY=YES ✅"
