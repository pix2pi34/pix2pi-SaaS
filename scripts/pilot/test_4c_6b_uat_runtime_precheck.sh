#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_6b_uat_runtime_precheck.sh"
PREV_REPORT="reports/pilot/faz4c/4c_6a_uat_execution_plan_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_test_report.md"

echo "===== 4C-6B UAT RUNTIME PRECHECK TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6A report yok: $PREV_REPORT"
pass "4C-6A report var"

grep -q "4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-6A PASS degil"
pass "4C-6A PASS"

grep -q "4C_6B_READY=YES" "$PREV_REPORT" || fail "4C-6B ready YES yok"
pass "4C-6B ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-6B report yok: $REPORT_FILE"
pass "4C-6B report var"

grep -q "4C_6B_UAT_RUNTIME_PRECHECK_STATUS=PASS" "$REPORT_FILE" || fail "UAT runtime precheck PASS degil"
pass "UAT runtime precheck PASS"

grep -q "4C_6B_API_GATEWAY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "API Gateway health 200 degil"
pass "API Gateway health 200"

grep -q "4C_6B_IDENTITY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Identity health 200 degil"
pass "Identity health 200"

grep -q "4C_6B_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
pass "DB connect PASS"

grep -q "4C_6B_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_6B_TENANT_SCHEMA_COUNT=1" "$REPORT_FILE" || fail "Tenant schema count 1 degil"
pass "Tenant schema count 1"

grep -q "4C_6B_USER_COUNT=1" "$REPORT_FILE" || fail "User count 1 degil"
pass "User count 1"

grep -q "4C_6B_ROLE_COUNT=1" "$REPORT_FILE" || fail "Role count 1 degil"
pass "Role count 1"

grep -q "4C_6B_ASSIGNMENT_COUNT=1" "$REPORT_FILE" || fail "Assignment count 1 degil"
pass "Assignment count 1"

grep -q "4C_6B_STAGING_TABLE_EXISTS=1" "$REPORT_FILE" || fail "Staging table exists 1 degil"
pass "Staging table exists 1"

grep -q "4C_6B_STAGING_ROW_COUNT=5" "$REPORT_FILE" || fail "Staging row count 5 degil"
pass "Staging row count 5"

grep -q "4C_6B_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
pass "Duplicate SKU count 0"

grep -q "4C_6B_TENANT_MISMATCH_COUNT=0" "$REPORT_FILE" || fail "Tenant mismatch count 0 degil"
pass "Tenant mismatch count 0"

grep -q "4C_6B_OEM_FIELD_COUNT=5" "$REPORT_FILE" || fail "OEM field count 5 degil"
pass "OEM field count 5"

grep -q "4C_6B_EQUIVALENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Equivalent field count 5 degil"
pass "Equivalent field count 5"

grep -q "4C_6B_FITMENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Fitment field count 5 degil"
pass "Fitment field count 5"

grep -q "4C_6B_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_6B_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_6C_READY=YES" "$REPORT_FILE" || fail "4C-6C ready YES yok"
pass "4C-6C ready YES"

WARNING_COUNT="$(grep '^4C_6B_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-6B UAT Runtime Precheck Test Report

Step: 4C-6B
Blok: UAT Runtime Precheck Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6B_TEST_STATUS=PASS
4C_6B_UAT_RUNTIME_PRECHECK_STATUS=PASS
4C_6B_API_GATEWAY_HEALTH_HTTP=200
4C_6B_IDENTITY_HEALTH_HTTP=200
4C_6B_DB_CONNECT_STATUS=PASS
4C_6B_TENANT_COUNT=1
4C_6B_TENANT_SCHEMA_COUNT=1
4C_6B_USER_COUNT=1
4C_6B_ROLE_COUNT=1
4C_6B_ASSIGNMENT_COUNT=1
4C_6B_STAGING_TABLE_EXISTS=1
4C_6B_STAGING_ROW_COUNT=5
4C_6B_DUPLICATE_SKU_COUNT=0
4C_6B_TENANT_MISMATCH_COUNT=0
4C_6B_OEM_FIELD_COUNT=5
4C_6B_EQUIVALENT_FIELD_COUNT=5
4C_6B_FITMENT_FIELD_COUNT=5
4C_6B_DB_WRITE_APPLIED=NO
4C_6B_WARNING_COUNT=$WARNING_COUNT
4C_6C_READY=YES

## Sonuc

UAT runtime precheck test tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6C UAT Test Case Package.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-6B TEST SONUCU ====="
echo "4C_6B_TEST_STATUS=PASS ✅"
echo "4C_6B_UAT_RUNTIME_PRECHECK_STATUS=PASS ✅"
echo "4C_6B_API_GATEWAY_HEALTH_HTTP=200 ✅"
echo "4C_6B_IDENTITY_HEALTH_HTTP=200 ✅"
echo "4C_6B_DB_CONNECT_STATUS=PASS ✅"
echo "4C_6B_TENANT_COUNT=1 ✅"
echo "4C_6B_USER_COUNT=1 ✅"
echo "4C_6B_ROLE_COUNT=1 ✅"
echo "4C_6B_ASSIGNMENT_COUNT=1 ✅"
echo "4C_6B_STAGING_ROW_COUNT=5 ✅"
echo "4C_6B_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_6B_TENANT_MISMATCH_COUNT=0 ✅"
echo "4C_6B_OEM_FIELD_COUNT=5 ✅"
echo "4C_6B_EQUIVALENT_FIELD_COUNT=5 ✅"
echo "4C_6B_FITMENT_FIELD_COUNT=5 ✅"
echo "4C_6B_DB_WRITE_APPLIED=NO ✅"
echo "4C_6C_READY=YES ✅"
