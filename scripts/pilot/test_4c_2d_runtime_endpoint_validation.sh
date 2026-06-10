#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_2d_runtime_endpoint_validation.sh"
PORT_REPORT="reports/pilot/faz4c/4c_2c_runtime_port_standardization_report.md"
DOC_FILE="docs/pilot/faz4c/4c_2d_runtime_endpoint_validation.md"
REPORT_FILE="reports/pilot/faz4c/4c_2d_runtime_endpoint_validation_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_2d_runtime_endpoint_validation_test_report.md"

echo "===== 4C-2D RUNTIME ENDPOINT VALIDATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PORT_REPORT" ] || fail "4C-2C port report yok: $PORT_REPORT"
pass "4C-2C port report var"

grep -q "4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS" "$PORT_REPORT" || fail "4C-2C PASS degil"
pass "4C-2C PASS"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "Endpoint validation dokumani yok: $DOC_FILE"
pass "Endpoint validation dokumani var"

[ -f "$REPORT_FILE" ] || fail "Endpoint validation report yok: $REPORT_FILE"
pass "Endpoint validation report var"

grep -q "4C_2D_ENDPOINT_VALIDATION_STATUS=PASS" "$REPORT_FILE" || fail "4C-2D endpoint validation PASS degil"
pass "4C-2D endpoint validation PASS"

grep -q "4C_2D_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker count 0 degil"
pass "Critical blocker count 0"

grep -q "4C_2D_GATEWAY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Gateway health 200 degil"
pass "Gateway health 200"

grep -q "4C_2D_POSTGRES_PRIMARY_PORT_STATUS=LISTEN" "$REPORT_FILE" || fail "Postgres primary LISTEN degil"
pass "Postgres primary LISTEN"

grep -q "4C_2E_READY=YES" "$REPORT_FILE" || fail "4C-2E ready YES yok"
pass "4C-2E ready YES"

WARNING_COUNT="$(grep '^4C_2D_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
IDENTITY_HEALTH="$(grep '^4C_2D_IDENTITY_HEALTH_HTTP=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-2D Runtime Endpoint Validation Test Report

Step: 4C-2D
Blok: Runtime Endpoint Validation Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2D_TEST_STATUS=PASS
4C_2D_ENDPOINT_VALIDATION_STATUS=PASS
4C_2D_CRITICAL_BLOCKER_COUNT=0
4C_2D_WARNING_COUNT=$WARNING_COUNT
4C_2D_GATEWAY_HEALTH_HTTP=200
4C_2D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH
4C_2E_READY=YES

## Sonuc

Runtime endpoint validation tamamlandi.
Kritik blocker yok.
Warning varsa 4C-2E fix/decision planinda ele alinacak.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-2D TEST SONUCU ====="
echo "4C_2D_TEST_STATUS=PASS ✅"
echo "4C_2D_ENDPOINT_VALIDATION_STATUS=PASS ✅"
echo "4C_2D_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_2D_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH"
echo "4C_2E_READY=YES ✅"
