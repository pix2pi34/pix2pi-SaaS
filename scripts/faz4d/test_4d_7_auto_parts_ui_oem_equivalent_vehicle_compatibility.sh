#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP6_REPORT="reports/faz4d/FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE_REPORT.txt"
STEP7_FILE="docs/faz4d/FAZ_4D_7_AUTO_PARTS_UI_OEM_EQUIVALENT_VEHICLE_COMPATIBILITY.md"
UI_FILE="web/auto-parts-ui/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_7_AUTO_PARTS_UI_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
UI_EVIDENCE_COUNT=0
DOC_EVIDENCE_COUNT=0

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

  if grep -Fq "$pattern" "$STEP7_FILE"; then
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

echo "===== FAZ 4D-7 AUTO PARTS UI TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP6_REPORT"
check_file "$STEP7_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-6 | Pilot business UI surface | DONE ✅" "4D-6 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-7 | Oto yedek parça UI: OEM / eşdeğer / araç uyum | IN_PROGRESS" "4D-7 master planda IN_PROGRESS"
check_grep_file "$STEP6_REPORT" "FAZ_4D_6_TEST_STATUS=PASS" "4D-6 test raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Core product sade kalır" "core product sade kalir karari var"
check_doc_evidence "OEM alanı extension kalır" "OEM extension karari var"
check_doc_evidence "Eşdeğer parça ilişkisi ayrı tutulur" "esdeger parca karari var"
check_doc_evidence "Araç uyum modeli ayrı tutulur" "arac uyum modeli karari var"
check_doc_evidence "Parça merkezli arama desteklenir" "parca merkezli arama karari var"
check_doc_evidence "Araç merkezli arama desteklenir" "arac merkezli arama karari var"
check_doc_evidence "Tenant-aware parça görünümü zorunludur" "tenant-aware parca gorunumu karari var"
check_doc_evidence "Barkod bu adımda opsiyonel kalır" "barkod opsiyonel karari var"
check_doc_evidence "FAZ_4D_8_READY=NO" "4D-8 baslangicta NO"

echo
echo "===== UI DOSYA KANIT TARAMASI ====="

check_ui_evidence "Oto Yedek Parça UI" "UI basligi var"
check_ui_evidence "OEM Numarası" "UI OEM numarasi var"
check_ui_evidence "Eşdeğer Parça" "UI esdeger parca var"
check_ui_evidence "Muadil Parça" "UI muadil parca var"
check_ui_evidence "Araç Uyum" "UI arac uyum var"
check_ui_evidence "Marka" "UI marka var"
check_ui_evidence "Model" "UI model var"
check_ui_evidence "Stok Durumu" "UI stok durumu var"
check_ui_evidence "Tenant-safe Görünüm" "UI tenant-safe gorunum var"
check_ui_evidence "Core Product" "UI core product ayrimi var"
check_ui_evidence "Auto Parts Extension" "UI auto parts extension ayrimi var"
check_ui_evidence "Vehicle Compatibility" "UI vehicle compatibility ayrimi var"
check_ui_evidence "Mobile-ready" "UI mobile-ready notu var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

if [ "$DOC_EVIDENCE_COUNT" -lt 9 ]; then
  fail_soft "oto yedek parca dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/9"
else
  pass "oto yedek parca dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/9"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "oto yedek parca UI kaniti yetersiz: $UI_EVIDENCE_COUNT/15"
else
  pass "oto yedek parca UI kaniti yeterli: $UI_EVIDENCE_COUNT/15"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP8_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP8_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_7_TEST_STATUS=$FINAL_STATUS
FAZ_4D_7_AUTO_PARTS_UI_OEM_EQUIVALENT_VEHICLE_COMPATIBILITY_STATUS=$FINAL_STATUS
FAZ_4D_7_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_7_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_7_OK_COUNT=$OK_COUNT
FAZ_4D_7_WARN_COUNT=$WARN_COUNT
FAZ_4D_7_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_8_READY=$STEP8_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-7 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-7 TEST SONUCU ====="
  echo "FAZ_4D_7_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_7_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_7_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_8_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-7 TEST SONUCU ====="
  echo "FAZ_4D_7_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_7_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_7_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_8_READY=NO ❌"
  exit 1
fi
