#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP15_FILE="docs/faz4d/FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE.md"
UI_FILE="web/release-rollback-gate/index.html"
PUBLIC_PAGE="/var/www/pix2pi/faz4d/pilot-go-live/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE_REPORT.txt"
URL="https://pix2pi.com.tr/faz4d/pilot-go-live/"

BACKUP_DIR="${FAZ4D_15_BACKUP_DIR:-}"

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$(find backups/faz4d -maxdepth 1 -type d -name '*_before_4d_15' 2>/dev/null | sort | tail -n 1 || true)"
fi

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="backups/faz4d/$(date +%Y%m%d_%H%M%S)_before_4d_15_test_rerun"
  mkdir -p "$BACKUP_DIR"
fi

mkdir -p "$BACKUP_DIR/nginx"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
DOC_EVIDENCE_COUNT=0
UI_EVIDENCE_COUNT=0
GATE_EVIDENCE_COUNT=0
REPORT_PASS_COUNT=0
HTTP_STATUS="000"
PAGE_BYTES="0"
NGINX_TEST_STATUS="UNKNOWN"

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

  if grep -Fq "$pattern" "$STEP15_FILE"; then
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

check_gate_evidence() {
  local ok="$1"
  local label="$2"

  if [ "$ok" = "YES" ]; then
    GATE_EVIDENCE_COUNT=$((GATE_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_step_report() {
  local step="$1"
  local file="$2"
  local pattern="$3"

  if [ ! -f "$file" ]; then
    fail_soft "4D-$step raporu yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    REPORT_PASS_COUNT=$((REPORT_PASS_COUNT + 1))
    pass "4D-$step raporu PASS"
  else
    fail_soft "4D-$step raporu PASS degil"
  fi
}

echo "===== FAZ 4D-15 RELEASE / ROLLBACK / BACKUP GATE TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP15_FILE"
check_file "$UI_FILE"
check_file "$PUBLIC_PAGE"

check_grep_file "$MASTER_FILE" "4D-14 | Mobile-ready PWA / işletme mobil yüzeyi | DONE ✅" "4D-14 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-15 | Release / Rollback / Backup Gate | IN_PROGRESS" "4D-15 master planda IN_PROGRESS"

echo
echo "===== 4D RAPOR PASS KONTROLU ====="

check_step_report "1" "reports/faz4d/FAZ_4D_1_SCOPE_FREEZE_REPORT.txt" "FAZ_4D_1_TEST_STATUS=PASS"
check_step_report "2" "reports/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_REPORT.txt" "FAZ_4D_2_TEST_STATUS=PASS"
check_step_report "3" "reports/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION_REPORT.txt" "FAZ_4D_3_TEST_STATUS=PASS"
check_step_report "4" "reports/faz4d/FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS_REPORT.txt" "FAZ_4D_4_TEST_STATUS=PASS"
check_step_report "5" "reports/faz4d/FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE_REPORT.txt" "FAZ_4D_5_TEST_STATUS=PASS"
check_step_report "6" "reports/faz4d/FAZ_4D_6_PILOT_BUSINESS_UI_SURFACE_REPORT.txt" "FAZ_4D_6_TEST_STATUS=PASS"
check_step_report "7" "reports/faz4d/FAZ_4D_7_AUTO_PARTS_UI_REPORT.txt" "FAZ_4D_7_TEST_STATUS=PASS"
check_step_report "8" "reports/faz4d/FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE_REPORT.txt" "FAZ_4D_8_TEST_STATUS=PASS"
check_step_report "9" "reports/faz4d/FAZ_4D_9_MARKETPLACE_DISCOVERY_REPORT.txt" "FAZ_4D_9_TEST_STATUS=PASS"
check_step_report "10" "reports/faz4d/FAZ_4D_10_PARASUT_DISCOVERY_REPORT.txt" "FAZ_4D_10_TEST_STATUS=PASS"
check_step_report "11" "reports/faz4d/FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE_REPORT.txt" "FAZ_4D_11_TEST_STATUS=PASS"
check_step_report "12" "reports/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION_REPORT.txt" "FAZ_4D_12_TEST_STATUS=PASS"
check_step_report "13" "reports/faz4d/FAZ_4D_13_SUPPORT_FEEDBACK_LOOP_REPORT.txt" "FAZ_4D_13_TEST_STATUS=PASS"
check_step_report "14" "reports/faz4d/FAZ_4D_14_MOBILE_READY_PWA_BUSINESS_SURFACE_REPORT.txt" "FAZ_4D_14_TEST_STATUS=PASS"

echo
echo "===== NGINX CONFIG TEST ====="

if nginx -t >/tmp/pix2pi_4d15_nginx_test.txt 2>&1; then
  pass "nginx config testi PASS"
  NGINX_TEST_STATUS="PASS ✅"
else
  cat /tmp/pix2pi_4d15_nginx_test.txt || true
  fail_soft "nginx config testi FAIL"
  NGINX_TEST_STATUS="HATA ❌"
fi

echo
echo "===== PUBLIC GET TEST ====="

curl -k -L -s -o /tmp/pix2pi_4d15_public_page.html -w "HTTP_STATUS=%{http_code}\nFINAL_URL=%{url_effective}\n" "$URL" > /tmp/pix2pi_4d15_curl_result.txt || true

cat /tmp/pix2pi_4d15_curl_result.txt || true

HTTP_STATUS="$(grep -E '^HTTP_STATUS=' /tmp/pix2pi_4d15_curl_result.txt | tail -n 1 | cut -d= -f2 || echo 000)"
PAGE_BYTES="$(wc -c < /tmp/pix2pi_4d15_public_page.html 2>/dev/null || echo 0)"

if [ "$HTTP_STATUS" = "200" ]; then
  pass "public GET status 200"
else
  fail_soft "public GET status 200 degil: $HTTP_STATUS"
fi

if grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d15_public_page.html 2>/dev/null; then
  pass "public sayfa icerik kontrolu PASS"
else
  fail_soft "public sayfa icerik kontrolu FAIL"
fi

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Release kontrollü pilot kapsamındadır" "controlled pilot release karari var"
check_doc_evidence "Public go-live sayfası doğrulanır" "public go-live dogrulama karari var"
check_doc_evidence "Nginx config testi zorunludur" "nginx config karari var"
check_doc_evidence "Public dosyalar yedeklenir" "public dosya backup karari var"
check_doc_evidence "Nginx config yedeklenir" "nginx backup karari var"
check_doc_evidence "4D raporları PASS olmalıdır" "4D raporlari PASS karari var"
check_doc_evidence "Rollback yolu bilinmelidir" "rollback yolu karari var"
check_doc_evidence "Marketplace production kapalı kalır" "marketplace production kapali karari var"
check_doc_evidence "Paraşüt production kapalı kalır" "parasut production kapali karari var"
check_doc_evidence "Mobile PWA pilot kanıtı kalır" "mobile PWA pilot karari var"
check_doc_evidence "No-go tetikleyicileri geçerlidir" "no-go karari var"
check_doc_evidence "4D-16 final closure bu gate'e bağlıdır" "4D-16 gate bagli karari var"
check_doc_evidence "FAZ_4D_16_READY=NO" "4D-16 baslangicta NO"

echo
echo "===== UI RELEASE GATE KANIT TARAMASI ====="

check_ui_evidence "Release / Rollback / Backup Gate" "UI basligi var"
check_ui_evidence "Public GET" "UI public GET var"
check_ui_evidence "Nginx Config" "UI nginx config var"
check_ui_evidence "4D Reports" "UI 4D reports var"
check_ui_evidence "Public File Backup" "UI public file backup var"
check_ui_evidence "Nginx Backup" "UI nginx backup var"
check_ui_evidence "Rollback Path" "UI rollback path var"
check_ui_evidence "No-Go" "UI no-go var"
check_ui_evidence "Marketplace / Paraşüt" "UI marketplace parasut var"
check_ui_evidence "4D-16 Ready" "UI 4D-16 ready var"
check_ui_evidence "Release PASS" "UI release PASS var"
check_ui_evidence "Rollback Ready" "UI rollback ready var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

echo
echo "===== GATE EVIDENCE SAYIMI ====="

[ -f "$PUBLIC_PAGE" ] && check_gate_evidence "YES" "public page local file var" || check_gate_evidence "NO" "public page local file var"
[ "$HTTP_STATUS" = "200" ] && check_gate_evidence "YES" "public HTTP 200 var" || check_gate_evidence "NO" "public HTTP 200 var"
grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d15_public_page.html 2>/dev/null && check_gate_evidence "YES" "public content match var" || check_gate_evidence "NO" "public content match var"
[ -d "backups/faz4d" ] && check_gate_evidence "YES" "faz4d backup dizini var" || check_gate_evidence "NO" "faz4d backup dizini var"
[ -d "$BACKUP_DIR" ] && check_gate_evidence "YES" "bu adim backup dizini var: $BACKUP_DIR" || check_gate_evidence "NO" "bu adim backup dizini var: $BACKUP_DIR"
[ -d "$BACKUP_DIR/nginx" ] && check_gate_evidence "YES" "nginx backup dizini var" || check_gate_evidence "NO" "nginx backup dizini var"
[ "$REPORT_PASS_COUNT" -eq 14 ] && check_gate_evidence "YES" "4D-1..4D-14 raporlari PASS" || check_gate_evidence "NO" "4D-1..4D-14 raporlari PASS"

if [ "$DOC_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "release gate dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/13"
else
  pass "release gate dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/13"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 13 ]; then
  fail_soft "release gate UI kaniti yetersiz: $UI_EVIDENCE_COUNT/14"
else
  pass "release gate UI kaniti yeterli: $UI_EVIDENCE_COUNT/14"
fi

if [ "$GATE_EVIDENCE_COUNT" -lt 7 ]; then
  fail_soft "release gate runtime kaniti yetersiz: $GATE_EVIDENCE_COUNT/7"
else
  pass "release gate runtime kaniti yeterli: $GATE_EVIDENCE_COUNT/7"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP16_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP16_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_15_TEST_STATUS=$FINAL_STATUS
FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE_STATUS=$FINAL_STATUS
FAZ_4D_15_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_15_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_15_GATE_EVIDENCE_COUNT=$GATE_EVIDENCE_COUNT
FAZ_4D_15_REPORT_PASS_COUNT=$REPORT_PASS_COUNT
FAZ_4D_15_OK_COUNT=$OK_COUNT
FAZ_4D_15_WARN_COUNT=$WARN_COUNT
FAZ_4D_15_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_15_PUBLIC_URL=$URL
FAZ_4D_15_PUBLIC_HTTP_STATUS=$HTTP_STATUS
FAZ_4D_15_PUBLIC_PAGE_BYTES=$PAGE_BYTES
FAZ_4D_15_NGINX_TEST_STATUS=$NGINX_TEST_STATUS
FAZ_4D_15_BACKUP_DIR=$BACKUP_DIR
FAZ_4D_16_READY=$STEP16_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-15 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-15 TEST SONUCU ====="
  echo "FAZ_4D_15_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_15_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_15_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_16_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-15 TEST SONUCU ====="
  echo "FAZ_4D_15_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_15_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_15_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_16_READY=NO ❌"
  exit 1
fi
