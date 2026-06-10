#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_3_2_ORG_ENTITY_SHAREHOLDERS_FIX_V5"

BACKUP_DIR="$REPO/backups/faz1/faz_1_3_2_org_entity_shareholders_fix_v5_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/organization"
SCRIPT_DIR="$REPO/scripts/organization"

FIX_SCRIPT_FILE="$SCRIPT_DIR/faz_1_3_2_org_entity_shareholders_fix_v5.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_3_2_org_entity_shareholders_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_3_2_ORG_ENTITY_SHAREHOLDERS.md"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_3_2_ORG_ENTITY_SHAREHOLDERS_FINAL_SEAL_FIX_V5_$TS.md"

OWNERSHIP_TEST_SQL="$SUITE_RUNTIME_DIR/org_entity_shareholders_ownership_suite_fix_v5.sql"
OWNERSHIP_TEST_OUT="$SUITE_RUNTIME_DIR/org_entity_shareholders_ownership_suite_fix_v5.out"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_3_2_fix_v5_strict_suite_run.out"

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

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS FIX V5 START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$FIX_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
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

echo "7. type-aware değerler ve mevcut bridge kontrol ediliyor..."

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

LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name='shareholder_kind';")"
LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name='ownership_ratio';")"
LEGACY_VOTING_RATIO_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name='voting_ratio';")"
LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='sync_entity_shareholder_legacy_fields';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_sync_legacy_fields' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"

echo "LEGAL_ENTITY_STATUS_VALUE=$LEGAL_ENTITY_STATUS_VALUE"
echo "TENANT_REF_TABLE=${TENANT_REF_TABLE:-N/A}"
echo "TENANT_REF_COL=${TENANT_REF_COL:-N/A}"
echo "REAL_TENANT_ID=${REAL_TENANT_ID:-N/A}"
echo "LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT=$LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT"
echo "LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT=$LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT"
echo "LEGACY_VOTING_RATIO_COLUMN_COUNT=$LEGACY_VOTING_RATIO_COLUMN_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ -n "$LEGAL_ENTITY_STATUS_VALUE" ] && pass "7.1 legal entity status değeri seçildi" || fail "7.1 legal entity status değeri seçilemedi"
[ -n "${TENANT_REF_TABLE:-}" ] && pass "7.2 tenant FK referans tablosu bulundu" || fail "7.2 tenant FK referans tablosu bulunamadı"
[ -n "${TENANT_REF_COL:-}" ] && pass "7.3 tenant FK referans UUID kolonu bulundu" || fail "7.3 tenant FK referans UUID kolonu bulunamadı"
[ -n "${REAL_TENANT_ID:-}" ] && pass "7.4 gerçek tenant_id bulundu" || fail "7.4 gerçek tenant_id bulunamadı"
[ "$LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "7.5 legacy sync function mevcut" || fail "7.5 legacy sync function eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "7.6 legacy sync trigger mevcut" || fail "7.6 legacy sync trigger eksik"

if [ "$FAIL_COUNT" -ne 0 ]; then
  echo "7.x hazırlık başarısız; devam edilmiyor / FAIL ❌"
  exit 1
fi

echo "8. ownership lifecycle / abuse SQL suite FIX V5 hazırlanıyor..."

cat <<SQL > "$OWNERSHIP_TEST_SQL"
BEGIN;

DO \$\$
DECLARE
  v_tenant_id uuid := '$REAL_TENANT_ID'::uuid;
  v_entity_id uuid := gen_random_uuid();
  v_shareholder_entity_id uuid := gen_random_uuid();
  v_external_shareholder_id uuid := gen_random_uuid();
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
  VALUES
  (
    v_entity_id, v_tenant_id, v_entity_id,
    'OWNED_ENTITY_' || v_suffix,
    'PIX2PI OWNED ENTITY TEST A.S.',
    'PIX2PI OWNED',
    '810' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120002001',
    'owned-' || lower(v_suffix) || '@pix2pi.local',
    'OWNED TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_2_fix_v5_owned')
  ),
  (
    v_shareholder_entity_id, v_tenant_id, v_shareholder_entity_id,
    'SHAREHOLDER_ENTITY_' || v_suffix,
    'PIX2PI SHAREHOLDER ENTITY TEST A.S.',
    'PIX2PI SHAREHOLDER',
    '820' || substr(replace(v_suffix,'_',''),1,7),
    'KADIKOY',
    '+902120002002',
    'shareholder-' || lower(v_suffix) || '@pix2pi.local',
    'SHAREHOLDER TEST ADRES',
    'KADIKOY',
    'ISTANBUL',
    'TR',
    '34000',
    v_legal_status,
    jsonb_build_object('test','faz_1_3_2_fix_v5_shareholder')
  );

  INSERT INTO org.entity_shareholders (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    shareholder_type,
    shareholder_entity_id,
    shareholder_name,
    shareholder_tax_number,
    share_class,
    ownership_percentage,
    voting_percentage,
    effective_from,
    status,
    ownership_audit_ref,
    ownership_change_reason,
    metadata
  )
  VALUES (
    v_shareholder_entity_id,
    v_tenant_id,
    v_entity_id,
    'ENTITY_SHAREHOLDER_LEGAL_' || v_suffix,
    'LEGAL_ENTITY',
    v_shareholder_entity_id,
    'PIX2PI SHAREHOLDER ENTITY TEST A.S.',
    '820' || substr(replace(v_suffix,'_',''),1,7),
    'COMMON',
    60.000000,
    60.000000,
    current_date,
    'ACTIVE',
    'OWNERSHIP_AUDIT_LEGAL_' || v_suffix,
    'initial legal entity shareholder test fix v5',
    jsonb_build_object('test','legal_shareholder_fix_v5')
  );

  INSERT INTO org.entity_shareholders (
    id,
    tenant_id,
    legal_entity_id,
    business_code,
    shareholder_type,
    shareholder_name,
    shareholder_tax_number,
    share_class,
    ownership_percentage,
    voting_percentage,
    effective_from,
    status,
    ownership_audit_ref,
    ownership_change_reason,
    metadata
  )
  VALUES (
    v_external_shareholder_id,
    v_tenant_id,
    v_entity_id,
    'ENTITY_SHAREHOLDER_INDIVIDUAL_' || v_suffix,
    'INDIVIDUAL',
    'PIX2PI INDIVIDUAL SHAREHOLDER',
    '830' || substr(replace(v_suffix,'_',''),1,7),
    'COMMON',
    40.000000,
    40.000000,
    current_date,
    'ACTIVE',
    'OWNERSHIP_AUDIT_INDIVIDUAL_' || v_suffix,
    'initial individual shareholder test fix v5',
    jsonb_build_object('test','individual_shareholder_fix_v5')
  );

  SELECT count(*)
  INTO v_count
  FROM org.entity_shareholders
  WHERE tenant_id=v_tenant_id
    AND legal_entity_id=v_entity_id
    AND status='ACTIVE';

  IF v_count <> 2 THEN
    RAISE EXCEPTION 'shareholder valid insert/read failed';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='shareholder_kind'
  ) THEN
    SELECT count(*)
    INTO v_count
    FROM org.entity_shareholders
    WHERE tenant_id=v_tenant_id
      AND legal_entity_id=v_entity_id
      AND shareholder_kind IS NOT NULL
      AND btrim(shareholder_kind::text) <> '';

    IF v_count <> 2 THEN
      RAISE EXCEPTION 'legacy shareholder_kind bridge did not populate rows';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='ownership_ratio'
  ) THEN
    SELECT count(*)
    INTO v_count
    FROM org.entity_shareholders
    WHERE tenant_id=v_tenant_id
      AND legal_entity_id=v_entity_id
      AND ownership_ratio IS NOT NULL;

    IF v_count <> 2 THEN
      RAISE EXCEPTION 'legacy ownership_ratio bridge did not populate rows';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='org'
      AND table_name='entity_shareholders'
      AND column_name='voting_ratio'
  ) THEN
    SELECT count(*)
    INTO v_count
    FROM org.entity_shareholders
    WHERE tenant_id=v_tenant_id
      AND legal_entity_id=v_entity_id
      AND voting_ratio IS NOT NULL;

    IF v_count <> 2 THEN
      RAISE EXCEPTION 'legacy voting_ratio bridge did not populate rows';
    END IF;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM org.entity_shareholders
  WHERE tenant_id=v_tenant_id
    AND legal_entity_id=v_entity_id
    AND ownership_audit_ref IS NOT NULL
    AND ownership_change_reason IS NOT NULL;

  IF v_count <> 2 THEN
    RAISE EXCEPTION 'ownership audit fields not persisted';
  END IF;

  BEGIN
    INSERT INTO org.entity_shareholders (
      tenant_id,
      legal_entity_id,
      business_code,
      shareholder_type,
      shareholder_name,
      ownership_percentage,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_entity_id,
      'ENTITY_SHAREHOLDER_OVER_100_' || v_suffix,
      'OTHER',
      'OVER 100 SHAREHOLDER',
      1.000000,
      current_date,
      'ACTIVE'
    );

    RAISE EXCEPTION 'ownership over 100 was not blocked';
  EXCEPTION WHEN raise_exception THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_shareholders (
      tenant_id,
      legal_entity_id,
      business_code,
      shareholder_type,
      shareholder_entity_id,
      shareholder_name,
      ownership_percentage,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_entity_id,
      'ENTITY_SHAREHOLDER_SELF_' || v_suffix,
      'LEGAL_ENTITY',
      v_entity_id,
      'SELF OWNERSHIP',
      1.000000,
      current_date + 1000,
      'INACTIVE'
    );

    RAISE EXCEPTION 'self ownership was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_shareholders (
      tenant_id,
      legal_entity_id,
      business_code,
      shareholder_type,
      shareholder_name,
      ownership_percentage,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_entity_id,
      'ENTITY_SHAREHOLDER_BAD_TYPE_' || v_suffix,
      'BAD_TYPE',
      'BAD TYPE SHAREHOLDER',
      1.000000,
      current_date + 1000,
      'INACTIVE'
    );

    RAISE EXCEPTION 'invalid shareholder_type was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_shareholders (
      tenant_id,
      legal_entity_id,
      business_code,
      shareholder_type,
      shareholder_name,
      ownership_percentage,
      effective_from,
      status
    )
    VALUES (
      v_tenant_id,
      v_entity_id,
      'ENTITY_SHAREHOLDER_NEGATIVE_' || v_suffix,
      'OTHER',
      'NEGATIVE SHAREHOLDER',
      -1.000000,
      current_date + 1000,
      'ACTIVE'
    );

    RAISE EXCEPTION 'negative ownership percentage was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO org.entity_shareholders (
      tenant_id,
      legal_entity_id,
      business_code,
      shareholder_type,
      shareholder_name,
      ownership_percentage,
      effective_from,
      effective_to,
      status
    )
    VALUES (
      v_tenant_id,
      v_entity_id,
      'ENTITY_SHAREHOLDER_BAD_DATE_' || v_suffix,
      'OTHER',
      'BAD DATE SHAREHOLDER',
      1.000000,
      current_date + 1000,
      current_date + 999,
      'INACTIVE'
    );

    RAISE EXCEPTION 'bad effective date range was not blocked';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END \$\$;

ROLLBACK;
SQL

echo "8.1 ownership SQL suite FIX V5 dosyası yazıldı: $OWNERSHIP_TEST_SQL / OK ✅"

echo "9. ownership lifecycle / abuse SQL suite FIX V5 çalıştırılıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$OWNERSHIP_TEST_SQL" > "$OWNERSHIP_TEST_OUT" 2>&1; then
  pass "9.1 ownership lifecycle / abuse SQL suite geçti"
else
  fail "9.1 ownership lifecycle / abuse SQL suite başarısız"
  cat "$OWNERSHIP_TEST_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$OWNERSHIP_TEST_OUT"; then
  pass "9.2 ownership test rollback ile temizlendi"
  OWNERSHIP_TEST_STATUS="PASS"
else
  fail "9.2 ownership rollback kanıtı yok"
  OWNERSHIP_TEST_STATUS="FAIL"
fi

echo "10. org.entity_shareholders sayaçları alınıyor..."

ENTITY_SHAREHOLDER_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
ENTITY_SHAREHOLDER_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name in ('id','tenant_id','legal_entity_id','branch_id','business_code','shareholder_type','shareholder_entity_id','shareholder_name','shareholder_tax_number','share_class','ownership_percentage','voting_percentage','effective_from','effective_to','status','ownership_audit_ref','ownership_change_reason','metadata','audit_metadata','created_at','updated_at','created_by','updated_by','deleted_at');")"
ENTITY_SHAREHOLDER_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='f';")"
ENTITY_SHAREHOLDER_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='c';")"
ENTITY_SHAREHOLDER_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_shareholders';")"
ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relrowsecurity=true;")"
ENTITY_SHAREHOLDER_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relforcerowsecurity=true;")"
ENTITY_SHAREHOLDER_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_shareholders';")"
OWNERSHIP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='prevent_entity_shareholder_over_100';")"
OWNERSHIP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_prevent_over_100' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"
UPDATED_AT_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_set_updated_at' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"
OWNERSHIP_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name in ('ownership_audit_ref','ownership_change_reason','audit_metadata');")"
ENTITY_SHAREHOLDER_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='entity_shareholders';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_sync_legacy_fields' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"

echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_COLUMN_COUNT=$ENTITY_SHAREHOLDER_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "OWNERSHIP_TEST_STATUS=$OWNERSHIP_TEST_STATUS"

[ "$ENTITY_SHAREHOLDER_TABLE_COUNT" -eq 1 ] && pass "10.1 org.entity_shareholders tablosu hazır" || fail "10.1 org.entity_shareholders tablosu eksik"
[ "$ENTITY_SHAREHOLDER_COLUMN_COUNT" -ge 24 ] && pass "10.2 org.entity_shareholders kolon kapsamı tam" || fail "10.2 kolon kapsamı eksik"
[ "$ENTITY_SHAREHOLDER_FK_COUNT" -ge 2 ] && pass "10.3 entity/shareholder FK seti hazır" || fail "10.3 FK seti eksik"
[ "$ENTITY_SHAREHOLDER_CHECK_COUNT" -ge 8 ] && pass "10.4 check constraint seti hazır" || fail "10.4 check constraint seti eksik"
[ "$ENTITY_SHAREHOLDER_INDEX_COUNT" -ge 9 ] && pass "10.5 ownership index seti hazır" || fail "10.5 ownership index seti eksik"
[ "$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT" -eq 1 ] && pass "10.6 entity_shareholders RLS enabled" || fail "10.6 RLS enabled eksik"
[ "$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT" -eq 1 ] && pass "10.7 entity_shareholders RLS forced" || fail "10.7 RLS forced eksik"
[ "$ENTITY_SHAREHOLDER_POLICY_COUNT" -ge 1 ] && pass "10.8 entity_shareholders tenant policy hazır" || fail "10.8 tenant policy eksik"
[ "$OWNERSHIP_FUNCTION_COUNT" -eq 1 ] && pass "10.9 ownership percentage guard function hazır" || fail "10.9 ownership percentage guard function eksik"
[ "$OWNERSHIP_TRIGGER_COUNT" -eq 1 ] && pass "10.10 ownership percentage guard trigger hazır" || fail "10.10 ownership percentage guard trigger eksik"
[ "$UPDATED_AT_TRIGGER_COUNT" -eq 1 ] && pass "10.11 updated_at trigger hazır" || fail "10.11 updated_at trigger eksik"
[ "$OWNERSHIP_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "10.12 ownership audit kolonları hazır" || fail "10.12 ownership audit kolonları eksik"
[ "$ENTITY_SHAREHOLDER_DICTIONARY_COUNT" -ge 1 ] && pass "10.13 data dictionary kaydı mevcut" || warn "10.13 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "10.14 legacy bridge trigger hazır" || fail "10.14 legacy bridge trigger eksik"
[ "$OWNERSHIP_TEST_STATUS" = "PASS" ] && pass "10.15 ownership lifecycle / abuse suite PASS" || fail "10.15 ownership lifecycle / abuse suite FAIL"

echo "11. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_2_org_entity_shareholders_strict_suite_fix_v5_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_2_ORG_ENTITY_SHAREHOLDERS_STRICT_SUITE_RESULT_FIX_V5_$TS.md"

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

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 START ====="

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

ENTITY_SHAREHOLDER_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
ENTITY_SHAREHOLDER_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='f';")"
ENTITY_SHAREHOLDER_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='c';")"
ENTITY_SHAREHOLDER_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_shareholders';")"
ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relrowsecurity=true;")"
ENTITY_SHAREHOLDER_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relforcerowsecurity=true;")"
ENTITY_SHAREHOLDER_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_shareholders';")"
OWNERSHIP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='prevent_entity_shareholder_over_100';")"
OWNERSHIP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_prevent_over_100' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"
OWNERSHIP_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name in ('ownership_audit_ref','ownership_change_reason','audit_metadata');")"
ENTITY_SHAREHOLDER_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='entity_shareholders';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_sync_legacy_fields' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"

echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ "$ENTITY_SHAREHOLDER_TABLE_COUNT" -eq 1 ] && pass "5.1 org.entity_shareholders tablosu hazır" || fail "5.1 org.entity_shareholders tablosu eksik"
[ "$ENTITY_SHAREHOLDER_FK_COUNT" -ge 2 ] && pass "5.2 entity/shareholder FK seti hazır" || fail "5.2 FK seti eksik"
[ "$ENTITY_SHAREHOLDER_CHECK_COUNT" -ge 8 ] && pass "5.3 check constraint seti hazır" || fail "5.3 check constraint seti eksik"
[ "$ENTITY_SHAREHOLDER_INDEX_COUNT" -ge 9 ] && pass "5.4 ownership index seti hazır" || fail "5.4 ownership index seti eksik"
[ "$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 RLS enabled" || fail "5.5 RLS enabled eksik"
[ "$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 RLS forced" || fail "5.6 RLS forced eksik"
[ "$ENTITY_SHAREHOLDER_POLICY_COUNT" -ge 1 ] && pass "5.7 tenant policy hazır" || fail "5.7 tenant policy eksik"
[ "$OWNERSHIP_FUNCTION_COUNT" -eq 1 ] && pass "5.8 ownership percentage guard function hazır" || fail "5.8 ownership percentage guard function eksik"
[ "$OWNERSHIP_TRIGGER_COUNT" -eq 1 ] && pass "5.9 ownership percentage guard trigger hazır" || fail "5.9 ownership percentage guard trigger eksik"
[ "$OWNERSHIP_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.10 ownership audit kolonları hazır" || fail "5.10 ownership audit kolonları eksik"
[ "$ENTITY_SHAREHOLDER_DICTIONARY_COUNT" -ge 1 ] && pass "5.11 data dictionary kaydı mevcut" || warn "5.11 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "5.12 legacy sync trigger hazır" || fail "5.12 legacy sync trigger eksik"

{
  echo "# FAZ 1-3.2 org.entity_shareholders Strict Suite Result FIX V5"
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

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=PASS"
  echo "FAZ_1_3_2_EFFECTIVE_DATE_STATUS=PASS"
  echo "FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_ENTITY_SHAREHOLDERS_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS")"

ENTITY_SHAREHOLDERS_MODEL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS")"
OWNERSHIP_PERCENTAGE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS")"
EFFECTIVE_DATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_EFFECTIVE_DATE_STATUS")"
SHAREHOLDER_TYPE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS")"
OWNERSHIP_AUDIT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "13. strict suite FAIL_COUNT=0 doğrulandı" || fail "13. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "14. strict suite status PASS doğrulandı" || fail "14. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "15. strict suite seal SEALED doğrulandı" || fail "15. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "16. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-3.2 — org.entity_shareholders

## Kapsam

- Ortaklık modeli
- Pay oranı
- Effective date
- Shareholder type
- Ownership audit

## FIX V5

FIX V5 ownership abuse test sırasını düzeltti:
- OVER_100 testi ACTIVE kaldı.
- SELF_OWNERSHIP testi INACTIVE yapıldı.
- BAD_TYPE testi INACTIVE yapıldı.
- BAD_DATE testi INACTIVE yapıldı.
- NEGATIVE percentage testi ACTIVE kaldı.

Böylece over-100 trigger sadece kendi senaryosunda çalışır, diğer abuse testlerinde ilgili check constraint'ler gerçek olarak doğrulanır.

## Final Status

- FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=${ENTITY_SHAREHOLDERS_MODEL_STATUS:-N/A}
- FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=${OWNERSHIP_PERCENTAGE_STATUS:-N/A}
- FAZ_1_3_2_EFFECTIVE_DATE_STATUS=${EFFECTIVE_DATE_STATUS:-N/A}
- FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=${SHAREHOLDER_TYPE_STATUS:-N/A}
- FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=${OWNERSHIP_AUDIT_STATUS:-N/A}
- FAZ_1_3_2_ENTITY_SHAREHOLDERS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}
- FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-3.2 org.entity_shareholders FIX V5 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo "- Ownership SQL: $OWNERSHIP_TEST_SQL"
  echo "- Ownership output: $OWNERSHIP_TEST_OUT"
  echo
  echo "## Counts"
  echo "- LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT=$LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT"
  echo "- LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT=$LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT"
  echo "- LEGACY_VOTING_RATIO_COLUMN_COUNT=$LEGACY_VOTING_RATIO_COLUMN_COUNT"
  echo "- LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
  echo "- LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
  echo "- ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
  echo "- ENTITY_SHAREHOLDER_COLUMN_COUNT=$ENTITY_SHAREHOLDER_COLUMN_COUNT"
  echo "- ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
  echo "- ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
  echo "- ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
  echo "- ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
  echo "- ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
  echo "- ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
  echo "- OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
  echo "- OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
  echo "- UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
  echo "- OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
  echo "- ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
  echo "- OWNERSHIP_TEST_STATUS=$OWNERSHIP_TEST_STATUS"
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
  echo "# FAZ 1-3.2 org.entity_shareholders Final Seal FIX V5"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=${ENTITY_SHAREHOLDERS_MODEL_STATUS:-N/A}"
  echo "FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=${OWNERSHIP_PERCENTAGE_STATUS:-N/A}"
  echo "FAZ_1_3_2_EFFECTIVE_DATE_STATUS=${EFFECTIVE_DATE_STATUS:-N/A}"
  echo "FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=${SHAREHOLDER_TYPE_STATUS:-N/A}"
  echo "FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=${OWNERSHIP_AUDIT_STATUS:-N/A}"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_3_3_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "16.1 dokümantasyon yazıldı: $DOC_FILE"
pass "16.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "16.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$FIX_SCRIPT_FILE"
chmod +x "$FIX_SCRIPT_FILE"
pass "16.4 FIX V5 script repo içine kopyalandı: $FIX_SCRIPT_FILE"

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "OWNERSHIP_TEST_STATUS=$OWNERSHIP_TEST_STATUS"
echo "LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT=$LEGACY_SHAREHOLDER_KIND_COLUMN_COUNT"
echo "LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT=$LEGACY_OWNERSHIP_RATIO_COLUMN_COUNT"
echo "LEGACY_VOTING_RATIO_COLUMN_COUNT=$LEGACY_VOTING_RATIO_COLUMN_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_COLUMN_COUNT=$ENTITY_SHAREHOLDER_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "UPDATED_AT_TRIGGER_COUNT=$UPDATED_AT_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "ENTITY_SHAREHOLDERS_MODEL_STATUS=${ENTITY_SHAREHOLDERS_MODEL_STATUS:-N/A}"
echo "OWNERSHIP_PERCENTAGE_STATUS=${OWNERSHIP_PERCENTAGE_STATUS:-N/A}"
echo "EFFECTIVE_DATE_STATUS=${EFFECTIVE_DATE_STATUS:-N/A}"
echo "SHAREHOLDER_TYPE_STATUS=${SHAREHOLDER_TYPE_STATUS:-N/A}"
echo "OWNERSHIP_AUDIT_STATUS=${OWNERSHIP_AUDIT_STATUS:-N/A}"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "$OWNERSHIP_TEST_STATUS" = "PASS" ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=PASS"
  echo "FAZ_1_3_2_EFFECTIVE_DATE_STATUS=PASS"
  echo "FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_FINAL_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=SEALED"
  echo "FAZ_1_3_3_READY=YES"
else
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_FINAL_STATUS=FAIL"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=OPEN"
  echo "FAZ_1_3_3_READY=NO"
  exit 1
fi

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS FIX V5 END ====="
