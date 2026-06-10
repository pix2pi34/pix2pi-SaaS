#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
TENANT_ENV="docs/pilot/faz4c/4c_3a_tenant_identity_setup_plan.env"
DIAG_REPORT="reports/pilot/faz4c/4c_3e_fix1_dry_run_error_diagnosis_report.md"

SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"
DOC_FILE="docs/pilot/faz4c/4c_3d_fix2_business_code_mapping.md"
REPORT_FILE="reports/pilot/faz4c/4c_3d_fix2_business_code_mapping_report.md"

echo "===== 4C-3D-FIX2 BUSINESS_CODE MAPPING FIX ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3d_fix2_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3d_fix2_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3d_fix2_psql_error.log
    return $?
  fi

  return 127
}

[ -f "$TENANT_ENV" ] || fail "Tenant env yok: $TENANT_ENV"
[ -f "$DIAG_REPORT" ] || fail "Diagnosis report yok: $DIAG_REPORT"

grep -q "business_code" "$DIAG_REPORT" || fail "Diagnosis report icinde business_code hatasi yok"
grep -q "4C_3E_FIX1_ROLLBACK_SAFE=YES" "$DIAG_REPORT" || fail "Rollback safe YES degil"

safe_source "$COMMON_ENV"
safe_source "$TENANT_ENV"

TENANT_CODE="${TENANT_CODE:-uzmanparcaci}"
TENANT_SLUG="${TENANT_SLUG:-uzmanparcaci}"
TENANT_DISPLAY_NAME="${TENANT_DISPLAY_NAME:-uzmanparcaci}"
TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"

if ! run_sql "select 1;" >/tmp/4c_3d_fix2_db_ping.out; then
  fail "DB baglantisi yok"
fi

BUSINESS_CODE_EXISTS="$(run_sql "
select count(*)
from information_schema.columns
where table_schema='platform'
  and table_name='tenants'
  and column_name='business_code';
" | tr -d '[:space:]')"

SLUG_EXISTS="$(run_sql "
select count(*)
from information_schema.columns
where table_schema='platform'
  and table_name='tenants'
  and column_name='slug';
" | tr -d '[:space:]')"

NAME_EXISTS="$(run_sql "
select count(*)
from information_schema.columns
where table_schema='platform'
  and table_name='tenants'
  and column_name='name';
" | tr -d '[:space:]')"

[ "$BUSINESS_CODE_EXISTS" = "1" ] || fail "platform.tenants.business_code kolonu yok"
[ "$SLUG_EXISTS" = "1" ] || fail "platform.tenants.slug kolonu yok"
[ "$NAME_EXISTS" = "1" ] || fail "platform.tenants.name kolonu yok"

EXISTING_TENANT_COUNT="$(run_sql "
select count(*)
from platform.tenants
where slug='${TENANT_SLUG}'
   or business_code='${TENANT_CODE}';
" | tr -d '[:space:]')"

SCHEMA_EXISTS="$(run_sql "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
" | tr -d '[:space:]')"

cat <<SQL_EOF > "$SQL_FILE"
-- FAZ 4C — 4C-3D-FIX2 Tenant Apply SQL Package / Preview
-- Purpose: uzmanparcaci tenant setup SQL preview
-- Fix: business_code mapping added
-- IMPORTANT:
--   This SQL file is generated as preview.
--   It is NOT committed.
--   It ends with ROLLBACK intentionally.
--
-- Generated at: $(date '+%Y-%m-%d %H:%M:%S')
-- Selected tenant table: platform.tenants
-- Tenant schema: ${TENANT_SCHEMA}
-- Tenant code: ${TENANT_CODE}

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

-- 3. Create schema guarded
CREATE SCHEMA IF NOT EXISTS ${TENANT_SCHEMA};

-- 4. Insert tenant metadata guarded
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
  '${TENANT_CODE}',
  '${TENANT_SLUG}',
  '${TENANT_DISPLAY_NAME}',
  'active',
  now(),
  now()
WHERE NOT EXISTS (
  SELECT 1
  FROM platform.tenants
  WHERE slug = '${TENANT_SLUG}'
     OR business_code = '${TENANT_CODE}'
);

-- 5. Verification
SELECT 'tenant_schema_exists' AS check_name, count(*)::text AS check_value
FROM information_schema.schemata
WHERE schema_name = '${TENANT_SCHEMA}';

SELECT 'tenant_metadata_exists' AS check_name, count(*)::text AS check_value
FROM platform.tenants
WHERE slug = '${TENANT_SLUG}'
   OR business_code = '${TENANT_CODE}';

ROLLBACK;

-- Note:
-- This preview intentionally ends with ROLLBACK.
-- Later apply step will generate/execute a guarded COMMIT version only after approval.
SQL_EOF

{
  echo "# FAZ 4C — 4C-3D-FIX2 business_code Mapping"
  echo
  echo "## Amaç"
  echo
  echo "4C-3E dry-run hatasında eksik görülen business_code mapping eklendi."
  echo
  echo "---"
  echo
  echo "## Teşhis"
  echo
  echo "Zorunlu kolonlar:"
  echo
  echo "- business_code"
  echo "- name"
  echo "- slug"
  echo
  echo "name ve slug önceki SQL paketinde vardı."
  echo "business_code eksikti."
  echo
  echo "---"
  echo
  echo "## Yeni SQL paketi"
  echo
  echo "SQL_FILE=$SQL_FILE"
  echo
  echo "Yeni insert kolonları:"
  echo
  echo "- business_code"
  echo "- slug"
  echo "- name"
  echo "- status"
  echo "- created_at"
  echo "- updated_at"
  echo
  echo "---"
  echo
  echo "## Durum"
  echo
  echo "4C_3D_FIX2_MAPPING_STATUS=PASS"
  echo "4C_3D_FIX2_SQL_FILE_CREATED=YES"
  echo "4C_3D_FIX2_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
  echo "4C_3D_FIX2_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
  echo "4C_3D_FIX2_DB_WRITE_APPLIED=NO"
  echo "4C_3E_RETRY_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3D-FIX2 business_code Mapping Report"
  echo
  echo "Step: 4C-3D-FIX2"
  echo "Blok: business_code Mapping Fix"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3D_FIX2_MAPPING_STATUS=PASS"
  echo "4C_3D_FIX2_BUSINESS_CODE_COLUMN_EXISTS=$BUSINESS_CODE_EXISTS"
  echo "4C_3D_FIX2_SLUG_COLUMN_EXISTS=$SLUG_EXISTS"
  echo "4C_3D_FIX2_NAME_COLUMN_EXISTS=$NAME_EXISTS"
  echo "4C_3D_FIX2_SQL_FILE_CREATED=YES"
  echo "4C_3D_FIX2_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
  echo "4C_3D_FIX2_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
  echo "4C_3D_FIX2_DB_WRITE_APPLIED=NO"
  echo "4C_3E_RETRY_READY=YES"
  echo
  echo "## Sonuç"
  echo
  echo "Tenant SQL preview dosyası business_code mapping ile yeniden üretildi."
  echo "Kalıcı DB yazma yapılmadı."
  echo "4C-3E dry-run tekrar çalıştırılabilir."
} > "$REPORT_FILE"

echo "OK ✅ SQL preview yeniden uretildi: $SQL_FILE"
echo "OK ✅ Fix report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-3D-FIX2 OZET ====="
echo "4C_3D_FIX2_MAPPING_STATUS=PASS ✅"
echo "4C_3D_FIX2_EXISTING_TENANT_COUNT=$EXISTING_TENANT_COUNT"
echo "4C_3D_FIX2_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
echo "4C_3D_FIX2_DB_WRITE_APPLIED=NO ✅"
echo "4C_3E_RETRY_READY=YES ✅"
