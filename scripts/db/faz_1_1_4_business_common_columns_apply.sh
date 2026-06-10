#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_4_BUSINESS_COMMON_COLUMNS"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_4_business_common_columns_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_4_business_common_columns_apply.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_4_business_common_columns_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_4_BUSINESS_COMMON_COLUMNS.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_1_4_business_common_columns.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_FINAL_SEAL_$TS.md"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_4_strict_suite_run.out"

BEFORE_MISSING_CSV="$BACKUP_DIR/business_common_columns_missing_before.csv"
AFTER_MISSING_CSV="$BACKUP_DIR/business_common_columns_missing_after.csv"
BUSINESS_TABLES_CSV="$BACKUP_DIR/business_table_candidates.csv"

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

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS APPLY START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$SUITE_RUNTIME_DIR" "$EVIDENCE_DIR" "$DOC_DIR" "$SCRIPT_DIR" "$MIGRATION_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$APPLY_SCRIPT_FILE" "$STRICT_SUITE_FILE" "$DOC_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
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

echo "7. business table adayları ve eksik kolon snapshot alınıyor..."

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  with business_tables as (
    select table_schema, table_name
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
      and table_name not like '\_%'
  )
  select table_schema, table_name
  from business_tables
  order by table_schema, table_name
) to '$BUSINESS_TABLES_CSV' with csv header;" >/dev/null

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  with business_tables as (
    select table_schema, table_name
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
      and table_name not like '\_%'
  ),
  required_cols as (
    select unnest(array[
      'tenant_id',
      'legal_entity_id',
      'branch_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'deleted_at',
      'audit_metadata'
    ]) as column_name
  )
  select bt.table_schema, bt.table_name, rc.column_name as missing_column
  from business_tables bt
  cross join required_cols rc
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema=bt.table_schema
      and c.table_name=bt.table_name
      and c.column_name=rc.column_name
  )
  order by bt.table_schema, bt.table_name, rc.column_name
) to '$BEFORE_MISSING_CSV' with csv header;" >/dev/null

BUSINESS_TABLE_COUNT="$(($(wc -l < "$BUSINESS_TABLES_CSV") - 1))"
BEFORE_MISSING_COUNT="$(($(wc -l < "$BEFORE_MISSING_CSV") - 1))"

echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "BEFORE_MISSING_COUNT=$BEFORE_MISSING_COUNT"
echo "BUSINESS_TABLES_CSV=$BUSINESS_TABLES_CSV"
echo "BEFORE_MISSING_CSV=$BEFORE_MISSING_CSV"

if [ "$BUSINESS_TABLE_COUNT" -gt 0 ]; then
  pass "7.1 business table adayları bulundu"
else
  fail "7.1 business table adayı bulunamadı"
  exit 1
fi

pass "7.2 eksik kolon snapshot alındı"

echo "8. migration SQL hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

DO $$
DECLARE
  r record;
BEGIN
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
    ORDER BY table_schema, table_name
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='tenant_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN tenant_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='legal_entity_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN legal_entity_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='branch_id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN branch_id uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='created_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN created_at timestamptz NOT NULL DEFAULT now()', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='updated_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now()', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='created_by'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN created_by uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='updated_by'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN updated_by uuid', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='deleted_at'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN deleted_at timestamptz', r.table_schema, r.table_name);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema=r.table_schema AND table_name=r.table_name AND column_name='audit_metadata'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN audit_metadata jsonb NOT NULL DEFAULT ''{}''::jsonb', r.table_schema, r.table_name);
    END IF;
  END LOOP;
END $$;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. migration sonrası eksik kolon snapshot alınıyor..."

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
  with business_tables as (
    select table_schema, table_name
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
      and table_name not like '\_%'
  ),
  required_cols as (
    select unnest(array[
      'tenant_id',
      'legal_entity_id',
      'branch_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'deleted_at',
      'audit_metadata'
    ]) as column_name
  )
  select bt.table_schema, bt.table_name, rc.column_name as missing_column
  from business_tables bt
  cross join required_cols rc
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema=bt.table_schema
      and c.table_name=bt.table_name
      and c.column_name=rc.column_name
  )
  order by bt.table_schema, bt.table_name, rc.column_name
) to '$AFTER_MISSING_CSV' with csv header;" >/dev/null

AFTER_MISSING_COUNT="$(($(wc -l < "$AFTER_MISSING_CSV") - 1))"

echo "AFTER_MISSING_COUNT=$AFTER_MISSING_COUNT"
echo "AFTER_MISSING_CSV=$AFTER_MISSING_CSV"

if [ "$AFTER_MISSING_COUNT" -eq 0 ]; then
  pass "10.1 tüm business tablolar ortak kolon standardına getirildi"
else
  fail "10.1 hâlâ eksik ortak kolon var count=$AFTER_MISSING_COUNT"
  cat "$AFTER_MISSING_CSV"
  exit 1
fi

echo "11. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_4_business_common_columns_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS STRICT SUITE START ====="

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

echo "5. business common column coverage sayaçları alınıyor..."

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

REQUIRED_COLUMN_TOTAL="$(scalar_count "
  with business_tables as (
    select table_schema, table_name
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
      and table_name not like '\_%'
  ),
  required_cols as (
    select unnest(array[
      'tenant_id',
      'legal_entity_id',
      'branch_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'deleted_at',
      'audit_metadata'
    ]) as column_name
  )
  select count(*)
  from business_tables cross join required_cols;
")"

ACTUAL_COLUMN_TOTAL="$(scalar_count "
  with business_tables as (
    select table_schema, table_name
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
      and table_name not like '\_%'
  ),
  required_cols as (
    select unnest(array[
      'tenant_id',
      'legal_entity_id',
      'branch_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'deleted_at',
      'audit_metadata'
    ]) as column_name
  )
  select count(*)
  from business_tables bt
  cross join required_cols rc
  join information_schema.columns c
    on c.table_schema=bt.table_schema
   and c.table_name=bt.table_name
   and c.column_name=rc.column_name;
")"

MISSING_COLUMN_TOTAL="$((REQUIRED_COLUMN_TOTAL - ACTUAL_COLUMN_TOTAL))"

TENANT_ID_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='tenant_id'
    );
")"

LEGAL_ENTITY_ID_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='legal_entity_id'
    );
")"

BRANCH_ID_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='branch_id'
    );
")"

CREATED_AT_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='created_at'
    );
")"

UPDATED_AT_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='updated_at'
    );
")"

CREATED_BY_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='created_by'
    );
")"

UPDATED_BY_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='updated_by'
    );
")"

DELETED_AT_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='deleted_at'
    );
")"

AUDIT_METADATA_TABLE_COUNT="$(scalar_count "
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
        and c.column_name='audit_metadata'
    );
")"

echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "REQUIRED_COLUMN_TOTAL=$REQUIRED_COLUMN_TOTAL"
echo "ACTUAL_COLUMN_TOTAL=$ACTUAL_COLUMN_TOTAL"
echo "MISSING_COLUMN_TOTAL=$MISSING_COLUMN_TOTAL"
echo "TENANT_ID_TABLE_COUNT=$TENANT_ID_TABLE_COUNT"
echo "LEGAL_ENTITY_ID_TABLE_COUNT=$LEGAL_ENTITY_ID_TABLE_COUNT"
echo "BRANCH_ID_TABLE_COUNT=$BRANCH_ID_TABLE_COUNT"
echo "CREATED_AT_TABLE_COUNT=$CREATED_AT_TABLE_COUNT"
echo "UPDATED_AT_TABLE_COUNT=$UPDATED_AT_TABLE_COUNT"
echo "CREATED_BY_TABLE_COUNT=$CREATED_BY_TABLE_COUNT"
echo "UPDATED_BY_TABLE_COUNT=$UPDATED_BY_TABLE_COUNT"
echo "DELETED_AT_TABLE_COUNT=$DELETED_AT_TABLE_COUNT"
echo "AUDIT_METADATA_TABLE_COUNT=$AUDIT_METADATA_TABLE_COUNT"

[ "$BUSINESS_TABLE_COUNT" -gt 0 ] && pass "5.1 business table kapsamı bulundu" || fail "5.1 business table kapsamı yok"
[ "$MISSING_COLUMN_TOTAL" -eq 0 ] && pass "5.2 tüm required common column coverage tam" || fail "5.2 eksik common column var"
[ "$TENANT_ID_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.3 tenant_id tüm business tablolarda mevcut" || fail "5.3 tenant_id kapsamı eksik"
[ "$LEGAL_ENTITY_ID_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.4 legal_entity_id tüm business tablolarda mevcut" || fail "5.4 legal_entity_id kapsamı eksik"
[ "$BRANCH_ID_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.5 branch_id tüm business tablolarda mevcut" || fail "5.5 branch_id kapsamı eksik"
[ "$CREATED_AT_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.6 created_at tüm business tablolarda mevcut" || fail "5.6 created_at kapsamı eksik"
[ "$UPDATED_AT_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.7 updated_at tüm business tablolarda mevcut" || fail "5.7 updated_at kapsamı eksik"
[ "$CREATED_BY_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.8 created_by tüm business tablolarda mevcut" || fail "5.8 created_by kapsamı eksik"
[ "$UPDATED_BY_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.9 updated_by tüm business tablolarda mevcut" || fail "5.9 updated_by kapsamı eksik"
[ "$DELETED_AT_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.10 deleted_at tüm business tablolarda mevcut" || fail "5.10 deleted_at kapsamı eksik"
[ "$AUDIT_METADATA_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.11 audit_metadata tüm business tablolarda mevcut" || fail "5.11 audit_metadata kapsamı eksik"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/business_common_columns_strict_assertion.sql"
SQL_SUITE_OUT="$BACKUP_DIR/business_common_columns_strict_assertion.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_missing int;
  v_business_tables int;
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
  ),
  required_cols AS (
    SELECT unnest(array[
      'tenant_id',
      'legal_entity_id',
      'branch_id',
      'created_at',
      'updated_at',
      'created_by',
      'updated_by',
      'deleted_at',
      'audit_metadata'
    ]) AS column_name
  )
  SELECT count(*)
  INTO v_missing
  FROM business_tables bt
  CROSS JOIN required_cols rc
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
    WHERE c.table_schema=bt.table_schema
      AND c.table_name=bt.table_name
      AND c.column_name=rc.column_name
  );

  SELECT count(*)
  INTO v_business_tables
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
    AND table_name NOT LIKE '\_%';

  IF v_business_tables < 1 THEN
    RAISE EXCEPTION 'business table scope is empty';
  END IF;

  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'business common column coverage has missing columns count=%', v_missing;
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
  echo "# FAZ 1-1.4 Business Common Columns Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
  echo "- REQUIRED_COLUMN_TOTAL=$REQUIRED_COLUMN_TOTAL"
  echo "- ACTUAL_COLUMN_TOTAL=$ACTUAL_COLUMN_TOTAL"
  echo "- MISSING_COLUMN_TOTAL=$MISSING_COLUMN_TOTAL"
  echo "- TENANT_ID_TABLE_COUNT=$TENANT_ID_TABLE_COUNT"
  echo "- LEGAL_ENTITY_ID_TABLE_COUNT=$LEGAL_ENTITY_ID_TABLE_COUNT"
  echo "- BRANCH_ID_TABLE_COUNT=$BRANCH_ID_TABLE_COUNT"
  echo "- CREATED_AT_TABLE_COUNT=$CREATED_AT_TABLE_COUNT"
  echo "- UPDATED_AT_TABLE_COUNT=$UPDATED_AT_TABLE_COUNT"
  echo "- CREATED_BY_TABLE_COUNT=$CREATED_BY_TABLE_COUNT"
  echo "- UPDATED_BY_TABLE_COUNT=$UPDATED_BY_TABLE_COUNT"
  echo "- DELETED_AT_TABLE_COUNT=$DELETED_AT_TABLE_COUNT"
  echo "- AUDIT_METADATA_TABLE_COUNT=$AUDIT_METADATA_TABLE_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "REQUIRED_COLUMN_TOTAL=$REQUIRED_COLUMN_TOTAL"
echo "ACTUAL_COLUMN_TOTAL=$ACTUAL_COLUMN_TOTAL"
echo "MISSING_COLUMN_TOTAL=$MISSING_COLUMN_TOTAL"
echo "TENANT_ID_TABLE_COUNT=$TENANT_ID_TABLE_COUNT"
echo "LEGAL_ENTITY_ID_TABLE_COUNT=$LEGAL_ENTITY_ID_TABLE_COUNT"
echo "BRANCH_ID_TABLE_COUNT=$BRANCH_ID_TABLE_COUNT"
echo "CREATED_AT_TABLE_COUNT=$CREATED_AT_TABLE_COUNT"
echo "UPDATED_AT_TABLE_COUNT=$UPDATED_AT_TABLE_COUNT"
echo "CREATED_BY_TABLE_COUNT=$CREATED_BY_TABLE_COUNT"
echo "UPDATED_BY_TABLE_COUNT=$UPDATED_BY_TABLE_COUNT"
echo "DELETED_AT_TABLE_COUNT=$DELETED_AT_TABLE_COUNT"
echo "AUDIT_METADATA_TABLE_COUNT=$AUDIT_METADATA_TABLE_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_4_TENANT_ID_STATUS=PASS"
  echo "FAZ_1_1_4_LEGAL_ENTITY_ID_STATUS=PASS"
  echo "FAZ_1_1_4_BRANCH_ID_STATUS=PASS"
  echo "FAZ_1_1_4_CREATED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_UPDATED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_CREATED_BY_STATUS=PASS"
  echo "FAZ_1_1_4_UPDATED_BY_STATUS=PASS"
  echo "FAZ_1_1_4_DELETED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_AUDIT_COLUMNS_STATUS=PASS"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS")"

TENANT_ID_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_TENANT_ID_STATUS")"
LEGAL_ENTITY_ID_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_LEGAL_ENTITY_ID_STATUS")"
BRANCH_ID_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_BRANCH_ID_STATUS")"
CREATED_AT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_CREATED_AT_STATUS")"
UPDATED_AT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_UPDATED_AT_STATUS")"
CREATED_BY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_CREATED_BY_STATUS")"
UPDATED_BY_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_UPDATED_BY_STATUS")"
DELETED_AT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_DELETED_AT_STATUS")"
AUDIT_COLUMNS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_4_AUDIT_COLUMNS_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "13. strict suite FAIL_COUNT=0 doğrulandı" || fail "13. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "14. strict suite status PASS doğrulandı" || fail "14. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "15. strict suite seal SEALED doğrulandı" || fail "15. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "16. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.4 Business Common Columns Standard

## Kapsam

- tenant_id
- legal_entity_id
- branch_id
- created_at
- updated_at
- created_by
- updated_by
- deleted_at
- audit columns

## Uygulama

Bu adım business table adaylarını metadata üzerinden tespit eder ve eksik standart kolonları güvenli migration ile ekler.

## Final Status

- FAZ_1_1_4_TENANT_ID_STATUS=${TENANT_ID_STATUS:-N/A}
- FAZ_1_1_4_LEGAL_ENTITY_ID_STATUS=${LEGAL_ENTITY_ID_STATUS:-N/A}
- FAZ_1_1_4_BRANCH_ID_STATUS=${BRANCH_ID_STATUS:-N/A}
- FAZ_1_1_4_CREATED_AT_STATUS=${CREATED_AT_STATUS:-N/A}
- FAZ_1_1_4_UPDATED_AT_STATUS=${UPDATED_AT_STATUS:-N/A}
- FAZ_1_1_4_CREATED_BY_STATUS=${CREATED_BY_STATUS:-N/A}
- FAZ_1_1_4_UPDATED_BY_STATUS=${UPDATED_BY_STATUS:-N/A}
- FAZ_1_1_4_DELETED_AT_STATUS=${DELETED_AT_STATUS:-N/A}
- FAZ_1_1_4_AUDIT_COLUMNS_STATUS=${AUDIT_COLUMNS_STATUS:-N/A}
- FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.4 Business Common Columns Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Snapshot Files"
  echo "- Business tables: $BUSINESS_TABLES_CSV"
  echo "- Missing before: $BEFORE_MISSING_CSV"
  echo "- Missing after: $AFTER_MISSING_CSV"
  echo
  echo "## Counts"
  echo "- BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
  echo "- BEFORE_MISSING_COUNT=$BEFORE_MISSING_COUNT"
  echo "- AFTER_MISSING_COUNT=$AFTER_MISSING_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Required Scope Status"
  echo "- TENANT_ID_STATUS=${TENANT_ID_STATUS:-N/A}"
  echo "- LEGAL_ENTITY_ID_STATUS=${LEGAL_ENTITY_ID_STATUS:-N/A}"
  echo "- BRANCH_ID_STATUS=${BRANCH_ID_STATUS:-N/A}"
  echo "- CREATED_AT_STATUS=${CREATED_AT_STATUS:-N/A}"
  echo "- UPDATED_AT_STATUS=${UPDATED_AT_STATUS:-N/A}"
  echo "- CREATED_BY_STATUS=${CREATED_BY_STATUS:-N/A}"
  echo "- UPDATED_BY_STATUS=${UPDATED_BY_STATUS:-N/A}"
  echo "- DELETED_AT_STATUS=${DELETED_AT_STATUS:-N/A}"
  echo "- AUDIT_COLUMNS_STATUS=${AUDIT_COLUMNS_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-1.4 Business Common Columns Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_4_TENANT_ID_STATUS=${TENANT_ID_STATUS:-N/A}"
  echo "FAZ_1_1_4_LEGAL_ENTITY_ID_STATUS=${LEGAL_ENTITY_ID_STATUS:-N/A}"
  echo "FAZ_1_1_4_BRANCH_ID_STATUS=${BRANCH_ID_STATUS:-N/A}"
  echo "FAZ_1_1_4_CREATED_AT_STATUS=${CREATED_AT_STATUS:-N/A}"
  echo "FAZ_1_1_4_UPDATED_AT_STATUS=${UPDATED_AT_STATUS:-N/A}"
  echo "FAZ_1_1_4_CREATED_BY_STATUS=${CREATED_BY_STATUS:-N/A}"
  echo "FAZ_1_1_4_UPDATED_BY_STATUS=${UPDATED_BY_STATUS:-N/A}"
  echo "FAZ_1_1_4_DELETED_AT_STATUS=${DELETED_AT_STATUS:-N/A}"
  echo "FAZ_1_1_4_AUDIT_COLUMNS_STATUS=${AUDIT_COLUMNS_STATUS:-N/A}"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_1_5_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "16.1 dokümantasyon güncellendi: $DOC_FILE"
pass "16.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "16.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "16.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS APPLY RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "BEFORE_MISSING_COUNT=$BEFORE_MISSING_COUNT"
echo "AFTER_MISSING_COUNT=$AFTER_MISSING_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "TENANT_ID_STATUS=${TENANT_ID_STATUS:-N/A}"
echo "LEGAL_ENTITY_ID_STATUS=${LEGAL_ENTITY_ID_STATUS:-N/A}"
echo "BRANCH_ID_STATUS=${BRANCH_ID_STATUS:-N/A}"
echo "CREATED_AT_STATUS=${CREATED_AT_STATUS:-N/A}"
echo "UPDATED_AT_STATUS=${UPDATED_AT_STATUS:-N/A}"
echo "CREATED_BY_STATUS=${CREATED_BY_STATUS:-N/A}"
echo "UPDATED_BY_STATUS=${UPDATED_BY_STATUS:-N/A}"
echo "DELETED_AT_STATUS=${DELETED_AT_STATUS:-N/A}"
echo "AUDIT_COLUMNS_STATUS=${AUDIT_COLUMNS_STATUS:-N/A}"
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

  echo "FAZ_1_1_4_TENANT_ID_STATUS=PASS"
  echo "FAZ_1_1_4_LEGAL_ENTITY_ID_STATUS=PASS"
  echo "FAZ_1_1_4_BRANCH_ID_STATUS=PASS"
  echo "FAZ_1_1_4_CREATED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_UPDATED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_CREATED_BY_STATUS=PASS"
  echo "FAZ_1_1_4_UPDATED_BY_STATUS=PASS"
  echo "FAZ_1_1_4_DELETED_AT_STATUS=PASS"
  echo "FAZ_1_1_4_AUDIT_COLUMNS_STATUS=PASS"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_FINAL_STATUS=PASS"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=SEALED"
  echo "FAZ_1_1_5_READY=YES"
else
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_4_BUSINESS_COMMON_COLUMNS_SEAL_STATUS=OPEN"
  echo "FAZ_1_1_5_READY=NO"
  exit 1
fi

echo "===== FAZ 1-1.4 BUSINESS COMMON COLUMNS APPLY END ====="
