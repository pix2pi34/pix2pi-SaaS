#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_2e_runtime_gap_decision_fix_plan.sh"
D_REPORT="reports/pilot/faz4c/4c_2d_runtime_endpoint_validation_report.md"
DOC_FILE="docs/pilot/faz4c/4c_2e_runtime_gap_decision_fix_plan.md"
REPORT_FILE="reports/pilot/faz4c/4c_2e_runtime_gap_decision_fix_plan_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_2e_runtime_gap_decision_fix_plan_test_report.md"

echo "===== 4C-2E RUNTIME GAP DECISION / FIX PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$D_REPORT" ] || fail "4C-2D report yok: $D_REPORT"
pass "4C-2D report var"

grep -q "4C_2D_ENDPOINT_VALIDATION_STATUS=PASS" "$D_REPORT" || fail "4C-2D PASS degil"
pass "4C-2D PASS"

grep -q "4C_2D_CRITICAL_BLOCKER_COUNT=0" "$D_REPORT" || fail "4C-2D critical blocker 0 degil"
pass "4C-2D critical blocker 0"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "Decision dokumani yok: $DOC_FILE"
pass "Decision dokumani var"

[ -f "$REPORT_FILE" ] || fail "Decision report yok: $REPORT_FILE"
pass "Decision report var"

grep -q "4C_2E_RUNTIME_GAP_DECISION_STATUS=PASS" "$REPORT_FILE" || fail "4C-2E decision PASS degil"
pass "4C-2E decision PASS"

grep -q "4C_2E_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "4C-2E critical blocker 0 degil"
pass "4C-2E critical blocker 0"

grep -q "4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO" "$REPORT_FILE" || fail "Blocking fix NO degil"
pass "Blocking fix required NO"

grep -q "4C_2E_GATEWAY_READY=YES" "$REPORT_FILE" || fail "Gateway ready YES yok"
pass "Gateway ready YES"

grep -q "4C_2E_DB_READY=YES" "$REPORT_FILE" || fail "DB ready YES yok"
pass "DB ready YES"

grep -q "4C_2E_IDENTITY_READY=YES" "$REPORT_FILE" || fail "Identity ready YES yok"
pass "Identity ready YES"

grep -q "4C_2F_READY=YES" "$REPORT_FILE" || fail "4C-2F ready YES yok"
pass "4C-2F ready YES"

WARNING_COUNT="$(grep '^4C_2E_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-2E Runtime Gap Decision / Fix Plan Test Report

Step: 4C-2E
Blok: Runtime Gap Decision / Fix Plan Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2E_TEST_STATUS=PASS
4C_2E_RUNTIME_GAP_DECISION_STATUS=PASS
4C_2E_CRITICAL_BLOCKER_COUNT=0
4C_2E_WARNING_COUNT=$WARNING_COUNT
4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO
4C_2F_READY=YES

## Sonuc

Runtime gap decision/fix plan test tamamlandi.
Kritik blocker yok.
4C-2F final closure adimina gecilebilir.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-2E TEST SONUCU ====="
echo "4C_2E_TEST_STATUS=PASS ✅"
echo "4C_2E_RUNTIME_GAP_DECISION_STATUS=PASS ✅"
echo "4C_2E_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_2E_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO ✅"
echo "4C_2F_READY=YES ✅"
