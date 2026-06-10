#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1c_real_pilot_business_info.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1c_real_pilot_business_info_report.md"

echo "===== 4C-1.1C REAL PILOT BUSINESS INFO TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Dokuman bulunamadi: $DOC_FILE"
pass "Dokuman var"

grep -q "OTO YEDEK PARCA" "$DOC_FILE" || fail "Pilot sektor yok"
pass "Pilot sektor var"

grep -q "Pilot isletme adi" "$DOC_FILE" || fail "Pilot isletme adi alani yok"
pass "Pilot isletme adi alani var"

grep -q "Yetkili kisi" "$DOC_FILE" || fail "Yetkili kisi alani yok"
pass "Yetkili kisi alani var"

grep -q "Sube sayisi" "$DOC_FILE" || fail "Sube sayisi alani yok"
pass "Sube sayisi alani var"

grep -q "Tahmini stok kalemi" "$DOC_FILE" || fail "Stok kalemi alani yok"
pass "Stok kalemi alani var"

grep -q "OEM kodu kullaniyor mu" "$DOC_FILE" || fail "OEM alani yok"
pass "OEM alani var"

grep -q "Esdeger parca mantigi var mi" "$DOC_FILE" || fail "Esdeger parca alani yok"
pass "Esdeger parca alani var"

grep -q "Pazaryeri entegrasyonu FAZ 4C icinde canli yapilmayacak" "$DOC_FILE" || fail "Pazaryeri scope guard yok"
pass "Pazaryeri scope guard var"

grep -q "Canli pazaryeri entegrasyonu 4C disi kabul edildi mi" "$DOC_FILE" || fail "Pazaryeri kabul alani yok"
pass "Pazaryeri kabul alani var"

grep -q "4C_1_1C_NEXT_STEP_READY=NO" "$DOC_FILE" || fail "Next step NO status yok"
pass "Next step NO status var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1C Real Pilot Business Info Report

Step: 4C-1.1C
Blok: Gercek pilot isletme bilgileri formu
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1C_DOCUMENT_CREATED=YES
4C_1_1C_REQUIRED_FIELDS_PRESENT=YES
4C_1_1C_MARKETPLACE_SCOPE_GUARD_PRESENT=YES
4C_1_1C_BUSINESS_INFO_STATUS=PENDING
4C_1_1C_NEXT_STEP_READY=NO

## Sonuc

Gercek pilot isletme bilgi formu hazirlandi.
Isletme bilgileri doldurulduktan sonra 4C-1.1C PASS durumuna alinacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1C TEST SONUCU ====="
echo "4C_1_1C_DOCUMENT_CREATED=YES ✅"
echo "4C_1_1C_REQUIRED_FIELDS_PRESENT=YES ✅"
echo "4C_1_1C_MARKETPLACE_SCOPE_GUARD_PRESENT=YES ✅"
echo "4C_1_1C_BUSINESS_INFO_STATUS=PENDING"
echo "4C_1_1C_NEXT_STEP_READY=NO"
