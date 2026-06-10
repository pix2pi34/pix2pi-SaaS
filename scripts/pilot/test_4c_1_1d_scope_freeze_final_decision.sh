#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DECISION_DOC="docs/pilot/faz4c/4c_1_1d_scope_freeze_final_decision.md"
MAIN_DOC="docs/pilot/faz4c/4c_1_1_pilot_isletme_secimi.md"
INFO_DOC="docs/pilot/faz4c/4c_1_1c_real_pilot_business_info.md"
FAZ4D_DOC="docs/pilot/faz4d/4d_marketplace_integrations_phase_registry.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1d_scope_freeze_final_decision_report.md"

echo "===== 4C-1.1D SCOPE FREEZE FINAL DECISION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DECISION_DOC" ] || fail "Decision dokumani yok: $DECISION_DOC"
pass "Decision dokumani var"

[ -f "$MAIN_DOC" ] || fail "Ana pilot dokumani yok: $MAIN_DOC"
pass "Ana pilot dokumani var"

[ -f "$INFO_DOC" ] || fail "Pilot bilgi formu yok: $INFO_DOC"
pass "Pilot bilgi formu var"

[ -f "$FAZ4D_DOC" ] || fail "FAZ 4D dokumani yok: $FAZ4D_DOC"
pass "FAZ 4D dokumani var"

grep -q "OTO YEDEK PARCA" "$DECISION_DOC" || fail "Oto yedek parca karari yok"
pass "Oto yedek parca karari var"

grep -q "4C_PILOT_PROFILE_FREEZE=PASS" "$DECISION_DOC" || fail "Pilot profile freeze PASS yok"
pass "Pilot profile freeze PASS var"

grep -q "FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS" "$DECISION_DOC" || fail "FAZ 4D marketplace phase status yok"
pass "FAZ 4D marketplace phase status var"

grep -q "FAZ_4D_CAN_START_NOW=NO" "$DECISION_DOC" || fail "FAZ 4D simdi baslamaz karari yok"
pass "FAZ 4D simdi baslamaz karari var"

grep -q "Canli pazaryeri entegrasyonu" "$DECISION_DOC" || fail "Canli pazaryeri kapsam disi yok"
pass "Canli pazaryeri kapsam disi var"

grep -q "4C_1_1D_REAL_BUSINESS_INFO_STATUS=PENDING" "$DECISION_DOC" || fail "Real business info PENDING status yok"
pass "Real business info PENDING status var"

grep -q "4C_1_1D_FULL_SCOPE_FREEZE_STATUS=CONDITIONAL" "$DECISION_DOC" || fail "Conditional full scope freeze status yok"
pass "Conditional full scope freeze status var"

grep -q "4C-1.1E" "$DECISION_DOC" || fail "Sonraki adim 4C-1.1E yok"
pass "Sonraki adim 4C-1.1E var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1D Scope Freeze Final Decision Report

Step: 4C-1.1D
Blok: Pilot Scope Freeze Final Decision
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1D_SCOPE_DECISION_DOC_STATUS=PASS
4C_1_1D_PILOT_SECTOR_FREEZE_STATUS=PASS
4C_1_1D_MARKETPLACE_PHASE_FREEZE_STATUS=PASS
4C_1_1D_REAL_BUSINESS_INFO_STATUS=PENDING
4C_1_1D_FULL_SCOPE_FREEZE_STATUS=CONDITIONAL
4C_1_1D_NEXT_STEP_READY=YES

## Sonuc

Pilot sektor ve kapsam kararlari sabitlendi.
Pazaryeri entegrasyonu FAZ 4D olarak ayrildi.
Gercek isletme bilgileri doldurulmadan 4C-1.1 ana blok tam PASS sayilmayacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1D TEST SONUCU ====="
echo "4C_1_1D_SCOPE_DECISION_DOC_STATUS=PASS ✅"
echo "4C_1_1D_PILOT_SECTOR_FREEZE_STATUS=PASS ✅"
echo "4C_1_1D_MARKETPLACE_PHASE_FREEZE_STATUS=PASS ✅"
echo "4C_1_1D_REAL_BUSINESS_INFO_STATUS=PENDING"
echo "4C_1_1D_FULL_SCOPE_FREEZE_STATUS=CONDITIONAL"
echo "4C_1_1D_NEXT_STEP_READY=YES ✅"
