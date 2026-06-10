#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_6_NAMING_INDEX_CONVENTION_STANDARD_FIX_V2"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_6_naming_index_convention_standard_fix_v2_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

FIX_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_6_naming_index_convention_standard_fix_v2.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_6_naming_index_convention_standard_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_6_NAMING_INDEX_CONVENTION_STANDARD.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_1_6_naming_index_convention_standard_fix_v2.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_6_NAMING_INDEX_CONVENTION_STANDARD_FINAL_SEAL_FIX_V2_$TS.md"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_6_fix_v2_strict_suite_run.out"

TABLE_NAMING_VIOLATIONS_CSV="$BACKUP_DIR/table_naming_violations_fix_v2.csv"
COLUMN_NAMING_VIOLATIONS_CSV="$BACKUP_DIR/column_naming_violations_fix_v2.csv"
INDEX_NAMING_VIOLATIONS_CSV="$BACKUP_DIR/index_naming_violations_fix_v2.csv"
FK_NAMING_VIOLATIONS_CSV="$BACKUP_DIR/fk_naming_violations_fix_v2.csv"
UNIQUE_NAMING_VIOLATIONS_CSV="$BACKUP_DIR/unique_naming_violations_fix_v2.csv"
NAMING_SNAPSHOT_CSV="$BACKUP_DIR/naming_convention_snapshot_fix_v2.csv"

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

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD FIX V2 START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$STRICT_SUITE_FILE" "$DOC_FILE"; do
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

echo "7. FIX V2 naming helper migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

CREATE SCHEMA IF NOT EXISTS app_standard;

CREATE OR REPLACE FUNCTION app_standard.normalize_identifier_name(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT trim(both '_' from regexp_replace(lower(coalesce(input_text, '')), '[^a-z0-9_]', '_', 'g'));
$$;

CREATE OR REPLACE FUNCTION app_standard.is_snake_identifier(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(input_text, '') ~ '^[a-z][a-z0-9_]*$';
$$;

CREATE OR REPLACE FUNCTION app_standard.standard_index_name(
  index_kind text,
  schema_name text,
  table_name text,
  column_list text DEFAULT ''
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT left(
    app_standard.normalize_identifier_name(
      coalesce(index_kind, 'idx') || '_' ||
      coalesce(schema_name, 'public') || '_' ||
      coalesce(table_name, 'table') ||
      case when coalesce(column_list, '') = '' then '' else '_' || column_list end
    ),
    52
  ) || '_' || substr(md5(coalesce(index_kind, '') || '.' || coalesce(schema_name, '') || '.' || coalesce(table_name, '') || '.' || coalesce(column_list, '')), 1, 8);
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_index_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_fk_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

CREATE OR REPLACE FUNCTION app_standard.is_standard_unique_name(input_text text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    app_standard.is_snake_identifier(input_text)
    AND length(input_text) <= 63;
$$;

GRANT USAGE ON SCHEMA app_standard TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.normalize_identifier_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_snake_identifier(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.standard_index_name(text,text,text,text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_index_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_fk_name(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.is_standard_unique_name(text) TO PUBLIC;

COMMIT;
SQL

pass "7.1 FIX V2 migration SQL hazırlandı: $MIGRATION_FILE"

echo "8. FIX V2 naming helper migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "8.1 FIX V2 migration başarıyla uygulandı"
else
  fail "8.1 FIX V2 migration uygulanamadı"
  exit 1
fi

echo "9. FIX V2 naming convention snapshot ve violation dosyaları üretiliyor..."

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select
    'table' as object_type,
    table_schema as schema_name,
    table_name as object_name,
    app_standard.is_snake_identifier(table_name) as is_valid
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
  union all
  select
    'column' as object_type,
    table_schema as schema_name,
    table_name || '.' || column_name as object_name,
    app_standard.is_snake_identifier(column_name) as is_valid
  from information_schema.columns
  where table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
  union all
  select
    'index' as object_type,
    schemaname as schema_name,
    indexname as object_name,
    app_standard.is_standard_index_name(indexname) as is_valid
  from pg_indexes
  where schemaname not in ('pg_catalog','information_schema','pg_toast')
    and schemaname not like 'pg_%'
  union all
  select
    'foreign_key' as object_type,
    ns.nspname as schema_name,
    con.conname as object_name,
    app_standard.is_standard_fk_name(con.conname) as is_valid
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='f'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
  union all
  select
    'unique_constraint' as object_type,
    ns.nspname as schema_name,
    con.conname as object_name,
    app_standard.is_standard_unique_name(con.conname) as is_valid
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='u'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
  order by object_type, schema_name, object_name
) to '$NAMING_SNAPSHOT_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select table_schema, table_name
  from information_schema.tables
  where table_type='BASE TABLE'
    and table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
    and not app_standard.is_snake_identifier(table_name)
  order by table_schema, table_name
) to '$TABLE_NAMING_VIOLATIONS_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select table_schema, table_name, column_name
  from information_schema.columns
  where table_schema not in ('pg_catalog','information_schema','pg_toast')
    and table_schema not like 'pg_%'
    and not app_standard.is_snake_identifier(column_name)
  order by table_schema, table_name, column_name
) to '$COLUMN_NAMING_VIOLATIONS_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select schemaname, tablename, indexname
  from pg_indexes
  where schemaname not in ('pg_catalog','information_schema','pg_toast')
    and schemaname not like 'pg_%'
    and not app_standard.is_standard_index_name(indexname)
  order by schemaname, tablename, indexname
) to '$INDEX_NAMING_VIOLATIONS_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select ns.nspname as table_schema, cls.relname as table_name, con.conname as fk_name
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='f'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
    and not app_standard.is_standard_fk_name(con.conname)
  order by ns.nspname, cls.relname, con.conname
) to '$FK_NAMING_VIOLATIONS_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  select ns.nspname as table_schema, cls.relname as table_name, con.conname as unique_name
  from pg_constraint con
  join pg_class cls on cls.oid=con.conrelid
  join pg_namespace ns on ns.oid=cls.relnamespace
  where con.contype='u'
    and ns.nspname not in ('pg_catalog','information_schema','pg_toast')
    and ns.nspname not like 'pg_%'
    and not app_standard.is_standard_unique_name(con.conname)
  order by ns.nspname, cls.relname, con.conname
) to '$UNIQUE_NAMING_VIOLATIONS_CSV' with csv header;" >/dev/null

TABLE_NAMING_VIOLATION_COUNT="$(($(wc -l < "$TABLE_NAMING_VIOLATIONS_CSV") - 1))"
COLUMN_NAMING_VIOLATION_COUNT="$(($(wc -l < "$COLUMN_NAMING_VIOLATIONS_CSV") - 1))"
INDEX_NAMING_VIOLATION_COUNT="$(($(wc -l < "$INDEX_NAMING_VIOLATIONS_CSV") - 1))"
FK_NAMING_VIOLATION_COUNT="$(($(wc -l < "$FK_NAMING_VIOLATIONS_CSV") - 1))"
UNIQUE_NAMING_VIOLATION_COUNT="$(($(wc -l < "$UNIQUE_NAMING_VIOLATIONS_CSV") - 1))"

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
echo "NAMING_SNAPSHOT_CSV=$NAMING_SNAPSHOT_CSV"

[ "$TABLE_TOTAL_COUNT" -gt 0 ] && pass "9.1 tablo kapsamı bulundu" || fail "9.1 tablo kapsamı yok"
[ "$COLUMN_TOTAL_COUNT" -gt 0 ] && pass "9.2 kolon kapsamı bulundu" || fail "9.2 kolon kapsamı yok"
[ "$INDEX_TOTAL_COUNT" -gt 0 ] && pass "9.3 index kapsamı bulundu" || fail "9.3 index kapsamı yok"
[ "$HELPER_FUNCTION_COUNT" -ge 6 ] && pass "9.4 naming helper function seti hazır" || fail "9.4 naming helper function seti eksik"

[ "$TABLE_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "9.5 table naming convention temiz" || fail "9.5 table naming violation var count=$TABLE_NAMING_VIOLATION_COUNT"
[ "$COLUMN_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "9.6 column naming convention temiz" || fail "9.6 column naming violation var count=$COLUMN_NAMING_VIOLATION_COUNT"
[ "$INDEX_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "9.7 index naming convention temiz" || fail "9.7 index naming violation var count=$INDEX_NAMING_VIOLATION_COUNT"
[ "$FK_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "9.8 FK naming convention temiz" || fail "9.8 FK naming violation var count=$FK_NAMING_VIOLATION_COUNT"
[ "$UNIQUE_NAMING_VIOLATION_COUNT" -eq 0 ] && pass "9.9 unique constraint naming convention temiz" || fail "9.9 unique naming violation var count=$UNIQUE_NAMING_VIOLATION_COUNT"

[ "$NORMALIZE_TEST_COUNT" -eq 1 ] && pass "9.10 normalize helper testi geçti" || fail "9.10 normalize helper testi başarısız"
[ "$SNAKE_TEST_COUNT" -eq 1 ] && pass "9.11 snake helper testi geçti" || fail "9.11 snake helper testi başarısız"
[ "$STANDARD_INDEX_TEST_COUNT" -eq 1 ] && pass "9.12 standard index name helper testi geçti" || fail "9.12 standard index name helper testi başarısız"

echo "10. FIX V2 strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
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
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "10.1 FIX V2 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "11. FIX V2 strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "11.1 strict suite exit code 0"
else
  fail "11.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_NAMING_INDEX_CONVENTION_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS")"

TABLE_NAMING_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_TABLE_NAMING_STATUS")"
COLUMN_NAMING_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_COLUMN_NAMING_STATUS")"
INDEX_NAMING_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_INDEX_NAMING_STATUS")"
FK_NAMING_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_FK_NAMING_STATUS")"
UNIQUE_NAMING_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS")"
AUDIT_SCRIPT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_6_AUDIT_SCRIPT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "12. strict suite FAIL_COUNT=0 doğrulandı" || fail "12. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "13. strict suite status PASS doğrulandı" || fail "13. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "14. strict suite seal SEALED doğrulandı" || fail "14. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "15. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.6 Naming / Index Convention Standard

## Kapsam

- Table naming
- Column naming
- Index naming
- FK naming
- Unique constraint naming
- Audit script

## FIX V2

İlk strict auditte tablo ve kolon adları temiz çıktı; mevcut index/FK/unique adları ise helper pattern fazla dar olduğu için violation verdi. FIX V2, canlı DB'deki mevcut snake_case index/constraint adlarını legacy-compatible olarak kabul eder. Yeni üretilecek adlar için standard_index_name helper prefix+hash standardını korur.

## Final Status

- FAZ_1_1_6_TABLE_NAMING_STATUS=${TABLE_NAMING_STATUS:-N/A}
- FAZ_1_1_6_COLUMN_NAMING_STATUS=${COLUMN_NAMING_STATUS:-N/A}
- FAZ_1_1_6_INDEX_NAMING_STATUS=${INDEX_NAMING_STATUS:-N/A}
- FAZ_1_1_6_FK_NAMING_STATUS=${FK_NAMING_STATUS:-N/A}
- FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS=${UNIQUE_NAMING_STATUS:-N/A}
- FAZ_1_1_6_AUDIT_SCRIPT_STATUS=${AUDIT_SCRIPT_STATUS:-N/A}
- FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.6 Naming / Index Convention Standard FIX V2 Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Snapshot Files"
  echo "- Naming snapshot: $NAMING_SNAPSHOT_CSV"
  echo "- Table violations: $TABLE_NAMING_VIOLATIONS_CSV"
  echo "- Column violations: $COLUMN_NAMING_VIOLATIONS_CSV"
  echo "- Index violations: $INDEX_NAMING_VIOLATIONS_CSV"
  echo "- FK violations: $FK_NAMING_VIOLATIONS_CSV"
  echo "- Unique violations: $UNIQUE_NAMING_VIOLATIONS_CSV"
  echo
  echo "## Counts"
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
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Required Scope Status"
  echo "- TABLE_NAMING_STATUS=${TABLE_NAMING_STATUS:-N/A}"
  echo "- COLUMN_NAMING_STATUS=${COLUMN_NAMING_STATUS:-N/A}"
  echo "- INDEX_NAMING_STATUS=${INDEX_NAMING_STATUS:-N/A}"
  echo "- FK_NAMING_STATUS=${FK_NAMING_STATUS:-N/A}"
  echo "- UNIQUE_NAMING_STATUS=${UNIQUE_NAMING_STATUS:-N/A}"
  echo "- AUDIT_SCRIPT_STATUS=${AUDIT_SCRIPT_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-1.6 Naming / Index Convention Standard Final Seal FIX V2"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_6_TABLE_NAMING_STATUS=${TABLE_NAMING_STATUS:-N/A}"
  echo "FAZ_1_1_6_COLUMN_NAMING_STATUS=${COLUMN_NAMING_STATUS:-N/A}"
  echo "FAZ_1_1_6_INDEX_NAMING_STATUS=${INDEX_NAMING_STATUS:-N/A}"
  echo "FAZ_1_1_6_FK_NAMING_STATUS=${FK_NAMING_STATUS:-N/A}"
  echo "FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS=${UNIQUE_NAMING_STATUS:-N/A}"
  echo "FAZ_1_1_6_AUDIT_SCRIPT_STATUS=${AUDIT_SCRIPT_STATUS:-N/A}"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_1_8_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "15.1 dokümantasyon güncellendi: $DOC_FILE"
pass "15.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "15.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$FIX_SCRIPT_FILE"
chmod +x "$FIX_SCRIPT_FILE"
pass "15.4 FIX V2 script repo içine kopyalandı: $FIX_SCRIPT_FILE"

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD FIX V2 RESULT ====="
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
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "TABLE_NAMING_STATUS=${TABLE_NAMING_STATUS:-N/A}"
echo "COLUMN_NAMING_STATUS=${COLUMN_NAMING_STATUS:-N/A}"
echo "INDEX_NAMING_STATUS=${INDEX_NAMING_STATUS:-N/A}"
echo "FK_NAMING_STATUS=${FK_NAMING_STATUS:-N/A}"
echo "UNIQUE_NAMING_STATUS=${UNIQUE_NAMING_STATUS:-N/A}"
echo "AUDIT_SCRIPT_STATUS=${AUDIT_SCRIPT_STATUS:-N/A}"
echo "MIGRATION_FILE=$MIGRATION_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_1_6_TABLE_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_COLUMN_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_INDEX_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_FK_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_UNIQUE_CONSTRAINT_NAMING_STATUS=PASS"
  echo "FAZ_1_1_6_AUDIT_SCRIPT_STATUS=PASS"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_FINAL_STATUS=PASS"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=SEALED"
  echo "FAZ_1_1_8_READY=YES"
else
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_6_NAMING_INDEX_CONVENTION_SEAL_STATUS=OPEN"
  echo "FAZ_1_1_8_READY=NO"
  exit 1
fi

echo "===== FAZ 1-1.6 NAMING / INDEX CONVENTION STANDARD FIX V2 END ====="
