#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_7a_burndown_plan_report.md"
CLASS_DOC="docs/pilot/faz4c/4c_7b_warning_burndown_classification.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/burndown_register.md"
REPORT_FILE="reports/pilot/faz4c/4c_7b_warning_burndown_classification_report.md"

echo "===== 4C-7B WARNING BURN-DOWN CLASSIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-7A report yok: $PREV_REPORT"
pass "4C-7A report var"

grep -q "4C_7A_BURNDOWN_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-7A PASS degil"
pass "4C-7A PASS"

grep -q "4C_7A_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-7A critical blocker 0 degil"
pass "4C-7A critical blocker 0"

grep -q "4C_7A_WARNING_COUNT=2" "$PREV_REPORT" || fail "4C-7A warning count 2 degil"
pass "4C-7A warning count 2"

grep -q "4C_7A_IMPROVEMENT_COUNT=3" "$PREV_REPORT" || fail "4C-7A improvement count 3 degil"
pass "4C-7A improvement count 3"

grep -q "4C_7B_READY=YES" "$PREV_REPORT" || fail "4C-7B ready YES yok"
pass "4C-7B ready YES"

[ -f "$CLASS_DOC" ] || fail "4C-7B classification doc yok"
pass "4C-7B classification doc var"

[ -f "$REGISTER_FILE" ] || fail "Burn-down register yok"
pass "Burn-down register var"

grep -q "4C_7B_WARNING_BURNDOWN_CLASSIFICATION_STATUS=PASS" "$CLASS_DOC" || fail "4C-7B status PASS yok"
pass "4C-7B status PASS"

grep -q "4C_7B_WARNING_COUNT=2" "$CLASS_DOC" || fail "4C-7B warning count 2 yok"
pass "4C-7B warning count 2"

grep -q "4C_7B_CLOSED_WARNING_COUNT=2" "$CLASS_DOC" || fail "4C-7B closed warning count 2 yok"
pass "4C-7B closed warning count 2"

grep -q "4C_7B_OPEN_WARNING_COUNT=0" "$CLASS_DOC" || fail "4C-7B open warning count 0 yok"
pass "4C-7B open warning count 0"

grep -q "4C_7B_BLOCKING_WARNING_COUNT=0" "$CLASS_DOC" || fail "4C-7B blocking warning count 0 yok"
pass "4C-7B blocking warning count 0"

grep -q "4C_7B_WARN_01_STATUS=CLOSED" "$CLASS_DOC" || fail "WARN-01 CLOSED yok"
pass "WARN-01 CLOSED"

grep -q "4C_7B_WARN_02_STATUS=CLOSED" "$CLASS_DOC" || fail "WARN-02 CLOSED yok"
pass "WARN-02 CLOSED"

grep -q "4C_7B_BLOCKING_FIX_REQUIRED=NO" "$CLASS_DOC" || fail "Blocking fix required NO yok"
pass "Blocking fix required NO"

grep -q "4C_7B_DB_WRITE_APPLIED=NO" "$CLASS_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_7C_READY=YES" "$CLASS_DOC" || fail "4C-7C ready YES yok"
pass "4C-7C ready YES"

grep -q "WARN_01_STATUS=CLOSED" "$REGISTER_FILE" || fail "Register WARN_01_STATUS CLOSED yok"
pass "Register WARN_01_STATUS CLOSED"

grep -q "WARN_02_STATUS=CLOSED" "$REGISTER_FILE" || fail "Register WARN_02_STATUS CLOSED yok"
pass "Register WARN_02_STATUS CLOSED"

grep -q "OPEN_WARNING_COUNT=0" "$REGISTER_FILE" || fail "Register OPEN_WARNING_COUNT 0 yok"
pass "Register OPEN_WARNING_COUNT 0"

grep -q "CLOSED_WARNING_COUNT=2" "$REGISTER_FILE" || fail "Register CLOSED_WARNING_COUNT 2 yok"
pass "Register CLOSED_WARNING_COUNT 2"

grep -q "IMP-01" "$REGISTER_FILE" || fail "IMP-01 register yok"
pass "IMP-01 register var"

grep -q "IMP-02" "$REGISTER_FILE" || fail "IMP-02 register yok"
pass "IMP-02 register var"

grep -q "IMP-03" "$REGISTER_FILE" || fail "IMP-03 register yok"
pass "IMP-03 register var"

grep -q "4C_7C_READY=YES" "$REGISTER_FILE" || fail "Register 4C-7C ready YES yok"
pass "Register 4C-7C ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-7B Warning Burn-down Classification Report

Step: 4C-7B
Blok: Warning Burn-down Classification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_7B_WARNING_BURNDOWN_CLASSIFICATION_STATUS=PASS
4C_7B_PREVIOUS_BLOCK_STATUS=PASS
4C_7B_WARNING_COUNT=2
4C_7B_CLOSED_WARNING_COUNT=2
4C_7B_OPEN_WARNING_COUNT=0
4C_7B_BLOCKING_WARNING_COUNT=0
4C_7B_WARN_01_STATUS=CLOSED
4C_7B_WARN_02_STATUS=CLOSED
4C_7B_BLOCKING_FIX_REQUIRED=NO
4C_7B_DB_WRITE_APPLIED=NO
4C_7C_READY=YES

## Karar

WARN-01 barkod boşluğu blocker değildir ve kapatıldı.
WARN-02 işletme kabul kapısı PASS alındığı için kapatıldı.
Açık warning kalmadı.
Improvement kayıtları 4C-7C adımına taşınacak.

## Sonuc

4C-7B warning burn-down classification tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-7C Improvement Carry-forward Plan.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-7B TEST SONUCU ====="
echo "4C_7B_WARNING_BURNDOWN_CLASSIFICATION_STATUS=PASS ✅"
echo "4C_7B_WARNING_COUNT=2 ⚠️"
echo "4C_7B_CLOSED_WARNING_COUNT=2 ✅"
echo "4C_7B_OPEN_WARNING_COUNT=0 ✅"
echo "4C_7B_BLOCKING_WARNING_COUNT=0 ✅"
echo "4C_7B_BLOCKING_FIX_REQUIRED=NO ✅"
echo "4C_7B_DB_WRITE_APPLIED=NO ✅"
echo "4C_7C_READY=YES ✅"
