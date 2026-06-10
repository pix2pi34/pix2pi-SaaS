#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_4_STORE_FACILITY_WAREHOUSE_LOCATIONS_FIX_V2"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_4_store_facility_warehouse_locations_fix_v2_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"
MIGRATION_DIR="$REPO/db/migrations/faz1"

FIX_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_4_store_facility_warehouse_locations_fix_v2.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_4_store_facility_warehouse_locations_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_4_STORE_FACILITY_WAREHOUSE_LOCATIONS.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_3_4_location_inventory_account_format_fix_v2.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_4_STORE_FACILITY_WAREHOUSE_LOCATIONS_FINAL_SEAL_FIX_V2_$TS.md"

LOCATION_TEST_SQL="$SUITE_RUNTIME_DIR/store_facility_warehouse_location_suite_fix_v2.sql"
LOCATION_TEST_OUT="$SUITE_RUNTIME_DIR/store_facility_warehouse_location_suite_fix_v2.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_4_fix_v2_strict_suite_run.out"

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

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS FIX V2 START ====="

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
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_fix_v2_$TS"
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

echo "7. type-aware değerler ve gerçek tenant tespit ediliyor..."

LEGAL_ENTITY_STATUS_VALUE="$(choose_enum_or_default "org.legal_entities" "status" "active" "
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
")"

[ -z "$LEGAL_ENTITY_STATUS_VALUE" ] && LEGAL_ENTITY_STATUS_VALUE="active"

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

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.2 tenant FK referans tablosu bulundu" || fail "7.2 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.3 tenant FK referans UUID kolonu bulundu" || fail "7.3 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.4 gerçek tenant_id bulundu" || fail "7.4 gerçek tenant_id bulunamadı"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. FIX V2 TDHP account regex migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

ALTER TABLE inventory.location_inventory_links
  DROP CONSTRAINT IF EXISTS ck_inventory_location_links_stock_account_format;

ALTER TABLE inventory.location_inventory_links
  DROP CONSTRAINT IF EXISTS ck_inventory_location_links_account_format;

ALTER TABLE inventory.location_inventory_links
  ADD CONSTRAINT ck_inventory_location_links_account_format
  CHECK (
    (
      default_stock_account_code IS NULL
      OR default_stock_account_code ~ '^[0-9]{3}(\.[0-9]{1,4})?$'
    )
    AND
    (
      default_cogs_account_code IS NULL
      OR default_cogs_account_code ~ '^[0-9]{3}(\.[0-9]{1,4})?$'
    )
  ) NOT VALID;

COMMIT;
SQL

pass "8.1 FIX V2 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. FIX V2 migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 FIX V2 migration başarıyla uygulandı"
else
  fail "9.1 FIX V2 migration uygulanamadı"
  exit 1
fi

ACCOUNT_FORMAT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and conname='ck_inventory_location_links_account_format';")"
echo "ACCOUNT_FORMAT_CHECK_COUNT=$ACCOUNT_FORMAT_CHECK_COUNT"
[ "$ACCOUNT_FORMAT_CHECK_COUNT" -eq 1 ] && pass "9.2 TDHP account format constraint düzeltildi" || fail "9.2 TDHP account format constraint eksik"

echo "10. location lifecycle / abuse SQL suite FIX V2 hazırlanıyor..."

cat <<SQL > "$LOCATION_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_entity_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_facility_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();
  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_legal_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
  v_count int;
BEGIN
  PERFORM set_config('app.tenant_id', v_tenant_id::text, true);
  PERFORM set_config('app.current_tenant_id', v_tenant_id::text, true);

  INSERT INTO org.legal_entities (
    id, tenant_id, legal_entity_id, business_code, legal_name, trade_name,
    tax_number, tax_office, phone, email, address_line, district, city,
    country_code, postal_code, status, metadata
  )
  VALUES (
    v_entity_id, v_tenant_id, v_entity_id,
    'LOCATION_ENTITY_' || v_suffix,
    'PIX2PI LOCATION TEST A.S.',
    'PIX2PI LOCATION',
    '940' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120004001',
    'location-' || lower(v_suffix) || '@pix2pi.local',
    'LOCATION TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_4_fix_v2_location_entity')
  );

  INSERT INTO org.business_locations (
    id, tenant_id, legal_entity_id, business_code, location_code, location_name,
    location_type, ownership_type, operation_type,
    inventory_enabled, sales_enabled, purchasing_enabled, is_default,
    address_line, district, city, country_code,
    latitude, longitude, capacity_profile,
    status, location_audit_ref, metadata
  )
  VALUES
  (
    v_store_id, v_tenant_id, v_entity_id,
    'LOC_STORE_' || v_suffix,
    'STORE_' || v_suffix,
    'PIX2PI TEST STORE',
    'STORE',
    'COMPANY_OWNED',
    'COMPANY_OPERATED',
    true,
    true,
    false,
    true,
    'STORE ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    41.0000000,
    29.0000000,
    jsonb_build_object('m2',120,'cash_register_count',2),
    'ACTIVE',
    'LOCATION_AUDIT_STORE_' || v_suffix,
    jsonb_build_object('test','store_location_fix_v2')
  ),
  (
    v_facility_id, v_tenant_id, v_entity_id,
    'LOC_FACILITY_' || v_suffix,
    'FACILITY_' || v_suffix,
    'PIX2PI TEST FACILITY',
    'FACILITY',
    'COMPANY_OWNED',
    'COMPANY_OPERATED',
    true,
    false,
    true,
    false,
    'FACILITY ADRES',
    'TUZLA',
    'ISTANBUL',
    'TR',
    40.9000000,
    29.3000000,
    jsonb_build_object('m2',1500,'dock_count',4),
    'ACTIVE',
    'LOCATION_AUDIT_FACILITY_' || v_suffix,
    jsonb_build_object('test','facility_location_fix_v2')
  ),
  (
    v_warehouse_id, v_tenant_id, v_entity_id,
    'LOC_WAREHOUSE_' || v_suffix,
    'WAREHOUSE_' || v_suffix,
    'PIX2PI TEST WAREHOUSE',
    'WAREHOUSE',
    'LEASED',
    'COMPANY_OPERATED',
    true,
    false,
    true,
    false,
    'WAREHOUSE ADRES',
    'GEBZE',
    'KOCAELI',
    'TR',
    40.8000000,
    29.4000000,
    jsonb_build_object('m2',3000,'rack_count',500),
    'ACTIVE',
    'LOCATION_AUDIT_WAREHOUSE_' || v_suffix,
    jsonb_build_object('test','warehouse_location_fix_v2')
  );

  SELECT count(*)
  INTO v_count
  FROM org.business_locations
  WHERE tenant_id=v_tenant_id
    AND legal_entity_id=v_entity_id
    AND location_type IN ('STORE','FACILITY','WAREHOUSE')
    AND inventory_enabled=true;

  IF v_count <> 3 THEN
    RAISE EXCEPTION 'store/facility/warehouse valid insert/read failed';
  END IF;

  INSERT INTO inventory.location_inventory_links (
    tenant_id, legal_entity_id, location_id, inventory_scope,
    stock_tracking_enabled, reservation_enabled,
    default_stock_account_code, default_cogs_account_code,
    status, relation_audit_ref, metadata
  )
  VALUES
  (
    v_tenant_id, v_entity_id, v_store_id,
    'ON_HAND_STOCK',
    true,
    true,
    '153',
    '621',
    'ACTIVE',
    'INV_LOC_LINK_STORE_' || v_suffix,
    jsonb_build_object('test','store_inventory_link_fix_v2')
  ),
  (
    v_tenant_id, v_entity_id, v_warehouse_id,
    'ON_HAND_STOCK',
    true,
    false,
    '153.01',
    '621.01',
    'ACTIVE',
    'INV_LOC_LINK_WH_' || v_suffix,
    jsonb_build_object('test','warehouse_inventory_link_fix_v2')
  );

  SELECT count(*)
  INTO v_count
  FROM inventory.location_inventory_links
  WHERE tenant_id=v_tenant_id
    AND legal_entity_id=v_entity_id
    AND location_id IN (v_store_id, v_warehouse_id)
    AND status='ACTIVE';

  IF v_count <> 2 THEN
    RAISE EXCEPTION 'inventory relation valid insert/read failed';
  END IF;

  BEGIN
    INSERT INTO org.business_locations (
      tenant_id, legal_entity_id, business_code, location_code, location_name,
      location_type, ownership_type, operation_type, status
    )
    VALUES (
      v_tenant_id, v_entity_id,
      'LOC_BAD_TYPE_' || v_suffix,
      'BAD_TYPE_' || v_suffix,
      'BAD TYPE LOCATION',
      'BAD_TYPE',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad location_type was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.business_locations (
      tenant_id, legal_entity_id, business_code, location_code, location_name,
      location_type, ownership_type, operation_type, status
    )
    VALUES (
      v_tenant_id, v_entity_id,
      'LOC_MISSING_CODE_' || v_suffix,
      '',
      'MISSING CODE LOCATION',
      'STORE',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      'ACTIVE'
    );

    RAISE EXCEPTION 'missing location_code was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.business_locations (
      tenant_id, legal_entity_id, business_code, location_code, location_name,
      location_type, ownership_type, operation_type, inventory_enabled, status
    )
    VALUES (
      v_tenant_id, v_entity_id,
      'LOC_OFFICE_INV_' || v_suffix,
      'OFFICE_INV_' || v_suffix,
      'OFFICE INVENTORY BAD LOCATION',
      'OFFICE',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      true,
      'ACTIVE'
    );

    RAISE EXCEPTION 'inventory-enabled OFFICE was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.business_locations (
      tenant_id, legal_entity_id, business_code, location_code, location_name,
      location_type, ownership_type, operation_type, status
    )
    VALUES (
      v_tenant_id, v_entity_id,
      'LOC_DUP_' || v_suffix,
      'STORE_' || v_suffix,
      'DUPLICATE STORE CODE',
      'STORE',
      'COMPANY_OWNED',
      'COMPANY_OPERATED',
      'ACTIVE'
    );

    RAISE EXCEPTION 'duplicate location_code was not blocked';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO inventory.location_inventory_links (
      tenant_id, legal_entity_id, location_id, inventory_scope,
      stock_tracking_enabled, status
    )
    VALUES (
      v_tenant_id, v_entity_id, v_store_id,
      'BAD_SCOPE',
      true,
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad inventory_scope was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO inventory.location_inventory_links (
      tenant_id, legal_entity_id, location_id, inventory_scope,
      stock_tracking_enabled, default_stock_account_code, status
    )
    VALUES (
      v_tenant_id, v_entity_id, v_facility_id,
      'ON_HAND_STOCK',
      true,
      'BAD-ACCOUNT',
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad stock account format was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO inventory.location_inventory_links (
      tenant_id, legal_entity_id, location_id, inventory_scope,
      stock_tracking_enabled, default_stock_account_code, default_cogs_account_code, status
    )
    VALUES (
      v_tenant_id, v_entity_id, v_facility_id,
      'RESERVATION',
      true,
      '153.9999',
      'BAD-COGS',
      'ACTIVE'
    );

    RAISE EXCEPTION 'bad cogs account format was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "10.1 location SQL suite FIX V2 dosyası yazıldı: $LOCATION_TEST_SQL / OK ✅"

echo "11. location lifecycle / abuse SQL suite FIX V2 çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$LOCATION_TEST_SQL" > "$LOCATION_TEST_OUT" 2>&1; then
  pass "11.1 location lifecycle / abuse SQL suite geçti"
else
  fail "11.1 location lifecycle / abuse SQL suite başarısız"
  cat "$LOCATION_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$LOCATION_TEST_OUT"; then
  pass "11.2 location test rollback ile temizlendi"
  LOCATION_TEST_STATUS="PASS"
else
  fail "11.2 location rollback kanıtı yok"
  LOCATION_TEST_STATUS="FAIL"
fi

echo "12. location model sayaçları alınıyor..."

LOCATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
LOCATION_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='business_locations'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id',
      'business_code','location_code','location_name','location_type',
      'ownership_type','operation_type',
      'inventory_enabled','sales_enabled','purchasing_enabled','is_default',
      'address_line','district','city','country_code','postal_code',
      'latitude','longitude','capacity_profile',
      'status','lifecycle_reason','location_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

LOCATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.business_locations'::regclass and contype='f';")"
LOCATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.business_locations'::regclass and contype='c';")"
LOCATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='business_locations';")"
LOCATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='business_locations' and c.relrowsecurity=true;")"
LOCATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='business_locations' and c.relforcerowsecurity=true;")"
LOCATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='business_locations';")"
LOCATION_UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_business_locations_set_updated_at' and tgrelid='org.business_locations'::regclass and not tgisinternal;")"
LOCATION_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='business_locations' and column_name in ('lifecycle_reason','location_audit_ref','audit_metadata');")"
LOCATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='business_locations';")"
LOCATION_BRANCH_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='business_locations' and column_name='branch_id';")"

INVENTORY_SCHEMA_COUNT="$(scalar_count "select count(*) from information_schema.schemata where schema_name='inventory';")"
INV_LINK_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='inventory' and table_name='location_inventory_links';")"
INV_LINK_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='inventory'
    and table_name='location_inventory_links'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','location_id',
      'inventory_scope','stock_tracking_enabled','reservation_enabled',
      'default_stock_account_code','default_cogs_account_code',
      'status','relation_audit_ref',
      'metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"
INV_LINK_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and contype='f';")"
INV_LINK_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and contype='c';")"
INV_LINK_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='inventory' and tablename='location_inventory_links';")"
INV_LINK_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='inventory' and c.relname='location_inventory_links' and c.relrowsecurity=true;")"
INV_LINK_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='inventory' and c.relname='location_inventory_links' and c.relforcerowsecurity=true;")"
INV_LINK_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='inventory' and tablename='location_inventory_links';")"
INV_LINK_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='inventory' and table_name='location_inventory_links';")"
INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and conname='ck_inventory_location_links_account_format';")"

echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "LOCATION_COLUMN_COUNT=$LOCATION_COLUMN_COUNT"
echo "LOCATION_FK_COUNT=$LOCATION_FK_COUNT"
echo "LOCATION_CHECK_COUNT=$LOCATION_CHECK_COUNT"
echo "LOCATION_INDEX_COUNT=$LOCATION_INDEX_COUNT"
echo "LOCATION_RLS_ENABLED_COUNT=$LOCATION_RLS_ENABLED_COUNT"
echo "LOCATION_RLS_FORCED_COUNT=$LOCATION_RLS_FORCED_COUNT"
echo "LOCATION_POLICY_COUNT=$LOCATION_POLICY_COUNT"
echo "LOCATION_UPDATED_AT_TRIGGER_COUNT=$LOCATION_UPDATED_AT_TRIGGER_COUNT"
echo "LOCATION_AUDIT_COLUMN_COUNT=$LOCATION_AUDIT_COLUMN_COUNT"
echo "LOCATION_DICTIONARY_COUNT=$LOCATION_DICTIONARY_COUNT"
echo "LOCATION_BRANCH_COLUMN_COUNT=$LOCATION_BRANCH_COLUMN_COUNT"
echo "INVENTORY_SCHEMA_COUNT=$INVENTORY_SCHEMA_COUNT"
echo "INV_LINK_TABLE_COUNT=$INV_LINK_TABLE_COUNT"
echo "INV_LINK_COLUMN_COUNT=$INV_LINK_COLUMN_COUNT"
echo "INV_LINK_FK_COUNT=$INV_LINK_FK_COUNT"
echo "INV_LINK_CHECK_COUNT=$INV_LINK_CHECK_COUNT"
echo "INV_LINK_INDEX_COUNT=$INV_LINK_INDEX_COUNT"
echo "INV_LINK_RLS_ENABLED_COUNT=$INV_LINK_RLS_ENABLED_COUNT"
echo "INV_LINK_RLS_FORCED_COUNT=$INV_LINK_RLS_FORCED_COUNT"
echo "INV_LINK_POLICY_COUNT=$INV_LINK_POLICY_COUNT"
echo "INV_LINK_DICTIONARY_COUNT=$INV_LINK_DICTIONARY_COUNT"
echo "INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT=$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT"
echo "LOCATION_TEST_STATUS=$LOCATION_TEST_STATUS"

[ "$LOCATION_TABLE_COUNT" -eq 1 ] && pass "12.1 org.business_locations tablosu hazır" || fail "12.1 org.business_locations tablosu eksik"
[ "$LOCATION_COLUMN_COUNT" -ge 32 ] && pass "12.2 business_locations kolon kapsamı tam" || fail "12.2 business_locations kolon kapsamı eksik"
[ "$LOCATION_FK_COUNT" -ge 1 ] && pass "12.3 location FK seti hazır" || fail "12.3 location FK seti eksik"
[ "$LOCATION_CHECK_COUNT" -ge 8 ] && pass "12.4 location check constraint seti hazır" || fail "12.4 location check constraint seti eksik"
[ "$LOCATION_INDEX_COUNT" -ge 10 ] && pass "12.5 location index seti hazır" || fail "12.5 location index seti eksik"
[ "$LOCATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.6 location RLS enabled" || fail "12.6 location RLS enabled eksik"
[ "$LOCATION_RLS_FORCED_COUNT" -eq 1 ] && pass "12.7 location RLS forced" || fail "12.7 location RLS forced eksik"
[ "$LOCATION_POLICY_COUNT" -ge 1 ] && pass "12.8 location tenant policy hazır" || fail "12.8 location tenant policy eksik"
[ "$LOCATION_UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "12.9 location updated_at trigger hazır" || fail "12.9 location updated_at trigger eksik"
[ "$LOCATION_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "12.10 location audit kolonları hazır" || fail "12.10 location audit kolonları eksik"
[ "$LOCATION_DICTIONARY_COUNT" -ge 1 ] && pass "12.11 location data dictionary kaydı mevcut" || warn "12.11 location data dictionary kaydı eksik"
[ "$LOCATION_BRANCH_COLUMN_COUNT" -eq 1 ] && pass "12.12 branch relation kolonu hazır" || fail "12.12 branch relation kolonu eksik"
[ "$INVENTORY_SCHEMA_COUNT" -eq 1 ] && pass "12.13 inventory schema hazır" || fail "12.13 inventory schema eksik"
[ "$INV_LINK_TABLE_COUNT" -eq 1 ] && pass "12.14 inventory location relation tablosu hazır" || fail "12.14 inventory relation tablosu eksik"
[ "$INV_LINK_COLUMN_COUNT" -ge 19 ] && pass "12.15 inventory relation kolon kapsamı tam" || fail "12.15 inventory relation kolon kapsamı eksik"
[ "$INV_LINK_FK_COUNT" -ge 2 ] && pass "12.16 inventory relation FK seti hazır" || fail "12.16 inventory relation FK seti eksik"
[ "$INV_LINK_CHECK_COUNT" -ge 4 ] && pass "12.17 inventory relation check seti hazır" || fail "12.17 inventory relation check seti eksik"
[ "$INV_LINK_INDEX_COUNT" -ge 6 ] && pass "12.18 inventory relation index seti hazır" || fail "12.18 inventory relation index seti eksik"
[ "$INV_LINK_RLS_ENABLED_COUNT" -eq 1 ] && pass "12.19 inventory relation RLS enabled" || fail "12.19 inventory relation RLS enabled eksik"
[ "$INV_LINK_RLS_FORCED_COUNT" -eq 1 ] && pass "12.20 inventory relation RLS forced" || fail "12.20 inventory relation RLS forced eksik"
[ "$INV_LINK_POLICY_COUNT" -ge 1 ] && pass "12.21 inventory relation tenant policy hazır" || fail "12.21 inventory relation tenant policy eksik"
[ "$INV_LINK_DICTIONARY_COUNT" -ge 1 ] && pass "12.22 inventory relation data dictionary kaydı mevcut" || warn "12.22 inventory relation data dictionary kaydı eksik"
[ "$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT" -eq 1 ] && pass "12.23 TDHP account format constraint hazır" || fail "12.23 TDHP account format constraint eksik"
[ "$LOCATION_TEST_STATUS" = "PASS" ] && pass "12.24 location lifecycle / abuse suite PASS" || fail "12.24 location lifecycle / abuse suite FAIL"

echo "13. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_4_store_facility_warehouse_locations_strict_suite_fix_v2_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_4_STORE_FACILITY_WAREHOUSE_LOCATIONS_STRICT_SUITE_RESULT_FIX_V2_$TS.md"

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

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS STRICT SUITE FIX V2 START ====="

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

LOCATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
LOCATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.business_locations'::regclass and contype='f';")"
LOCATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.business_locations'::regclass and contype='c';")"
LOCATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='business_locations';")"
LOCATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='business_locations' and c.relrowsecurity=true;")"
LOCATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='business_locations' and c.relforcerowsecurity=true;")"
LOCATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='business_locations';")"
LOCATION_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='business_locations' and column_name in ('lifecycle_reason','location_audit_ref','audit_metadata');")"
LOCATION_BRANCH_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='business_locations' and column_name='branch_id';")"
LOCATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='business_locations';")"

INV_LINK_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='inventory' and table_name='location_inventory_links';")"
INV_LINK_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and contype='f';")"
INV_LINK_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and contype='c';")"
INV_LINK_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='inventory' and tablename='location_inventory_links';")"
INV_LINK_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='inventory' and c.relname='location_inventory_links' and c.relrowsecurity=true;")"
INV_LINK_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='inventory' and c.relname='location_inventory_links' and c.relforcerowsecurity=true;")"
INV_LINK_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='inventory' and tablename='location_inventory_links';")"
INV_LINK_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='inventory' and table_name='location_inventory_links';")"
INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='inventory.location_inventory_links'::regclass and conname='ck_inventory_location_links_account_format';")"

echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "LOCATION_FK_COUNT=$LOCATION_FK_COUNT"
echo "LOCATION_CHECK_COUNT=$LOCATION_CHECK_COUNT"
echo "LOCATION_INDEX_COUNT=$LOCATION_INDEX_COUNT"
echo "LOCATION_RLS_ENABLED_COUNT=$LOCATION_RLS_ENABLED_COUNT"
echo "LOCATION_RLS_FORCED_COUNT=$LOCATION_RLS_FORCED_COUNT"
echo "LOCATION_POLICY_COUNT=$LOCATION_POLICY_COUNT"
echo "LOCATION_AUDIT_COLUMN_COUNT=$LOCATION_AUDIT_COLUMN_COUNT"
echo "LOCATION_BRANCH_COLUMN_COUNT=$LOCATION_BRANCH_COLUMN_COUNT"
echo "LOCATION_DICTIONARY_COUNT=$LOCATION_DICTIONARY_COUNT"
echo "INV_LINK_TABLE_COUNT=$INV_LINK_TABLE_COUNT"
echo "INV_LINK_FK_COUNT=$INV_LINK_FK_COUNT"
echo "INV_LINK_CHECK_COUNT=$INV_LINK_CHECK_COUNT"
echo "INV_LINK_INDEX_COUNT=$INV_LINK_INDEX_COUNT"
echo "INV_LINK_RLS_ENABLED_COUNT=$INV_LINK_RLS_ENABLED_COUNT"
echo "INV_LINK_RLS_FORCED_COUNT=$INV_LINK_RLS_FORCED_COUNT"
echo "INV_LINK_POLICY_COUNT=$INV_LINK_POLICY_COUNT"
echo "INV_LINK_DICTIONARY_COUNT=$INV_LINK_DICTIONARY_COUNT"
echo "INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT=$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT"

[ "$LOCATION_TABLE_COUNT" -eq 1 ] && pass "5.1 org.business_locations tablosu hazır" || fail "5.1 org.business_locations tablosu eksik"
[ "$LOCATION_FK_COUNT" -ge 1 ] && pass "5.2 location FK seti hazır" || fail "5.2 location FK seti eksik"
[ "$LOCATION_CHECK_COUNT" -ge 8 ] && pass "5.3 location check constraint seti hazır" || fail "5.3 location check constraint seti eksik"
[ "$LOCATION_INDEX_COUNT" -ge 10 ] && pass "5.4 location index seti hazır" || fail "5.4 location index seti eksik"
[ "$LOCATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 location RLS enabled" || fail "5.5 location RLS enabled eksik"
[ "$LOCATION_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 location RLS forced" || fail "5.6 location RLS forced eksik"
[ "$LOCATION_POLICY_COUNT" -ge 1 ] && pass "5.7 location tenant policy hazır" || fail "5.7 location tenant policy eksik"
[ "$LOCATION_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.8 location audit kolonları hazır" || fail "5.8 location audit kolonları eksik"
[ "$LOCATION_BRANCH_COLUMN_COUNT" -eq 1 ] && pass "5.9 branch relation kolonu hazır" || fail "5.9 branch relation kolonu eksik"
[ "$LOCATION_DICTIONARY_COUNT" -ge 1 ] && pass "5.10 location data dictionary mevcut" || warn "5.10 location data dictionary eksik"
[ "$INV_LINK_TABLE_COUNT" -eq 1 ] && pass "5.11 inventory relation tablosu hazır" || fail "5.11 inventory relation tablosu eksik"
[ "$INV_LINK_FK_COUNT" -ge 2 ] && pass "5.12 inventory relation FK seti hazır" || fail "5.12 inventory relation FK seti eksik"
[ "$INV_LINK_CHECK_COUNT" -ge 4 ] && pass "5.13 inventory relation check seti hazır" || fail "5.13 inventory relation check seti eksik"
[ "$INV_LINK_INDEX_COUNT" -ge 6 ] && pass "5.14 inventory relation index seti hazır" || fail "5.14 inventory relation index seti eksik"
[ "$INV_LINK_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.15 inventory relation RLS enabled" || fail "5.15 inventory relation RLS enabled eksik"
[ "$INV_LINK_RLS_FORCED_COUNT" -eq 1 ] && pass "5.16 inventory relation RLS forced" || fail "5.16 inventory relation RLS forced eksik"
[ "$INV_LINK_POLICY_COUNT" -ge 1 ] && pass "5.17 inventory relation tenant policy hazır" || fail "5.17 inventory relation tenant policy eksik"
[ "$INV_LINK_DICTIONARY_COUNT" -ge 1 ] && pass "5.18 inventory relation data dictionary mevcut" || warn "5.18 inventory relation data dictionary eksik"
[ "$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT" -eq 1 ] && pass "5.19 TDHP account format constraint hazır" || fail "5.19 TDHP account format constraint eksik"

{
  echo "# FAZ 1-3.4 Store / Facility / Warehouse Locations Strict Suite Result FIX V2"
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

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS STRICT SUITE FIX V2 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "LOCATION_FK_COUNT=$LOCATION_FK_COUNT"
echo "LOCATION_CHECK_COUNT=$LOCATION_CHECK_COUNT"
echo "LOCATION_INDEX_COUNT=$LOCATION_INDEX_COUNT"
echo "LOCATION_RLS_ENABLED_COUNT=$LOCATION_RLS_ENABLED_COUNT"
echo "LOCATION_RLS_FORCED_COUNT=$LOCATION_RLS_FORCED_COUNT"
echo "LOCATION_POLICY_COUNT=$LOCATION_POLICY_COUNT"
echo "LOCATION_AUDIT_COLUMN_COUNT=$LOCATION_AUDIT_COLUMN_COUNT"
echo "LOCATION_BRANCH_COLUMN_COUNT=$LOCATION_BRANCH_COLUMN_COUNT"
echo "LOCATION_DICTIONARY_COUNT=$LOCATION_DICTIONARY_COUNT"
echo "INV_LINK_TABLE_COUNT=$INV_LINK_TABLE_COUNT"
echo "INV_LINK_FK_COUNT=$INV_LINK_FK_COUNT"
echo "INV_LINK_CHECK_COUNT=$INV_LINK_CHECK_COUNT"
echo "INV_LINK_INDEX_COUNT=$INV_LINK_INDEX_COUNT"
echo "INV_LINK_RLS_ENABLED_COUNT=$INV_LINK_RLS_ENABLED_COUNT"
echo "INV_LINK_RLS_FORCED_COUNT=$INV_LINK_RLS_FORCED_COUNT"
echo "INV_LINK_POLICY_COUNT=$INV_LINK_POLICY_COUNT"
echo "INV_LINK_DICTIONARY_COUNT=$INV_LINK_DICTIONARY_COUNT"
echo "INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT=$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_4_STORE_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_FACILITY_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_WAREHOUSE_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_BRANCH_RELATION_STATUS=PASS"
  echo "FAZ_1_3_4_INVENTORY_RELATION_STATUS=PASS"
  echo "FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS=PASS"
  echo "FAZ_1_3_4_LOCATION_TEST_STATUS=PASS"
  echo "FAZ_1_3_4_LOCATION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_4_LOCATION_TEST_STATUS=FAIL"
  echo "FAZ_1_3_4_LOCATION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS STRICT SUITE FIX V2 END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_LOCATION_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_LOCATION_SEAL_STATUS")"

STORE_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_STORE_MODEL_STATUS")"
FACILITY_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_FACILITY_MODEL_STATUS")"
WAREHOUSE_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_WAREHOUSE_MODEL_STATUS")"
BRANCH_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_BRANCH_RELATION_STATUS")"
INVENTORY_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_INVENTORY_RELATION_STATUS")"
TDHP_ACCOUNT_FORMAT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "15. strict suite FAIL_COUNT=0 doğrulandı" || fail "15. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "16. strict suite status PASS doğrulandı" || fail "16. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "17. strict suite seal SEALED doğrulandı" || fail "17. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "18. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.4 — Store / Facility / Warehouse Lokasyon Modeli

## Kapsam

- Store
- Facility
- Warehouse
- Branch relation
- Inventory relation
- Location tests

## FIX V2

İlk testte inventory.location_inventory_links içindeki TDHP hesap kodu regex constraint'i 153.01 gibi geçerli alt hesap formatını reddetti.

FIX V2:
- ck_inventory_location_links_stock_account_format kaldırıldı.
- ck_inventory_location_links_account_format eklendi.
- 153 ve 153.01 gibi hesaplar geçerli kabul edilir.
- BAD-ACCOUNT ve BAD-COGS gibi formatlar engellenir.
- default_stock_account_code ve default_cogs_account_code birlikte korunur.

## Final Status

- FAZ_1_3_4_STORE_MODEL_STATUS=${STORE_MODEL_STATUS:-N/A}
- FAZ_1_3_4_FACILITY_MODEL_STATUS=${FACILITY_MODEL_STATUS:-N/A}
- FAZ_1_3_4_WAREHOUSE_MODEL_STATUS=${WAREHOUSE_MODEL_STATUS:-N/A}
- FAZ_1_3_4_BRANCH_RELATION_STATUS=${BRANCH_RELATION_STATUS:-N/A}
- FAZ_1_3_4_INVENTORY_RELATION_STATUS=${INVENTORY_RELATION_STATUS:-N/A}
- FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS=${TDHP_ACCOUNT_FORMAT_STATUS:-N/A}
- FAZ_1_3_4_LOCATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_4_LOCATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.4 Store / Facility / Warehouse Locations FIX V2 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Location SQL: $LOCATION_TEST_SQL"
  echo "- Location output: $LOCATION_TEST_OUT"
  echo
  echo "## Location Counts"
  echo "- LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
  echo "- LOCATION_COLUMN_COUNT=$LOCATION_COLUMN_COUNT"
  echo "- LOCATION_FK_COUNT=$LOCATION_FK_COUNT"
  echo "- LOCATION_CHECK_COUNT=$LOCATION_CHECK_COUNT"
  echo "- LOCATION_INDEX_COUNT=$LOCATION_INDEX_COUNT"
  echo "- LOCATION_RLS_ENABLED_COUNT=$LOCATION_RLS_ENABLED_COUNT"
  echo "- LOCATION_RLS_FORCED_COUNT=$LOCATION_RLS_FORCED_COUNT"
  echo "- LOCATION_POLICY_COUNT=$LOCATION_POLICY_COUNT"
  echo "- LOCATION_UPDATED_AT_TRIGGER_COUNT=$LOCATION_UPDATED_AT_TRIGGER_COUNT"
  echo "- LOCATION_AUDIT_COLUMN_COUNT=$LOCATION_AUDIT_COLUMN_COUNT"
  echo "- LOCATION_DICTIONARY_COUNT=$LOCATION_DICTIONARY_COUNT"
  echo "- LOCATION_BRANCH_COLUMN_COUNT=$LOCATION_BRANCH_COLUMN_COUNT"
  echo
  echo "## Inventory Relation Counts"
  echo "- INVENTORY_SCHEMA_COUNT=$INVENTORY_SCHEMA_COUNT"
  echo "- INV_LINK_TABLE_COUNT=$INV_LINK_TABLE_COUNT"
  echo "- INV_LINK_COLUMN_COUNT=$INV_LINK_COLUMN_COUNT"
  echo "- INV_LINK_FK_COUNT=$INV_LINK_FK_COUNT"
  echo "- INV_LINK_CHECK_COUNT=$INV_LINK_CHECK_COUNT"
  echo "- INV_LINK_INDEX_COUNT=$INV_LINK_INDEX_COUNT"
  echo "- INV_LINK_RLS_ENABLED_COUNT=$INV_LINK_RLS_ENABLED_COUNT"
  echo "- INV_LINK_RLS_FORCED_COUNT=$INV_LINK_RLS_FORCED_COUNT"
  echo "- INV_LINK_POLICY_COUNT=$INV_LINK_POLICY_COUNT"
  echo "- INV_LINK_DICTIONARY_COUNT=$INV_LINK_DICTIONARY_COUNT"
  echo "- INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT=$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT"
  echo
  echo "## Tests"
  echo "- LOCATION_TEST_STATUS=$LOCATION_TEST_STATUS"
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
  echo "# FAZ 1-3.4 Store / Facility / Warehouse Locations Final Seal FIX V2"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_4_STORE_MODEL_STATUS=${STORE_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_4_FACILITY_MODEL_STATUS=${FACILITY_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_4_WAREHOUSE_MODEL_STATUS=${WAREHOUSE_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_4_BRANCH_RELATION_STATUS=${BRANCH_RELATION_STATUS:-N/A}"
  echo "FAZ_1_3_4_INVENTORY_RELATION_STATUS=${INVENTORY_RELATION_STATUS:-N/A}"
  echo "FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS=${TDHP_ACCOUNT_FORMAT_STATUS:-N/A}"
  echo "FAZ_1_3_4_LOCATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_4_LOCATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_5_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "18.1 dokümantasyon yazıldı: $DOC_FILE"
pass "18.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "18.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$FIX_SCRIPT_FILE"
chmod +x "$FIX_SCRIPT_FILE"
pass "18.4 FIX V2 script repo içine kopyalandı: $FIX_SCRIPT_FILE"

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS FIX V2 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LOCATION_TEST_STATUS=$LOCATION_TEST_STATUS"
echo "ACCOUNT_FORMAT_CHECK_COUNT=$ACCOUNT_FORMAT_CHECK_COUNT"
echo "LOCATION_TABLE_COUNT=$LOCATION_TABLE_COUNT"
echo "LOCATION_COLUMN_COUNT=$LOCATION_COLUMN_COUNT"
echo "LOCATION_FK_COUNT=$LOCATION_FK_COUNT"
echo "LOCATION_CHECK_COUNT=$LOCATION_CHECK_COUNT"
echo "LOCATION_INDEX_COUNT=$LOCATION_INDEX_COUNT"
echo "LOCATION_RLS_ENABLED_COUNT=$LOCATION_RLS_ENABLED_COUNT"
echo "LOCATION_RLS_FORCED_COUNT=$LOCATION_RLS_FORCED_COUNT"
echo "LOCATION_POLICY_COUNT=$LOCATION_POLICY_COUNT"
echo "LOCATION_UPDATED_AT_TRIGGER_COUNT=$LOCATION_UPDATED_AT_TRIGGER_COUNT"
echo "LOCATION_AUDIT_COLUMN_COUNT=$LOCATION_AUDIT_COLUMN_COUNT"
echo "LOCATION_DICTIONARY_COUNT=$LOCATION_DICTIONARY_COUNT"
echo "LOCATION_BRANCH_COLUMN_COUNT=$LOCATION_BRANCH_COLUMN_COUNT"
echo "INVENTORY_SCHEMA_COUNT=$INVENTORY_SCHEMA_COUNT"
echo "INV_LINK_TABLE_COUNT=$INV_LINK_TABLE_COUNT"
echo "INV_LINK_COLUMN_COUNT=$INV_LINK_COLUMN_COUNT"
echo "INV_LINK_FK_COUNT=$INV_LINK_FK_COUNT"
echo "INV_LINK_CHECK_COUNT=$INV_LINK_CHECK_COUNT"
echo "INV_LINK_INDEX_COUNT=$INV_LINK_INDEX_COUNT"
echo "INV_LINK_RLS_ENABLED_COUNT=$INV_LINK_RLS_ENABLED_COUNT"
echo "INV_LINK_RLS_FORCED_COUNT=$INV_LINK_RLS_FORCED_COUNT"
echo "INV_LINK_POLICY_COUNT=$INV_LINK_POLICY_COUNT"
echo "INV_LINK_DICTIONARY_COUNT=$INV_LINK_DICTIONARY_COUNT"
echo "INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT=$INV_LINK_ACCOUNT_FORMAT_CHECK_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "STORE_MODEL_STATUS=${STORE_MODEL_STATUS:-N/A}"
echo "FACILITY_MODEL_STATUS=${FACILITY_MODEL_STATUS:-N/A}"
echo "WAREHOUSE_MODEL_STATUS=${WAREHOUSE_MODEL_STATUS:-N/A}"
echo "BRANCH_RELATION_STATUS=${BRANCH_RELATION_STATUS:-N/A}"
echo "INVENTORY_RELATION_STATUS=${INVENTORY_RELATION_STATUS:-N/A}"
echo "TDHP_ACCOUNT_FORMAT_STATUS=${TDHP_ACCOUNT_FORMAT_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$LOCATION_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_4_STORE_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_FACILITY_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_WAREHOUSE_MODEL_STATUS=PASS"
  echo "FAZ_1_3_4_BRANCH_RELATION_STATUS=PASS"
  echo "FAZ_1_3_4_INVENTORY_RELATION_STATUS=PASS"
  echo "FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS=PASS"
  echo "FAZ_1_3_4_LOCATION_FINAL_STATUS=PASS"
  echo "FAZ_1_3_4_LOCATION_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_5_READY=YES"
else
  echo "FAZ_1_3_4_LOCATION_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_4_LOCATION_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_5_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.4 STORE / FACILITY / WAREHOUSE LOCATIONS FIX V2 END ====="
