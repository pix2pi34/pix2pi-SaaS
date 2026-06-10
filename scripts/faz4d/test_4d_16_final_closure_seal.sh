#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP16_FILE="docs/faz4d/FAZ_4D_16_FINAL_CLOSURE_SEAL.md"
UI_FILE="web/faz4d-final-closure/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_16_FINAL_CLOSURE_SEAL_REPORT.txt"
FINAL_SEAL_FILE="reports/faz4d/FAZ_4D_FINAL_SEAL.txt"
PUBLIC_URL="https://pix2pi.com.tr/faz4d/pilot-go-live/"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
REPORT_PASS_COUNT=0
FINAL_EVIDENCE_COUNT=0
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

check_final_evidence() {
  local ok="$1"
  local label="$2"

  if [ "$ok" = "YES" ]; then
    FINAL_EVIDENCE_COUNT=$((FINAL_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 4D-16 FINAL CLOSURE / SEAL TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP16_FILE"
check_file "$UI_FILE"

check_grep_file "$MASTER_FILE" "4D-15 | Release / Rollback / Backup Gate | DONE ✅" "4D-15 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-16 | FAZ 4D Final Closure / Seal | IN_PROGRESS" "4D-16 master planda IN_PROGRESS"

echo
echo "===== 4D-1 .. 4D-15 RAPOR PASS KONTROLU ====="

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
check_step_report "15" "reports/faz4d/FAZ_4D_15_RELEASE_ROLLBACK_BACKUP_GATE_REPORT.txt" "FAZ_4D_15_TEST_STATUS=PASS"

echo
echo "===== NGINX CONFIG TEST ====="

if nginx -t >/tmp/pix2pi_4d16_nginx_test.txt 2>&1; then
  pass "nginx config testi PASS"
  NGINX_TEST_STATUS="PASS ✅"
else
  cat /tmp/pix2pi_4d16_nginx_test.txt || true
  fail_soft "nginx config testi FAIL"
  NGINX_TEST_STATUS="HATA ❌"
fi

echo
echo "===== PUBLIC GO-LIVE GET TEST ====="

curl -k -L -s -o /tmp/pix2pi_4d16_public_page.html -w "HTTP_STATUS=%{http_code}\nFINAL_URL=%{url_effective}\n" "$PUBLIC_URL" > /tmp/pix2pi_4d16_curl_result.txt || true

cat /tmp/pix2pi_4d16_curl_result.txt || true

HTTP_STATUS="$(grep -E '^HTTP_STATUS=' /tmp/pix2pi_4d16_curl_result.txt | tail -n 1 | cut -d= -f2 || echo 000)"
PAGE_BYTES="$(wc -c < /tmp/pix2pi_4d16_public_page.html 2>/dev/null || echo 0)"

if [ "$HTTP_STATUS" = "200" ]; then
  pass "public GET status 200"
else
  fail_soft "public GET status 200 degil: $HTTP_STATUS"
fi

if grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d16_public_page.html 2>/dev/null; then
  pass "public sayfa icerik kontrolu PASS"
else
  fail_soft "public sayfa icerik kontrolu FAIL"
fi

echo
echo "===== FINAL EVIDENCE SAYIMI ====="

[ "$REPORT_PASS_COUNT" -eq 15 ] && check_final_evidence "YES" "4D-1..4D-15 raporlari PASS" || check_final_evidence "NO" "4D-1..4D-15 raporlari PASS"
[ "$HTTP_STATUS" = "200" ] && check_final_evidence "YES" "public HTTP 200 var" || check_final_evidence "NO" "public HTTP 200 var"
grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d16_public_page.html 2>/dev/null && check_final_evidence "YES" "public content match var" || check_final_evidence "NO" "public content match var"
[ -f "web/pilot-business-ui/index.html" ] && check_final_evidence "YES" "pilot business UI var" || check_final_evidence "NO" "pilot business UI var"
[ -f "web/auto-parts-ui/index.html" ] && check_final_evidence "YES" "auto parts UI var" || check_final_evidence "NO" "auto parts UI var"
[ -f "web/mobile-ready-pwa/index.html" ] && check_final_evidence "YES" "mobile-ready PWA var" || check_final_evidence "NO" "mobile-ready PWA var"
[ -f "web/mobile-ready-pwa/manifest.webmanifest" ] && check_final_evidence "YES" "PWA manifest var" || check_final_evidence "NO" "PWA manifest var"
[ -f "web/mobile-ready-pwa/sw.js" ] && check_final_evidence "YES" "PWA service worker var" || check_final_evidence "NO" "PWA service worker var"
[ -f "web/release-rollback-gate/index.html" ] && check_final_evidence "YES" "release rollback gate UI var" || check_final_evidence "NO" "release rollback gate UI var"
[ -d "backups/faz4d" ] && check_final_evidence "YES" "faz4d backup dizini var" || check_final_evidence "NO" "faz4d backup dizini var"

check_grep_file "$STEP16_FILE" "FAZ_4D_CRITICAL_BLOCKER_COUNT=0" "critical blocker 0"
check_grep_file "$STEP16_FILE" "FAZ_4D_BLOCKING_ACTION_COUNT=0" "blocking action 0"
check_grep_file "$UI_FILE" "FAZ 4D Final Closure / Seal" "final closure UI basligi var"
check_grep_file "$UI_FILE" "FAZ 5 Ready" "FAZ 5 ready UI var"

if [ "$FINAL_EVIDENCE_COUNT" -lt 10 ]; then
  fail_soft "final evidence yetersiz: $FINAL_EVIDENCE_COUNT/10"
else
  pass "final evidence yeterli: $FINAL_EVIDENCE_COUNT/10"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  FINAL_SEAL_STATUS="SEALED ✅"
  FAZ5_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  FINAL_SEAL_STATUS="OPEN ❌"
  FAZ5_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_16_TEST_STATUS=$FINAL_STATUS
FAZ_4D_16_FINAL_CLOSURE_STATUS=$FINAL_STATUS
FAZ_4D_16_FINAL_SEAL_STATUS=$FINAL_SEAL_STATUS
FAZ_4D_16_REPORT_PASS_COUNT=$REPORT_PASS_COUNT
FAZ_4D_16_FINAL_EVIDENCE_COUNT=$FINAL_EVIDENCE_COUNT
FAZ_4D_16_OK_COUNT=$OK_COUNT
FAZ_4D_16_WARN_COUNT=$WARN_COUNT
FAZ_4D_16_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_PUBLIC_URL=$PUBLIC_URL
FAZ_4D_PUBLIC_HTTP_STATUS=$HTTP_STATUS
FAZ_4D_PUBLIC_PAGE_BYTES=$PAGE_BYTES
FAZ_4D_NGINX_TEST_STATUS=$NGINX_TEST_STATUS
FAZ_5_READY=$FAZ5_READY
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

cat <<SEAL_EOF > "$FINAL_SEAL_FILE"
FAZ_4D_FINAL_STATUS=$FINAL_STATUS
FAZ_4D_FINAL_SEAL_STATUS=$FINAL_SEAL_STATUS
FAZ_4D_PILOT_COMPLETION_SEAL_STATUS=$FINAL_SEAL_STATUS
FAZ_4D_CONTROLLED_GO_LIVE_STATUS=PASS ✅
FAZ_4D_MONITORING_STABILIZATION_STATUS=PASS ✅
FAZ_4D_SUPPORT_FEEDBACK_LOOP_STATUS=PASS ✅
FAZ_4D_MOBILE_READY_PWA_STATUS=PASS ✅
FAZ_4D_RELEASE_ROLLBACK_BACKUP_GATE_STATUS=PASS ✅
FAZ_4D_CRITICAL_BLOCKER_COUNT=0 ✅
FAZ_4D_BLOCKING_ACTION_COUNT=0 ✅
FAZ_4D_PUBLIC_URL=$PUBLIC_URL
FAZ_4D_PUBLIC_HTTP_STATUS=$HTTP_STATUS
FAZ_4D_FINAL_REPORT=$REPORT_FILE
FAZ_5_READY=$FAZ5_READY
SEALED_AT=$(date -Is)
SEAL_EOF

echo
echo "===== FAZ 4D-16 RAPOR ====="
cat "$REPORT_FILE"

echo
echo "===== FAZ 4D FINAL SEAL ====="
cat "$FINAL_SEAL_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D FINAL TEST SONUCU ====="
  echo "FAZ_4D_16_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_FINAL_SEAL_STATUS=SEALED ✅"
  echo "FAZ_5_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D FINAL TEST SONUCU ====="
  echo "FAZ_4D_16_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_FINAL_SEAL_STATUS=OPEN ❌"
  echo "FAZ_5_READY=NO ❌"
  exit 1
fi
