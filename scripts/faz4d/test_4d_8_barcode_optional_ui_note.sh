#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP7_REPORT="reports/faz4d/FAZ_4D_7_AUTO_PARTS_UI_REPORT.txt"
STEP8_FILE="docs/faz4d/FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE.md"
UI_FILE="web/auto-parts-ui/barcode-optional-note.html"
REPORT_FILE="reports/faz4d/FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
DOC_EVIDENCE_COUNT=0
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

check_doc_evidence() {
  local pattern="$1"
  local label="$2"

  if grep -Fq "$pattern" "$STEP8_FILE"; then
    DOC_EVIDENCE_COUNT=$((DOC_EVIDENCE_COUNT + 1))
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

echo "===== FAZ 4D-8 BARCODE OPTIONAL UI NOTE TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP7_REPORT"
check_file "$STEP8_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-7 | Oto yedek parça UI: OEM / eşdeğer / araç uyum | DONE ✅" "4D-7 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-8 | Barkod opsiyonel UI notu | IN_PROGRESS" "4D-8 master planda IN_PROGRESS"
check_grep_file "$STEP7_REPORT" "FAZ_4D_7_TEST_STATUS=PASS" "4D-7 test raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Barkod opsiyonel kalır" "barkod opsiyonel karari var"
check_doc_evidence "SKU manuel arama desteklenir" "SKU manuel arama karari var"
check_doc_evidence "OEM manuel arama desteklenir" "OEM manuel arama karari var"
check_doc_evidence "EAN/GTIN alanı staging kabul edilir" "EAN GTIN staging karari var"
check_doc_evidence "Kamera ile barkod okutma production yapılmaz" "kamera scanner kapsam disi karari var"
check_doc_evidence "Barkod yoksa ürün satışı bloke edilmez" "barkodsuz satis bloke degil karari var"
check_doc_evidence "Barkod tenant-safe olmalıdır" "tenant-safe barkod karari var"
check_doc_evidence "FAZ_4D_9_READY=NO" "4D-9 baslangicta NO"

echo
echo "===== UI NOT KANIT TARAMASI ====="

check_ui_evidence "Barkod Opsiyonel UI Notu" "UI basligi var"
check_ui_evidence "Barkod Durumu" "UI barkod durumu var"
check_ui_evidence "OPSİYONEL" "UI opsiyonel etiketi var"
check_ui_evidence "Barkodsuz Satış" "UI barkodsuz satis var"
check_ui_evidence "OEM Arama" "UI OEM arama var"
check_ui_evidence "Scanner" "UI scanner notu var"
check_ui_evidence "SKU ile Arama" "UI SKU ile arama var"
check_ui_evidence "EAN / GTIN" "UI EAN GTIN var"
check_ui_evidence "tenant-safe" "UI tenant-safe notu var"
check_ui_evidence "Mobile-ready PWA" "UI mobile-ready PWA notu var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 8 ]; then
  fail_soft "barkod dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/8"
else
  pass "barkod dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/8"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 11 ]; then
  fail_soft "barkod UI kaniti yetersiz: $UI_EVIDENCE_COUNT/12"
else
  pass "barkod UI kaniti yeterli: $UI_EVIDENCE_COUNT/12"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP9_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP9_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_8_TEST_STATUS=$FINAL_STATUS
FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE_STATUS=$FINAL_STATUS
FAZ_4D_8_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_8_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_8_OK_COUNT=$OK_COUNT
FAZ_4D_8_WARN_COUNT=$WARN_COUNT
FAZ_4D_8_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_9_READY=$STEP9_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-8 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-8 TEST SONUCU ====="
  echo "FAZ_4D_8_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_8_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_8_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_9_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-8 TEST SONUCU ====="
  echo "FAZ_4D_8_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_8_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_8_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_9_READY=NO ❌"
  exit 1
fi
