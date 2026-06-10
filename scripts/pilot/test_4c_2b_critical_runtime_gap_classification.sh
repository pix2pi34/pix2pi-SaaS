#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_2b_critical_runtime_gap_classification.sh"
SCAN_REPORT="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md"
DOC_FILE="docs/pilot/faz4c/4c_2b_critical_runtime_gap_classification.md"
REPORT_FILE="reports/pilot/faz4c/4c_2b_critical_runtime_gap_classification_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_2b_critical_runtime_gap_classification_test_report.md"

echo "===== 4C-2B CRITICAL RUNTIME GAP CLASSIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$SCAN_REPORT" ] || fail "4C-2A scan report yok: $SCAN_REPORT"
pass "4C-2A scan report var"

grep -q "4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS" "$SCAN_REPORT" || fail "4C-2A PASS degil"
pass "4C-2A PASS"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "Classification dokumani yok: $DOC_FILE"
pass "Classification dokumani var"

[ -f "$REPORT_FILE" ] || fail "Classification report yok: $REPORT_FILE"
pass "Classification report var"

grep -q "4C_2B_CLASSIFICATION_STATUS=PASS" "$REPORT_FILE" || fail "4C-2B classification PASS degil"
pass "4C-2B classification PASS"

grep -q "4C_2B_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker count 0 degil"
pass "Critical blocker count 0"

grep -q "4C_2B_RUNTIME_PORT_STANDARDIZATION_NEEDED=YES" "$REPORT_FILE" || fail "Runtime port standardization needed yok"
pass "Runtime port standardization needed kaydi var"

grep -q "4C_2B_IDENTITY_PORT_MISMATCH=YES" "$REPORT_FILE" || fail "Identity port mismatch kaydi yok"
pass "Identity port mismatch kaydi var"

grep -q "4C_2B_GRAFANA_PORT_MISMATCH=YES" "$REPORT_FILE" || fail "Grafana port mismatch kaydi yok"
pass "Grafana port mismatch kaydi var"

grep -q "4C_2C_READY=YES" "$REPORT_FILE" || fail "4C-2C ready YES yok"
pass "4C-2C ready YES"

WARNING_COUNT="$(grep '^4C_2B_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-2B Critical Runtime Gap Classification Test Report

Step: 4C-2B
Blok: Critical Runtime Gap Classification Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2B_TEST_STATUS=PASS
4C_2B_CLASSIFICATION_STATUS=PASS
4C_2B_CRITICAL_BLOCKER_COUNT=0
4C_2B_WARNING_COUNT=$WARNING_COUNT
4C_2B_RUNTIME_PORT_STANDARDIZATION_NEEDED=YES
4C_2C_READY=YES

## Sonuc

Critical runtime gap classification tamamlandi.
Kritik blocker yok.
Sonraki adim: 4C-2C Runtime Port Standardization Notes.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-2B TEST SONUCU ====="
echo "4C_2B_TEST_STATUS=PASS ✅"
echo "4C_2B_CLASSIFICATION_STATUS=PASS ✅"
echo "4C_2B_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_2B_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2C_READY=YES ✅"
