#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP13_REPORT="reports/faz4d/FAZ_4D_13_SUPPORT_FEEDBACK_LOOP_REPORT.txt"
STEP14_FILE="docs/faz4d/FAZ_4D_14_MOBILE_READY_PWA_BUSINESS_SURFACE.md"
UI_FILE="web/mobile-ready-pwa/index.html"
MANIFEST_FILE="web/mobile-ready-pwa/manifest.webmanifest"
SW_FILE="web/mobile-ready-pwa/sw.js"
REPORT_FILE="reports/faz4d/FAZ_4D_14_MOBILE_READY_PWA_BUSINESS_SURFACE_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
DOC_EVIDENCE_COUNT=0
UI_EVIDENCE_COUNT=0
PWA_EVIDENCE_COUNT=0

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

  if grep -Fq "$pattern" "$STEP14_FILE"; then
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

check_pwa_evidence_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    PWA_EVIDENCE_COUNT=$((PWA_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 4D-14 MOBILE-READY PWA TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP13_REPORT"
check_file "$STEP14_FILE"
check_file "$UI_FILE"
check_file "$MANIFEST_FILE"
check_file "$SW_FILE"

check_grep_file "$MASTER_FILE" "4D-13 | Support / Feedback Loop | DONE ✅" "4D-13 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-14 | Mobile-ready PWA / işletme mobil yüzeyi | IN_PROGRESS" "4D-14 master planda IN_PROGRESS"
check_grep_file "$STEP13_REPORT" "FAZ_4D_13_TEST_STATUS=PASS" "4D-13 support feedback raporu PASS"

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Native mobil bu fazda yapılmaz" "native mobil kapsam disi karari var"
check_doc_evidence "PWA pilot için yeterlidir" "PWA pilot karari var"
check_doc_evidence "Responsive tasarım zorunludur" "responsive tasarim karari var"
check_doc_evidence "Manifest dosyası zorunludur" "manifest karari var"
check_doc_evidence "Service worker dosyası zorunludur" "service worker karari var"
check_doc_evidence "Offline-first POS final değildir" "offline POS final degil karari var"
check_doc_evidence "Hızlı satış kısayolu görünür olur" "hizli satis kisayolu karari var"
check_doc_evidence "Stok kısayolu görünür olur" "stok kisayolu karari var"
check_doc_evidence "Oto yedek parça kısayolu görünür olur" "oto yedek parca kisayolu karari var"
check_doc_evidence "Monitoring ve feedback kısayolları görünür olur" "monitoring feedback kisayolu karari var"
check_doc_evidence "Marketplace/Paraşüt production kapalı kalır" "marketplace parasut kapali karari var"
check_doc_evidence "4D-15 release gate zorunludur" "4D-15 release gate karari var"
check_doc_evidence "FAZ_4D_15_READY=NO" "4D-15 baslangicta NO"

echo
echo "===== UI MOBILE KANIT TARAMASI ====="

check_ui_evidence "Pix2pi Pilot Mobile PWA" "UI title var"
check_ui_evidence "İşletme Mobil Yüzeyi" "UI mobil yuzey basligi var"
check_ui_evidence "manifest.webmanifest" "UI manifest link var"
check_ui_evidence "serviceWorker" "UI service worker registration var"
check_ui_evidence "viewport" "UI viewport var"
check_ui_evidence "theme-color" "UI theme-color var"
check_ui_evidence "Hızlı Satış" "UI hizli satis var"
check_ui_evidence "Stok" "UI stok var"
check_ui_evidence "Cari / Müşteri" "UI cari musteri var"
check_ui_evidence "Ürün" "UI urun var"
check_ui_evidence "Oto Yedek Parça" "UI oto yedek parca var"
check_ui_evidence "Feedback" "UI feedback var"
check_ui_evidence "Monitoring" "UI monitoring var"
check_ui_evidence "Offline-ready" "UI offline-ready var"
check_ui_evidence "release / rollback gate" "UI release rollback gate var"
check_ui_evidence "@media" "UI media query var"

echo
echo "===== PWA DOSYA KANIT TARAMASI ====="

check_pwa_evidence_file "$MANIFEST_FILE" "\"name\"" "manifest name var"
check_pwa_evidence_file "$MANIFEST_FILE" "\"short_name\"" "manifest short_name var"
check_pwa_evidence_file "$MANIFEST_FILE" "\"start_url\"" "manifest start_url var"
check_pwa_evidence_file "$MANIFEST_FILE" "\"display\": \"standalone\"" "manifest standalone var"
check_pwa_evidence_file "$MANIFEST_FILE" "\"theme_color\"" "manifest theme_color var"
check_pwa_evidence_file "$MANIFEST_FILE" "\"background_color\"" "manifest background_color var"
check_pwa_evidence_file "$SW_FILE" "self.addEventListener(\"install\"" "service worker install event var"
check_pwa_evidence_file "$SW_FILE" "self.addEventListener(\"activate\"" "service worker activate event var"
check_pwa_evidence_file "$SW_FILE" "self.addEventListener(\"fetch\"" "service worker fetch event var"
check_pwa_evidence_file "$SW_FILE" "caches.open" "service worker cache open var"
check_pwa_evidence_file "$SW_FILE" "cache.addAll" "service worker cache addAll var"
check_pwa_evidence_file "$SW_FILE" "caches.match" "service worker cache match var"

if [ "$DOC_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "mobile PWA dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/13"
else
  pass "mobile PWA dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/13"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 15 ]; then
  fail_soft "mobile PWA UI kaniti yetersiz: $UI_EVIDENCE_COUNT/16"
else
  pass "mobile PWA UI kaniti yeterli: $UI_EVIDENCE_COUNT/16"
fi

if [ "$PWA_EVIDENCE_COUNT" -lt 12 ]; then
  fail_soft "PWA manifest/service worker kaniti yetersiz: $PWA_EVIDENCE_COUNT/12"
else
  pass "PWA manifest/service worker kaniti yeterli: $PWA_EVIDENCE_COUNT/12"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP15_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP15_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_14_TEST_STATUS=$FINAL_STATUS
FAZ_4D_14_MOBILE_READY_PWA_BUSINESS_SURFACE_STATUS=$FINAL_STATUS
FAZ_4D_14_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_14_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_14_PWA_EVIDENCE_COUNT=$PWA_EVIDENCE_COUNT
FAZ_4D_14_OK_COUNT=$OK_COUNT
FAZ_4D_14_WARN_COUNT=$WARN_COUNT
FAZ_4D_14_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_15_READY=$STEP15_READY
UI_FILE=$UI_FILE
MANIFEST_FILE=$MANIFEST_FILE
SW_FILE=$SW_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-14 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-14 TEST SONUCU ====="
  echo "FAZ_4D_14_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_14_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_14_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_15_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-14 TEST SONUCU ====="
  echo "FAZ_4D_14_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_14_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_14_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_15_READY=NO ❌"
  exit 1
fi
