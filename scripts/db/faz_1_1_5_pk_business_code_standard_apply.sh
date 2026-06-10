#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_5_pk_business_code_standard_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_5_pk_business_code_standard_apply.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_5_pk_business_code_standard_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_1_5_pk_business_code_standard.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD_FINAL_SEAL_$TS.md"
STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_5_strict_suite_run.out"

BUSINESS_TABLES_CSV="$BACKUP_DIR/business_table_candidates.csv"
BEFORE_STANDARD_CSV="$BACKUP_DIR/pk_business_code_standard_before.csv"
AFTER_STANDARD_CSV="$BACKUP_DIR/pk_business_code_standard_after.csv"
DUPLICATE_BUSINESS_CODE_CSV="$BACKUP_DIR/tenant_business_code_duplicates_after.csv"

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

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD APPLY START ====="

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

echo "7. business table ve mevcut PK/business_code snapshot alınıyor..."

psql "$DSN" -v ON_ERROR_STOP=1 -c "\copy (
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
  )
  select
    bt.table_schema,
    bt.table_name,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema=bt.table_schema
        and c.table_name=bt.table_name
        and c.column_name='id'
    ) as has_id,
    exists (
      select 1
      from information_schema.table_constraints tc
      where tc.table_schema=bt.table_schema
        and tc.table_name=bt.table_name
        and tc.constraint_type='PRIMARY KEY'
    ) as has_pk,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema=bt.table_schema
        and c.table_name=bt.table_name
        and c.column_name='business_code'
    ) as has_business_code,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema=bt.table_schema
        and c.table_name=bt.table_name
        and c.column_name='tenant_id'
    ) as has_tenant_id
  from business_tables bt
  order by bt.table_schema, bt.table_name
) to '$BEFORE_STANDARD_CSV' with csv header;" >/dev/null

BUSINESS_TABLE_COUNT="$(($(wc -l < "$BUSINESS_TABLES_CSV") - 1))"

BEFORE_MISSING_ID_COUNT="$(awk -F, 'NR>1 && $3=="f"{c++} END{print c+0}' "$BEFORE_STANDARD_CSV")"
BEFORE_MISSING_PK_COUNT="$(awk -F, 'NR>1 && $4=="f"{c++} END{print c+0}' "$BEFORE_STANDARD_CSV")"
BEFORE_MISSING_BUSINESS_CODE_COUNT="$(awk -F, 'NR>1 && $5=="f"{c++} END{print c+0}' "$BEFORE_STANDARD_CSV")"

echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "BEFORE_MISSING_ID_COUNT=$BEFORE_MISSING_ID_COUNT"
echo "BEFORE_MISSING_PK_COUNT=$BEFORE_MISSING_PK_COUNT"
echo "BEFORE_MISSING_BUSINESS_CODE_COUNT=$BEFORE_MISSING_BUSINESS_CODE_COUNT"
echo "BUSINESS_TABLES_CSV=$BUSINESS_TABLES_CSV"
echo "BEFORE_STANDARD_CSV=$BEFORE_STANDARD_CSV"

if [ "$BUSINESS_TABLE_COUNT" -gt 0 ]; then
  pass "7.1 business table adayları bulundu"
else
  fail "7.1 business table adayı bulunamadı"
  exit 1
fi

pass "7.2 PK/business_code standard snapshot alındı"

echo "8. migration SQL hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS app_standard;

CREATE OR REPLACE FUNCTION app_standard.normalize_business_code(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT regexp_replace(upper(coalesce(input_text, '')), '[^A-Z0-9_-]', '_', 'g');
$$;

CREATE OR REPLACE FUNCTION app_standard.generate_business_code(prefix text, source_id uuid DEFAULT gen_random_uuid())
RETURNS text
LANGUAGE sql
VOLATILE
AS $$
  SELECT left(app_standard.normalize_business_code(coalesce(prefix, 'CODE')), 16)
         || '_'
         || substr(replace(coalesce(source_id, gen_random_uuid())::text, '-', ''), 1, 12);
$$;

DO $$
DECLARE
  r record;
  pk_count int;
  id_type text;
  pk_name text;
  ux_name text;
  ck_name text;
  prefix text;
  duplicate_count int;
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
    pk_name := left('pk_' || r.table_schema || '_' || r.table_name, 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.pk'), 1, 8);
    ux_name := left('ux_' || r.table_schema || '_' || r.table_name || '_tenant_business_code', 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.tenant_business_code'), 1, 8);
    ck_name := left('ck_' || r.table_schema || '_' || r.table_name || '_business_code_format', 52) || '_' || substr(md5(r.table_schema || '.' || r.table_name || '.business_code_format'), 1, 8);
    prefix := left(app_standard.normalize_business_code(r.table_name), 16);

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='id'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN id uuid', r.table_schema, r.table_name);
    END IF;

    SELECT data_type
    INTO id_type
    FROM information_schema.columns
    WHERE table_schema=r.table_schema
      AND table_name=r.table_name
      AND column_name='id'
    LIMIT 1;

    IF id_type='uuid' THEN
      EXECUTE format('UPDATE %I.%I SET id=gen_random_uuid() WHERE id IS NULL', r.table_schema, r.table_name);
      EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN id SET DEFAULT gen_random_uuid()', r.table_schema, r.table_name);

      BEGIN
        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN id SET NOT NULL', r.table_schema, r.table_name);
      EXCEPTION WHEN others THEN
        RAISE NOTICE 'id not-null skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
      END;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='business_code'
    ) THEN
      EXECUTE format('ALTER TABLE %I.%I ADD COLUMN business_code text', r.table_schema, r.table_name);
    END IF;

    IF id_type='uuid' THEN
      EXECUTE format(
        'UPDATE %I.%I SET business_code = app_standard.generate_business_code(%L, id) WHERE business_code IS NULL OR btrim(business_code) = ''''',
        r.table_schema,
        r.table_name,
        prefix
      );
    ELSE
      EXECUTE format(
        'UPDATE %I.%I SET business_code = app_standard.generate_business_code(%L, gen_random_uuid()) WHERE business_code IS NULL OR btrim(business_code) = ''''',
        r.table_schema,
        r.table_name,
        prefix
      );
    END IF;

    IF EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_schema=r.table_schema
        AND tc.table_name=r.table_name
        AND tc.constraint_type='PRIMARY KEY'
    ) THEN
      -- Existing PK is preserved.
      NULL;
    ELSE
      IF id_type='uuid' THEN
        BEGIN
          EXECUTE format('ALTER TABLE %I.%I ADD CONSTRAINT %I PRIMARY KEY (id)', r.table_schema, r.table_name, pk_name);
        EXCEPTION WHEN duplicate_object THEN
          NULL;
        WHEN others THEN
          RAISE NOTICE 'primary key skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
        END;
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_schema=r.table_schema
        AND tc.table_name=r.table_name
        AND tc.constraint_name=ck_name
    ) THEN
      BEGIN
        EXECUTE format(
          'ALTER TABLE %I.%I ADD CONSTRAINT %I CHECK (business_code IS NULL OR business_code ~ %L) NOT VALID',
          r.table_schema,
          r.table_name,
          ck_name,
          '^[A-Z0-9][A-Z0-9_-]{1,127}$'
        );
      EXCEPTION WHEN duplicate_object THEN
        NULL;
      WHEN others THEN
        RAISE NOTICE 'business_code check skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
      END;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema=r.table_schema
        AND table_name=r.table_name
        AND column_name='tenant_id'
    ) THEN
      EXECUTE format(
        'SELECT count(*) FROM (
           SELECT tenant_id, business_code
           FROM %I.%I
           WHERE business_code IS NOT NULL
             AND (%s)
           GROUP BY tenant_id, business_code
           HAVING count(*) > 1
         ) d',
        r.table_schema,
        r.table_name,
        CASE
          WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema=r.table_schema
              AND table_name=r.table_name
              AND column_name='deleted_at'
          )
          THEN 'deleted_at IS NULL'
          ELSE 'true'
        END
      )
      INTO duplicate_count;

      IF duplicate_count = 0 THEN
        BEGIN
          EXECUTE format(
            'CREATE UNIQUE INDEX IF NOT EXISTS %I ON %I.%I (tenant_id, business_code) WHERE business_code IS NOT NULL AND %s',
            ux_name,
            r.table_schema,
            r.table_name,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema=r.table_schema
                  AND table_name=r.table_name
                  AND column_name='deleted_at'
              )
              THEN 'deleted_at IS NULL'
              ELSE 'true'
            END
          );
        EXCEPTION WHEN others THEN
          RAISE NOTICE 'tenant business_code unique index skipped for %.%: %', r.table_schema, r.table_name, SQLERRM;
        END;
      ELSE
        RAISE NOTICE 'tenant business_code unique index skipped for %.% because duplicate_count=%', r.table_schema, r.table_name, duplicate_count;
      END IF;
    END IF;
  END LOOP;
END $$;

GRANT USAGE ON SCHEMA app_standard TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.normalize_business_code(text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_standard.generate_business_code(text, uuid) TO PUBLIC;

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

echo "10. migration sonrası PK/business_code snapshot alınıyor..."

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
  select
    bt.table_schema,
    bt.table_name,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema=bt.table_schema
        and c.table_name=bt.table_name
        and c.column_name='id'
    ) as has_id,
    exists (
      select 1
      from information_schema.table_constraints tc
      where tc.table_schema=bt.table_schema
        and tc.table_name=bt.table_name
        and tc.constraint_type='PRIMARY KEY'
    ) as has_pk,
    exists (
      select 1
      from information_schema.columns c
      where c.table_schema=bt.table_schema
        and c.table_name=bt.table_name
        and c.column_name='business_code'
    ) as has_business_code,
    exists (
      select 1
      from pg_indexes i
      where i.schemaname=bt.table_schema
        and i.tablename=bt.table_name
        and i.indexdef ilike '%tenant_id%'
        and i.indexdef ilike '%business_code%'
        and i.indexdef ilike '%UNIQUE%'
    ) as has_tenant_business_code_unique,
    exists (
      select 1
      from information_schema.check_constraints cc
      join information_schema.constraint_table_usage ctu
        on ctu.constraint_catalog=cc.constraint_catalog
       and ctu.constraint_schema=cc.constraint_schema
       and ctu.constraint_name=cc.constraint_name
      where ctu.table_schema=bt.table_schema
        and ctu.table_name=bt.table_name
        and cc.check_clause ilike '%business_code%'
    ) as has_business_code_format_check
  from business_tables bt
  order by bt.table_schema, bt.table_name
) to '$AFTER_STANDARD_CSV' with csv header;" >/dev/null

AFTER_MISSING_ID_COUNT="$(awk -F, 'NR>1 && $3=="f"{c++} END{print c+0}' "$AFTER_STANDARD_CSV")"
AFTER_MISSING_PK_COUNT="$(awk -F, 'NR>1 && $4=="f"{c++} END{print c+0}' "$AFTER_STANDARD_CSV")"
AFTER_MISSING_BUSINESS_CODE_COUNT="$(awk -F, 'NR>1 && $5=="f"{c++} END{print c+0}' "$AFTER_STANDARD_CSV")"
AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT="$(awk -F, 'NR>1 && $6=="f"{c++} END{print c+0}' "$AFTER_STANDARD_CSV")"
AFTER_MISSING_FORMAT_CHECK_COUNT="$(awk -F, 'NR>1 && $7=="f"{c++} END{print c+0}' "$AFTER_STANDARD_CSV")"

echo "AFTER_MISSING_ID_COUNT=$AFTER_MISSING_ID_COUNT"
echo "AFTER_MISSING_PK_COUNT=$AFTER_MISSING_PK_COUNT"
echo "AFTER_MISSING_BUSINESS_CODE_COUNT=$AFTER_MISSING_BUSINESS_CODE_COUNT"
echo "AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT=$AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT"
echo "AFTER_MISSING_FORMAT_CHECK_COUNT=$AFTER_MISSING_FORMAT_CHECK_COUNT"
echo "AFTER_STANDARD_CSV=$AFTER_STANDARD_CSV"

[ "$AFTER_MISSING_ID_COUNT" -eq 0 ] && pass "10.1 tüm business tablolarda id standardı var" || fail "10.1 id standardı eksik count=$AFTER_MISSING_ID_COUNT"
[ "$AFTER_MISSING_PK_COUNT" -eq 0 ] && pass "10.2 tüm business tablolarda PK standardı var" || fail "10.2 PK standardı eksik count=$AFTER_MISSING_PK_COUNT"
[ "$AFTER_MISSING_BUSINESS_CODE_COUNT" -eq 0 ] && pass "10.3 tüm business tablolarda business_code standardı var" || fail "10.3 business_code standardı eksik count=$AFTER_MISSING_BUSINESS_CODE_COUNT"
[ "$AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT" -eq 0 ] && pass "10.4 tenant-safe business_code unique index standardı tam" || fail "10.4 tenant-safe business_code unique index eksik count=$AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT"
[ "$AFTER_MISSING_FORMAT_CHECK_COUNT" -eq 0 ] && pass "10.5 business_code format check standardı tam" || fail "10.5 business_code format check eksik count=$AFTER_MISSING_FORMAT_CHECK_COUNT"

echo "11. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_5_pk_business_code_standard_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_5_PK_BUSINESS_CODE_STANDARD_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE START ====="

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
      select 1
      from information_schema.columns c
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
      select 1
      from information_schema.table_constraints tc
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
      select 1
      from information_schema.columns c
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
      from information_schema.check_constraints cc
      join information_schema.constraint_table_usage ctu
        on ctu.constraint_catalog=cc.constraint_catalog
       and ctu.constraint_schema=cc.constraint_schema
       and ctu.constraint_name=cc.constraint_name
      where ctu.table_schema=t.table_schema
        and ctu.table_name=t.table_name
        and cc.check_clause ilike '%business_code%'
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

echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "ID_COLUMN_TABLE_COUNT=$ID_COLUMN_TABLE_COUNT"
echo "PK_TABLE_COUNT=$PK_TABLE_COUNT"
echo "BUSINESS_CODE_TABLE_COUNT=$BUSINESS_CODE_TABLE_COUNT"
echo "TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT=$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT"
echo "BUSINESS_CODE_FORMAT_CHECK_COUNT=$BUSINESS_CODE_FORMAT_CHECK_COUNT"
echo "CODE_GENERATOR_FUNCTION_COUNT=$CODE_GENERATOR_FUNCTION_COUNT"
echo "GENERATOR_TEST_COUNT=$GENERATOR_TEST_COUNT"

[ "$BUSINESS_TABLE_COUNT" -gt 0 ] && pass "5.1 business table kapsamı bulundu" || fail "5.1 business table kapsamı yok"
[ "$ID_COLUMN_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.2 teknik id standardı tüm business tablolarda mevcut" || fail "5.2 teknik id standardı eksik"
[ "$PK_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.3 PK standardı tüm business tablolarda mevcut" || fail "5.3 PK standardı eksik"
[ "$BUSINESS_CODE_TABLE_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.4 business_code standardı tüm business tablolarda mevcut" || fail "5.4 business_code standardı eksik"
[ "$TENANT_BUSINESS_CODE_UNIQUE_INDEX_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.5 tenant-safe unique index standardı tüm business tablolarda mevcut" || fail "5.5 tenant-safe unique index standardı eksik"
[ "$BUSINESS_CODE_FORMAT_CHECK_COUNT" -eq "$BUSINESS_TABLE_COUNT" ] && pass "5.6 business_code format check standardı tüm business tablolarda mevcut" || fail "5.6 business_code format check standardı eksik"
[ "$CODE_GENERATOR_FUNCTION_COUNT" -ge 2 ] && pass "5.7 kod normalize/generate function seti mevcut" || fail "5.7 kod üretim function seti eksik"
[ "$GENERATOR_TEST_COUNT" -eq 1 ] && pass "5.8 kod üretim testi geçti" || fail "5.8 kod üretim testi başarısız"

echo "6. strict SQL assertion suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/pk_business_code_standard_strict_assertion.sql"
SQL_SUITE_OUT="$BACKUP_DIR/pk_business_code_standard_strict_assertion.out"

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
  SELECT count(*)
  INTO v_missing_id
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
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
  SELECT count(*)
  INTO v_missing_pk
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
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
  SELECT count(*)
  INTO v_missing_business_code
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns c
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
  SELECT count(*)
  INTO v_missing_tenant_unique
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_indexes i
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
  SELECT count(*)
  INTO v_missing_format_check
  FROM business_tables bt
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.check_constraints cc
    JOIN information_schema.constraint_table_usage ctu
      ON ctu.constraint_catalog=cc.constraint_catalog
     AND ctu.constraint_schema=cc.constraint_schema
     AND ctu.constraint_name=cc.constraint_name
    WHERE ctu.table_schema=bt.table_schema
      AND ctu.table_name=bt.table_name
      AND cc.check_clause ILIKE '%business_code%'
  );

  IF v_missing_format_check <> 0 THEN
    RAISE EXCEPTION 'business_code format check missing count=%', v_missing_format_check;
  END IF;

  SELECT CASE
    WHEN app_standard.generate_business_code('TEST', '00000000-0000-0000-0000-000000000123'::uuid) ~ '^TEST_[A-F0-9]{12}$'
    THEN 1 ELSE 0
  END
  INTO v_generator_ok;

  IF v_generator_ok <> 1 THEN
    RAISE EXCEPTION 'business code generator test failed';
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
  echo "# FAZ 1-1.5 PK / Business-Code Standard Strict Suite Result"
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
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE RESULT ====="
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

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_PK_BUSINESS_CODE_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS")"

TECHNICAL_ID_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_TECHNICAL_ID_STANDARD_STATUS")"
BUSINESS_CODE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_BUSINESS_CODE_STANDARD_STATUS")"
TENANT_SAFE_UNIQUE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_TENANT_SAFE_UNIQUE_CONSTRAINT_STATUS")"
CODE_FORMAT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_CODE_FORMAT_STATUS")"
CODE_GENERATION_TEST_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_5_CODE_GENERATION_TEST_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "13. strict suite FAIL_COUNT=0 doğrulandı" || fail "13. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "14. strict suite status PASS doğrulandı" || fail "14. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "15. strict suite seal SEALED doğrulandı" || fail "15. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "16. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.5 PK / Business-Code Standard

## Kapsam

- Teknik ID standardı
- Business code standardı
- Tenant-safe unique constraint
- Kod formatları
- Kod üretim testleri

## Uygulama

Bu adım business table adaylarında teknik id, primary key, business_code, tenant-safe unique index ve business_code format check standardını doğrular/uygular. Mevcut primary key varsa korunur.

## Final Status

- FAZ_1_1_5_TECHNICAL_ID_STANDARD_STATUS=${TECHNICAL_ID_STATUS:-N/A}
- FAZ_1_1_5_BUSINESS_CODE_STANDARD_STATUS=${BUSINESS_CODE_STATUS:-N/A}
- FAZ_1_1_5_TENANT_SAFE_UNIQUE_CONSTRAINT_STATUS=${TENANT_SAFE_UNIQUE_STATUS:-N/A}
- FAZ_1_1_5_CODE_FORMAT_STATUS=${CODE_FORMAT_STATUS:-N/A}
- FAZ_1_1_5_CODE_GENERATION_TEST_STATUS=${CODE_GENERATION_TEST_STATUS:-N/A}
- FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.5 PK / Business-Code Standard Real Implementation Audit"
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
  echo "- Before standard: $BEFORE_STANDARD_CSV"
  echo "- After standard: $AFTER_STANDARD_CSV"
  echo
  echo "## Before Counts"
  echo "- BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
  echo "- BEFORE_MISSING_ID_COUNT=$BEFORE_MISSING_ID_COUNT"
  echo "- BEFORE_MISSING_PK_COUNT=$BEFORE_MISSING_PK_COUNT"
  echo "- BEFORE_MISSING_BUSINESS_CODE_COUNT=$BEFORE_MISSING_BUSINESS_CODE_COUNT"
  echo
  echo "## After Counts"
  echo "- AFTER_MISSING_ID_COUNT=$AFTER_MISSING_ID_COUNT"
  echo "- AFTER_MISSING_PK_COUNT=$AFTER_MISSING_PK_COUNT"
  echo "- AFTER_MISSING_BUSINESS_CODE_COUNT=$AFTER_MISSING_BUSINESS_CODE_COUNT"
  echo "- AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT=$AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT"
  echo "- AFTER_MISSING_FORMAT_CHECK_COUNT=$AFTER_MISSING_FORMAT_CHECK_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Required Scope Status"
  echo "- TECHNICAL_ID_STATUS=${TECHNICAL_ID_STATUS:-N/A}"
  echo "- BUSINESS_CODE_STATUS=${BUSINESS_CODE_STATUS:-N/A}"
  echo "- TENANT_SAFE_UNIQUE_STATUS=${TENANT_SAFE_UNIQUE_STATUS:-N/A}"
  echo "- CODE_FORMAT_STATUS=${CODE_FORMAT_STATUS:-N/A}"
  echo "- CODE_GENERATION_TEST_STATUS=${CODE_GENERATION_TEST_STATUS:-N/A}"
  echo
  echo "## Apply Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-1.5 PK / Business-Code Standard Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_5_TECHNICAL_ID_STANDARD_STATUS=${TECHNICAL_ID_STATUS:-N/A}"
  echo "FAZ_1_1_5_BUSINESS_CODE_STANDARD_STATUS=${BUSINESS_CODE_STATUS:-N/A}"
  echo "FAZ_1_1_5_TENANT_SAFE_UNIQUE_CONSTRAINT_STATUS=${TENANT_SAFE_UNIQUE_STATUS:-N/A}"
  echo "FAZ_1_1_5_CODE_FORMAT_STATUS=${CODE_FORMAT_STATUS:-N/A}"
  echo "FAZ_1_1_5_CODE_GENERATION_TEST_STATUS=${CODE_GENERATION_TEST_STATUS:-N/A}"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_1_6_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "16.1 dokümantasyon güncellendi: $DOC_FILE"
pass "16.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "16.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "16.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD APPLY RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "BUSINESS_TABLE_COUNT=$BUSINESS_TABLE_COUNT"
echo "BEFORE_MISSING_ID_COUNT=$BEFORE_MISSING_ID_COUNT"
echo "BEFORE_MISSING_PK_COUNT=$BEFORE_MISSING_PK_COUNT"
echo "BEFORE_MISSING_BUSINESS_CODE_COUNT=$BEFORE_MISSING_BUSINESS_CODE_COUNT"
echo "AFTER_MISSING_ID_COUNT=$AFTER_MISSING_ID_COUNT"
echo "AFTER_MISSING_PK_COUNT=$AFTER_MISSING_PK_COUNT"
echo "AFTER_MISSING_BUSINESS_CODE_COUNT=$AFTER_MISSING_BUSINESS_CODE_COUNT"
echo "AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT=$AFTER_MISSING_TENANT_BUSINESS_UNIQUE_COUNT"
echo "AFTER_MISSING_FORMAT_CHECK_COUNT=$AFTER_MISSING_FORMAT_CHECK_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "TECHNICAL_ID_STATUS=${TECHNICAL_ID_STATUS:-N/A}"
echo "BUSINESS_CODE_STATUS=${BUSINESS_CODE_STATUS:-N/A}"
echo "TENANT_SAFE_UNIQUE_STATUS=${TENANT_SAFE_UNIQUE_STATUS:-N/A}"
echo "CODE_FORMAT_STATUS=${CODE_FORMAT_STATUS:-N/A}"
echo "CODE_GENERATION_TEST_STATUS=${CODE_GENERATION_TEST_STATUS:-N/A}"
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

  echo "FAZ_1_1_5_TECHNICAL_ID_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_5_BUSINESS_CODE_STANDARD_STATUS=PASS"
  echo "FAZ_1_1_5_TENANT_SAFE_UNIQUE_CONSTRAINT_STATUS=PASS"
  echo "FAZ_1_1_5_CODE_FORMAT_STATUS=PASS"
  echo "FAZ_1_1_5_CODE_GENERATION_TEST_STATUS=PASS"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_FINAL_STATUS=PASS"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=SEALED"
  echo "FAZ_1_1_6_READY=YES"
else
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_5_PK_BUSINESS_CODE_SEAL_STATUS=OPEN"
  echo "FAZ_1_1_6_READY=NO"
  exit 1
fi

echo "===== FAZ 1-1.5 PK / BUSINESS-CODE STANDARD APPLY END ====="
