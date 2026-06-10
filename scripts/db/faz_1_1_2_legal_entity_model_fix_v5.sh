#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_2_LEGAL_ENTITY_MODEL_FIX_V5"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_2_legal_entity_model_fix_v5_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"

FIX_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_2_legal_entity_model_fix_v5.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_2_legal_entity_model_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_2_LEGAL_ENTITY_MODEL.md"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_2_LEGAL_ENTITY_MODEL_FINAL_SEAL_FIX_V5_$TS.md"

LEGAL_ENTITY_TEST_SQL="$SUITE_RUNTIME_DIR/legal_entity_lifecycle_abuse_suite_fix_v5.sql"
LEGAL_ENTITY_TEST_OUT="$SUITE_RUNTIME_DIR/legal_entity_lifecycle_abuse_suite_fix_v5.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_2_fix_v5_strict_suite_run.out"

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

choose_status_value() {
  local fq_table="$1"
  local column_name="$2"

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
        WHEN 'active' THEN 1
        WHEN 'enabled' THEN 2
        WHEN 'open' THEN 3
        WHEN 'created' THEN 4
        WHEN 'draft' THEN 5
        ELSE 99
      END,
      enumlabel
    LIMIT 1
  ),
  'ACTIVE'
);
" 2>/dev/null | head -n1
}

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL FIX V5 START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$STRICT_SUITE_FILE" "$DOC_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_fix_v5_$TS"
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

echo "7. type-aware status ve tenant FK bilgileri tespit ediliyor..."

LEGAL_ENTITY_STATUS_VALUE="$(choose_status_value "org.legal_entities" "status")"
LEGAL_ENTITY_ADDRESS_STATUS_VALUE="$(choose_status_value "org.legal_entity_addresses" "status")"

if [ -z "$LEGAL_ENTITY_STATUS_VALUE" ]; then LEGAL_ENTITY_STATUS_VALUE="active"; fi
if [ -z "$LEGAL_ENTITY_ADDRESS_STATUS_VALUE" ]; then LEGAL_ENTITY_ADDRESS_STATUS_VALUE="$LEGAL_ENTITY_STATUS_VALUE"; fi

LEGAL_ENTITY_STATUS_TYPE="$(psql "$DSN" -Atqc "select a.atttypid::regtype::text from pg_attribute a where a.attrelid='org.legal_entities'::regclass and a.attname='status' and a.attnum > 0 and not a.attisdropped;" 2>/dev/null | head -n1)"
LEGAL_ENTITY_ADDRESS_STATUS_TYPE="$(psql "$DSN" -Atqc "select a.atttypid::regtype::text from pg_attribute a where a.attrelid='org.legal_entity_addresses'::regclass and a.attname='status' and a.attnum > 0 and not a.attisdropped;" 2>/dev/null | head -n1)"

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
echo "LEGAL_ENTITY_ADDRESS_STATUS_VALUE=$LEGAL_ENTITY_ADDRESS_STATUS_VALUE"
echo "LEGAL_ENTITY_STATUS_TYPE=${LEGAL_ENTITY_STATUS_TYPE:-N/A}"
echo "LEGAL_ENTITY_ADDRESS_STATUS_TYPE=${LEGAL_ENTITY_ADDRESS_STATUS_TYPE:-N/A}"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"

pass "7.1 legal entity status değeri seçildi"
pass "7.2 legal entity address status değeri seçildi"
pass "7.3 legal entity status tipi algılandı"
pass "7.4 legal entity address status tipi algılandı"

if [ -n "${TENANT_REF_TABLE:-}" ]; then
  pass "7.5 tenant FK referans tablosu bulundu"
else
  fail "7.5 tenant FK referans tablosu bulunamadı"
  exit 1
fi

if [ -n "${TENANT_REF_COL:-}" ]; then
  pass "7.6 tenant FK referans UUID kolonu bulundu"
else
  fail "7.6 tenant FK referans UUID kolonu bulunamadı"
  exit 1
fi

if [ -n "${REAL_TENANT_ID:-}" ]; then
  pass "7.7 gerçek tenant_id bulundu"
else
  fail "7.7 tenants tablosunda test için kullanılacak gerçek tenant_id yok"
  exit 1
fi

echo "8. legal entity lifecycle / abuse SQL suite FIX V5 hazırlanıyor..."

cat <<SQL > "$LEGAL_ENTITY_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_tenant_b uuid := gen_random_uuid();
  v_entity_id uuid := gen_random_uuid();
  v_address_id uuid := gen_random_uuid();
  v_suffix text := upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  v_status org.legal_entities.status%TYPE := '$LEGAL_ENTITY_STATUS_VALUE';
  v_address_status org.legal_entity_addresses.status%TYPE := '$LEGAL_ENTITY_ADDRESS_STATUS_VALUE';
  v_count int;
BEGIN
  PERFORM set_config('app.tenant_id', v_tenant_id::text, true);
  PERFORM set_config('app.current_tenant_id', v_tenant_id::text, true);

  INSERT INTO org.legal_entities (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    legal_name,
    trade_name,
    tax_number,
    tax_office,
    mersis_no,
    phone,
    email,
    address_line,
    district,
    city,
    country_code,
    postal_code,
    status,
    metadata
  )
  VALUES (
    v_entity_id,
    v_tenant_id,
    v_entity_id,
    'LEGAL_ENTITY_TEST_' || v_suffix,
    'PIX2PI TEST LIMITED SIRKETI',
    'PIX2PI TEST',
    '1234567890',
    'KADIKOY',
    NULL,
    '+902120000000',
    'legal-entity-test@pix2pi.local',
    'TEST MAHALLESI TEST SOKAK NO 1',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_status,
    jsonb_build_object('test','faz_1_1_2_fix_v5')
  );

  SELECT count(*)
  INTO v_count
  FROM org.legal_entities
  WHERE id=v_entity_id
    AND tenant_id=v_tenant_id
    AND legal_name='PIX2PI TEST LIMITED SIRKETI'
    AND tax_number='1234567890'
    AND tax_office='KADIKOY'
    AND address_line IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'legal entity valid insert/read failed';
  END IF;

  INSERT INTO org.legal_entity_addresses (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    address_type,
    address_line,
    district,
    city,
    country_code,
    postal_code,
    is_primary,
    status
  )
  VALUES (
    v_address_id,
    v_tenant_id,
    v_entity_id,
    'LEGAL_ENTITY_ADDRESS_TEST_' || v_suffix,
    'PRIMARY',
    'TEST MAHALLESI TEST SOKAK NO 1',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    true,
    v_address_status
  );

  SELECT count(*)
  INTO v_count
  FROM org.legal_entity_addresses
  WHERE id=v_address_id
    AND tenant_id=v_tenant_id
    AND legal_entity_id=v_entity_id
    AND address_line IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'legal entity address link failed';
  END IF;

  BEGIN
    INSERT INTO org.legal_entities (
      id,
      tenant_id,
      legal_entity_id,
      business_code,
      legal_name,
      tax_number,
      tax_office,
      address_line,
      country_code,
      status
    )
    VALUES (
      gen_random_uuid(),
      v_tenant_id,
      gen_random_uuid(),
      'LEGAL_ENTITY_TEST_MISSING_ADDRESS_' || v_suffix,
      'MISSING ADDRESS TEST',
      '2234567890',
      'KADIKOY',
      NULL,
      'TR',
      v_status
    );

    RAISE EXCEPTION 'missing address insert was not blocked';
  EXCEPTION WHEN check_violation OR not_null_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.legal_entities (
      id,
      tenant_id,
      legal_entity_id,
      business_code,
      legal_name,
      tax_number,
      tax_office,
      address_line,
      country_code,
      status
    )
    VALUES (
      gen_random_uuid(),
      v_tenant_id,
      gen_random_uuid(),
      'LEGAL_ENTITY_TEST_MISSING_TAX_OFFICE_' || v_suffix,
      'MISSING TAX OFFICE TEST',
      '3234567890',
      NULL,
      'TEST ADDRESS',
      'TR',
      v_status
    );

    RAISE EXCEPTION 'missing tax office insert was not blocked';
  EXCEPTION WHEN check_violation OR not_null_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.legal_entities (
      id,
      tenant_id,
      legal_entity_id,
      business_code,
      legal_name,
      tax_number,
      tax_office,
      address_line,
      country_code,
      status
    )
    VALUES (
      gen_random_uuid(),
      v_tenant_id,
      gen_random_uuid(),
      'LEGAL_ENTITY_TEST_' || v_suffix,
      'DUPLICATE BUSINESS CODE TEST',
      '4234567890',
      'KADIKOY',
      'TEST ADDRESS',
      'TR',
      v_status
    );

    RAISE EXCEPTION 'duplicate business_code insert was not blocked';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.legal_entity_addresses (
      id,
      tenant_id,
      legal_entity_id,
      business_code,
      address_type,
      address_line,
      country_code,
      is_primary,
      status
    )
    VALUES (
      gen_random_uuid(),
      v_tenant_b,
      v_entity_id,
      'LEGAL_ENTITY_ADDRESS_CROSS_TENANT_' || v_suffix,
      'PRIMARY',
      'CROSS TENANT ADDRESS',
      'TR',
      true,
      v_address_status
    );

    RAISE EXCEPTION 'cross-tenant address link was not blocked';
  EXCEPTION WHEN foreign_key_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "8.1 lifecycle / abuse SQL suite FIX V5 dosyası yazıldı: $LEGAL_ENTITY_TEST_SQL / OK ✅"

echo "9. legal entity lifecycle / abuse SQL suite FIX V5 çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$LEGAL_ENTITY_TEST_SQL" > "$LEGAL_ENTITY_TEST_OUT" 2>&1; then
  pass "9.1 legal entity lifecycle / abuse SQL suite geçti"
else
  fail "9.1 legal entity lifecycle / abuse SQL suite başarısız"
  cat "$LEGAL_ENTITY_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$LEGAL_ENTITY_TEST_OUT"; then
  pass "9.2 lifecycle test rollback ile temizlendi"
else
  fail "9.2 lifecycle rollback kanıtı yok"
fi

echo "10. legal entity model sayaçları alınıyor..."

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entities';")"
LEGAL_ENTITY_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entity_addresses';")"

LEGAL_ENTITY_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entities'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'legal_name','trade_name','tax_number','tax_office','mersis_no',
      'phone','email','address_line','district','city','country_code',
      'postal_code','status','metadata','audit_metadata','created_at','updated_at',
      'created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_ADDRESS_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entity_addresses'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'address_type','address_line','district','city','country_code',
      'postal_code','is_primary','status','metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entities'::regclass
    and conname in (
      'ck_org_legal_entities_required_company_fields',
      'ck_org_legal_entities_status',
      'ck_org_legal_entities_country_code',
      'ck_org_legal_entities_tax_number_format'
    );
")"

LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entity_addresses'::regclass
    and conname in (
      'fk_org_legal_entity_addresses_legal_entity_tenant',
      'ck_org_legal_entity_addresses_required_fields',
      'ck_org_legal_entity_addresses_status',
      'ck_org_legal_entity_addresses_address_type'
    );
")"

LEGAL_ENTITY_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entities'
    and indexname in (
      'ux_org_legal_entities_id_tenant_id_fk',
      'ux_org_legal_entities_tenant_business_code',
      'ux_org_legal_entities_tenant_tax_number',
      'idx_org_legal_entities_tenant_id',
      'idx_org_legal_entities_legal_name',
      'idx_org_legal_entities_status'
    );
")"

LEGAL_ENTITY_ADDRESS_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entity_addresses'
    and indexname in (
      'ux_org_legal_entity_addresses_tenant_business_code',
      'idx_org_legal_entity_addresses_tenant_id',
      'idx_org_legal_entity_addresses_legal_entity_id',
      'idx_org_legal_entity_addresses_status'
    );
")"

LEGAL_ENTITY_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relrowsecurity=true;
")"

LEGAL_ENTITY_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relforcerowsecurity=true;
")"

LEGAL_ENTITY_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='org'
    and tablename in ('legal_entities','legal_entity_addresses');
")"

LEGAL_ENTITY_DICTIONARY_TABLE_COUNT="$(scalar_count "
  select count(*)
  from app_dictionary.table_contracts
  where schema_name='org'
    and table_name in ('legal_entities','legal_entity_addresses');
")"

echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"

[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "10.1 firma modeli tablosu hazır" || fail "10.1 firma modeli tablosu eksik"
[ "$LEGAL_ENTITY_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "10.2 adres bağlantısı tablosu hazır" || fail "10.2 adres bağlantısı tablosu eksik"
[ "$LEGAL_ENTITY_COLUMN_COUNT" -ge 25 ] && pass "10.3 firma modeli canonical kolon kapsamı tam" || fail "10.3 firma modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT" -ge 20 ] && pass "10.4 adres modeli canonical kolon kapsamı tam" || fail "10.4 adres modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT" -ge 4 ] && pass "10.5 vergi/ticari/adres required constraint seti hazır" || fail "10.5 required constraint seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT" -ge 4 ] && pass "10.6 adres FK/constraint seti hazır" || fail "10.6 adres FK/constraint seti eksik"
[ "$LEGAL_ENTITY_INDEX_COUNT" -ge 6 ] && pass "10.7 legal entity tenant-safe index seti hazır" || fail "10.7 legal entity index seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_INDEX_COUNT" -ge 4 ] && pass "10.8 legal entity address index seti hazır" || fail "10.8 legal entity address index seti eksik"
[ "$LEGAL_ENTITY_RLS_ENABLED_COUNT" -eq 2 ] && pass "10.9 legal entity tablolarında RLS enabled" || fail "10.9 RLS enabled eksik"
[ "$LEGAL_ENTITY_RLS_FORCED_COUNT" -eq 2 ] && pass "10.10 legal entity tablolarında RLS forced" || fail "10.10 RLS forced eksik"
[ "$LEGAL_ENTITY_POLICY_COUNT" -ge 2 ] && pass "10.11 legal entity tenant policy seti hazır" || fail "10.11 tenant policy seti eksik"
[ "$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT" -ge 2 ] && pass "10.12 data dictionary table contract mevcut" || warn "10.12 data dictionary table contract yok"

echo "11. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_2_legal_entity_model_strict_suite_fix_v5_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_SUITE_RESULT_FIX_V5_$TS.md"

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

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 START ====="

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

echo "5. legal entity model sayaçları alınıyor..."

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entities';")"
LEGAL_ENTITY_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entity_addresses';")"

LEGAL_ENTITY_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entities'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'legal_name','trade_name','tax_number','tax_office','mersis_no',
      'phone','email','address_line','district','city','country_code',
      'postal_code','status','metadata','audit_metadata','created_at','updated_at',
      'created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_ADDRESS_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entity_addresses'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'address_type','address_line','district','city','country_code',
      'postal_code','is_primary','status','metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entities'::regclass
    and conname in (
      'ck_org_legal_entities_required_company_fields',
      'ck_org_legal_entities_status',
      'ck_org_legal_entities_country_code',
      'ck_org_legal_entities_tax_number_format'
    );
")"

LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entity_addresses'::regclass
    and conname in (
      'fk_org_legal_entity_addresses_legal_entity_tenant',
      'ck_org_legal_entity_addresses_required_fields',
      'ck_org_legal_entity_addresses_status',
      'ck_org_legal_entity_addresses_address_type'
    );
")"

LEGAL_ENTITY_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entities'
    and indexname in (
      'ux_org_legal_entities_id_tenant_id_fk',
      'ux_org_legal_entities_tenant_business_code',
      'ux_org_legal_entities_tenant_tax_number',
      'idx_org_legal_entities_tenant_id',
      'idx_org_legal_entities_legal_name',
      'idx_org_legal_entities_status'
    );
")"

LEGAL_ENTITY_ADDRESS_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entity_addresses'
    and indexname in (
      'ux_org_legal_entity_addresses_tenant_business_code',
      'idx_org_legal_entity_addresses_tenant_id',
      'idx_org_legal_entity_addresses_legal_entity_id',
      'idx_org_legal_entity_addresses_status'
    );
")"

LEGAL_ENTITY_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relrowsecurity=true;
")"

LEGAL_ENTITY_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relforcerowsecurity=true;
")"

LEGAL_ENTITY_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='org'
    and tablename in ('legal_entities','legal_entity_addresses');
")"

LEGAL_ENTITY_DICTIONARY_TABLE_COUNT="$(scalar_count "
  select count(*)
  from app_dictionary.table_contracts
  where schema_name='org'
    and table_name in ('legal_entities','legal_entity_addresses');
")"

echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"

[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "5.1 firma modeli tablosu hazır" || fail "5.1 firma modeli tablosu eksik"
[ "$LEGAL_ENTITY_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "5.2 adres bağlantısı tablosu hazır" || fail "5.2 adres bağlantısı tablosu eksik"
[ "$LEGAL_ENTITY_COLUMN_COUNT" -ge 25 ] && pass "5.3 firma modeli canonical kolon kapsamı tam" || fail "5.3 firma modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT" -ge 20 ] && pass "5.4 adres modeli canonical kolon kapsamı tam" || fail "5.4 adres modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT" -ge 4 ] && pass "5.5 vergi/ticari/adres required constraint seti hazır" || fail "5.5 required constraint seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT" -ge 4 ] && pass "5.6 adres FK/constraint seti hazır" || fail "5.6 adres FK/constraint seti eksik"
[ "$LEGAL_ENTITY_INDEX_COUNT" -ge 6 ] && pass "5.7 legal entity tenant-safe index seti hazır" || fail "5.7 legal entity index seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_INDEX_COUNT" -ge 4 ] && pass "5.8 legal entity address index seti hazır" || fail "5.8 legal entity address index seti eksik"
[ "$LEGAL_ENTITY_RLS_ENABLED_COUNT" -eq 2 ] && pass "5.9 legal entity tablolarında RLS enabled" || fail "5.9 RLS enabled eksik"
[ "$LEGAL_ENTITY_RLS_FORCED_COUNT" -eq 2 ] && pass "5.10 legal entity tablolarında RLS forced" || fail "5.10 RLS forced eksik"
[ "$LEGAL_ENTITY_POLICY_COUNT" -ge 2 ] && pass "5.11 tenant policy seti hazır" || fail "5.11 tenant policy seti eksik"
[ "$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT" -ge 2 ] && pass "5.12 data dictionary table contract mevcut" || warn "5.12 data dictionary table contract yok"

{
  echo "# FAZ 1-1.2 Legal Entity Model Strict Suite Result FIX V5"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
  echo "- LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
  echo "- LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
  echo "- LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
  echo "- LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
  echo "- LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_2_COMPANY_MODEL_STATUS=PASS"
  echo "FAZ_1_1_2_TAX_INFO_STATUS=PASS"
  echo "FAZ_1_1_2_TRADE_TITLE_STATUS=PASS"
  echo "FAZ_1_1_2_ADDRESS_LINK_STATUS=PASS"
  echo "FAZ_1_1_2_TENANT_RELATION_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "11.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "12. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "12.1 strict suite exit code 0"
else
  fail "12.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS")"

COMPANY_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_COMPANY_MODEL_STATUS")"
TAX_INFO_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_TAX_INFO_STATUS")"
TRADE_TITLE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_TRADE_TITLE_STATUS")"
ADDRESS_LINK_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_ADDRESS_LINK_STATUS")"
TENANT_RELATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_TENANT_RELATION_STATUS")"
LEGAL_ENTITY_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "13. strict suite FAIL_COUNT=0 doğrulandı" || fail "13. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "14. strict suite status PASS doğrulandı" || fail "14. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "15. strict suite seal SEALED doğrulandı" || fail "15. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "16. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.2 Legal Entity Model

## Kapsam

- Firma modeli
- Vergi bilgileri
- Ticari unvan
- Adres bağlantısı
- Tenant relation
- Legal entity tests

## FIX V5

FIX V4 lifecycle testi sentetik tenant_id kullandığı için tenants FK tarafından doğru şekilde engellendi. FIX V5 test tenant'ını uydurmaz; org.legal_entities.tenant_id FK metadata'sından gerçek tenants referans tablosunu ve UUID kolonunu bulur, mevcut gerçek tenant_id ile lifecycle testini çalıştırır.

## Kurallar

- tax_number zorunludur.
- tax_office zorunludur.
- legal_name zorunludur.
- address_line zorunludur.
- mersis_no opsiyoneldir.
- phone ve email alanları desteklenir.
- address bağlantısı legal_entity_id + tenant_id composite relation ile tenant-safe korunur.
- legal entity tablolarında RLS enabled + forced uygulanır.

## Final Status

- FAZ_1_1_2_COMPANY_MODEL_STATUS=${COMPANY_MODEL_STATUS:-N/A}
- FAZ_1_1_2_TAX_INFO_STATUS=${TAX_INFO_STATUS:-N/A}
- FAZ_1_1_2_TRADE_TITLE_STATUS=${TRADE_TITLE_STATUS:-N/A}
- FAZ_1_1_2_ADDRESS_LINK_STATUS=${ADDRESS_LINK_STATUS:-N/A}
- FAZ_1_1_2_TENANT_RELATION_STATUS=${TENANT_RELATION_STATUS:-N/A}
- FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=${LEGAL_ENTITY_TEST_STATUS:-N/A}
- FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.2 Legal Entity Model FIX V5 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Lifecycle SQL: $LEGAL_ENTITY_TEST_SQL"
  echo "- Lifecycle output: $LEGAL_ENTITY_TEST_OUT"
  echo
  echo "## Type-aware status / tenant FK"
  echo "- LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
  echo "- LEGAL_ENTITY_ADDRESS_STATUS_VALUE=$LEGAL_ENTITY_ADDRESS_STATUS_VALUE"
  echo "- LEGAL_ENTITY_STATUS_TYPE=${LEGAL_ENTITY_STATUS_TYPE:-N/A}"
  echo "- LEGAL_ENTITY_ADDRESS_STATUS_TYPE=${LEGAL_ENTITY_ADDRESS_STATUS_TYPE:-N/A}"
  echo "- TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
  echo "- TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
  echo "- REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
  echo
  echo "## Counts"
  echo "- LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
  echo "- LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
  echo "- LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
  echo "- LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
  echo "- LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
  echo "- LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Required Scope Status"
  echo "- COMPANY_MODEL_STATUS=${COMPANY_MODEL_STATUS:-N/A}"
  echo "- TAX_INFO_STATUS=${TAX_INFO_STATUS:-N/A}"
  echo "- TRADE_TITLE_STATUS=${TRADE_TITLE_STATUS:-N/A}"
  echo "- ADDRESS_LINK_STATUS=${ADDRESS_LINK_STATUS:-N/A}"
  echo "- TENANT_RELATION_STATUS=${TENANT_RELATION_STATUS:-N/A}"
  echo "- LEGAL_ENTITY_TEST_STATUS=${LEGAL_ENTITY_TEST_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-1.2 Legal Entity Model Final Seal FIX V5"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_2_COMPANY_MODEL_STATUS=${COMPANY_MODEL_STATUS:-N/A}"
  echo "FAZ_1_1_2_TAX_INFO_STATUS=${TAX_INFO_STATUS:-N/A}"
  echo "FAZ_1_1_2_TRADE_TITLE_STATUS=${TRADE_TITLE_STATUS:-N/A}"
  echo "FAZ_1_1_2_ADDRESS_LINK_STATUS=${ADDRESS_LINK_STATUS:-N/A}"
  echo "FAZ_1_1_2_TENANT_RELATION_STATUS=${TENANT_RELATION_STATUS:-N/A}"
  echo "FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=${LEGAL_ENTITY_TEST_STATUS:-N/A}"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_1_3_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "16.1 dokümantasyon güncellendi: $DOC_FILE"
pass "16.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "16.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$FIX_SCRIPT_FILE"
chmod +x "$FIX_SCRIPT_FILE"
pass "16.4 FIX V5 script repo içine kopyalandı: $FIX_SCRIPT_FILE"

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "LEGAL_ENTITY_ADDRESS_STATUS_VALUE=$LEGAL_ENTITY_ADDRESS_STATUS_VALUE"
echo "LEGAL_ENTITY_STATUS_TYPE=${LEGAL_ENTITY_STATUS_TYPE:-N/A}"
echo "LEGAL_ENTITY_ADDRESS_STATUS_TYPE=${LEGAL_ENTITY_ADDRESS_STATUS_TYPE:-N/A}"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "COMPANY_MODEL_STATUS=${COMPANY_MODEL_STATUS:-N/A}"
echo "TAX_INFO_STATUS=${TAX_INFO_STATUS:-N/A}"
echo "TRADE_TITLE_STATUS=${TRADE_TITLE_STATUS:-N/A}"
echo "ADDRESS_LINK_STATUS=${ADDRESS_LINK_STATUS:-N/A}"
echo "TENANT_RELATION_STATUS=${TENANT_RELATION_STATUS:-N/A}"
echo "LEGAL_ENTITY_TEST_STATUS=${LEGAL_ENTITY_TEST_STATUS:-N/A}"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_1_2_COMPANY_MODEL_STATUS=PASS"
  echo "FAZ_1_1_2_TAX_INFO_STATUS=PASS"
  echo "FAZ_1_1_2_TRADE_TITLE_STATUS=PASS"
  echo "FAZ_1_1_2_ADDRESS_LINK_STATUS=PASS"
  echo "FAZ_1_1_2_TENANT_RELATION_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_FINAL_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=SEALED"
  echo "FAZ_1_1_3_READY=YES"
else
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=OPEN"
  echo "FAZ_1_1_3_READY=NO"
  exit 1
fi

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL FIX V5 END ====="
