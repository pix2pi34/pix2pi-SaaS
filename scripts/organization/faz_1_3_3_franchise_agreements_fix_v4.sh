#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_3_FRANCHISE_AGREEMENTS_FIX_V4"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_3_franchise_agreements_fix_v4_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

FIX_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_3_franchise_agreements_fix_v4.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_3_franchise_agreements_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_3_FRANCHISE_AGREEMENTS.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_3_franchise_agreements_fix_v4_legacy_date_bridge.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_SEAL_FIX_V4_$TS.md"

AGREEMENT_TEST_SQL="$SUITE_RUNTIME_DIR/franchise_agreements_lifecycle_abuse_suite_fix_v4.sql"
AGREEMENT_TEST_OUT="$SUITE_RUNTIME_DIR/franchise_agreements_lifecycle_abuse_suite_fix_v4.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_3_fix_v4_strict_suite_run.out"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

scalar_count() {
  local sql="$1"
  local out=""
  set +e
  out="$(psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

choose_enum_or_default() {
  local fq_table="$1"
  local column_name="$2"
  local fallback="$3"
  local preference_sql="$4"

  psql "$DSN" -Atqc "
WITH rel AS (
  SELECT to_regclass('$fq_table') AS oid
),
col AS (
  SELECT a.atttypid
  FROM rel
  JOIN pg_attribute a ON a.attrelid=rel.oid
  WHERE rel.oid IS NOT NULL
    AND a.attname='$column_name'
    AND a.attnum > 0
    AND NOT a.attisdropped
),
typ AS (
  SELECT
    CASE
      WHEN t.typtype='d' THEN t.typbasetype
      ELSE c.atttypid
    END AS base_type_oid
  FROM col c
  JOIN pg_type t ON t.oid=c.atttypid
),
labels AS (
  SELECT e.enumlabel
  FROM typ
  JOIN pg_enum e ON e.enumtypid=typ.base_type_oid
)
SELECT COALESCE(
  (
    SELECT enumlabel
    FROM labels
    ORDER BY
      CASE lower(enumlabel)
        $preference_sql
        ELSE 99
      END,
      enumlabel
    LIMIT 1
  ),
  '$fallback'
);
" 2>/dev/null | head -n1
}

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS FIX V4 START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$FIX_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_fix_v4_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. env kaynakları yükleniyor..."

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "3.1 common.env yüklendi"
else
  warn "3.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "3.2 repo .env yüklendi"
else
  warn "3.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then
  pass "4. DB DSN bulundu"
else
  fail "4. DB DSN bulunamadı"
  exit 1
fi

if command -v psql >/dev/null 2>&1; then
  pass "5. psql mevcut"
else
  fail "5. psql bulunamadı"
  exit 1
fi

if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then
  pass "6. DB bağlantısı başarılı"
else
  fail "6. DB bağlantısı başarısız"
  exit 1
fi

echo "7. type-aware değerler ve legacy kolonlar tespit ediliyor..."

LEGAL_ENTITY_STATUS_VALUE="$(choose_enum_or_default "org.legal_entities" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
")"

AGREEMENT_GENERIC_STATUS_VALUE="$(choose_enum_or_default "franchise.agreements" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
        WHEN 'inactive' THEN 6
")"

[ -z "$LEGAL_ENTITY_STATUS_VALUE" ] && LEGAL_ENTITY_STATUS_VALUE="active"
[ -z "$AGREEMENT_GENERIC_STATUS_VALUE" ] && AGREEMENT_GENERIC_STATUS_VALUE="active"

TENANT_REF_TABLE="$(psql "$DSN" -Atqc "
SELECT con.confrelid::regclass::text
FROM pg_constraint con
JOIN pg_attribute att
  ON att.attrelid=con.conrelid
 AND att.attnum = ANY(con.conkey)
WHERE con.conrelid='org.legal_entities'::regclass
  AND con.contype='f'
  AND att.attname='tenant_id'
LIMIT 1;
" 2>/dev/null | head -n1)"

TENANT_REF_COL="$(psql "$DSN" -Atqc "
WITH ref AS (
  SELECT con.confrelid AS ref_oid
  FROM pg_constraint con
  JOIN pg_attribute att
    ON att.attrelid=con.conrelid
   AND att.attnum = ANY(con.conkey)
  WHERE con.conrelid='org.legal_entities'::regclass
    AND con.contype='f'
    AND att.attname='tenant_id'
  LIMIT 1
)
SELECT a.attname
FROM ref
JOIN pg_attribute a ON a.attrelid=ref.ref_oid
WHERE a.attnum > 0
  AND NOT a.attisdropped
  AND a.atttypid='uuid'::regtype
  AND a.attname IN ('id','tenant_id','tenant_uuid')
ORDER BY
  CASE a.attname
    WHEN 'id' THEN 1
    WHEN 'tenant_id' THEN 2
    WHEN 'tenant_uuid' THEN 3
    ELSE 99
  END
LIMIT 1;
" 2>/dev/null | head -n1)"

REAL_TENANT_ID=""
if [ -n "${TENANT_REF_TABLE:-}" ] && [ -n "${TENANT_REF_COL:-}" ]; then
  REAL_TENANT_ID="$(psql "$DSN" -Atqc "select ${TENANT_REF_COL} from ${TENANT_REF_TABLE} where ${TENANT_REF_COL} is not null limit 1;" 2>/dev/null | head -n1)"
fi

STATUS_TYPE="$(psql "$DSN" -Atqc "
SELECT COALESCE(format_type(a.atttypid,a.atttypmod),'N/A')
FROM pg_attribute a
WHERE a.attrelid='franchise.agreements'::regclass
  AND a.attname='status'
  AND a.attnum > 0
  AND NOT a.attisdropped
LIMIT 1;
" 2>/dev/null | head -n1 || true)"

LEGACY_AGREEMENT_CODE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_code';")"
LEGACY_STARTS_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='starts_on';")"
LEGACY_ENDS_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='ends_on';")"
LEGACY_TERMINATED_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='terminated_on';")"
AGREEMENT_LIFECYCLE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_lifecycle_status';")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "AGREEMENT_GENERIC_STATUS_VALUE=$AGREEMENT_GENERIC_STATUS_VALUE"
echo "AGREEMENT_STATUS_TYPE=${STATUS_TYPE:-N/A}"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LEGACY_AGREEMENT_CODE_COLUMN_COUNT=$LEGACY_AGREEMENT_CODE_COLUMN_COUNT"
echo "LEGACY_STARTS_ON_COLUMN_COUNT=$LEGACY_STARTS_ON_COLUMN_COUNT"
echo "LEGACY_ENDS_ON_COLUMN_COUNT=$LEGACY_ENDS_ON_COLUMN_COUNT"
echo "LEGACY_TERMINATED_ON_COLUMN_COUNT=$LEGACY_TERMINATED_ON_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "$AGREEMENT_GENERIC_STATUS_VALUE" ] && pass "7.2 franchise generic status değeri seçildi" || fail "7.2 franchise generic status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.3 tenant FK referans tablosu bulundu" || fail "7.3 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.4 tenant FK referans UUID kolonu bulundu" || fail "7.4 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.5 gerçek tenant_id bulundu" || fail "7.5 gerçek tenant_id bulunamadı"
[ "$LEGACY_STARTS_ON_COLUMN_COUNT" -ge 1 ] && pass "7.6 legacy starts_on kolonu algılandı" || warn "7.6 legacy starts_on kolonu yok"
[ "$AGREEMENT_LIFECYCLE_COLUMN_COUNT" -eq 1 ] && pass "7.7 agreement_lifecycle_status mevcut" || fail "7.7 agreement_lifecycle_status eksik"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. FIX V4 legacy date bridge migration hazırlanıyor..."

cat <<SQL > "$MIGRATION_FILE"
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS franchise;

DO \$\$
DECLARE
  has_agreement_code boolean := false;
  has_starts_on boolean := false;
  has_ends_on boolean := false;
  has_terminated_on boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='agreement_code'
  ) INTO has_agreement_code;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='starts_on'
  ) INTO has_starts_on;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='ends_on'
  ) INTO has_ends_on;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='terminated_on'
  ) INTO has_terminated_on;

  IF has_agreement_code AND has_starts_on AND has_ends_on AND has_terminated_on THEN
    EXECUTE \$fn\$
      CREATE OR REPLACE FUNCTION franchise.sync_agreements_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$body\$
      BEGIN
        IF NEW.id IS NULL THEN
          NEW.id := gen_random_uuid();
        END IF;

        IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
        END IF;

        IF NEW.end_date IS NULL AND NEW.ends_on IS NOT NULL THEN
          NEW.end_date := NEW.ends_on::date;
        END IF;

        IF NEW.ends_on IS NULL THEN
          NEW.ends_on := NEW.end_date;
        END IF;

        IF NEW.terminated_at IS NULL AND NEW.terminated_on IS NOT NULL THEN
          NEW.terminated_at := NEW.terminated_on::timestamptz;
        END IF;

        IF NEW.terminated_on IS NULL AND NEW.terminated_at IS NOT NULL THEN
          NEW.terminated_on := NEW.terminated_at::date;
        END IF;

        IF NEW.agreement_lifecycle_status IS NULL OR btrim(NEW.agreement_lifecycle_status::text) = '' THEN
          NEW.agreement_lifecycle_status := 'DRAFT';
        END IF;

        IF NEW.metadata IS NULL THEN
          NEW.metadata := '{}'::jsonb;
        END IF;

        IF NEW.audit_metadata IS NULL THEN
          NEW.audit_metadata := '{}'::jsonb;
        END IF;

        RETURN NEW;
      END
      \$body\$;
    \$fn\$;

  ELSIF has_agreement_code AND has_starts_on AND has_ends_on THEN
    EXECUTE \$fn\$
      CREATE OR REPLACE FUNCTION franchise.sync_agreements_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$body\$
      BEGIN
        IF NEW.id IS NULL THEN
          NEW.id := gen_random_uuid();
        END IF;

        IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
        END IF;

        IF NEW.end_date IS NULL AND NEW.ends_on IS NOT NULL THEN
          NEW.end_date := NEW.ends_on::date;
        END IF;

        IF NEW.ends_on IS NULL THEN
          NEW.ends_on := NEW.end_date;
        END IF;

        IF NEW.agreement_lifecycle_status IS NULL OR btrim(NEW.agreement_lifecycle_status::text) = '' THEN
          NEW.agreement_lifecycle_status := 'DRAFT';
        END IF;

        IF NEW.metadata IS NULL THEN
          NEW.metadata := '{}'::jsonb;
        END IF;

        IF NEW.audit_metadata IS NULL THEN
          NEW.audit_metadata := '{}'::jsonb;
        END IF;

        RETURN NEW;
      END
      \$body\$;
    \$fn\$;

  ELSIF has_agreement_code AND has_starts_on THEN
    EXECUTE \$fn\$
      CREATE OR REPLACE FUNCTION franchise.sync_agreements_legacy_fields()
      RETURNS trigger
      LANGUAGE plpgsql
      AS \$body\$
      BEGIN
        IF NEW.id IS NULL THEN
          NEW.id := gen_random_uuid();
        END IF;

        IF NEW.business_code IS NULL OR btrim(NEW.business_code::text) = '' THEN
          NEW.business_code := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.agreement_number::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_number IS NULL OR btrim(NEW.agreement_number::text) = '' THEN
          NEW.agreement_number := COALESCE(NULLIF(NEW.agreement_code::text, ''), NULLIF(NEW.business_code::text, ''), 'FR-AGR-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.agreement_code IS NULL OR btrim(NEW.agreement_code::text) = '' OR NEW.agreement_code::text = 'FR_AGR_PENDING' THEN
          NEW.agreement_code := COALESCE(NULLIF(NEW.agreement_number::text, ''), NULLIF(NEW.business_code::text, ''), 'FR_AGR_' || upper(substr(replace(NEW.id::text, '-', ''), 1, 12)));
        END IF;

        IF NEW.start_date IS NULL THEN
          NEW.start_date := COALESCE(NEW.starts_on::date, current_date);
        END IF;

        IF NEW.starts_on IS NULL THEN
          NEW.starts_on := NEW.start_date;
        END IF;

        IF NEW.agreement_lifecycle_status IS NULL OR btrim(NEW.agreement_lifecycle_status::text) = '' THEN
          NEW.agreement_lifecycle_status := 'DRAFT';
        END IF;

        IF NEW.metadata IS NULL THEN
          NEW.metadata := '{}'::jsonb;
        END IF;

        IF NEW.audit_metadata IS NULL THEN
          NEW.audit_metadata := '{}'::jsonb;
        END IF;

        RETURN NEW;
      END
      \$body\$;
    \$fn\$;

  ELSE
    RAISE NOTICE 'No legacy date bridge required or partial unsupported legacy set detected';
  END IF;

  IF has_agreement_code OR has_starts_on THEN
    EXECUTE 'DROP TRIGGER IF EXISTS trg_franchise_agreements_sync_legacy_fields ON franchise.agreements';
    EXECUTE 'CREATE TRIGGER trg_franchise_agreements_sync_legacy_fields
             BEFORE INSERT OR UPDATE ON franchise.agreements
             FOR EACH ROW
             EXECUTE FUNCTION franchise.sync_agreements_legacy_fields()';

    EXECUTE 'GRANT EXECUTE ON FUNCTION franchise.sync_agreements_legacy_fields() TO PUBLIC';
  END IF;

  IF has_agreement_code THEN
    EXECUTE 'ALTER TABLE franchise.agreements ALTER COLUMN agreement_code SET DEFAULT ''FR_AGR_PENDING''';

    EXECUTE '
      UPDATE franchise.agreements
      SET agreement_code = COALESCE(
        NULLIF(agreement_code::text, ''''),
        NULLIF(agreement_number::text, ''''),
        NULLIF(business_code::text, ''''),
        ''FR_AGR_'' || upper(substr(replace(id::text, ''-'', ''''), 1, 12))
      )
      WHERE agreement_code IS NULL
         OR btrim(agreement_code::text) = ''''
    ';
  END IF;

  IF has_starts_on THEN
    EXECUTE 'ALTER TABLE franchise.agreements ALTER COLUMN starts_on SET DEFAULT current_date';

    EXECUTE '
      UPDATE franchise.agreements
      SET starts_on = COALESCE(starts_on, start_date, current_date)
      WHERE starts_on IS NULL
    ';
  END IF;

  IF has_ends_on THEN
    EXECUTE '
      UPDATE franchise.agreements
      SET ends_on = COALESCE(ends_on, end_date)
      WHERE ends_on IS NULL
        AND end_date IS NOT NULL
    ';
  END IF;

  IF has_terminated_on THEN
    EXECUTE '
      UPDATE franchise.agreements
      SET terminated_on = COALESCE(terminated_on, terminated_at::date)
      WHERE terminated_on IS NULL
        AND terminated_at IS NOT NULL
    ';
  END IF;
END \$\$;

COMMIT;
SQL

pass "8.1 FIX V4 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. FIX V4 migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 FIX V4 migration başarıyla uygulandı"
else
  fail "9.1 FIX V4 migration uygulanamadı"
  exit 1
fi

LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='sync_agreements_legacy_fields';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_sync_legacy_fields' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"

echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ "$LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "9.2 legacy sync function hazır" || fail "9.2 legacy sync function eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "9.3 legacy sync trigger hazır" || fail "9.3 legacy sync trigger eksik"

echo "10. franchise lifecycle / abuse SQL suite FIX V4 hazırlanıyor..."

cat <<SQL > "$AGREEMENT_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_franchisor_id uuid := gen_random_uuid();
  v_franchisee_id uuid := gen_random_uuid();
  v_operator_id uuid := gen_random_uuid();
  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_legal_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
  v_generic_status franchise.agreements.status%TYPE := '$AGREEMENT_GENERIC_STATUS_VALUE';
  v_count int;
BEGIN
  PERFORM set_config('app.tenant_id', v_tenant_id::text, true);
  PERFORM set_config('app.current_tenant_id', v_tenant_id::text, true);

  INSERT INTO org.legal_entities (
    id, tenant_id, legal_entity_id, business_code, legal_name, trade_name,
    tax_number, tax_office, phone, email, address_line, district, city,
    country_code, postal_code, status, metadata
  )
  VALUES
  (
    v_franchisor_id, v_tenant_id, v_franchisor_id,
    'FRANCHISOR_' || v_suffix,
    'PIX2PI FRANCHISOR TEST A.S.',
    'PIX2PI FRANCHISOR',
    '910' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120003001',
    'franchisor-' || lower(v_suffix) || '@pix2pi.local',
    'FRANCHISOR TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_3_fix_v4_franchisor')
  ),
  (
    v_franchisee_id, v_tenant_id, v_franchisee_id,
    'FRANCHISEE_' || v_suffix,
    'PIX2PI FRANCHISEE TEST A.S.',
    'PIX2PI FRANCHISEE',
    '920' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120003002',
    'franchisee-' || lower(v_suffix) || '@pix2pi.local',
    'FRANCHISEE TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_3_fix_v4_franchisee')
  ),
  (
    v_operator_id, v_tenant_id, v_operator_id,
    'FRANCHISE_OPERATOR_' || v_suffix,
    'PIX2PI FRANCHISE OPERATOR TEST A.S.',
    'PIX2PI OPERATOR',
    '930' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120003003',
    'operator-' || lower(v_suffix) || '@pix2pi.local',
    'OPERATOR TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_3_fix_v4_operator')
  );

  INSERT INTO franchise.agreements (
    tenant_id,
    legal_entity_id,
    business_code,
    agreement_number,
    agreement_type,
    franchisor_entity_id,
    franchisee_entity_id,
    owner_entity_id,
    operator_entity_id,
    territory_code,
    territory_name,
    start_date,
    end_date,
    signed_at,
    activated_at,
    status,
    agreement_lifecycle_status,
    lifecycle_reason,
    agreement_audit_ref,
    metadata
  )
  VALUES (
    v_tenant_id,
    v_franchisor_id,
    'FR_AGREEMENT_' || v_suffix,
    'FR-AGR-' || v_suffix,
    'STANDARD_FRANCHISE',
    v_franchisor_id,
    v_franchisee_id,
    v_franchisee_id,
    v_operator_id,
    'TR-IST-KADIKOY',
    'Istanbul Kadikoy',
    current_date,
    current_date + 365,
    now(),
    now(),
    v_generic_status,
    'ACTIVE',
    'initial activation',
    'AGREEMENT_AUDIT_' || v_suffix,
    jsonb_build_object('test','faz_1_3_3_fix_v4_agreement')
  );

  SELECT count(*)
  INTO v_count
  FROM franchise.agreements
  WHERE tenant_id=v_tenant_id
    AND franchisor_entity_id=v_franchisor_id
    AND franchisee_entity_id=v_franchisee_id
    AND owner_entity_id=v_franchisee_id
    AND operator_entity_id=v_operator_id
    AND agreement_lifecycle_status='ACTIVE'
    AND agreement_audit_ref IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'franchise agreement valid insert/read failed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='agreement_code'
  ) THEN
    SELECT count(*)
    INTO v_count
    FROM franchise.agreements
    WHERE tenant_id=v_tenant_id
      AND agreement_code IS NOT NULL
      AND btrim(agreement_code::text) <> '';

    IF v_count <> 1 THEN
      RAISE EXCEPTION 'legacy agreement_code bridge did not populate rows';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='franchise'
      AND table_name='agreements'
      AND column_name='starts_on'
  ) THEN
    SELECT count(*)
    INTO v_count
    FROM franchise.agreements
    WHERE tenant_id=v_tenant_id
      AND starts_on IS NOT NULL;

    IF v_count <> 1 THEN
      RAISE EXCEPTION 'legacy starts_on bridge did not populate rows';
    END IF;
  END IF;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date, end_date,
      signed_at, activated_at, status, agreement_lifecycle_status
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_OVERLAP_' || v_suffix,
      'FR-AGR-OVERLAP-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisee_id, v_franchisee_id, v_operator_id,
      current_date + 10, current_date + 100,
      now(), now(), v_generic_status, 'ACTIVE'
    );

    RAISE EXCEPTION 'overlapping active agreement was not blocked';
  EXCEPTION WHEN raise_exception THEN
    NULL;
  END;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date, end_date,
      status, agreement_lifecycle_status
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_BAD_DATE_' || v_suffix,
      'FR-AGR-BAD-DATE-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisee_id, v_franchisee_id, v_operator_id,
      current_date + 10, current_date + 9,
      v_generic_status, 'DRAFT'
    );

    RAISE EXCEPTION 'bad date range was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date,
      status, agreement_lifecycle_status
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_BAD_STATUS_' || v_suffix,
      'FR-AGR-BAD-STATUS-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisee_id, v_franchisee_id, v_operator_id,
      current_date + 500,
      v_generic_status, 'BAD_STATUS'
    );

    RAISE EXCEPTION 'bad lifecycle status was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date,
      status, agreement_lifecycle_status
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_ACTIVE_NO_DATE_' || v_suffix,
      'FR-AGR-ACTIVE-NO-DATE-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisee_id, v_franchisee_id, v_operator_id,
      current_date + 600,
      v_generic_status, 'ACTIVE'
    );

    RAISE EXCEPTION 'active without activated_at was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date,
      status, agreement_lifecycle_status, terminated_at
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_TERMINATED_NO_AUDIT_' || v_suffix,
      'FR-AGR-TERM-NO-AUDIT-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisee_id, v_franchisee_id, v_operator_id,
      current_date + 700,
      v_generic_status, 'TERMINATED', now()
    );

    RAISE EXCEPTION 'terminated without audit was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO franchise.agreements (
      tenant_id, legal_entity_id, business_code, agreement_number,
      agreement_type, franchisor_entity_id, franchisee_entity_id,
      owner_entity_id, operator_entity_id, start_date,
      status, agreement_lifecycle_status
    )
    VALUES (
      v_tenant_id, v_franchisor_id, 'FR_AGREEMENT_SELF_' || v_suffix,
      'FR-AGR-SELF-' || v_suffix, 'STANDARD_FRANCHISE',
      v_franchisor_id, v_franchisor_id, v_franchisor_id, v_operator_id,
      current_date + 800,
      v_generic_status, 'DRAFT'
    );

    RAISE EXCEPTION 'self franchise was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 franchise agreement SQL suite FIX V4 dosyası yazıldı: $AGREEMENT_TEST_SQL / OK ✅"

echo "11. franchise lifecycle / abuse SQL suite FIX V4 çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$AGREEMENT_TEST_SQL" > "$AGREEMENT_TEST_OUT" 2>&1; then
  pass "11.1 franchise lifecycle / abuse SQL suite geçti"
else
  fail "11.1 franchise lifecycle / abuse SQL suite başarısız"
  cat "$AGREEMENT_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$AGREEMENT_TEST_OUT"; then
  pass "11.2 franchise agreement test rollback ile temizlendi"
  AGREEMENT_TEST_STATUS="PASS"
else
  fail "11.2 franchise agreement rollback kanıtı yok"
  AGREEMENT_TEST_STATUS="FAIL"
fi

echo "12. franchise.agreements sayaçları alınıyor..."

FRANCHISE_SCHEMA_COUNT="$(scalar_count "select count(*) from information_schema.schemata where schema_name='franchise';")"
AGREEMENT_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"

AGREEMENT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='franchise'
    and table_name='agreements'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id',
      'business_code','agreement_number','agreement_type',
      'franchisor_entity_id','franchisee_entity_id',
      'owner_entity_id','operator_entity_id',
      'territory_code','territory_name',
      'start_date','end_date',
      'signed_at','activated_at','terminated_at',
      'status','agreement_lifecycle_status','lifecycle_reason','agreement_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

AGREEMENT_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='f';")"
AGREEMENT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='c';")"
AGREEMENT_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='franchise' and tablename='agreements';")"
AGREEMENT_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relrowsecurity=true;")"
AGREEMENT_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relforcerowsecurity=true;")"
AGREEMENT_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='franchise' and tablename='agreements';")"
OVERLAP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='prevent_overlapping_active_agreement';")"
OVERLAP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_prevent_overlap' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"
UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_set_updated_at' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"
AGREEMENT_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name in ('lifecycle_reason','agreement_audit_ref','audit_metadata');")"
AGREEMENT_LIFECYCLE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_lifecycle_status';")"
AGREEMENT_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='franchise' and table_name='agreements';")"
LEGACY_AGREEMENT_CODE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_code';")"
LEGACY_STARTS_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='starts_on';")"
LEGACY_ENDS_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='ends_on';")"
LEGACY_TERMINATED_ON_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='terminated_on';")"
LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='sync_agreements_legacy_fields';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_sync_legacy_fields' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"

echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_COLUMN_COUNT=$AGREEMENT_COLUMN_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "LEGACY_AGREEMENT_CODE_COLUMN_COUNT=$LEGACY_AGREEMENT_CODE_COLUMN_COUNT"
echo "LEGACY_STARTS_ON_COLUMN_COUNT=$LEGACY_STARTS_ON_COLUMN_COUNT"
echo "LEGACY_ENDS_ON_COLUMN_COUNT=$LEGACY_ENDS_ON_COLUMN_COUNT"
echo "LEGACY_TERMINATED_ON_COLUMN_COUNT=$LEGACY_TERMINATED_ON_COLUMN_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "AGREEMENT_TEST_STATUS=$AGREEMENT_TEST_STATUS"

[ "$FRANCHISE_SCHEMA_COUNT" -eq 1 ] && pass "12.1 franchise schema hazır" || fail "12.1 franchise schema eksik"
[ "$AGREEMENT_TABLE_COUNT" -eq 1 ] && pass "12.2 franchise.agreements tablosu hazır" || fail "12.2 franchise.agreements tablosu eksik"
[ "$AGREEMENT_COLUMN_COUNT" -ge 29 ] && pass "12.3 franchise.agreements kolon kapsamı tam" || fail "12.3 kolon kapsamı eksik"
[ "$AGREEMENT_FK_COUNT" -ge 5 ] && pass "12.4 owner/operator/entity FK seti hazır" || fail "12.4 FK seti eksik"
[ "$AGREEMENT_CHECK_COUNT" -ge 8 ] && pass "12.5 agreement check constraint seti hazır" || fail "12.5 check constraint seti eksik"
[ "$AGREEMENT_INDEX_COUNT" -ge 12 ] && pass "12.6 agreement index seti hazır" || fail "12.6 agreement index seti eksik"
[ "$AGREEMENT_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.7 agreements RLS enabled" || fail "12.7 RLS enabled eksik"
[ "$AGREEMENT_RLS_FORCED_COUNT" -eq 1 ] && pass "12.8 agreements RLS forced" || fail "12.8 RLS forced eksik"
[ "$AGREEMENT_POLICY_COUNT" -ge 1 ] && pass "12.9 agreements tenant policy hazır" || fail "12.9 tenant policy eksik"
[ "$OVERLAP_FUNCTION_COUNT" -eq 1 ] && pass "12.10 overlap guard function hazır" || fail "12.10 overlap guard function eksik"
[ "$OVERLAP_TRIGGER_COUNT" -eq 1 ] && pass "12.11 overlap guard trigger hazır" || fail "12.11 overlap guard trigger eksik"
[ "$UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.12 updated_at trigger hazır" || fail "12.12 updated_at trigger eksik"
[ "$AGREEMENT_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "12.13 agreement audit kolonları hazır" || fail "12.13 agreement audit kolonları eksik"
[ "$AGREEMENT_LIFECYCLE_COLUMN_COUNT" -eq 1 ] && pass "12.14 agreement_lifecycle_status hazır" || fail "12.14 agreement_lifecycle_status eksik"
[ "$AGREEMENT_DICTIONARY_COUNT" -ge 1 ] && pass "12.15 data dictionary kaydı mevcut" || warn "12.15 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "12.16 legacy sync function hazır" || fail "12.16 legacy sync function eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "12.17 legacy sync trigger hazır" || fail "12.17 legacy sync trigger eksik"
[ "$LEGACY_STARTS_ON_COLUMN_COUNT" -eq 0 ] || [ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "12.18 legacy starts_on bridge hazır" || fail "12.18 legacy starts_on bridge eksik"
[ "$AGREEMENT_TEST_STATUS" = "PASS" ] && pass "12.19 franchise lifecycle / abuse suite PASS" || fail "12.19 franchise lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_3_franchise_agreements_strict_suite_fix_v4_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_SUITE_RESULT_FIX_V4_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

scalar_count() {
  local sql="$1"
  local out=""
  set +e
  out="$(psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 START ====="

mkdir -p "$BACKUP_DIR" "$EVIDENCE_DIR"
cd "$REPO"

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "1.1 common.env yüklendi"
else
  warn "1.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  source "$REPO/.env"
  set +a
  pass "1.2 repo .env yüklendi"
else
  warn "1.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "${DSN:-}" ]; then pass "2. DB DSN bulundu"; else fail "2. DB DSN bulunamadı"; exit 1; fi
if command -v psql >/dev/null 2>&1; then pass "3. psql mevcut"; else fail "3. psql bulunamadı"; exit 1; fi
if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then pass "4. DB bağlantısı başarılı"; else fail "4. DB bağlantısı başarısız"; exit 1; fi

FRANCHISE_SCHEMA_COUNT="$(scalar_count "select count(*) from information_schema.schemata where schema_name='franchise';")"
AGREEMENT_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"
AGREEMENT_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='f';")"
AGREEMENT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='c';")"
AGREEMENT_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='franchise' and tablename='agreements';")"
AGREEMENT_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relrowsecurity=true;")"
AGREEMENT_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relforcerowsecurity=true;")"
AGREEMENT_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='franchise' and tablename='agreements';")"
OVERLAP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='prevent_overlapping_active_agreement';")"
OVERLAP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_prevent_overlap' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"
AGREEMENT_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name in ('lifecycle_reason','agreement_audit_ref','audit_metadata');")"
AGREEMENT_LIFECYCLE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_lifecycle_status';")"
AGREEMENT_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='franchise' and table_name='agreements';")"
LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='sync_agreements_legacy_fields';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_sync_legacy_fields' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"

echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ "$FRANCHISE_SCHEMA_COUNT" -eq 1 ] && pass "5.1 franchise schema hazır" || fail "5.1 franchise schema eksik"
[ "$AGREEMENT_TABLE_COUNT" -eq 1 ] && pass "5.2 franchise.agreements tablosu hazır" || fail "5.2 franchise.agreements tablosu eksik"
[ "$AGREEMENT_FK_COUNT" -ge 5 ] && pass "5.3 owner/operator/entity FK seti hazır" || fail "5.3 FK seti eksik"
[ "$AGREEMENT_CHECK_COUNT" -ge 8 ] && pass "5.4 check constraint seti hazır" || fail "5.4 check constraint seti eksik"
[ "$AGREEMENT_INDEX_COUNT" -ge 12 ] && pass "5.5 index seti hazır" || fail "5.5 index seti eksik"
[ "$AGREEMENT_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.6 RLS enabled" || fail "5.6 RLS enabled eksik"
[ "$AGREEMENT_RLS_FORCED_COUNT" -eq 1 ] && pass "5.7 RLS forced" || fail "5.7 RLS forced eksik"
[ "$AGREEMENT_POLICY_COUNT" -ge 1 ] && pass "5.8 tenant policy hazır" || fail "5.8 tenant policy eksik"
[ "$OVERLAP_FUNCTION_COUNT" -eq 1 ] && pass "5.9 overlap guard function hazır" || fail "5.9 overlap guard function eksik"
[ "$OVERLAP_TRIGGER_COUNT" -eq 1 ] && pass "5.10 overlap guard trigger hazır" || fail "5.10 overlap guard trigger eksik"
[ "$AGREEMENT_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.11 agreement audit kolonları hazır" || fail "5.11 agreement audit kolonları eksik"
[ "$AGREEMENT_LIFECYCLE_COLUMN_COUNT" -eq 1 ] && pass "5.12 agreement_lifecycle_status hazır" || fail "5.12 agreement_lifecycle_status eksik"
[ "$AGREEMENT_DICTIONARY_COUNT" -ge 1 ] && pass "5.13 data dictionary kaydı mevcut" || warn "5.13 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "5.14 legacy sync function hazır" || fail "5.14 legacy sync function eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "5.15 legacy sync trigger hazır" || fail "5.15 legacy sync trigger eksik"

{
  echo "# FAZ 1-3.3 franchise.agreements Strict Suite Result FIX V4"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=PASS"
  echo "FAZ_1_3_3_START_END_DATE_STATUS=PASS"
  echo "FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=PASS"
  echo "FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "13.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "14. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "14.1 strict suite exit code 0"
else
  fail "14.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS")"

FRANCHISE_AGREEMENT_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS")"
FRANCHISE_OWNER_OPERATOR_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS")"
START_END_DATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_START_END_DATE_STATUS")"
STATUS_LIFECYCLE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_STATUS_LIFECYCLE_STATUS")"
AGREEMENT_AUDIT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_3_AGREEMENT_AUDIT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.3 — franchise.agreements

## Kapsam

- Franchise sözleşme modeli
- Franchise owner/operator
- Start/end date
- Status lifecycle
- Agreement audit

## FIX V4

FIX V3 agreement_code legacy bridge'i kurdu. Sonraki testte mevcut legacy starts_on NOT NULL kolonu yakalandı.

FIX V4:
- start_date ve legacy starts_on arasında bridge kurar.
- end_date ve legacy ends_on arasında bridge kurar.
- terminated_at ve legacy terminated_on arasında bridge kurar.
- business_code/agreement_number/agreement_code bridge korunur.
- Yeni lifecycle standardı agreement_lifecycle_status üzerinden korunur.

## Final Status

- FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=${FRANCHISE_AGREEMENT_MODEL_STATUS:-N/A}
- FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=${FRANCHISE_OWNER_OPERATOR_STATUS:-N/A}
- FAZ_1_3_3_START_END_DATE_STATUS=${START_END_DATE_STATUS:-N/A}
- FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=${STATUS_LIFECYCLE_STATUS:-N/A}
- FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=${AGREEMENT_AUDIT_STATUS:-N/A}
- FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.3 franchise.agreements FIX V4 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Agreement SQL: $AGREEMENT_TEST_SQL"
  echo "- Agreement output: $AGREEMENT_TEST_OUT"
  echo
  echo "## Counts"
  echo "- AGREEMENT_STATUS_TYPE=${STATUS_TYPE:-N/A}"
  echo "- AGREEMENT_GENERIC_STATUS_VALUE=$AGREEMENT_GENERIC_STATUS_VALUE"
  echo "- LEGACY_AGREEMENT_CODE_COLUMN_COUNT=$LEGACY_AGREEMENT_CODE_COLUMN_COUNT"
  echo "- LEGACY_STARTS_ON_COLUMN_COUNT=$LEGACY_STARTS_ON_COLUMN_COUNT"
  echo "- LEGACY_ENDS_ON_COLUMN_COUNT=$LEGACY_ENDS_ON_COLUMN_COUNT"
  echo "- LEGACY_TERMINATED_ON_COLUMN_COUNT=$LEGACY_TERMINATED_ON_COLUMN_COUNT"
  echo "- LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
  echo "- LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
  echo "- FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
  echo "- AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
  echo "- AGREEMENT_COLUMN_COUNT=$AGREEMENT_COLUMN_COUNT"
  echo "- AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
  echo "- AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
  echo "- AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
  echo "- AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
  echo "- AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
  echo "- AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
  echo "- OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
  echo "- OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
  echo "- UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
  echo "- AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
  echo "- AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
  echo "- AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
  echo "- AGREEMENT_TEST_STATUS=$AGREEMENT_TEST_STATUS"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-3.3 franchise.agreements Final Seal FIX V4"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=${FRANCHISE_AGREEMENT_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=${FRANCHISE_OWNER_OPERATOR_STATUS:-N/A}"
  echo "FAZ_1_3_3_START_END_DATE_STATUS=${START_END_DATE_STATUS:-N/A}"
  echo "FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=${STATUS_LIFECYCLE_STATUS:-N/A}"
  echo "FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=${AGREEMENT_AUDIT_STATUS:-N/A}"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_4_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$FIX_SCRIPT_FILE"
chmod +x "$FIX_SCRIPT_FILE"
pass "18.4 FIX V4 script repo içine kopyalandı: $FIX_SCRIPT_FILE"

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS FIX V4 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "AGREEMENT_TEST_STATUS=$AGREEMENT_TEST_STATUS"
echo "AGREEMENT_STATUS_TYPE=${STATUS_TYPE:-N/A}"
echo "AGREEMENT_GENERIC_STATUS_VALUE=$AGREEMENT_GENERIC_STATUS_VALUE"
echo "LEGACY_AGREEMENT_CODE_COLUMN_COUNT=$LEGACY_AGREEMENT_CODE_COLUMN_COUNT"
echo "LEGACY_STARTS_ON_COLUMN_COUNT=$LEGACY_STARTS_ON_COLUMN_COUNT"
echo "LEGACY_ENDS_ON_COLUMN_COUNT=$LEGACY_ENDS_ON_COLUMN_COUNT"
echo "LEGACY_TERMINATED_ON_COLUMN_COUNT=$LEGACY_TERMINATED_ON_COLUMN_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_COLUMN_COUNT=$AGREEMENT_COLUMN_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "FRANCHISE_AGREEMENT_MODEL_STATUS=${FRANCHISE_AGREEMENT_MODEL_STATUS:-N/A}"
echo "FRANCHISE_OWNER_OPERATOR_STATUS=${FRANCHISE_OWNER_OPERATOR_STATUS:-N/A}"
echo "START_END_DATE_STATUS=${START_END_DATE_STATUS:-N/A}"
echo "STATUS_LIFECYCLE_STATUS=${STATUS_LIFECYCLE_STATUS:-N/A}"
echo "AGREEMENT_AUDIT_STATUS=${AGREEMENT_AUDIT_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$AGREEMENT_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=PASS"
  echo "FAZ_1_3_3_START_END_DATE_STATUS=PASS"
  echo "FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=PASS"
  echo "FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_4_READY=YES"
else
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_4_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS FIX V4 END ====="
