#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_3c_tenant_apply_strategy_decision.sh"
PREV_REPORT="reports/pilot/faz4c/4c_3b_db_tenant_precheck_report.md"
DOC_FILE="docs/pilot/faz4c/4c_3c_tenant_apply_strategy_decision.md"
REPORT_FILE="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_test_report.md"

echo "===== 4C-3C TENANT APPLY STRATEGY DECISION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-3B report yok: $PREV_REPORT"
pass "4C-3B report var"

grep -q "4C_3B_DB_TENANT_PRECHECK_STATUS=PASS" "$PREV_REPORT" || fail "4C-3B PASS degil"
pass "4C-3B PASS"

grep -q "4C_3B_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-3B DB write NO degil"
pass "4C-3B DB write NO"

grep -q "4C_3C_READY=YES" "$PREV_REPORT" || fail "4C-3C ready YES yok"
pass "4C-3C ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "Strategy dokumani yok: $DOC_FILE"
pass "Strategy dokumani var"

[ -f "$REPORT_FILE" ] || fail "Strategy report yok: $REPORT_FILE"
pass "Strategy report var"

grep -q "4C_3C_TENANT_APPLY_STRATEGY_STATUS=PASS" "$REPORT_FILE" || fail "4C-3C strategy PASS degil"
pass "4C-3C strategy PASS"

grep -q "4C_3C_TENANT_SCHEMA_CREATE_NEEDED=YES" "$REPORT_FILE" || fail "Schema create needed YES degil"
pass "Schema create needed YES"

grep -q "4C_3C_TENANT_METADATA_INSERT_NEEDED=YES" "$REPORT_FILE" || fail "Tenant metadata insert needed YES degil"
pass "Tenant metadata insert needed YES"

grep -q "4C_3C_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_3C_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_3D_READY=YES" "$REPORT_FILE" || fail "4C-3D ready YES yok"
pass "4C-3D ready YES"

SELECTED_TABLE="$(grep '^4C_3C_SELECTED_TENANT_TABLE=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
SCHEMA_CREATE_NEEDED="$(grep '^4C_3C_TENANT_SCHEMA_CREATE_NEEDED=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_3C_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3C Tenant Apply Strategy Decision Test Report

Step: 4C-3C
Blok: Tenant Apply Strategy Decision Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3C_TEST_STATUS=PASS
4C_3C_TENANT_APPLY_STRATEGY_STATUS=PASS
4C_3C_SELECTED_TENANT_TABLE=$SELECTED_TABLE
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED
4C_3C_TENANT_METADATA_INSERT_NEEDED=YES
4C_3C_DB_WRITE_APPLIED=NO
4C_3C_WARNING_COUNT=$WARNING_COUNT
4C_3D_READY=YES

## Sonuc

Tenant apply strategy decision test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-3D Tenant Apply SQL Package / Dry Run Plan.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3C TEST SONUCU ====="
echo "4C_3C_TEST_STATUS=PASS ✅"
echo "4C_3C_SELECTED_TENANT_TABLE=$SELECTED_TABLE"
echo "4C_3C_TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED"
echo "4C_3C_TENANT_METADATA_INSERT_NEEDED=YES"
echo "4C_3C_DB_WRITE_APPLIED=NO ✅"
echo "4C_3D_READY=YES ✅"
