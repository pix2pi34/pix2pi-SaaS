#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/apply_4c_5h_controlled_sample_data.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_test_report.md"

echo "===== 4C-5H CONTROLLED SAMPLE DATA APPLY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5G test report yok: $PREV_REPORT"
pass "4C-5G test report var"

grep -q "4C_5G_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5G test PASS degil"
pass "4C-5G test PASS"

grep -q "4C_5H_READY=YES" "$PREV_REPORT" || fail "4C-5H ready YES yok"
pass "4C-5H ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Apply script yok: $RUN_SCRIPT"
pass "Apply script var"

[ -x "$RUN_SCRIPT" ] || fail "Apply script executable degil"
pass "Apply script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5H report yok: $REPORT_FILE"
pass "4C-5H report var"

grep -q "4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS" "$REPORT_FILE" || fail "Controlled sample apply PASS degil"
pass "Controlled sample apply PASS"

grep -q "4C_5H_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_5H_AFTER_TABLE_EXISTS=1" "$REPORT_FILE" || fail "After table exists 1 degil"
pass "After table exists 1"

grep -q "4C_5H_AFTER_ROW_COUNT=5" "$REPORT_FILE" || fail "After row count 5 degil"
pass "After row count 5"

grep -q "4C_5H_AFTER_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "After duplicate SKU count 0 degil"
pass "After duplicate SKU count 0"

grep -q "4C_5H_DB_WRITE_APPLIED=YES" "$REPORT_FILE" || fail "DB write applied YES degil"
pass "DB write applied YES"

grep -q "4C_5H_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5I_READY=YES" "$REPORT_FILE" || fail "4C-5I ready YES yok"
pass "4C-5I ready YES"

BEFORE_TABLE_EXISTS="$(grep '^4C_5H_BEFORE_TABLE_EXISTS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_TABLE_EXISTS="$(grep '^4C_5H_AFTER_TABLE_EXISTS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEFORE_ROW_COUNT="$(grep '^4C_5H_BEFORE_ROW_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ROW_COUNT="$(grep '^4C_5H_AFTER_ROW_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_5H_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-5H Controlled Sample Data Apply Test Report

Step: 4C-5H
Blok: Controlled Sample Data Apply Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5H_TEST_STATUS=PASS
4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS
4C_5H_SQL_EXECUTION_STATUS=PASS
4C_5H_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5H_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5H_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5H_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5H_AFTER_DUPLICATE_SKU_COUNT=0
4C_5H_DB_WRITE_APPLIED=YES
4C_5H_WARNING_COUNT=$WARNING_COUNT
4C_5I_READY=YES

## Sonuc

Controlled sample data apply test tamamlandi.
Sample ürün verileri staging tabloya kalıcı olarak işlendi.
Sonraki adim: 4C-5I Sample Data Verification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5H TEST SONUCU ====="
echo "4C_5H_TEST_STATUS=PASS ✅"
echo "4C_5H_CONTROLLED_SAMPLE_APPLY_STATUS=PASS ✅"
echo "4C_5H_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_5H_AFTER_TABLE_EXISTS=1 ✅"
echo "4C_5H_AFTER_ROW_COUNT=5 ✅"
echo "4C_5H_AFTER_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5H_DB_WRITE_APPLIED=YES ✅"
echo "4C_5I_READY=YES ✅"
