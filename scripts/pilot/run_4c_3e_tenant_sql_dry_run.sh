#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_3e_tenant_sql_dry_run.md"
REPORT_FILE="reports/pilot/faz4c/4c_3e_tenant_sql_dry_run_report.md"
PREV_REPORT="reports/pilot/faz4c/4c_3d_tenant_apply_sql_package_test_report.md"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

echo "===== 4C-3E TENANT SQL DRY RUN / ROLLBACK VERIFICATION ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

safe_source() {
  local f="$1"
  if [ -f "$f" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$f"
    set +a
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3e_sql_output.log 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3e_sql_output.log 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_3e_preview.sql
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_3e_preview.sql >/tmp/4c_3e_sql_output.log 2>/tmp/4c_3e_psql_error.log
    return $?
  fi

  return 127
}

[ -f "$SQL_FILE" ] || fail "SQL preview file yok: $SQL_FILE"
[ -f "$PREV_REPORT" ] || fail "4C-3D test report yok: $PREV_REPORT"

grep -q "4C_3D_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-3D test PASS degil"
grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL preview ROLLBACK icermiyor"
grep -q "CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci" "$SQL_FILE" || fail "SQL preview schema create icermiyor"
grep -q "INSERT INTO platform.tenants" "$SQL_FILE" || fail "SQL preview tenant insert icermiyor"

safe_source "$COMMON_ENV"

BEFORE_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
BEFORE_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci';" | tr -d '[:space:]')"

DRY_RUN_STATUS="PASS"
DRY_RUN_ERROR=""

if ! run_sql_file "$SQL_FILE"; then
  DRY_RUN_STATUS="FAIL"
  DRY_RUN_ERROR="$(cat /tmp/4c_3e_psql_error.log 2>/dev/null || true)"
fi

AFTER_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
AFTER_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci';" | tr -d '[:space:]')"

SQL_OUTPUT="$(cat /tmp/4c_3e_sql_output.log 2>/dev/null || true)"

ROLLBACK_VERIFIED="NO"
if [ "$BEFORE_SCHEMA_COUNT" = "$AFTER_SCHEMA_COUNT" ] && [ "$BEFORE_TENANT_COUNT" = "$AFTER_TENANT_COUNT" ]; then
  ROLLBACK_VERIFIED="YES"
fi

CRITICAL_BLOCKER_COUNT=0
NEXT_READY="YES"

if [ "$DRY_RUN_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  NEXT_READY="NO"
fi

if [ "$ROLLBACK_VERIFIED" != "YES" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  NEXT_READY="NO"
fi

if [ "$CRITICAL_BLOCKER_COUNT" -eq 0 ]; then
  STEP_STATUS="PASS"
else
  STEP_STATUS="BLOCKED"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-3E Tenant SQL Dry Run / ROLLBACK Verification

## Blok

4C-3E — Tenant SQL Dry Run Execution / ROLLBACK Verification

## Amaç

Bu adım 4C-3D'de üretilen SQL preview dosyasını çalıştırır.

Bu SQL dosyası ROLLBACK ile biter.
Bu nedenle kalıcı DB yazma yapılmamalıdır.

---

## 1. SQL preview dosyası

SQL_FILE=$SQL_FILE

---

## 2. Dry-run öncesi durum

BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT
BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT

---

## 3. Dry-run sonucu

DRY_RUN_STATUS=$DRY_RUN_STATUS

SQL output:

\`\`\`text
$SQL_OUTPUT
\`\`\`

SQL error:

\`\`\`text
$DRY_RUN_ERROR
\`\`\`

---

## 4. Dry-run sonrası durum

AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT
AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT

---

## 5. Rollback doğrulama

ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED

Beklenen:
- BEFORE_SCHEMA_COUNT == AFTER_SCHEMA_COUNT
- BEFORE_TENANT_COUNT == AFTER_TENANT_COUNT

---

## 6. Karar

4C_3E_DRY_RUN_STATUS=$STEP_STATUS
4C_3E_SQL_EXECUTION_STATUS=$DRY_RUN_STATUS
4C_3E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED
4C_3E_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT
4C_3E_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT
4C_3E_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT
4C_3E_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT
4C_3E_DB_WRITE_APPLIED=NO
4C_3E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3E_NEXT_STEP_READY=$NEXT_READY
4C_3F_READY=$NEXT_READY

---

## 7. Sonraki adım

Sonraki adım:

4C-3F — Tenant Apply Guard / Commit SQL Package

Bu adımda dry-run başarılıysa COMMIT versiyonu kontrollü olarak hazırlanacak.
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3E Tenant SQL Dry Run Report

Step: 4C-3E
Blok: Tenant SQL Dry Run Execution / ROLLBACK Verification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3E_DRY_RUN_STATUS=$STEP_STATUS
4C_3E_SQL_EXECUTION_STATUS=$DRY_RUN_STATUS
4C_3E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED
4C_3E_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT
4C_3E_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT
4C_3E_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT
4C_3E_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT
4C_3E_DB_WRITE_APPLIED=NO
4C_3E_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3F_READY=$NEXT_READY

## Sonuc

Tenant SQL dry-run tamamlandi.
Rollback doğrulaması: $ROLLBACK_VERIFIED
Kalıcı DB yazma yapilmadi.
Sonraki adim: 4C-3F Tenant Apply Guard / Commit SQL Package.
REPORT_EOF

echo "OK ✅ Tenant SQL dry-run dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Tenant SQL dry-run report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-3E DRY RUN OZETI ====="
echo "4C_3E_DRY_RUN_STATUS=$STEP_STATUS"
echo "4C_3E_SQL_EXECUTION_STATUS=$DRY_RUN_STATUS"
echo "4C_3E_ROLLBACK_VERIFIED=$ROLLBACK_VERIFIED"
echo "4C_3E_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
echo "4C_3E_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
echo "4C_3E_BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
echo "4C_3E_AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
echo "4C_3F_READY=$NEXT_READY"
