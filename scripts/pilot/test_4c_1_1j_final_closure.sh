#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_1_1j_final_closure.md"
PROFILE_DOC="docs/pilot/faz4c/4c_1_1h_real_business_profile_applied.md"
ENV_FILE="docs/pilot/faz4c/4c_1_1g_real_business_input_template.env"
H_REPORT="reports/pilot/faz4c/4c_1_1h_real_business_apply_guard_report.md"
I_REPORT="reports/pilot/faz4c/4c_1_1i_fill_real_business_values_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1j_final_closure_report.md"

echo "===== 4C-1.1J FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "Final closure dokumani yok: $FINAL_DOC"
pass "Final closure dokumani var"

[ -f "$PROFILE_DOC" ] || fail "Applied business profile yok: $PROFILE_DOC"
pass "Applied business profile var"

[ -f "$ENV_FILE" ] || fail "Env dosyasi yok: $ENV_FILE"
pass "Env dosyasi var"

[ -f "$H_REPORT" ] || fail "4C-1.1H apply guard report yok: $H_REPORT"
pass "4C-1.1H apply guard report var"

[ -f "$I_REPORT" ] || fail "4C-1.1I fill values report yok: $I_REPORT"
pass "4C-1.1I fill values report var"

PENDING_COUNT="$(grep -c '="PENDING"' "$ENV_FILE" || true)"

if [ "$PENDING_COUNT" -ne 0 ]; then
  fail "Env dosyasinda PENDING alan kalmis: $PENDING_COUNT"
fi
pass "Env dosyasinda PENDING alan yok"

grep -q "4C_1_1H_APPLY_STATUS=PASS" "$H_REPORT" || fail "4C-1.1H apply PASS degil"
pass "4C-1.1H apply PASS"

grep -q "4C_1_1H_FINAL_CLOSURE_READY=YES" "$H_REPORT" || fail "4C-1.1H final closure ready YES degil"
pass "4C-1.1H final closure ready YES"

grep -q "4C_1_1I_REAL_VALUES_FILLED=YES" "$I_REPORT" || fail "4C-1.1I real values filled YES degil"
pass "4C-1.1I real values filled YES"

grep -q "PILOT_ISLETME_ADI=uzmanparcaci" "$FINAL_DOC" || fail "Final dokumanda uzmanparcaci yok"
pass "Final dokumanda pilot isletme var"

grep -q "4C_1_1_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "Final status PASS yok"
pass "Final status PASS var"

grep -q "4C_1_1_PILOT_BUSINESS_SELECTED=YES" "$FINAL_DOC" || fail "Pilot business selected YES yok"
pass "Pilot business selected YES var"

grep -q "4C_1_2_READY=YES" "$FINAL_DOC" || fail "4C-1.2 ready YES yok"
pass "4C-1.2 ready YES var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1J Final Closure Report

Step: 4C-1.1J
Blok: Final Closure / Pilot Business Selected
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1J_FINAL_DOC_STATUS=PASS
4C_1_1J_PROFILE_DOC_FOUND=YES
4C_1_1J_ENV_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_1_1J_APPLY_GUARD_STATUS=PASS
4C_1_1J_REAL_VALUES_FILLED=YES
4C_1_1_FINAL_STATUS=PASS
4C_1_1_PILOT_BUSINESS_SELECTED=YES
4C_1_1_SELECTED_BUSINESS=uzmanparcaci
4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_1_1_MARKETPLACE_PHASE=FAZ_4D
4C_1_2_READY=YES

## Sonuc

4C-1.1 Pilot isletme secimi ana blogu kapandi.
Secilen pilot isletme: uzmanparcaci.
Sonraki adim: 4C-1.2 Pilot Execution Master Plan / Scope Freeze.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1J TEST SONUCU ====="
echo "4C_1_1_FINAL_STATUS=PASS ✅"
echo "4C_1_1_PILOT_BUSINESS_SELECTED=YES ✅"
echo "4C_1_1_SELECTED_BUSINESS=uzmanparcaci ✅"
echo "4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA ✅"
echo "4C_1_1_MARKETPLACE_PHASE=FAZ_4D ✅"
echo "4C_1_2_READY=YES ✅"
