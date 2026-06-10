#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/build_4c_3f_tenant_commit_sql_package.sh"
REPORT_FILE="reports/pilot/faz4c/4c_3f_tenant_commit_sql_package_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3f_tenant_commit_sql_package_test_report.md"
COMMIT_SQL="sql/pilot/faz4c/4c_3f_commit_tenant_uzmanparcaci.sql"

echo "===== 4C-3F TENANT COMMIT SQL PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-3F report yok: $REPORT_FILE"
pass "4C-3F report var"

[ -f "$COMMIT_SQL" ] || fail "Commit SQL dosyasi yok: $COMMIT_SQL"
pass "Commit SQL dosyasi var"

grep -q "4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS" "$REPORT_FILE" || fail "Commit package PASS degil"
pass "Commit package PASS"

grep -q "4C_3F_COMMIT_SQL_FILE_CREATED=YES" "$REPORT_FILE" || fail "Commit SQL file created YES degil"
pass "Commit SQL file created YES"

grep -q "4C_3F_COMMIT_SQL_HAS_COMMIT=YES" "$REPORT_FILE" || fail "Commit SQL has commit YES degil"
pass "Commit SQL has COMMIT"

grep -q "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO" "$REPORT_FILE" || fail "Commit SQL has rollback NO degil"
pass "Commit SQL has no ROLLBACK"

grep -q "4C_3F_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "4C-3F DB write applied NO degil"
pass "4C-3F DB write applied NO"

grep -q "4C_3G_READY=YES" "$REPORT_FILE" || fail "4C-3G ready YES yok"
pass "4C-3G ready YES"

grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL icinde COMMIT yok"
pass "Commit SQL icinde COMMIT var"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi
pass "Commit SQL icinde ROLLBACK yok"

grep -q "'UZMANPARCACI'::core.code_text" "$COMMIT_SQL" || fail "business_code core.code_text yok"
pass "business_code core.code_text var"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3F Tenant Commit SQL Package Test Report

Step: 4C-3F
Blok: Tenant Commit SQL Package / Apply Guard Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3F_TEST_STATUS=PASS
4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS
4C_3F_COMMIT_SQL_FILE_CREATED=YES
4C_3F_COMMIT_SQL_HAS_COMMIT=YES
4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO
4C_3F_DB_WRITE_APPLIED=NO
4C_3G_READY=YES

## Sonuç

Tenant COMMIT SQL paketi test edildi.
Bu adımda DB yazma yapılmadı.
Sonraki adım: 4C-3G Tenant Apply Execution.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3F TEST SONUCU ====="
echo "4C_3F_TEST_STATUS=PASS ✅"
echo "4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS ✅"
echo "4C_3F_COMMIT_SQL_FILE_CREATED=YES ✅"
echo "4C_3F_COMMIT_SQL_HAS_COMMIT=YES ✅"
echo "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO ✅"
echo "4C_3F_DB_WRITE_APPLIED=NO ✅"
echo "4C_3G_READY=YES ✅"
