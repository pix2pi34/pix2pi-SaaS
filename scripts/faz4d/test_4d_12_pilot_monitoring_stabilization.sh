#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP2_REPORT="reports/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_REPORT.txt"
STEP3_REPORT="reports/faz4d/FAZ_4D_3_BUSINESS_CHAIN_FINAL_VALIDATION_REPORT.txt"
STEP11_REPORT="reports/faz4d/FAZ_4D_11_CONTROLLED_PILOT_GO_LIVE_REPORT.txt"
STEP12_FILE="docs/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION.md"
UI_FILE="web/pilot-monitoring/index.html"
PUBLIC_PAGE="/var/www/pix2pi/faz4d/pilot-go-live/index.html"
REPORT_FILE="reports/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION_REPORT.txt"
URL="https://pix2pi.com.tr/faz4d/pilot-go-live/"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
DOC_EVIDENCE_COUNT=0
UI_EVIDENCE_COUNT=0
MONITORING_EVIDENCE_COUNT=0
HTTP_STATUS="000"
PAGE_BYTES="0"

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

  if grep -Fq "$pattern" "$STEP12_FILE"; then
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

check_monitoring_evidence() {
  local ok="$1"
  local label="$2"

  if [ "$ok" = "YES" ]; then
    MONITORING_EVIDENCE_COUNT=$((MONITORING_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    fail_soft "$label"
  fi
}

echo "===== FAZ 4D-12 PILOT MONITORING / STABILIZATION TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP2_REPORT"
check_file "$STEP3_REPORT"
check_file "$STEP11_REPORT"
check_file "$STEP12_FILE"
check_file "$UI_FILE"
check_file "$PUBLIC_PAGE"

check_grep_file "$MASTER_FILE" "4D-11 | Controlled Pilot Go-Live | DONE ✅" "4D-11 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-12 | Pilot Monitoring / Stabilization | IN_PROGRESS" "4D-12 master planda IN_PROGRESS"
check_grep_file "$STEP2_REPORT" "FAZ_4D_2_TEST_STATUS=PASS" "4D-2 security raporu PASS"
check_grep_file "$STEP3_REPORT" "FAZ_4D_3_TEST_STATUS=PASS" "4D-3 business chain raporu PASS"
check_grep_file "$STEP11_REPORT" "FAZ_4D_11_TEST_STATUS=PASS" "4D-11 go-live raporu PASS"

echo
echo "===== NGINX CONFIG TEST ====="

if nginx -t >/tmp/pix2pi_4d12_nginx_test.txt 2>&1; then
  pass "nginx config testi PASS"
  NGINX_TEST_STATUS="PASS ✅"
else
  cat /tmp/pix2pi_4d12_nginx_test.txt || true
  fail_soft "nginx config testi FAIL"
  NGINX_TEST_STATUS="HATA ❌"
fi

echo
echo "===== PUBLIC GET TEST ====="

curl -k -L -s -o /tmp/pix2pi_4d12_public_page.html -w "HTTP_STATUS=%{http_code}\nFINAL_URL=%{url_effective}\n" "$URL" > /tmp/pix2pi_4d12_curl_result.txt || true

cat /tmp/pix2pi_4d12_curl_result.txt || true

HTTP_STATUS="$(grep -E '^HTTP_STATUS=' /tmp/pix2pi_4d12_curl_result.txt | tail -n 1 | cut -d= -f2 || echo 000)"
PAGE_BYTES="$(wc -c < /tmp/pix2pi_4d12_public_page.html 2>/dev/null || echo 0)"

if [ "$HTTP_STATUS" = "200" ]; then
  pass "public GET status 200"
else
  fail_soft "public GET status 200 degil: $HTTP_STATUS"
fi

if grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d12_public_page.html 2>/dev/null; then
  pass "public sayfa icerik kontrolu PASS"
else
  fail_soft "public sayfa icerik kontrolu FAIL"
fi

echo
echo "===== DOKUMAN KANIT TARAMASI ====="

check_doc_evidence "Pilot erişim GET ile doğrulanır" "GET dogrulama karari var"
check_doc_evidence "Nginx config testi zorunludur" "nginx config karari var"
check_doc_evidence "Go-live raporu zorunludur" "go-live raporu karari var"
check_doc_evidence "Security/tenant raporu görünür olmalıdır" "security tenant raporu karari var"
check_doc_evidence "Business chain raporu görünür olmalıdır" "business chain raporu karari var"
check_doc_evidence "Public route stabil izlenir" "public route izleme karari var"
check_doc_evidence "No-go tetikleyicileri monitoring alanıdır" "no-go monitoring karari var"
check_doc_evidence "Marketplace ve Paraşüt kapalı izlenir" "marketplace parasut kapali izleme karari var"
check_doc_evidence "Rollback gate sonraki kapıdır" "rollback gate karari var"
check_doc_evidence "Support feedback loop sonraki kapıdır" "support feedback karari var"
check_doc_evidence "FAZ_4D_13_READY=NO" "4D-13 baslangicta NO"

echo
echo "===== UI MONITORING KANIT TARAMASI ====="

check_ui_evidence "Pilot Monitoring / Stabilization" "UI basligi var"
check_ui_evidence "Public Page Health" "UI public page health var"
check_ui_evidence "Nginx Config Health" "UI nginx config health var"
check_ui_evidence "Go-Live Report" "UI go-live report var"
check_ui_evidence "Security / Tenant Report" "UI security tenant report var"
check_ui_evidence "Business Chain Report" "UI business chain report var"
check_ui_evidence "No-Go Triggers" "UI no-go triggers var"
check_ui_evidence "Marketplace / Paraşüt Closed" "UI marketplace parasut closed var"
check_ui_evidence "Support Feedback Ready" "UI support feedback ready var"
check_ui_evidence "Rollback Readiness" "UI rollback readiness var"
check_ui_evidence "Green Signals" "UI green signals var"
check_ui_evidence "Warning Signals" "UI warning signals var"
check_ui_evidence "No-Go Signals" "UI no-go signals var"
check_ui_evidence "viewport" "UI responsive viewport var"
check_ui_evidence "@media" "UI mobile media query var"

echo
echo "===== MONITORING EVIDENCE SAYIMI ====="

[ -f "$PUBLIC_PAGE" ] && check_monitoring_evidence "YES" "public page local file var" || check_monitoring_evidence "NO" "public page local file var"
[ "$HTTP_STATUS" = "200" ] && check_monitoring_evidence "YES" "public HTTP 200 var" || check_monitoring_evidence "NO" "public HTTP 200 var"
grep -Fq "Controlled Pilot Go-Live" /tmp/pix2pi_4d12_public_page.html 2>/dev/null && check_monitoring_evidence "YES" "public content match var" || check_monitoring_evidence "NO" "public content match var"
grep -Fq "FAZ_4D_11_TEST_STATUS=PASS" "$STEP11_REPORT" 2>/dev/null && check_monitoring_evidence "YES" "4D-11 PASS evidence var" || check_monitoring_evidence "NO" "4D-11 PASS evidence var"
grep -Fq "FAZ_4D_2_TEST_STATUS=PASS" "$STEP2_REPORT" 2>/dev/null && check_monitoring_evidence "YES" "4D-2 security PASS evidence var" || check_monitoring_evidence "NO" "4D-2 security PASS evidence var"
grep -Fq "FAZ_4D_3_TEST_STATUS=PASS" "$STEP3_REPORT" 2>/dev/null && check_monitoring_evidence "YES" "4D-3 business PASS evidence var" || check_monitoring_evidence "NO" "4D-3 business PASS evidence var"

if [ "$DOC_EVIDENCE_COUNT" -lt 11 ]; then
  fail_soft "monitoring dokuman kaniti yetersiz: $DOC_EVIDENCE_COUNT/11"
else
  pass "monitoring dokuman kaniti yeterli: $DOC_EVIDENCE_COUNT/11"
fi

if [ "$UI_EVIDENCE_COUNT" -lt 14 ]; then
  fail_soft "monitoring UI kaniti yetersiz: $UI_EVIDENCE_COUNT/15"
else
  pass "monitoring UI kaniti yeterli: $UI_EVIDENCE_COUNT/15"
fi

if [ "$MONITORING_EVIDENCE_COUNT" -lt 6 ]; then
  fail_soft "monitoring runtime kaniti yetersiz: $MONITORING_EVIDENCE_COUNT/6"
else
  pass "monitoring runtime kaniti yeterli: $MONITORING_EVIDENCE_COUNT/6"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP13_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP13_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_12_TEST_STATUS=$FINAL_STATUS
FAZ_4D_12_PILOT_MONITORING_STABILIZATION_STATUS=$FINAL_STATUS
FAZ_4D_12_DOC_EVIDENCE_COUNT=$DOC_EVIDENCE_COUNT
FAZ_4D_12_UI_EVIDENCE_COUNT=$UI_EVIDENCE_COUNT
FAZ_4D_12_MONITORING_EVIDENCE_COUNT=$MONITORING_EVIDENCE_COUNT
FAZ_4D_12_OK_COUNT=$OK_COUNT
FAZ_4D_12_WARN_COUNT=$WARN_COUNT
FAZ_4D_12_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_12_PUBLIC_URL=$URL
FAZ_4D_12_PUBLIC_HTTP_STATUS=$HTTP_STATUS
FAZ_4D_12_PUBLIC_PAGE_BYTES=$PAGE_BYTES
FAZ_4D_12_NGINX_TEST_STATUS=$NGINX_TEST_STATUS
FAZ_4D_13_READY=$STEP13_READY
UI_FILE=$UI_FILE
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-12 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-12 TEST SONUCU ====="
  echo "FAZ_4D_12_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_12_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_12_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_13_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-12 TEST SONUCU ====="
  echo "FAZ_4D_12_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_12_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_12_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_13_READY=NO ❌"
  exit 1
fi
