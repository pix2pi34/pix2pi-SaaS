#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PLAN_DOC="docs/pilot/faz4c/4c_1_2_pilot_execution_master_plan.md"
CLOSURE_DOC="docs/pilot/faz4c/4c_1_1j_final_closure.md"
CLOSURE_REPORT="reports/pilot/faz4c/4c_1_1j_final_closure_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_2a_execution_master_plan_report.md"

echo "===== 4C-1.2A EXECUTION MASTER PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PLAN_DOC" ] || fail "Execution master plan yok: $PLAN_DOC"
pass "Execution master plan var"

[ -f "$CLOSURE_DOC" ] || fail "4C-1.1J final closure dokumani yok: $CLOSURE_DOC"
pass "4C-1.1J final closure dokumani var"

[ -f "$CLOSURE_REPORT" ] || fail "4C-1.1J final closure report yok: $CLOSURE_REPORT"
pass "4C-1.1J final closure report var"

grep -q "4C_1_1_FINAL_STATUS=PASS" "$CLOSURE_REPORT" || fail "4C-1.1 final PASS degil"
pass "4C-1.1 final PASS"

grep -q "4C_1_2_READY=YES" "$CLOSURE_REPORT" || fail "4C-1.2 ready YES degil"
pass "4C-1.2 ready YES"

grep -q "uzmanparcaci" "$PLAN_DOC" || fail "Plan dokumaninda uzmanparcaci yok"
pass "Plan dokumaninda pilot isletme var"

grep -q "OTO YEDEK PARCA" "$PLAN_DOC" || fail "Plan dokumaninda sektor yok"
pass "Plan dokumaninda sektor var"

grep -q "4C-2 — Real Runtime Gap Completion" "$PLAN_DOC" || fail "4C-2 sirasi yok"
pass "4C-2 sirasi var"

grep -q "4C-13 — FAZ 4C Final Closure" "$PLAN_DOC" || fail "4C-13 final closure yok"
pass "4C-13 final closure var"

grep -q "4C_1_2_EXECUTION_MASTER_PLAN_STATUS=PASS" "$PLAN_DOC" || fail "4C-1.2 status PASS yok"
pass "4C-1.2 status PASS var"

grep -q "4C_2_READY=YES" "$PLAN_DOC" || fail "4C-2 ready YES yok"
pass "4C-2 ready YES var"

grep -q "FAZ_4D" "$PLAN_DOC" || fail "FAZ 4D marketplace karari yok"
pass "FAZ 4D marketplace karari var"

grep -q "Pazar entegrasyonu beklentisi scope'u sisirebilir" "$PLAN_DOC" || fail "Pazaryeri risk kaydi yok"
pass "Pazaryeri risk kaydi var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.2A Execution Master Plan Report

Step: 4C-1.2A
Blok: Pilot Execution Master Plan / Scope Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_2A_PLAN_DOC_STATUS=PASS
4C_1_2A_PREVIOUS_BLOCK_STATUS=PASS
4C_1_2A_SELECTED_BUSINESS=uzmanparcaci
4C_1_2A_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_1_2A_SCOPE_FREEZE_STATUS=PASS
4C_1_2A_MARKETPLACE_PHASE=FAZ_4D
4C_1_2A_EXECUTION_SEQUENCE_STATUS=PASS
4C_2_READY=YES

## Sonuc

4C-1.2 Pilot Execution Master Plan olusturuldu.
4C-1 Pilot Execution Master Plan / Scope Freeze blogu kapanisa yaklasti.
Sonraki adim: 4C-1.2B final scope freeze closure.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.2A TEST SONUCU ====="
echo "4C_1_2A_PLAN_DOC_STATUS=PASS ✅"
echo "4C_1_2A_PREVIOUS_BLOCK_STATUS=PASS ✅"
echo "4C_1_2A_SELECTED_BUSINESS=uzmanparcaci ✅"
echo "4C_1_2A_SELECTED_SECTOR=OTO_YEDEK_PARCA ✅"
echo "4C_1_2A_SCOPE_FREEZE_STATUS=PASS ✅"
echo "4C_1_2A_MARKETPLACE_PHASE=FAZ_4D ✅"
echo "4C_2_READY=YES ✅"
