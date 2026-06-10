#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP5_REPORT="reports/faz4d/FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE_REPORT.txt"
STEP6_FILE="docs/faz4d/FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE.md"
UI_FILE="web/pilot-business-ui/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
UI_EVIDENCE_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "UYARI ⚠️ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    pass "dosya var: $file"
  else
    fail_soft "dosya yok: $file"
  fi
}

check_grep_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_ui_evidence() {
  local pattern="$1"
  local label="$2"

  if grep -Fq "$pattern" "$UI_FILE"; then
    UI_EVIDENCE_COUNT=$((UI_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 4D-6 PILOT BUSINESS UI SURFACE TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP5_REPORT"
check_file "$STEP6_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-5 | Pilot access / password reset / invite | DONE ✅" "4D-5 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-6 | Pilot business UI surface | IN_PROGRESS" "4D-6 master planda IN_PROGRESS"
check_grep_file "$STEP5_REPORT" "FAZ_4D_5_TEST_STATUS=PASS" "4D-5 test raporu PASS"

check_grep_file "$STEP6_FILE" "Pilot dashboard tek yüzeyle başlar" "pilot dashboard karari var"
check_grep_file "$STEP6_FILE" "Tenant/access durumu görünür olur" "tenant access UI karari var"
check_grep_file "$STEP6_FILE" "Cari / müşteri kartı görünür olur" "cari musteri UI karari var"
check_grep_file "$STEP6_FILE" "Ürün / stok kartı görünür olur" "urun stok UI karari var"
check_grep_file "$STEP6_FILE" "Satış / sipariş kartı görünür olur" "satis siparis UI karari var"
check_grep_file "$STEP6_FILE" "ERP apply kartı görünür olur" "ERP apply UI karari var"
check_grep_file "$STEP6_FILE" "Event / audit kartı görünür olur" "event audit UI karari var"
check_grep_file "$STEP6_FILE" "Raporlama / izleme kartı görünür olur" "raporlama izleme UI karari var"
check_grep_file "$STEP6_FILE" "Oto yedek parça kısayolu hazırlanır" "oto yedek parca UI kapisi var"
check_grep_file "$STEP6_FILE" "FAZ_4D_7_READY=NO" "4D-7 baslangicta NO"

echo
echo "===== UI DOSYA KANIT TARAMASI ====="

check_ui_evidence "Pilot Business UI Surface" "UI basligi var"
check_ui_evidence "Tenant / Access" "UI tenant access var"
check_ui_evidence "Cari / Müşteri" "UI cari musteri var"
check_ui_evidence "Ürün / Stok" "UI urun stok var"
check_ui_evidence "Satış / Sipariş" "UI satis siparis var"
check_ui_evidence "ERP Apply" "UI ERP apply var"
check_ui_evidence "Event / Audit" "UI event audit var"
check_ui_evidence "Raporlama / İzleme" "UI raporlama izleme var"
check_ui_evidence "Oto Yedek Parça" "UI oto yedek parca var"
check_ui_evidence "Mobile-ready PWA" "UI mobile-ready PWA notu var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$UI_EVIDENCE_COUNT" -lt 10 ]; then
  fail_soft "pilot UI kaniti yetersiz: $UI_EVIDENCE_COUNT/12"
else
  pass "pilot UI kaniti yeterli: $UI_EVIDENCE_COUNT/12"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP7_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP7_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_6_TEST_STATUS=$FINAL_STATUS
FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE_STATUS=$FINAL_STATUS
FAZ_4D_6_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_6_OK_COUNT=$OK_COUNT
FAZ_4D_6_WARN_COUNT=$WARN_COUNT
FAZ_4D_6_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_7_READY=$STEP7_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-6 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-6 TEST SONUCU ====="
  echo "FAZ_4D_6_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_6_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_6_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_7_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-6 TEST SONUCU ====="
  echo "FAZ_4D_6_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_6_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_6_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_7_READY=NO ❌"
  exit 1
fi
