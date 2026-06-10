#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_2c_runtime_port_standardization.md"
REPORT_FILE="reports/pilot/faz4c/4c_2c_runtime_port_standardization_report.md"
SCAN_REPORT="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md"
CLASS_REPORT="reports/pilot/faz4c/4c_2b_critical_runtime_gap_classification_report.md"

echo "===== 4C-2C RUNTIME PORT STANDARDIZATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$DOC_FILE" ] || fail "Port standardization dokumani yok: $DOC_FILE"
pass "Port standardization dokumani var"

[ -f "$SCAN_REPORT" ] || fail "4C-2A scan report yok: $SCAN_REPORT"
pass "4C-2A scan report var"

[ -f "$CLASS_REPORT" ] || fail "4C-2B classification report yok: $CLASS_REPORT"
pass "4C-2B classification report var"

grep -q "4C_2B_CLASSIFICATION_STATUS=PASS" "$CLASS_REPORT" || fail "4C-2B classification PASS degil"
pass "4C-2B classification PASS"

grep -q "4C_2B_CRITICAL_BLOCKER_COUNT=0" "$CLASS_REPORT" || fail "4C-2B critical blocker count 0 degil"
pass "4C-2B critical blocker count 0"

grep -q "API_GATEWAY_PORT=9010" "$DOC_FILE" || fail "API Gateway port standardi yok"
pass "API Gateway port standardi var"

grep -q "IDENTITY_API_PORT=9002" "$DOC_FILE" || fail "Identity 9002 port standardi yok"
pass "Identity 9002 port standardi var"

grep -q "GRAFANA_HOST_PORT=3001" "$DOC_FILE" || fail "Grafana 3001 port standardi yok"
pass "Grafana 3001 port standardi var"

grep -q "POSTGRES_PRIMARY_HOST_PORT=5433" "$DOC_FILE" || fail "Postgres 5433 port standardi yok"
pass "Postgres 5433 port standardi var"

grep -q "4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS" "$DOC_FILE" || fail "4C-2C status PASS yok"
pass "4C-2C status PASS var"

grep -q "4C_2C_CRITICAL_BLOCKER_COUNT=0" "$DOC_FILE" || fail "4C-2C critical blocker 0 yok"
pass "4C-2C critical blocker 0 var"

grep -q "4C_2D_READY=YES" "$DOC_FILE" || fail "4C-2D ready YES yok"
pass "4C-2D ready YES var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-2C Runtime Port Standardization Report

Step: 4C-2C
Blok: Runtime Port Standardization Notes
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2C_TEST_STATUS=PASS
4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS
4C_2C_CRITICAL_BLOCKER_COUNT=0
4C_2C_WARNING_COUNT=4
4C_2C_API_GATEWAY_PORT=9010
4C_2C_IDENTITY_RUNTIME_PORT=9002
4C_2C_GRAFANA_RUNTIME_PORT=3001
4C_2C_POSTGRES_PRIMARY_PORT=5433
4C_2D_READY=YES

## Sonuc

Runtime port standardizasyon notu olusturuldu.
Mevcut port uyumsuzluklari kritik blocker degildir.
Sonraki adim: 4C-2D Runtime Endpoint Validation.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-2C TEST SONUCU ====="
echo "4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS ✅"
echo "4C_2C_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_2C_API_GATEWAY_PORT=9010 ✅"
echo "4C_2C_IDENTITY_RUNTIME_PORT=9002 ✅"
echo "4C_2C_GRAFANA_RUNTIME_PORT=3001 ✅"
echo "4C_2D_READY=YES ✅"
