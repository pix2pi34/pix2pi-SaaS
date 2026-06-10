#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_2a_runtime_baseline_gap_scan.sh"
REPORT_FILE="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_test_report.md"
PREV_REPORT="reports/pilot/faz4c/4c_1_2b_final_scope_freeze_closure_report.md"

echo "===== 4C-2A RUNTIME BASELINE GAP SCAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-1 final closure report yok: $PREV_REPORT"
pass "4C-1 final closure report var"

grep -q "4C_1_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-1 final PASS degil"
pass "4C-1 final PASS"

grep -q "4C_2_READY=YES" "$PREV_REPORT" || fail "4C-2 ready YES degil"
pass "4C-2 ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "Runtime baseline report yok: $REPORT_FILE"
pass "Runtime baseline report var"

grep -q "4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS" "$REPORT_FILE" || fail "4C-2A status PASS yok"
pass "4C-2A status PASS var"

grep -q "4C_2A_REPORT_CREATED=YES" "$REPORT_FILE" || fail "Report created YES yok"
pass "Report created YES var"

grep -q "4C_2B_READY=YES" "$REPORT_FILE" || fail "4C-2B ready YES yok"
pass "4C-2B ready YES var"

grep -q "PORT_9010_API_GATEWAY" "$REPORT_FILE" || fail "API Gateway port kontrolu yok"
pass "API Gateway port kontrolu var"

grep -q "PORT_5433_POSTGRES_HOST" "$REPORT_FILE" || fail "Postgres port kontrolu yok"
pass "Postgres port kontrolu var"

grep -q "GATEWAY_HEALTH_HTTP" "$REPORT_FILE" || fail "Gateway health kontrolu yok"
pass "Gateway health kontrolu var"

CRITICAL_COUNT="$(grep '^4C_2A_CRITICAL_BLOCKER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_2A_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-2A Runtime Baseline Gap Scan Test Report

Step: 4C-2A
Blok: Runtime Baseline Inventory / Gap Scan Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2A_TEST_STATUS=PASS
4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS
4C_2A_REPORT_CREATED=YES
4C_2A_CRITICAL_BLOCKER_COUNT=$CRITICAL_COUNT
4C_2A_WARNING_COUNT=$WARNING_COUNT
4C_2B_READY=YES

## Sonuc

Runtime baseline inventory ve gap scan raporu uretildi.
Sonraki adim: 4C-2B Critical Runtime Gap Classification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-2A TEST SONUCU ====="
echo "4C_2A_TEST_STATUS=PASS ✅"
echo "4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS ✅"
echo "4C_2A_CRITICAL_BLOCKER_COUNT=$CRITICAL_COUNT"
echo "4C_2A_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2B_READY=YES ✅"
