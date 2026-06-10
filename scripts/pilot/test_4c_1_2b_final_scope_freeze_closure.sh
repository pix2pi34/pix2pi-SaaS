#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_1_2b_final_scope_freeze_closure.md"
FINAL_ALIAS_DOC="docs/pilot/faz4c/4c_1_final_closure.md"
CLOSURE_11_REPORT="reports/pilot/faz4c/4c_1_1j_final_closure_report.md"
PLAN_12_DOC="docs/pilot/faz4c/4c_1_2_pilot_execution_master_plan.md"
PLAN_12_REPORT="reports/pilot/faz4c/4c_1_2a_execution_master_plan_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_2b_final_scope_freeze_closure_report.md"

echo "===== 4C-1.2B FINAL SCOPE FREEZE CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-1.2B final closure dokumani yok: $FINAL_DOC"
pass "4C-1.2B final closure dokumani var"

[ -f "$FINAL_ALIAS_DOC" ] || fail "4C-1 final closure alias dokumani yok: $FINAL_ALIAS_DOC"
pass "4C-1 final closure alias dokumani var"

[ -f "$CLOSURE_11_REPORT" ] || fail "4C-1.1J report yok: $CLOSURE_11_REPORT"
pass "4C-1.1J report var"

[ -f "$PLAN_12_DOC" ] || fail "4C-1.2 plan dokumani yok: $PLAN_12_DOC"
pass "4C-1.2 plan dokumani var"

[ -f "$PLAN_12_REPORT" ] || fail "4C-1.2A report yok: $PLAN_12_REPORT"
pass "4C-1.2A report var"

grep -q "4C_1_1_FINAL_STATUS=PASS" "$CLOSURE_11_REPORT" || fail "4C-1.1 final PASS degil"
pass "4C-1.1 final PASS"

grep -q "4C_1_2A_PLAN_DOC_STATUS=PASS" "$PLAN_12_REPORT" || fail "4C-1.2A plan PASS degil"
pass "4C-1.2A plan PASS"

grep -q "4C_2_READY=YES" "$PLAN_12_REPORT" || fail "4C-2 ready YES 4C-1.2A raporda yok"
pass "4C-2 ready YES 4C-1.2A raporda var"

grep -q "4C_1_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-1 final PASS yok"
pass "4C-1 final PASS var"

grep -q "4C_1_1_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-1.1 final PASS yok"
pass "4C-1.1 final PASS var"

grep -q "4C_1_2_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-1.2 final PASS yok"
pass "4C-1.2 final PASS var"

grep -q "4C_1_SELECTED_BUSINESS=uzmanparcaci" "$FINAL_DOC" || fail "Secilen isletme yok"
pass "Secilen isletme var"

grep -q "4C_1_SCOPE_FREEZE_STATUS=PASS" "$FINAL_DOC" || fail "Scope freeze PASS yok"
pass "Scope freeze PASS var"

grep -q "4C_1_MARKETPLACE_PHASE=FAZ_4D" "$FINAL_DOC" || fail "Marketplace FAZ 4D karari yok"
pass "Marketplace FAZ 4D karari var"

grep -q "4C_2_READY=YES" "$FINAL_DOC" || fail "4C-2 ready YES yok"
pass "4C-2 ready YES var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.2B Final Scope Freeze Closure Report

Step: 4C-1.2B
Blok: Final Scope Freeze Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_2B_FINAL_DOC_STATUS=PASS
4C_1_2B_ALIAS_DOC_STATUS=PASS
4C_1_1_FINAL_STATUS=PASS
4C_1_2_FINAL_STATUS=PASS
4C_1_FINAL_STATUS=PASS
4C_1_SELECTED_BUSINESS=uzmanparcaci
4C_1_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_1_SCOPE_FREEZE_STATUS=PASS
4C_1_MARKETPLACE_PHASE=FAZ_4D
4C_2_READY=YES

## Sonuc

4C-1 Pilot Execution Master Plan / Scope Freeze ana blogu kapandi.
Sonraki ana blok: 4C-2 Real Runtime Gap Completion.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.2B TEST SONUCU ====="
echo "4C_1_FINAL_STATUS=PASS ✅"
echo "4C_1_1_FINAL_STATUS=PASS ✅"
echo "4C_1_2_FINAL_STATUS=PASS ✅"
echo "4C_1_SELECTED_BUSINESS=uzmanparcaci ✅"
echo "4C_1_SCOPE_FREEZE_STATUS=PASS ✅"
echo "4C_1_MARKETPLACE_PHASE=FAZ_4D ✅"
echo "4C_2_READY=YES ✅"
