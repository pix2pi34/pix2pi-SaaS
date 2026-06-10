#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_6_naming_index_convention_standard_strict_suite_fix_v2_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_6_NAMING_INDEX_CONVENTION_STANDARD_STRICT_SUITE_RESULT_FIX_V2_$TS.md"

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

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD STRICT SUITE FIX V2 START ====="

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

echo "5. naming convention sayaçları alınıyor..."

TABLE_TOTAL_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%';
")"

COLUMN_TOTAL_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%';
")"

INDEX_TOTAL_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname not in ('pg_catalog','information_schema','pg_toast')
    and schemaname not like 'pg_%';
")"

FK_TOTAL_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='f'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%';
")"

UNIQUE_TOTAL_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='u'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%';
")"

HELPER_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='app_standard'
    and p.proname in (
      'normalize_identifier_name',
      'is_snake_identifier',
      'standard_index_name',
      'is_standard_index_name',
      'is_standard_fk_name',
      'is_standard_unique_name'
    );
")"

TABLE_NAMING_VIOLATION_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
    and not app_standard.is_snake_identifier(table_name);
")"

COLUMN_NAMING_VIOLATION_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
    and not app_standard.is_snake_identifier(column_name);
")"

INDEX_NAMING_VIOLATION_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname not in ('pg_catalog','information_schema','pg_toast')
    and schemaname not like 'pg_%'
    and not app_standard.is_standard_index_name(indexname);
")"

FK_NAMING_VIOLATION_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='f'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
    and not app_standard.is_standard_fk_name(con.conname);
")"

UNIQUE_NAMING_VIOLATION_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='u'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
    and not app_standard.is_standard_unique_name(con.conname);
")"

NORMALIZE_TEST_COUNT="$(scalar_count "
  select case when app_standard.normalize_identifier_name('Test Name-ABC')='test_name_abc' then 1 else 0 end;
")"

SNAKE_TEST_COUNT="$(scalar_count "
  select case
    when app_standard.is_snake_identifier('valid_name_123') = true
     and app_standard.is_snake_identifier('InvalidName') = false
    then 1 else 0 end;
")"

STANDARD_INDEX_TEST_COUNT="$(scalar_count "
  select case
    when app_standard.standard_index_name('idx','erp','sales_invoice','tenant_id') ~ '^idx_erp_sales_invoice_tenant_id_[a-f0-9]{8}$'
    then 1 else 0 end;
")"

echo "TABLE_TOTAL_COUNT=$TABLE_TOTAL_COUNT"
echo "COLUMN_TOTAL_COUNT=$COLUMN_TOTAL_COUNT"
echo "INDEX_TOTAL_COUNT=$INDEX_TOTAL_COUNT"
echo "FK_TOTAL_COUNT=$FK_TOTAL_COUNT"
echo "UNIQUE_TOTAL_COUNT=$UNIQUE_TOTAL_COUNT"
echo "HELPER_FUNCTION_COUNT=$HELPER_FUNCTION_COUNT"
echo "TABLE_NAMING_VIOLATION_COUNT=$TABLE_NAMING_VIOLATION_COUNT"
echo "COLUMN_NAMING_VIOLATION_COUNT=$COLUMN_NAMING_VIOLATION_COUNT"
echo "INDEX_NAMING_VIOLATION_COUNT=$INDEX_NAMING_VIOLATION_COUNT"
echo "FK_NAMING_VIOLATION_COUNT=$FK_NAMING_VIOLATION_COUNT"
echo "UNIQUE_NAMING_VIOLATION_COUNT=$UNIQUE_NAMING_VIOLATION_COUNT"
echo "NORMALIZE_TEST_COUNT=$NORMALIZE_TEST_COUNT"
echo "SNAKE_TEST_COUNT=$SNAKE_TEST_COUNT"
echo "STANDARD_INDEX_TEST_COUNT=$STANDARD_INDEX_TEST_COUNT"

[ "$TABLE_TOTAL_COUNT" -gt 0 ] && pass "5.1 table naming kapsamı bulundu" || fail "5.1 table naming kapsamı yok"
[ "$COLUMN_TOTAL_COUNT" -gt 0 ] && pass "5.2 column naming kapsamı bulundu" || fail "5.2 column naming kapsamı yok"
[ "$INDEX_TOTAL_COUNT" -gt 0 ] && pass "5.3 index naming kapsamı bulundu" || fail "5.3 index naming kapsamı yok"
[ "$HELPER_FUNCTION_COUNT" -ge 6 ] && pass "5.4 naming helper function seti hazır" || fail "5.4 naming helper function seti eksik"
[ "$TABLE_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "5.5 table naming temiz" || fail "5.5 table naming violation var"
[ "$COLUMN_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "5.6 column naming temiz" || fail "5.6 column naming violation var"
[ "$INDEX_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "5.7 index naming temiz" || fail "5.7 index naming violation var"
[ "$FK_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "5.8 FK naming temiz" || fail "5.8 FK naming violation var"
[ "$UNIQUE_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "5.9 unique constraint naming temiz" || fail "5.9 unique constraint naming violation var"
[ "$NORMALIZE_TEST_COUNT" -eq 1 ] && pass "5.10 normalize helper testi geçti" || fail "5.10 normalize helper testi başarısız"
[ "$SNAKE_TEST_COUNT" -eq 1 ] && pass "5.11 snake helper testi geçti" || fail "5.11 snake helper testi başarısız"
[ "$STANDARD_INDEX_TEST_COUNT" -eq 1 ] && pass "5.12 standard index name helper testi geçti" || fail "5.12 standard index name helper testi başarısız"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/naming_index_convention_standard_strict_assertion_fix_v2.sql"
SQL_SUITE_OUT="$BACKUP_DIR/naming_index_convention_standard_strict_assertion_fix_v2.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_table_violation int;
  v_column_violation int;
  v_index_violation int;
  v_fk_violation int;
  v_unique_violation int;
  v_helper_count int;
BEGIN
  SELECT count(*)
  INTO v_helper_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='app_standard'
    AND p.proname IN (
      'normalize_identifier_name',
      'is_snake_identifier',
      'standard_index_name',
      'is_standard_index_name',
      'is_standard_fk_name',
      'is_standard_unique_name'
    );

  IF v_helper_count < 6 THEN
    RAISE EXCEPTION 'naming helper function set missing count=%', v_helper_count;
  END IF;

  SELECT count(*)
  INTO v_table_violation
  FROM information_schema.tables
  WHERE table_type='BASE TABLE'
    AND table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND table_schema NOT LIKE 'pg_%'
    AND NOT app_standard.is_snake_identifier(table_name);

  IF v_table_violation <> 0 THEN
    RAISE EXCEPTION 'table naming violation count=%', v_table_violation;
  END IF;

  SELECT count(*)
  INTO v_column_violation
  FROM information_schema.columns
  WHERE table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
    AND table_schema NOT LIKE 'pg_%'
    AND NOT app_standard.is_snake_identifier(column_name);

  IF v_column_violation <> 0 THEN
    RAISE EXCEPTION 'column naming violation count=%', v_column_violation;
  END IF;

  SELECT count(*)
  INTO v_index_violation
  FROM pg_indexes
  WHERE schemaname NOT IN ('pg_catalog','information_schema','pg_toast')
    AND schemaname NOT LIKE 'pg_%'
    AND NOT app_standard.is_standard_index_name(indexname);

  IF v_index_violation <> 0 THEN
    RAISE EXCEPTION 'index naming violation count=%', v_index_violation;
  END IF;

  SELECT count(*)
  INTO v_fk_violation
  FROM pg_constraint con
  JOIN pg_class cls ON cls.oid=con.conrelid
  JOIN pg_namespace ns ON ns.oid=cls.relnamespace
  WHERE con.contype='f'
    AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    AND ns.nspname NOT LIKE 'pg_%'
    AND NOT app_standard.is_standard_fk_name(con.conname);

  IF v_fk_violation <> 0 THEN
    RAISE EXCEPTION 'FK naming violation count=%', v_fk_violation;
  END IF;

  SELECT count(*)
  INTO v_unique_violation
  FROM pg_constraint con
  JOIN pg_class cls ON cls.oid=con.conrelid
  JOIN pg_namespace ns ON ns.oid=cls.relnamespace
  WHERE con.contype='u'
    AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    AND ns.nspname NOT LIKE 'pg_%'
    AND NOT app_standard.is_standard_unique_name(con.conname);

  IF v_unique_violation <> 0 THEN
    RAISE EXCEPTION 'unique constraint naming violation count=%', v_unique_violation;
  END IF;

  IF app_standard.normalize_identifier_name('Test Name-ABC') <> 'test_name_abc' THEN
    RAISE EXCEPTION 'normalize_identifier_name test failed';
  END IF;

  IF app_standard.is_snake_identifier('valid_name_123') IS NOT TRUE THEN
    RAISE EXCEPTION 'is_snake_identifier positive test failed';
  END IF;

  IF app_standard.is_snake_identifier('InvalidName') IS NOT FALSE THEN
    RAISE EXCEPTION 'is_snake_identifier negative test failed';
  END IF;

  IF app_standard.standard_index_name('idx','erp','sales_invoice','tenant_id') !~ '^idx_erp_sales_invoice_tenant_id_[a-f0-9]{8}$' THEN
    RAISE EXCEPTION 'standard_index_name helper test failed';
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
  echo "# FAZ 1-1.6 Naming / Index Convention Standard Strict Suite Result FIX V2"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- TABLE_TOTAL_COUNT=$TABLE_TOTAL_COUNT"
  echo "- COLUMN_TOTAL_COUNT=$COLUMN_TOTAL_COUNT"
  echo "- INDEX_TOTAL_COUNT=$INDEX_TOTAL_COUNT"
  echo "- FK_TOTAL_COUNT=$FK_TOTAL_COUNT"
  echo "- UNIQUE_TOTAL_COUNT=$UNIQUE_TOTAL_COUNT"
  echo "- HELPER_FUNCTION_COUNT=$HELPER_FUNCTION_COUNT"
  echo "- TABLE_NAMING_VIOLATION_COUNT=$TABLE_NAMING_VIOLATION_COUNT"
  echo "- COLUMN_NAMING_VIOLATION_COUNT=$COLUMN_NAMING_VIOLATION_COUNT"
  echo "- INDEX_NAMING_VIOLATION_COUNT=$INDEX_NAMING_VIOLATION_COUNT"
  echo "- FK_NAMING_VIOLATION_COUNT=$FK_NAMING_VIOLATION_COUNT"
  echo "- UNIQUE_NAMING_VIOLATION_COUNT=$UNIQUE_NAMING_VIOLATION_COUNT"
  echo "- NORMALIZE_TEST_COUNT=$NORMALIZE_TEST_COUNT"
  echo "- SNAKE_TEST_COUNT=$SNAKE_TEST_COUNT"
  echo "- STANDARD_INDEX_TEST_COUNT=$STANDARD_INDEX_TEST_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD STRICT SUITE FIX V2 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TABLE_TOTAL_COUNT=$TABLE_TOTAL_COUNT"
echo "COLUMN_TOTAL_COUNT=$COLUMN_TOTAL_COUNT"
echo "INDEX_TOTAL_COUNT=$INDEX_TOTAL_COUNT"
echo "FK_TOTAL_COUNT=$FK_TOTAL_COUNT"
echo "UNIQUE_TOTAL_COUNT=$UNIQUE_TOTAL_COUNT"
echo "HELPER_FUNCTION_COUNT=$HELPER_FUNCTION_COUNT"
echo "TABLE_NAMING_VIOLATION_COUNT=$TABLE_NAMING_VIOLATION_COUNT"
echo "COLUMN_NAMING_VIOLATION_COUNT=$COLUMN_NAMING_VIOLATION_COUNT"
echo "INDEX_NAMING_VIOLATION_COUNT=$INDEX_NAMING_VIOLATION_COUNT"
echo "FK_NAMING_VIOLATION_COUNT=$FK_NAMING_VIOLATION_COUNT"
echo "UNIQUE_NAMING_VIOLATION_COUNT=$UNIQUE_NAMING_VIOLATION_COUNT"
echo "NORMALIZE_TEST_COUNT=$NORMALIZE_TEST_COUNT"
echo "SNAKE_TEST_COUNT=$SNAKE_TEST_COUNT"
echo "STANDARD_INDEX_TEST_COUNT=$STANDARD_INDEX_TEST_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_6_TABLE_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_COLUMN_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_INDEX_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_FK_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_AUDIT_SCRIPT_STATUS=PASS"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD STRICT SUITE FIX V2 END ====="
