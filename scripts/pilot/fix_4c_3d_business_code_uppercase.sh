#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
DOMAIN_REPORT="reports/pilot/faz4c/4c_3e_fix3a_code_text_domain_report.md"

SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_3d_fix3_business_code_uppercase.md"
REPORT_FILE="reports/pilot/faz4c/4c_3d_fix3_business_code_uppercase_report.md"

echo "===== 4C-3D-FIX3 BUSINESS_CODE UPPERCASE FIX ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3d_fix3_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3d_fix3_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3d_fix3_psql_error.log
    return $?
  fi

  return 127
}

[ -f "$DOMAIN_REPORT" ] || fail "Domain discovery report yok: $DOMAIN_REPORT"

grep -q "4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS" "$DOMAIN_REPORT" || fail "Domain discovery PASS degil"
grep -q "4C_3E_FIX3A_BEST_BUSINESS_CODE=UZMANPARCACI" "$DOMAIN_REPORT" || fail "BEST_BUSINESS_CODE UZMANPARCACI degil"

safe_source "$COMMON_ENV"

BUSINESS_CODE="UZMANPARCACI"
SLUG="uzmanparcaci"
NAME="uzmanparcaci"
TENANT_SCHEMA="tenant_uzmanparcaci"

if ! run_sql "select 1;" >/tmp/4c_3d_fix3_db_ping.out; then
  fail "DB baglantisi yok"
fi

BUSINESS_CODE_CAST_STATUS="FAIL"
if run_sql "select '${BUSINESS_CODE}'::core.code_text;" >/tmp/4c_3d_fix3_cast.out; then
  BUSINESS_CODE_CAST_STATUS="PASS"
fi

[ "$BUSINESS_CODE_CAST_STATUS" = "PASS" ] || fail "BUSINESS_CODE core.code_text cast PASS olmadi"

EXISTING_TENANT_COUNT="$(
  run_sql "
select count(*)
from platform.tenants
where slug='${SLUG}'
   or business_code='${BUSINESS_CODE}';
" | tr -d '[:space:]'
)"

SCHEMA_EXISTS="$(
  run_sql "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
" | tr -d '[:space:]'
)"

cat <<SQL_EOF > "$SQL_FILE"
-- FAZ 4C — 4C-3D-FIX3 Tenant Apply SQL Package / Preview
-- Purpose: uzmanparcaci tenant setup SQL preview
-- Fix: business_code converted to core.code_text compatible uppercase value
-- IMPORTANT:
--   This SQL file is generated as preview.
--   It is NOT committed.
--   It ends with ROLLBACK intentionally.
--
-- Generated at: $(date '+%Y-%m-%d %H:%M:%S')
-- Selected tenant table: platform.tenants
-- Tenant schema: ${TENANT_SCHEMA}
-- Tenant business_code: ${BUSINESS_CODE}
-- Tenant slug: ${SLUG}

BEGIN;

-- 1. Safety check: selected tenant table must exist
DO \$\$
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
\$\$;

-- 2. Safety check: required columns must exist
DO \$\$
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
\$\$;

-- 3. Safety check: business_code must satisfy core.code_text
SELECT '${BUSINESS_CODE}'::core.code_text;

-- 4. Create schema guarded
CREATE SCHEMA IF NOT EXISTS ${TENANT_SCHEMA};

-- 5. Insert tenant metadata guarded
-- Existing count detected during generation: ${EXISTING_TENANT_COUNT}
INSERT INTO platform.tenants (
  business_code,
  slug,
  name,
  status,
  created_at,
  updated_at
)
SELECT
  '${BUSINESS_CODE}'::core.code_text,
  '${SLUG}',
  '${NAME}',
  'active',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1
  FROM platform.tenants
  WHERE slug = '${SLUG}'
     OR business_code = '${BUSINESS_CODE}'::core.code_text
);

-- 6. Verification
SELECT 'tenant_schema_exists' AS check_name, count(*)::text AS check_value
FROM information_schema.schemata
WHERE schema_name = '${TENANT_SCHEMA}';

SELECT 'tenant_metadata_exists' AS check_name, count(*)::text AS check_value
FROM platform.tenants
WHERE slug = '${SLUG}'
   OR business_code = '${BUSINESS_CODE}'::core.code_text;

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- Later apply step will generate/execute a guarded COMMIT version only after approval.
SQL_EOF

{
  echo "# FAZ 4C — 4C-3D-FIX3 business_code Uppercase Fix"
  echo
  echo "## Amaç"
  echo
  echo "core.code_text domain kuralına göre business_code değerini düzeltmek."
  echo
  echo "---"
  echo
  echo "## Domain kuralı"
  echo
  echo "core.code_text kabul formatı:"
  echo
  echo '```text'
  echo "^[A-Z0-9_\\-]+$"
  echo '```'
  echo
  echo "---"
  echo
  echo "## Karar"
  echo
  echo "BUSINESS_CODE=$BUSINESS_CODE"
  echo "SLUG=$SLUG"
  echo "NAME=$NAME"
  echo "TENANT_SCHEMA=$TENANT_SCHEMA"
  echo
  echo "---"
  echo
  echo "## Status"
  echo
  echo "4C_3D_FIX3_BUSINESS_CODE_UPPERCASE_STATUS=PASS"
  echo "4C_3D_FIX3_BUSINESS_CODE_CAST_STATUS=$BUSINESS_CODE_CAST_STATUS"
  echo "4C_3D_FIX3_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
  echo "4C_3D_FIX3_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
  echo "4C_3D_FIX3_SQL_FILE_CREATED=YES"
  echo "4C_3D_FIX3_DB_WRITE_APPLIED=NO"
  echo "4C_3E_RETRY_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3D-FIX3 business_code Uppercase Fix Report"
  echo
  echo "Step: 4C-3D-FIX3"
  echo "Blok: business_code Uppercase Fix"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3D_FIX3_BUSINESS_CODE_UPPERCASE_STATUS=PASS"
  echo "4C_3D_FIX3_BUSINESS_CODE=$BUSINESS_CODE"
  echo "4C_3D_FIX3_SLUG=$SLUG"
  echo "4C_3D_FIX3_BUSINESS_CODE_CAST_STATUS=$BUSINESS_CODE_CAST_STATUS"
  echo "4C_3D_FIX3_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
  echo "4C_3D_FIX3_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
  echo "4C_3D_FIX3_SQL_FILE_CREATED=YES"
  echo "4C_3D_FIX3_DB_WRITE_APPLIED=NO"
  echo "4C_3E_RETRY_READY=YES"
  echo
  echo "## Sonuç"
  echo
  echo "SQL preview dosyası business_code=UZMANPARCACI ile yeniden üretildi."
  echo "Kalıcı DB yazma yapılmadı."
  echo "4C-3E dry-run tekrar çalıştırılabilir."
} > "$REPORT_FILE"

echo "OK ✅ SQL preview yeniden uretildi: $SQL_FILE"
echo "OK ✅ Fix report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3D-FIX3 OZET ====="
echo "4C_3D_FIX3_BUSINESS_CODE_UPPERCASE_STATUS=PASS ✅"
echo "4C_3D_FIX3_BUSINESS_CODE=$BUSINESS_CODE"
echo "4C_3D_FIX3_BUSINESS_CODE_CAST_STATUS=$BUSINESS_CODE_CAST_STATUS ✅"
echo "4C_3D_FIX3_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
echo "4C_3D_FIX3_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
echo "4C_3D_FIX3_DB_WRITE_APPLIED=NO ✅"
echo "4C_3E_RETRY_READY=YES ✅"
