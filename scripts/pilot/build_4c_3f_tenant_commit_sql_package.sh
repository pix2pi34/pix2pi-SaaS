#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DRY_RUN_REPORT="reports/pilot/faz4c/4c_3e_tenant_sql_dry_run_test_report.md"
FIX3_REPORT="reports/pilot/faz4c/4c_3d_fix3_business_code_uppercase_report.md"

COMMIT_SQL="sql/pilot/faz4c/4c_3f_commit_tenant_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_3f_tenant_commit_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_3f_tenant_commit_sql_package_report.md"

echo "===== 4C-3F TENANT COMMIT SQL PACKAGE / APPLY GUARD ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$DRY_RUN_REPORT" ] || fail "4C-3E dry-run test report yok: $DRY_RUN_REPORT"
[ -f "$FIX3_REPORT" ] || fail "4C-3D-FIX3 report yok: $FIX3_REPORT"

grep -q "4C_3E_TEST_STATUS=PASS" "$DRY_RUN_REPORT" || fail "4C-3E test PASS degil"
grep -q "4C_3E_SQL_EXECUTION_STATUS=PASS" "$DRY_RUN_REPORT" || fail "4C-3E SQL execution PASS degil"
grep -q "4C_3E_ROLLBACK_VERIFIED=YES" "$DRY_RUN_REPORT" || fail "4C-3E rollback verified YES degil"
grep -q "4C_3E_DB_WRITE_APPLIED=NO" "$DRY_RUN_REPORT" || fail "4C-3E DB write NO degil"
grep -q "4C_3F_READY=YES" "$DRY_RUN_REPORT" || fail "4C-3F ready YES degil"

grep -q "4C_3D_FIX3_BUSINESS_CODE=UZMANPARCACI" "$FIX3_REPORT" || fail "business_code UZMANPARCACI degil"
grep -q "4C_3D_FIX3_BUSINESS_CODE_CAST_STATUS=PASS" "$FIX3_REPORT" || fail "business_code cast PASS degil"

cat <<'SQL_EOF' > "$COMMIT_SQL"
-- FAZ 4C — 4C-3F Tenant Commit SQL Package
-- Purpose: uzmanparcaci real pilot tenant setup
-- IMPORTANT:
--   This file is a COMMIT package.
--   4C-3F only creates this file.
--   4C-3F does NOT execute it.
--   Execution must happen in 4C-3G Apply step only.

BEGIN;

-- 1. Safety check: selected tenant table must exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'platform'
      AND table_name = 'tenants'
  ) THEN
    RAISE EXCEPTION 'Selected tenant table %.% does not exist', 'platform', 'tenants';
  END IF;
END
$$;

-- 2. Safety check: required columns must exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='business_code'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.business_code does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='slug'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.slug does not exist';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='platform'
      AND table_name='tenants'
      AND column_name='name'
  ) THEN
    RAISE EXCEPTION 'Required column platform.tenants.name does not exist';
  END IF;
END
$$;

-- 3. Safety check: business_code must satisfy core.code_text
SELECT 'UZMANPARCACI'::core.code_text;

-- 4. Create tenant schema guarded
CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci;

-- 5. Insert tenant metadata guarded
INSERT INTO platform.tenants (
  business_code,
  slug,
  name,
  status,
  created_at,
  updated_at
)
SELECT
  'UZMANPARCACI'::core.code_text,
  'uzmanparcaci',
  'uzmanparcaci',
  'active',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1
  FROM platform.tenants
  WHERE slug = 'uzmanparcaci'
     OR business_code = 'UZMANPARCACI'::core.code_text
);

-- 6. Verification before commit
DO $$
DECLARE
  schema_count integer;
  tenant_count integer;
BEGIN
  SELECT count(*) INTO schema_count
  FROM information_schema.schemata
  WHERE schema_name = 'tenant_uzmanparcaci';

  SELECT count(*) INTO tenant_count
  FROM platform.tenants
  WHERE slug = 'uzmanparcaci'
     OR business_code = 'UZMANPARCACI'::core.code_text;

  IF schema_count <> 1 THEN
    RAISE EXCEPTION 'Tenant schema verification failed. schema_count=%', schema_count;
  END IF;

  IF tenant_count <> 1 THEN
    RAISE EXCEPTION 'Tenant metadata verification failed. tenant_count=%', tenant_count;
  END IF;
END
$$;

COMMIT;
SQL_EOF

if ! grep -q "COMMIT;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde COMMIT yok"
fi

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi

if ! grep -q "CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci" "$COMMIT_SQL"; then
  fail "Commit SQL icinde schema create yok"
fi

if ! grep -q "INSERT INTO platform.tenants" "$COMMIT_SQL"; then
  fail "Commit SQL icinde tenant insert yok"
fi

if ! grep -q "'UZMANPARCACI'::core.code_text" "$COMMIT_SQL"; then
  fail "Commit SQL icinde core.code_text business_code yok"
fi

{
  echo "# FAZ 4C — 4C-3F Tenant Commit SQL Package / Apply Guard"
  echo
  echo "## Amaç"
  echo
  echo "uzmanparcaci tenant kurulumu için COMMIT SQL paketini hazırlamak."
  echo
  echo "Bu adım SQL dosyasını hazırlar ama çalıştırmaz."
  echo
  echo "---"
  echo
  echo "## Ön koşullar"
  echo
  echo "4C_3E_TEST_STATUS=PASS"
  echo "4C_3E_SQL_EXECUTION_STATUS=PASS"
  echo "4C_3E_ROLLBACK_VERIFIED=YES"
  echo "4C_3E_DB_WRITE_APPLIED=NO"
  echo "4C_3D_FIX3_BUSINESS_CODE=UZMANPARCACI"
  echo
  echo "---"
  echo
  echo "## Commit SQL"
  echo
  echo "COMMIT_SQL=$COMMIT_SQL"
  echo
  echo "---"
  echo
  echo "## Güvenlik kararı"
  echo
  echo "4C-3F dosya üretir."
  echo "4C-3F DB apply yapmaz."
  echo "DB apply sadece 4C-3G içinde yapılacaktır."
  echo
  echo "---"
  echo
  echo "## Status"
  echo
  echo "4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS"
  echo "4C_3F_COMMIT_SQL_FILE_CREATED=YES"
  echo "4C_3F_COMMIT_SQL_HAS_COMMIT=YES"
  echo "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO"
  echo "4C_3F_DB_WRITE_APPLIED=NO"
  echo "4C_3G_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3F Tenant Commit SQL Package Report"
  echo
  echo "Step: 4C-3F"
  echo "Blok: Tenant Commit SQL Package / Apply Guard"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS"
  echo "4C_3F_COMMIT_SQL_FILE_CREATED=YES"
  echo "4C_3F_COMMIT_SQL_FILE=$COMMIT_SQL"
  echo "4C_3F_COMMIT_SQL_HAS_COMMIT=YES"
  echo "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO"
  echo "4C_3F_BUSINESS_CODE=UZMANPARCACI"
  echo "4C_3F_TENANT_SCHEMA=tenant_uzmanparcaci"
  echo "4C_3F_DB_WRITE_APPLIED=NO"
  echo "4C_3G_READY=YES"
  echo
  echo "## Sonuç"
  echo
  echo "Tenant COMMIT SQL paketi hazırlandı."
  echo "Bu adımda DB yazma yapılmadı."
  echo "Sonraki adım: 4C-3G Tenant Apply Execution."
} > "$REPORT_FILE"

echo "OK ✅ Commit SQL paketi olusturuldu: $COMMIT_SQL"
echo "OK ✅ Commit SQL report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3F OZET ====="
echo "4C_3F_COMMIT_SQL_PACKAGE_STATUS=PASS ✅"
echo "4C_3F_COMMIT_SQL_FILE_CREATED=YES ✅"
echo "4C_3F_COMMIT_SQL_HAS_COMMIT=YES ✅"
echo "4C_3F_COMMIT_SQL_HAS_ROLLBACK=NO ✅"
echo "4C_3F_DB_WRITE_APPLIED=NO ✅"
echo "4C_3G_READY=YES ✅"
