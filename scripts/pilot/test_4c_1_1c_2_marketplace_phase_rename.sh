#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MAIN_DOC="docs/pilot/faz4c/4c_1_1_pilot_isletme_secimi.md"
INFO_DOC="docs/pilot/faz4c/4c_1_1c_real_pilot_business_info.md"
PHASE_DOC="docs/pilot/faz4d/4d_marketplace_integrations_phase_registry.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1c_2_marketplace_phase_rename_report.md"

echo "===== 4C-1.1C-2 MARKETPLACE PHASE RENAME TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$MAIN_DOC" ] || fail "Ana pilot dokumani yok: $MAIN_DOC"
pass "Ana pilot dokumani var"

[ -f "$INFO_DOC" ] || fail "Pilot bilgi formu yok: $INFO_DOC"
pass "Pilot bilgi formu var"

[ -f "$PHASE_DOC" ] || fail "FAZ 4D phase registry yok: $PHASE_DOC"
pass "FAZ 4D phase registry var"

grep -q "FAZ 4D — Channel / Marketplace Integrations" "$MAIN_DOC" || fail "Ana dokumanda FAZ 4D adi yok"
pass "Ana dokumanda FAZ 4D adi var"

grep -q "FUTURE_MARKETPLACE_PHASE=FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS" "$MAIN_DOC" || fail "Ana dokumanda FAZ 4D future phase status yok"
pass "Ana dokumanda FAZ 4D future phase status var"

grep -q "FAZ 4D — Channel / Marketplace Integrations" "$PHASE_DOC" || fail "FAZ 4D registry basligi yok"
pass "FAZ 4D registry basligi var"

grep -q "FAZ_4D_MARKETPLACE_STATUS=PLANNED" "$PHASE_DOC" || fail "FAZ 4D planned status yok"
pass "FAZ 4D planned status var"

grep -q "FAZ_4D_CAN_START_NOW=NO" "$PHASE_DOC" || fail "FAZ 4D can start now NO yok"
pass "FAZ 4D simdi baslamayacak karari var"

if grep -q "FAZ_5A_CHANNEL_MARKETPLACE_INTEGRATIONS" "$MAIN_DOC"; then
  fail "Eski FAZ 5A status hala ana dokumanda var"
fi
pass "Eski FAZ 5A status ana dokumandan temizlendi"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1C-2 Marketplace Phase Rename Report

Step: 4C-1.1C-2
Blok: Pazaryeri faz adini FAZ 4D olarak sabitleme
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Karar

FUTURE_MARKETPLACE_PHASE=FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS
FAZ_4D_MARKETPLACE_STATUS=PLANNED
FAZ_4D_START_CONDITION=AFTER_4C_FINAL_CLOSURE
FAZ_4D_CAN_START_NOW=NO

## Sonuc

Pazaryeri entegrasyonu FAZ 5A yerine FAZ 4D olarak yeniden adlandirildi.
FAZ 5 ana faz olarak korunacak.
FAZ 4D, FAZ 4C final closure sonrasinda baslatilacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1C-2 TEST SONUCU ====="
echo "FUTURE_MARKETPLACE_PHASE=FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS ✅"
echo "FAZ_4D_MARKETPLACE_STATUS=PLANNED ✅"
echo "FAZ_4D_START_CONDITION=AFTER_4C_FINAL_CLOSURE ✅"
echo "FAZ_4D_CAN_START_NOW=NO ✅"
