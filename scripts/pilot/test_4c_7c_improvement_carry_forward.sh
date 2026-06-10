#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_7b_warning_burndown_classification_report.md"
PLAN_DOC="docs/pilot/faz4c/4c_7c_improvement_carry_forward_plan.md"
FUTURE_DOC="docs/pilot/faz4d/4d_carry_forward_from_4c.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/burndown_register.md"
IMPROVEMENT_REGISTER="uat/pilot/faz4c/uzmanparcaci/improvement_carry_forward_register.md"
REPORT_FILE="reports/pilot/faz4c/4c_7c_improvement_carry_forward_report.md"

echo "===== 4C-7C IMPROVEMENT CARRY-FORWARD TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-7B report yok: $PREV_REPORT"
pass "4C-7B report var"

grep -q "4C_7B_WARNING_BURNDOWN_CLASSIFICATION_STATUS=PASS" "$PREV_REPORT" || fail "4C-7B PASS degil"
pass "4C-7B PASS"

grep -q "4C_7B_CLOSED_WARNING_COUNT=2" "$PREV_REPORT" || fail "4C-7B closed warning count 2 degil"
pass "4C-7B closed warning count 2"

grep -q "4C_7B_OPEN_WARNING_COUNT=0" "$PREV_REPORT" || fail "4C-7B open warning count 0 degil"
pass "4C-7B open warning count 0"

grep -q "4C_7B_BLOCKING_FIX_REQUIRED=NO" "$PREV_REPORT" || fail "4C-7B blocking fix NO degil"
pass "4C-7B blocking fix NO"

grep -q "4C_7C_READY=YES" "$PREV_REPORT" || fail "4C-7C ready YES yok"
pass "4C-7C ready YES"

[ -f "$PLAN_DOC" ] || fail "4C-7C plan doc yok"
pass "4C-7C plan doc var"

[ -f "$FUTURE_DOC" ] || fail "FAZ 4D carry-forward doc yok"
pass "FAZ 4D carry-forward doc var"

[ -f "$REGISTER_FILE" ] || fail "Burn-down register yok"
pass "Burn-down register var"

[ -f "$IMPROVEMENT_REGISTER" ] || fail "Improvement carry-forward register yok"
pass "Improvement carry-forward register var"

grep -q "4C_7C_IMPROVEMENT_CARRY_FORWARD_STATUS=PASS" "$PLAN_DOC" || fail "4C-7C status PASS yok"
pass "4C-7C status PASS"

grep -q "4C_7C_SOURCE_IMPROVEMENT_COUNT=3" "$PLAN_DOC" || fail "Source improvement count 3 yok"
pass "Source improvement count 3"

grep -q "4C_7C_CARRIED_FORWARD_COUNT=3" "$PLAN_DOC" || fail "Carried forward count 3 yok"
pass "Carried forward count 3"

grep -q "4C_7C_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$PLAN_DOC" || fail "Open improvement for 4C 0 yok"
pass "Open improvement for 4C 0"

grep -q "4C_7C_IMP_01_STATUS=CARRIED_FORWARD" "$PLAN_DOC" || fail "IMP-01 carried forward yok"
pass "IMP-01 carried forward"

grep -q "4C_7C_IMP_02_STATUS=CARRIED_FORWARD" "$PLAN_DOC" || fail "IMP-02 carried forward yok"
pass "IMP-02 carried forward"

grep -q "4C_7C_IMP_03_STATUS=CARRIED_FORWARD" "$PLAN_DOC" || fail "IMP-03 carried forward yok"
pass "IMP-03 carried forward"

grep -q "4C_7C_TARGET_PHASE_4D_COUNT=3" "$PLAN_DOC" || fail "Target phase 4D count 3 yok"
pass "Target phase 4D count 3"

grep -q "4C_7C_TARGET_PHASE_5_COUNT=1" "$PLAN_DOC" || fail "Target phase 5 count 1 yok"
pass "Target phase 5 count 1"

grep -q "4C_7C_BLOCKING_FIX_REQUIRED=NO" "$PLAN_DOC" || fail "Blocking fix required NO yok"
pass "Blocking fix required NO"

grep -q "4C_7C_DB_WRITE_APPLIED=NO" "$PLAN_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_7D_READY=YES" "$PLAN_DOC" || fail "4C-7D ready YES yok"
pass "4C-7D ready YES"

grep -q "4D_CARRY_FORWARD_FROM_4C_STATUS=PLANNED" "$FUTURE_DOC" || fail "FAZ 4D carry-forward planned yok"
pass "FAZ 4D carry-forward planned"

grep -q "4D_CARRY_FORWARD_ITEM_COUNT=3" "$FUTURE_DOC" || fail "FAZ 4D item count 3 yok"
pass "FAZ 4D item count 3"

grep -q "IMP_01_STATUS=CARRIED_FORWARD" "$REGISTER_FILE" || fail "Register IMP_01 carried forward yok"
pass "Register IMP_01 carried forward"

grep -q "IMP_02_STATUS=CARRIED_FORWARD" "$REGISTER_FILE" || fail "Register IMP_02 carried forward yok"
pass "Register IMP_02 carried forward"

grep -q "IMP_03_STATUS=CARRIED_FORWARD" "$REGISTER_FILE" || fail "Register IMP_03 carried forward yok"
pass "Register IMP_03 carried forward"

grep -q "OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$REGISTER_FILE" || fail "Register open improvement for 4C 0 yok"
pass "Register open improvement for 4C 0"

grep -q "4C_7D_READY=YES" "$REGISTER_FILE" || fail "Register 4C-7D ready YES yok"
pass "Register 4C-7D ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-7C Improvement Carry-forward Report

Step: 4C-7C
Blok: Improvement Carry-forward Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_7C_IMPROVEMENT_CARRY_FORWARD_STATUS=PASS
4C_7C_PREVIOUS_BLOCK_STATUS=PASS
4C_7C_SOURCE_IMPROVEMENT_COUNT=3
4C_7C_CARRIED_FORWARD_COUNT=3
4C_7C_OPEN_IMPROVEMENT_COUNT_FOR_4C=0
4C_7C_IMP_01_STATUS=CARRIED_FORWARD
4C_7C_IMP_02_STATUS=CARRIED_FORWARD
4C_7C_IMP_03_STATUS=CARRIED_FORWARD
4C_7C_TARGET_PHASE_4D_COUNT=3
4C_7C_TARGET_PHASE_5_COUNT=1
4C_7C_BLOCKING_FIX_REQUIRED=NO
4C_7C_DB_WRITE_APPLIED=NO
4C_7D_READY=YES

## Carry-forward dosyalari

BURNDOWN_REGISTER=uat/pilot/faz4c/uzmanparcaci/burndown_register.md
IMPROVEMENT_REGISTER=uat/pilot/faz4c/uzmanparcaci/improvement_carry_forward_register.md
FAZ_4D_CARRY_FORWARD_DOC=docs/pilot/faz4d/4d_carry_forward_from_4c.md

## Karar

3 improvement kaydi FAZ 4C final kapanisini engellemez.
Tamami hedef fazlara tasindi.
FAZ 4C icin acik improvement kalmadi.

## Sonuc

4C-7C improvement carry-forward tamamlandi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-7D Burn-down Closure Gate.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-7C TEST SONUCU ====="
echo "4C_7C_IMPROVEMENT_CARRY_FORWARD_STATUS=PASS ✅"
echo "4C_7C_SOURCE_IMPROVEMENT_COUNT=3 ✅"
echo "4C_7C_CARRIED_FORWARD_COUNT=3 ✅"
echo "4C_7C_OPEN_IMPROVEMENT_COUNT_FOR_4C=0 ✅"
echo "4C_7C_TARGET_PHASE_4D_COUNT=3 ✅"
echo "4C_7C_TARGET_PHASE_5_COUNT=1 ✅"
echo "4C_7C_BLOCKING_FIX_REQUIRED=NO ✅"
echo "4C_7C_DB_WRITE_APPLIED=NO ✅"
echo "4C_7D_READY=YES ✅"
