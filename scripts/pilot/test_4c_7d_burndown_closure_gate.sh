#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

A_REPORT="reports/pilot/faz4c/4c_7a_burndown_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_7b_warning_burndown_classification_report.md"
C_REPORT="reports/pilot/faz4c/4c_7c_improvement_carry_forward_report.md"

GATE_DOC="docs/pilot/faz4c/4c_7d_burndown_closure_gate.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/burndown_register.md"
IMPROVEMENT_REGISTER="uat/pilot/faz4c/uzmanparcaci/improvement_carry_forward_register.md"
FAZ4D_CARRY_FORWARD="docs/pilot/faz4d/4d_carry_forward_from_4c.md"

REPORT_FILE="reports/pilot/faz4c/4c_7d_burndown_closure_gate_report.md"

echo "===== 4C-7D BURN-DOWN CLOSURE GATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "4C-7A/7B/7C report dosyalari var"

[ -f "$GATE_DOC" ] || fail "4C-7D gate doc yok"
pass "4C-7D gate doc var"

[ -f "$REGISTER_FILE" ] || fail "Burn-down register yok"
pass "Burn-down register var"

[ -f "$IMPROVEMENT_REGISTER" ] || fail "Improvement register yok"
pass "Improvement register var"

[ -f "$FAZ4D_CARRY_FORWARD" ] || fail "FAZ 4D carry-forward doc yok"
pass "FAZ 4D carry-forward doc var"

grep -q "4C_7A_BURNDOWN_PLAN_STATUS=PASS" "$A_REPORT" || fail "4C-7A PASS degil"
pass "4C-7A PASS"

grep -q "4C_7A_CRITICAL_BLOCKER_COUNT=0" "$A_REPORT" || fail "4C-7A critical blocker 0 degil"
pass "4C-7A critical blocker 0"

grep -q "4C_7B_WARNING_BURNDOWN_CLASSIFICATION_STATUS=PASS" "$B_REPORT" || fail "4C-7B PASS degil"
pass "4C-7B PASS"

grep -q "4C_7B_CLOSED_WARNING_COUNT=2" "$B_REPORT" || fail "4C-7B closed warning count 2 degil"
pass "4C-7B closed warning count 2"

grep -q "4C_7B_OPEN_WARNING_COUNT=0" "$B_REPORT" || fail "4C-7B open warning count 0 degil"
pass "4C-7B open warning count 0"

grep -q "4C_7B_BLOCKING_WARNING_COUNT=0" "$B_REPORT" || fail "4C-7B blocking warning count 0 degil"
pass "4C-7B blocking warning count 0"

grep -q "4C_7B_BLOCKING_FIX_REQUIRED=NO" "$B_REPORT" || fail "4C-7B blocking fix NO degil"
pass "4C-7B blocking fix NO"

grep -q "4C_7C_IMPROVEMENT_CARRY_FORWARD_STATUS=PASS" "$C_REPORT" || fail "4C-7C PASS degil"
pass "4C-7C PASS"

grep -q "4C_7C_SOURCE_IMPROVEMENT_COUNT=3" "$C_REPORT" || fail "4C-7C source improvement count 3 degil"
pass "4C-7C source improvement count 3"

grep -q "4C_7C_CARRIED_FORWARD_COUNT=3" "$C_REPORT" || fail "4C-7C carried forward count 3 degil"
pass "4C-7C carried forward count 3"

grep -q "4C_7C_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$C_REPORT" || fail "4C-7C open improvement for 4C 0 degil"
pass "4C-7C open improvement for 4C 0"

grep -q "4C_7C_BLOCKING_FIX_REQUIRED=NO" "$C_REPORT" || fail "4C-7C blocking fix NO degil"
pass "4C-7C blocking fix NO"

grep -q "4C_7D_READY=YES" "$C_REPORT" || fail "4C-7D ready YES yok"
pass "4C-7D ready YES"

grep -q "4C_7D_BURNDOWN_CLOSURE_GATE_STATUS=PASS" "$GATE_DOC" || fail "4C-7D gate status PASS yok"
pass "4C-7D gate status PASS"

grep -q "4C_7D_CRITICAL_BLOCKER_COUNT=0" "$GATE_DOC" || fail "4C-7D critical blocker 0 yok"
pass "4C-7D critical blocker 0"

grep -q "4C_7D_OPEN_WARNING_COUNT=0" "$GATE_DOC" || fail "4C-7D open warning count 0 yok"
pass "4C-7D open warning count 0"

grep -q "4C_7D_BLOCKING_WARNING_COUNT=0" "$GATE_DOC" || fail "4C-7D blocking warning count 0 yok"
pass "4C-7D blocking warning count 0"

grep -q "4C_7D_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$GATE_DOC" || fail "4C-7D open improvement for 4C 0 yok"
pass "4C-7D open improvement for 4C 0"

grep -q "4C_7D_CARRIED_FORWARD_IMPROVEMENT_COUNT=3" "$GATE_DOC" || fail "4C-7D carried forward improvement count 3 yok"
pass "4C-7D carried forward improvement count 3"

grep -q "4C_7D_BLOCKING_FIX_REQUIRED=NO" "$GATE_DOC" || fail "4C-7D blocking fix NO yok"
pass "4C-7D blocking fix NO"

grep -q "4C_7D_DB_WRITE_APPLIED=NO" "$GATE_DOC" || fail "4C-7D DB write NO yok"
pass "4C-7D DB write NO"

grep -q "4C_7E_READY=YES" "$GATE_DOC" || fail "4C-7E ready YES yok"
pass "4C-7E ready YES"

grep -q "OPEN_WARNING_COUNT=0" "$REGISTER_FILE" || fail "Register open warning 0 yok"
pass "Register open warning 0"

grep -q "OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$REGISTER_FILE" || fail "Register open improvement for 4C 0 yok"
pass "Register open improvement for 4C 0"

grep -q "CARRIED_FORWARD_IMPROVEMENT_COUNT=3" "$REGISTER_FILE" || fail "Register carried forward count 3 yok"
pass "Register carried forward count 3"

grep -q "4C_7D_READY=YES" "$IMPROVEMENT_REGISTER" || fail "Improvement register 4C-7D ready YES yok"
pass "Improvement register 4C-7D ready YES"

grep -q "4D_CARRY_FORWARD_ITEM_COUNT=3" "$FAZ4D_CARRY_FORWARD" || fail "FAZ 4D carry-forward item count 3 yok"
pass "FAZ 4D carry-forward item count 3"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-7D Burn-down Closure Gate Report

Step: 4C-7D
Blok: Burn-down Closure Gate
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_7D_BURNDOWN_CLOSURE_GATE_STATUS=PASS
4C_7D_PREVIOUS_BLOCK_STATUS=PASS
4C_7D_7A_STATUS=PASS
4C_7D_7B_STATUS=PASS
4C_7D_7C_STATUS=PASS
4C_7D_CRITICAL_BLOCKER_COUNT=0
4C_7D_WARNING_COUNT=2
4C_7D_CLOSED_WARNING_COUNT=2
4C_7D_OPEN_WARNING_COUNT=0
4C_7D_BLOCKING_WARNING_COUNT=0
4C_7D_SOURCE_IMPROVEMENT_COUNT=3
4C_7D_CARRIED_FORWARD_IMPROVEMENT_COUNT=3
4C_7D_OPEN_IMPROVEMENT_COUNT_FOR_4C=0
4C_7D_BLOCKING_FIX_REQUIRED=NO
4C_7D_DB_WRITE_APPLIED=NO
4C_7E_READY=YES

## Karar

4C-7 final closure öncesi kapı PASS.
Critical blocker yok.
Açık warning yok.
FAZ 4C için açık improvement yok.
Blocking fix gerekmiyor.

## Sonuc

4C-7D Burn-down Closure Gate tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-7E Bug / Blocker Burn-down Final Closure.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-7D TEST SONUCU ====="
echo "4C_7D_BURNDOWN_CLOSURE_GATE_STATUS=PASS ✅"
echo "4C_7D_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_7D_OPEN_WARNING_COUNT=0 ✅"
echo "4C_7D_OPEN_IMPROVEMENT_COUNT_FOR_4C=0 ✅"
echo "4C_7D_BLOCKING_FIX_REQUIRED=NO ✅"
echo "4C_7D_DB_WRITE_APPLIED=NO ✅"
echo "4C_7E_READY=YES ✅"
