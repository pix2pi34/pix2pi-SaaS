#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1_pilot_isletme_secimi.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1b_final_report.md"

echo "===== 4C-1.1B OTO YEDEK PARCA FREEZE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Dokuman bulunamadi: $DOC_FILE"
pass "Dokuman var"

grep -q "Pilot sektor: OTO YEDEK PARCA" "$DOC_FILE" || fail "Pilot sektor sabitlenmemis"
pass "Pilot sektor oto yedek parca olarak sabitlendi"

grep -q "4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA" "$DOC_FILE" || fail "Selected sector status yok"
pass "Selected sector status var"

grep -q "4C_1_1_PROFILE_FREEZE_STATUS=PASS" "$DOC_FILE" || fail "Profile freeze PASS yok"
pass "Profile freeze PASS var"

grep -q "urun_adi" "$DOC_FILE" || fail "Urun minimum veri alani yok"
pass "Urun minimum veri alanlari var"

grep -q "oem_kodu" "$DOC_FILE" || fail "OEM kod alani yok"
pass "OEM kod alani var"

grep -q "arac_uyum_notu" "$DOC_FILE" || fail "Arac uyum notu alani yok"
pass "Arac uyum notu alani var"

grep -q "esdeger_kod" "$DOC_FILE" || fail "Esdeger kod alani yok"
pass "Esdeger kod alani var"

grep -q "kapsam disi" "$DOC_FILE" || fail "Kapsam disi bolumu yok"
pass "Kapsam disi bolumu var"

grep -q "4C_1_1_NEXT_STEP_READY=YES" "$DOC_FILE" || fail "Next step ready YES yok"
pass "Next step ready YES var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1B Final Report

Step: 4C-1.1B
Blok: Pilot sektor/profil freeze
Secilen sektor: Oto yedek parca
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_1_1_PROFILE_FREEZE_STATUS=PASS
4C_1_1_BUSINESS_NAME_STATUS=PENDING
4C_1_1_SCOPE_FREEZE_STATUS=PARTIAL
4C_1_1_NEXT_STEP_READY=YES

## Karar

Ilk gercek pilot profili oto yedek parca olarak sabitlendi.
Bir sonraki adimda gercek isletme bilgileri doldurulacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1B TEST SONUCU ====="
echo "4C_1_1_SELECTED_SECTOR=OTO_YEDEK_PARCA ✅"
echo "4C_1_1_PROFILE_FREEZE_STATUS=PASS ✅"
echo "4C_1_1_BUSINESS_NAME_STATUS=PENDING"
echo "4C_1_1_SCOPE_FREEZE_STATUS=PARTIAL"
echo "4C_1_1_NEXT_STEP_READY=YES ✅"
