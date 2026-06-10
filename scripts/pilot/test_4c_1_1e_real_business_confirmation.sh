#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_1_1e_real_business_confirmation.md"
REPORT_FILE="reports/pilot/faz4c/4c_1_1e_real_business_confirmation_report.md"

echo "===== 4C-1.1E REAL BUSINESS CONFIRMATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Confirmation dokumani yok: $DOC_FILE"
pass "Confirmation dokumani var"

grep -q "OTO YEDEK PARCA" "$DOC_FILE" || fail "Pilot sektor yok"
pass "Pilot sektor var"

grep -q "FAZ 4D'ye ayrildi" "$DOC_FILE" || fail "Pazaryeri FAZ 4D karari yok"
pass "Pazaryeri FAZ 4D karari var"

grep -q "Pilot isletme adi" "$DOC_FILE" || fail "Pilot isletme adi alani yok"
pass "Pilot isletme adi alani var"

grep -q "Yetkili kisi" "$DOC_FILE" || fail "Yetkili kisi alani yok"
pass "Yetkili kisi alani var"

grep -q "Yetkili telefon" "$DOC_FILE" || fail "Yetkili telefon alani yok"
pass "Yetkili telefon alani var"

grep -q "Tahmini stok kalemi" "$DOC_FILE" || fail "Tahmini stok kalemi alani yok"
pass "Tahmini stok kalemi alani var"

grep -q "OEM kodu kullaniyor mu" "$DOC_FILE" || fail "OEM kontrol alani yok"
pass "OEM kontrol alani var"

grep -q "Canli pazaryeri entegrasyonu FAZ 4C disi kabul edildi mi" "$DOC_FILE" || fail "Pazaryeri scope kabul alani yok"
pass "Pazaryeri scope kabul alani var"

grep -q "4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING" "$DOC_FILE" || fail "Real business values PENDING status yok"
pass "Real business values PENDING status var"

grep -q "4C_1_1E_NEXT_STEP_READY=NO" "$DOC_FILE" || fail "Next step NO status yok"
pass "Next step NO status var"

PENDING_COUNT="$(grep -o "\[ PENDING \]" "$DOC_FILE" | wc -l | tr -d ' ')"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-1.1E Real Business Confirmation Report

Step: 4C-1.1E
Blok: Gercek pilot isletme bilgileri confirmation paketi
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_1_1E_CONFIRMATION_DOC_STATUS=PASS
4C_1_1E_REQUIRED_FIELDS_PRESENT=YES
4C_1_1E_MARKETPLACE_PHASE_DECISION_PRESENT=YES
4C_1_1E_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING
4C_1_1E_SCOPE_ACCEPTANCE_STATUS=PENDING
4C_1_1E_NEXT_STEP_READY=NO

## Sonuc

Gercek isletme confirmation paketi hazirlandi.
Isletme bilgileri henuz doldurulmadigi icin ana blok PASS degil.
Gercek bilgiler girildikten sonra 4C-1.1F ile final closure yapilacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-1.1E TEST SONUCU ====="
echo "4C_1_1E_CONFIRMATION_DOC_STATUS=PASS ✅"
echo "4C_1_1E_REQUIRED_FIELDS_PRESENT=YES ✅"
echo "4C_1_1E_MARKETPLACE_PHASE_DECISION_PRESENT=YES ✅"
echo "4C_1_1E_PENDING_FIELD_COUNT=$PENDING_COUNT"
echo "4C_1_1E_REAL_BUSINESS_VALUES_STATUS=PENDING"
echo "4C_1_1E_SCOPE_ACCEPTANCE_STATUS=PENDING"
echo "4C_1_1E_NEXT_STEP_READY=NO"
