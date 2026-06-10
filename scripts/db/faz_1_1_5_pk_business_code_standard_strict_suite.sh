#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_5_pk_business_code_standard_strict_suite_fix_v3b_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD_STRICT_SUITE_RESULT_FIX_V3B_$TS.md"

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

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE FIX V3B START ====="

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

echo "5. PK / business-code coverage sayaçları alınıyor..."

BUSINESS_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and table_schema not like 'pg_%'
    and table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and table_name not like '\_%';
")"

ID_COLUMN_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables t
  where t.table_type='BASE TABLE'
    and t.table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and t.table_schema not like 'pg_%'
    and t.table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and t.table_name not like '\_%'
    and exists (
      select 1 from information_schema.columns c
      where c.table_schema=t.table_schema
        and c.table_name=t.table_name
        and c.column_name='id'
    );
")"

PK_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables t
  where t.table_type='BASE TABLE'
    and t.table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and t.table_schema not like 'pg_%'
    and t.table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and t.table_name not like '\_%'
    and exists (
      select 1 from information_schema.table_constraints tc
      where tc.table_schema=t.table_schema
        and tc.table_name=t.table_name
        and tc.constraint_type='PRIMARY KEY'
    );
")"

BUSINESS_CODE_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables t
  where t.table_type='BASE TABLE'
    and t.table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and t.table_schema not like 'pg_%'
    and t.table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and t.table_name not like '\_%'
    and exists (
      select 1 from information_schema.columns c
      where c.table_schema=t.table_schema
        and c.table_name=t.table_name
        and c.column_name='business_code'
    );
")"

TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables t
  where t.table_type='BASE TABLE'
    and t.table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and t.table_schema not like 'pg_%'
    and t.table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and t.table_name not like '\_%'
    and exists (
      select 1
      from pg_indexes i
      where i.schemaname=t.table_schema
        and i.tablename=t.table_name
        and i.indexdef ilike '%UNIQUE%'
        and i.indexdef ilike '%tenant_id%'
        and i.indexdef ilike '%business_code%'
    );
")"

BUSINESS_CODE_FORMAT_CHECK_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables t
  where t.table_type='BASE TABLE'
    and t.table_schema not in (
      'pg_catalog',
      'information_schema',
      'auth',
      'security',
      'app_security',
      'audit',
      'ops',
      'monitoring',
      'observability',
      'pg_toast'
    )
    and t.table_schema not like 'pg_%'
    and t.table_name not in (
      'schema_migrations',
      'goose_db_version',
      'atlas_schema_revisions',
      'spatial_ref_sys'
    )
    and t.table_name not like '\_%'
    and exists (
      select 1
      from pg_constraint con
      join pg_class cls on cls.oid=con.conrelid
      join pg_namespace ns on ns.oid=cls.relnamespace
      where ns.nspname=t.table_schema
        and cls.relname=t.table_name
        and con.contype='c'
        and pg_get_constraintdef(con.oid) ilike '%business_code%'
    );
")"

CODE_GENERATOR_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='app_standard'
    and p.proname in ('generate_business_code','normalize_business_code');
")"

GENERATOR_TEST_COUNT="$(scalar_count "
  select case
    when app_standard.generate_business_code('TEST', '00000000-0000-0000-0000-000000000123'::uuid) ~ '^TEST_[A-F0-9]{12}$'
    then 1
    else 0
  end;
")"

UPPERCASE_GENERATOR_TEST_COUNT="$(scalar_count "
  select case
    when app_standard.generate_business_code('test code', '00000000-0000-0000-0000-000000abcdef'::uuid)
         = upper(app_standard.generate_business_code('test code', '00000000-0000-0000-0000-000000abcdef'::uuid))
    then 1
    else 0
  end;
")"

echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "ID_COLUMN_TABLE_COUNT=$ID_COLUMN_TABLE_COUNT"
echo "PK_TABLE_COUNT=$PK_TABLE_COUNT"
echo "BUSINESS_CODE_TABLE_COUNT=$BUSINESS_CODE_TABLE_COUNT"
echo "TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT=$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT"
echo "BUSINESS_CODE_FORMAT_CHECK_COUNT=$BUSINESS_CODE_FORMAT_CHECK_COUNT"
echo "CODE_GENERATOR_FUNCTION_COUNT=$CODE_GENERATOR_FUNCTION_COUNT"
echo "GENERATOR_TEST_COUNT=$GENERATOR_TEST_COUNT"
echo "UPPERCASE_GENERATOR_TEST_COUNT=$UPPERCASE_GENERATOR_TEST_COUNT"

[ "$BUSINESS_TABLE_COUNT" -gt 0 ] && pass "5.1 business table kapsamı bulundu" || fail "5.1 business table kapsamı yok"
[ "$ID_COLUMN_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.2 teknik id standardı tüm business tablolarda mevcut" || fail "5.2 teknik id standardı eksik"
[ "$PK_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.3 PK standardı tüm business tablolarda mevcut" || fail "5.3 PK standardı eksik"
[ "$BUSINESS_CODE_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.4 business_code standardı tüm business tablolarda mevcut" || fail "5.4 business_code standardı eksik"
[ "$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.5 tenant-safe unique index standardı tüm business tablolarda mevcut" || fail "5.5 tenant-safe unique index standardı eksik"
[ "$BUSINESS_CODE_FORMAT_CHECK_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.6 business_code format check standardı tüm business tablolarda mevcut" || fail "5.6 business_code format check standardı eksik"
[ "$CODE_GENERATOR_FUNCTION_COUNT" -ge 2 ] && pass "5.7 kod normalize/generate function seti mevcut" || fail "5.7 kod üretim function seti eksik"
[ "$GENERATOR_TEST_COUNT" -eq 1 ] && pass "5.8 kod üretim regex testi geçti" || fail "5.8 kod üretim regex testi başarısız"
[ "$UPPERCASE_GENERATOR_TEST_COUNT" -eq 1 ] && pass "5.9 kod üretim uppercase testi geçti" || fail "5.9 kod üretim uppercase testi başarısız"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/pk_business_code_standard_strict_assertion_fix_v3b.sql"
SQL_SUITE_OUT="$BACKUP_DIR/pk_business_code_standard_strict_assertion_fix_v3b.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_missing_id int;
  v_missing_pk int;
  v_missing_business_code int;
  v_missing_tenant_unique int;
  v_missing_format_check int;
  v_generator_ok int;
  v_generator_upper_ok int;
  r record;
  invalid_count bigint;
BEGIN
  WITH business_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  )
  SELECT count(*) INTO v_missing_id
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema=bt.table_schema
      AND c.table_name=bt.table_name
      AND c.column_name='id'
  );

  IF v_missing_id <> 0 THEN
    RAISE EXCEPTION 'technical id standard missing count=%', v_missing_id;
  END IF;

  WITH business_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  )
  SELECT count(*) INTO v_missing_pk
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    WHERE tc.table_schema=bt.table_schema
      AND tc.table_name=bt.table_name
      AND tc.constraint_type='PRIMARY KEY'
  );

  IF v_missing_pk <> 0 THEN
    RAISE EXCEPTION 'primary key standard missing count=%', v_missing_pk;
  END IF;

  WITH business_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  )
  SELECT count(*) INTO v_missing_business_code
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema=bt.table_schema
      AND c.table_name=bt.table_name
      AND c.column_name='business_code'
  );

  IF v_missing_business_code <> 0 THEN
    RAISE EXCEPTION 'business_code standard missing count=%', v_missing_business_code;
  END IF;

  WITH business_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  )
  SELECT count(*) INTO v_missing_tenant_unique
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1 FROM pg_indexes i
    WHERE i.schemaname=bt.table_schema
      AND i.tablename=bt.table_name
      AND i.indexdef ILIKE '%UNIQUE%'
      AND i.indexdef ILIKE '%tenant_id%'
      AND i.indexdef ILIKE '%business_code%'
  );

  IF v_missing_tenant_unique <> 0 THEN
    RAISE EXCEPTION 'tenant-safe business_code unique index missing count=%', v_missing_tenant_unique;
  END IF;

  WITH business_tables AS (
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  )
  SELECT count(*) INTO v_missing_format_check
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_constraint con
    JOIN pg_class cls ON cls.oid=con.conrelid
    JOIN pg_namespace ns ON ns.oid=cls.relnamespace
    WHERE ns.nspname=bt.table_schema
      AND cls.relname=bt.table_name
      AND con.contype='c'
      AND pg_get_constraintdef(con.oid) ILIKE '%business_code%'
  );

  IF v_missing_format_check <> 0 THEN
    RAISE EXCEPTION 'business_code format check missing count=%', v_missing_format_check;
  END IF;

  FOR r IN
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_type='BASE TABLE'
      AND table_schema NOT IN (
        'pg_catalog',
        'information_schema',
        'auth',
        'security',
        'app_security',
        'audit',
        'ops',
        'monitoring',
        'observability',
        'pg_toast'
      )
      AND table_schema NOT LIKE 'pg_%'
      AND table_name NOT IN (
        'schema_migrations',
        'goose_db_version',
        'atlas_schema_revisions',
        'spatial_ref_sys'
      )
      AND table_name NOT LIKE '\_%'
  LOOP
    EXECUTE format(
      'SELECT count(*) FROM %I.%I
       WHERE business_code IS NULL
          OR btrim(business_code) = ''''
          OR business_code !~ %L',
      r.table_schema,
      r.table_name,
      '^[A-Z0-9][A-Z0-9_-]{1,127}$'
    )
    INTO invalid_count;

    IF invalid_count <> 0 THEN
      RAISE EXCEPTION 'invalid business_code rows in %.% count=%', r.table_schema, r.table_name, invalid_count;
    END IF;
  END LOOP;

  SELECT CASE
    WHEN app_standard.generate_business_code('TEST', '00000000-0000-0000-0000-000000000123'::uuid) ~ '^TEST_[A-F0-9]{12}$'
    THEN 1 ELSE 0
  END INTO v_generator_ok;

  IF v_generator_ok <> 1 THEN
    RAISE EXCEPTION 'business code generator regex test failed';
  END IF;

  SELECT CASE
    WHEN app_standard.generate_business_code('test code', '00000000-0000-0000-0000-000000abcdef'::uuid)
         = upper(app_standard.generate_business_code('test code', '00000000-0000-0000-0000-000000abcdef'::uuid))
    THEN 1 ELSE 0
  END INTO v_generator_upper_ok;

  IF v_generator_upper_ok <> 1 THEN
    RAISE EXCEPTION 'business code generator uppercase test failed';
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "6.1 strict SQL assertion suite geçti"
else
  fail "6.1 strict SQL assertion suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "6.2 strict SQL suite rollback ile temizlendi"
else
  fail "6.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-1.5 PK / Business-Code Standard Strict Suite Result FIX V3B"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
  echo "- ID_COLUMN_TABLE_COUNT=$ID_COLUMN_TABLE_COUNT"
  echo "- PK_TABLE_COUNT=$PK_TABLE_COUNT"
  echo "- BUSINESS_CODE_TABLE_COUNT=$BUSINESS_CODE_TABLE_COUNT"
  echo "- TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT=$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT"
  echo "- BUSINESS_CODE_FORMAT_CHECK_COUNT=$BUSINESS_CODE_FORMAT_CHECK_COUNT"
  echo "- CODE_GENERATOR_FUNCTION_COUNT=$CODE_GENERATOR_FUNCTION_COUNT"
  echo "- GENERATOR_TEST_COUNT=$GENERATOR_TEST_COUNT"
  echo "- UPPERCASE_GENERATOR_TEST_COUNT=$UPPERCASE_GENERATOR_TEST_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE FIX V3B RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "ID_COLUMN_TABLE_COUNT=$ID_COLUMN_TABLE_COUNT"
echo "PK_TABLE_COUNT=$PK_TABLE_COUNT"
echo "BUSINESS_CODE_TABLE_COUNT=$BUSINESS_CODE_TABLE_COUNT"
echo "TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT=$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT"
echo "BUSINESS_CODE_FORMAT_CHECK_COUNT=$BUSINESS_CODE_FORMAT_CHECK_COUNT"
echo "CODE_GENERATOR_FUNCTION_COUNT=$CODE_GENERATOR_FUNCTION_COUNT"
echo "GENERATOR_TEST_COUNT=$GENERATOR_TEST_COUNT"
echo "UPPERCASE_GENERATOR_TEST_COUNT=$UPPERCASE_GENERATOR_TEST_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_5_TECHNICAL_ID_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_5_BUSINESS_CODE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_5_TENANT_SAFE_UNIQUE_CONSTRAINT_STATUS=PASS"
  echo "FAZ_1_1_5_CODE_FORMAT_STATUS=PASS"
  echo "FAZ_1_1_5_CODE_GENERATION_TEST_STATUS=PASS"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE FIX V3B END ====="
