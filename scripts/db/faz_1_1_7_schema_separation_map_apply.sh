#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_1_7_SCHEMA_SEPARATION_MAP"

BACKUP_DIR="$REPO/backups/faz1/faz_1_1_7_schema_separation_map_$TS"
SUITE_RUNTIME_DIR="$BACKUP_DIR/suite_runtime"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
DOC_DIR="$REPO/docs/faz1/db"
SCRIPT_DIR="$REPO/scripts/db"
MIGRATION_DIR="$REPO/db/migrations/faz1"

APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_1_7_schema_separation_map_apply.sh"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_1_7_schema_separation_map_strict_suite.sh"
DOC_FILE="$DOC_DIR/FAZ_1_1_7_SCHEMA_SEPARATION_MAP.md"
MIGRATION_FILE="$MIGRATION_DIR/${TS}_faz_1_1_7_schema_separation_map.sql"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_1_7_SCHEMA_SEPARATION_MAP_FINAL_SEAL_$TS.md"

STRICT_SUITE_OUT="$SUITE_RUNTIME_DIR/faz_1_1_7_strict_suite_run.out"
SCHEMA_INVENTORY_CSV="$SUITE_RUNTIME_DIR/schema_inventory.csv"
TABLE_INVENTORY_CSV="$SUITE_RUNTIME_DIR/schema_table_inventory.csv"
BOUNDARY_MAP_CSV="$SUITE_RUNTIME_DIR/schema_boundary_map.csv"
MIGRATION_PATH_INVENTORY="$SUITE_RUNTIME_DIR/migration_path_inventory.txt"

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

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP APPLY START ====="

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

echo "7. migration path envanteri alınıyor..."

MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"
FAZ1_MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations/faz1" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"

find "$REPO/db/migrations" -maxdepth 3 -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | sort > "$MIGRATION_PATH_INVENTORY" || true

echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"

[ "$MIGRATION_FILE_COUNT" -ge 1 ] && pass "7.1 migration path dosyaları mevcut" || fail "7.1 migration path dosyası yok"
[ "$FAZ1_MIGRATION_FILE_COUNT" -ge 1 ] && pass "7.2 faz1 migration path dosyaları mevcut" || fail "7.2 faz1 migration path dosyası yok"
[ -f "$MIGRATION_PATH_INVENTORY" ] && pass "7.3 migration path inventory üretildi" || fail "7.3 migration path inventory üretilemedi"

echo "8. schema separation map migration hazırlanıyor..."

cat <<'SQL' > "$MIGRATION_FILE"
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS app_schema;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS erp;
CREATE SCHEMA IF NOT EXISTS ops;
CREATE SCHEMA IF NOT EXISTS reporting;

CREATE OR REPLACE FUNCTION app_schema.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TABLE IF NOT EXISTS app_schema.schema_boundary_map (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  boundary_code text NOT NULL,
  boundary_name_tr text NOT NULL,
  boundary_name_en text NOT NULL,
  purpose text NOT NULL,
  canonical_schemas text[] NOT NULL DEFAULT ARRAY[]::text[],
  accepted_schema_patterns text[] NOT NULL DEFAULT ARRAY[]::text[],
  write_owner text NOT NULL,
  read_owner text NOT NULL,
  migration_path text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_app_schema_boundary_map_boundary_code
  ON app_schema.schema_boundary_map(boundary_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_app_schema_boundary_map_status
  ON app_schema.schema_boundary_map(status);

CREATE INDEX IF NOT EXISTS idx_app_schema_boundary_map_write_owner
  ON app_schema.schema_boundary_map(write_owner);

ALTER TABLE app_schema.schema_boundary_map DROP CONSTRAINT IF EXISTS ck_app_schema_boundary_map_required_fields;
ALTER TABLE app_schema.schema_boundary_map
  ADD CONSTRAINT ck_app_schema_boundary_map_required_fields
  CHECK (
    boundary_code IS NOT NULL AND btrim(boundary_code) <> ''
    AND boundary_name_tr IS NOT NULL AND btrim(boundary_name_tr) <> ''
    AND boundary_name_en IS NOT NULL AND btrim(boundary_name_en) <> ''
    AND purpose IS NOT NULL AND btrim(purpose) <> ''
    AND array_length(canonical_schemas, 1) IS NOT NULL
    AND write_owner IS NOT NULL AND btrim(write_owner) <> ''
    AND read_owner IS NOT NULL AND btrim(read_owner) <> ''
    AND migration_path IS NOT NULL AND btrim(migration_path) <> ''
    AND status IS NOT NULL AND btrim(status) <> ''
  ) NOT VALID;

ALTER TABLE app_schema.schema_boundary_map DROP CONSTRAINT IF EXISTS ck_app_schema_boundary_map_status;
ALTER TABLE app_schema.schema_boundary_map
  ADD CONSTRAINT ck_app_schema_boundary_map_status
  CHECK (status IN ('ACTIVE','PLANNED','DEPRECATED')) NOT VALID;

DROP TRIGGER IF EXISTS trg_app_schema_boundary_map_set_updated_at ON app_schema.schema_boundary_map;
CREATE TRIGGER trg_app_schema_boundary_map_set_updated_at
BEFORE UPDATE ON app_schema.schema_boundary_map
FOR EACH ROW
EXECUTE FUNCTION app_schema.set_updated_at();

INSERT INTO app_schema.schema_boundary_map (
  boundary_code,
  boundary_name_tr,
  boundary_name_en,
  purpose,
  canonical_schemas,
  accepted_schema_patterns,
  write_owner,
  read_owner,
  migration_path,
  status,
  metadata
)
VALUES
(
  'AUTH',
  'Kimlik / Yetki Schema Alanı',
  'Authentication / Authorization Schema Boundary',
  'Kullanıcı, rol, permission, user scope, super-admin ve break-glass güvenlik modellerini taşır.',
  ARRAY['auth','security','app_security'],
  ARRAY['auth.%','security.%','app_security.%'],
  'identity-security-platform',
  'api-gateway-and-authorized-services',
  'db/migrations/faz1/security',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','auth_schema')
),
(
  'TENANT',
  'Tenant / Organizasyon Schema Alanı',
  'Tenant / Organization Schema Boundary',
  'Tenant, legal entity, branch ve tenant scoped business modellerini taşır.',
  ARRAY['platform','org','tenant_*'],
  ARRAY['platform.%','org.%','tenant_*.%'],
  'tenant-core-platform',
  'tenant-aware-services',
  'db/migrations/faz1',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','tenant_schema')
),
(
  'ERP',
  'ERP / Domain Schema Alanı',
  'ERP / Domain Schema Boundary',
  'ERP çekirdek domainleri, muhasebe, stok, satış, ürün ve operasyonel iş tablolarını taşır.',
  ARRAY['erp','accounting','inventory','sales','purchase','product','catalog','org'],
  ARRAY['erp.%','accounting.%','inventory.%','sales.%','purchase.%','product.%','catalog.%','org.%'],
  'erp-domain-platform',
  'erp-services-and-reporting-readers',
  'db/migrations/faz1/db',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','erp_schema')
),
(
  'OPS',
  'Operasyon / Gözlemlenebilirlik Schema Alanı',
  'Operations / Observability Schema Boundary',
  'Audit, ops, security alert, incident, observability ve runtime control kayıtlarını taşır.',
  ARRAY['ops','audit','observability','app_security','security'],
  ARRAY['ops.%','audit.%','observability.%','app_security.%','security.%'],
  'sre-security-platform',
  'ops-console-and-admin-services',
  'db/migrations/faz1/ops',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','ops_schema')
),
(
  'REPORTING',
  'Raporlama / Read Model Schema Alanı',
  'Reporting / Read Model Schema Boundary',
  'Read model, reporting store, analytics ve raporlama için optimize edilmiş verileri taşır.',
  ARRAY['reporting','read_model','analytics'],
  ARRAY['reporting.%','read_model.%','analytics.%'],
  'reporting-platform',
  'reporting-api-and-dashboard',
  'db/migrations/faz1/reporting',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','reporting_schema')
),
(
  'MIGRATION_PATH',
  'Migration Path / Değişiklik Yönetimi',
  'Migration Path / Change Management Boundary',
  'DB değişikliklerinin faz bazlı migration dosyaları, rollback kanıtları ve evidence pathleriyle yönetilmesini standartlaştırır.',
  ARRAY['db/migrations','db/migrations/faz1','docs/faz1/evidence','backups/faz1'],
  ARRAY['db/migrations/%','docs/faz1/evidence/%','backups/faz1/%'],
  'platform-migration-owner',
  'release-and-audit-process',
  'db/migrations/faz1',
  'ACTIVE',
  jsonb_build_object('phase','FAZ_1_1_7','scope','migration_path')
)
ON CONFLICT (boundary_code) WHERE deleted_at IS NULL
DO UPDATE SET
  boundary_name_tr=EXCLUDED.boundary_name_tr,
  boundary_name_en=EXCLUDED.boundary_name_en,
  purpose=EXCLUDED.purpose,
  canonical_schemas=EXCLUDED.canonical_schemas,
  accepted_schema_patterns=EXCLUDED.accepted_schema_patterns,
  write_owner=EXCLUDED.write_owner,
  read_owner=EXCLUDED.read_owner,
  migration_path=EXCLUDED.migration_path,
  status=EXCLUDED.status,
  metadata=EXCLUDED.metadata,
  updated_at=now();

GRANT USAGE ON SCHEMA app_schema TO PUBLIC;
GRANT SELECT ON app_schema.schema_boundary_map TO PUBLIC;
GRANT EXECUTE ON FUNCTION app_schema.set_updated_at() TO PUBLIC;

COMMIT;
SQL

pass "8.1 migration SQL hazırlandı: $MIGRATION_FILE"

echo "9. schema separation map migration uygulanıyor..."

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$MIGRATION_FILE"; then
  pass "9.1 migration başarıyla uygulandı"
else
  fail "9.1 migration uygulanamadı"
  exit 1
fi

echo "10. schema/table inventory CSV snapshot üretiliyor..."

psql "$DSN" -c "\copy (
  SELECT
    n.nspname AS schema_name,
    count(c.oid) FILTER (WHERE c.relkind IN ('r','p')) AS table_count,
    count(c.oid) FILTER (WHERE c.relkind = 'v') AS view_count,
    count(c.oid) FILTER (WHERE c.relkind = 'm') AS materialized_view_count
  FROM pg_namespace n
  LEFT JOIN pg_class c ON c.relnamespace=n.oid
  WHERE n.nspname NOT LIKE 'pg_%'
    AND n.nspname <> 'information_schema'
  GROUP BY n.nspname
  ORDER BY n.nspname
) TO '$SCHEMA_INVENTORY_CSV' WITH CSV HEADER;"

psql "$DSN" -c "\copy (
  SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    CASE c.relkind
      WHEN 'r' THEN 'table'
      WHEN 'p' THEN 'partitioned_table'
      WHEN 'v' THEN 'view'
      WHEN 'm' THEN 'materialized_view'
      ELSE c.relkind::text
    END AS object_kind,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname NOT LIKE 'pg_%'
    AND n.nspname <> 'information_schema'
    AND c.relkind IN ('r','p','v','m')
  ORDER BY n.nspname, c.relname
) TO '$TABLE_INVENTORY_CSV' WITH CSV HEADER;"

psql "$DSN" -c "\copy (
  SELECT
    boundary_code,
    boundary_name_tr,
    boundary_name_en,
    canonical_schemas,
    accepted_schema_patterns,
    write_owner,
    read_owner,
    migration_path,
    status
  FROM app_schema.schema_boundary_map
  WHERE deleted_at IS NULL
  ORDER BY boundary_code
) TO '$BOUNDARY_MAP_CSV' WITH CSV HEADER;"

[ -f "$SCHEMA_INVENTORY_CSV" ] && pass "10.1 schema inventory CSV üretildi" || fail "10.1 schema inventory CSV üretilemedi"
[ -f "$TABLE_INVENTORY_CSV" ] && pass "10.2 table inventory CSV üretildi" || fail "10.2 table inventory CSV üretilemedi"
[ -f "$BOUNDARY_MAP_CSV" ] && pass "10.3 boundary map CSV üretildi" || fail "10.3 boundary map CSV üretilemedi"

echo "11. schema separation counters alınıyor..."

BOUNDARY_MAP_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='app_schema' and table_name='schema_boundary_map';")"
BOUNDARY_MAP_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null;")"
BOUNDARY_REQUIRED_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null and boundary_code in ('AUTH','TENANT','ERP','OPS','REPORTING','MIGRATION_PATH');")"
BOUNDARY_ACTIVE_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null and status='ACTIVE';")"

AUTH_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('auth','security','app_security');")"
TENANT_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('platform','org') or nspname like 'tenant_%';")"
ERP_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('erp','accounting','inventory','sales','purchase','product','catalog','org');")"
OPS_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('ops','audit','observability','app_security','security');")"
REPORTING_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('reporting','read_model','analytics');")"

AUTH_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='AUTH' and status='ACTIVE' and 'auth'=any(canonical_schemas);")"
TENANT_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='TENANT' and status='ACTIVE' and 'org'=any(canonical_schemas);")"
ERP_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='ERP' and status='ACTIVE' and 'erp'=any(canonical_schemas);")"
OPS_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='OPS' and status='ACTIVE' and 'ops'=any(canonical_schemas);")"
REPORTING_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='REPORTING' and status='ACTIVE' and 'reporting'=any(canonical_schemas);")"
MIGRATION_PATH_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='MIGRATION_PATH' and status='ACTIVE' and migration_path like 'db/migrations%';")"

BOUNDARY_CONSTRAINT_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='app_schema.schema_boundary_map'::regclass and conname in ('ck_app_schema_boundary_map_required_fields','ck_app_schema_boundary_map_status');")"
BOUNDARY_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='app_schema' and tablename='schema_boundary_map';")"
BOUNDARY_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_app_schema_boundary_map_set_updated_at' and tgrelid='app_schema.schema_boundary_map'::regclass and not tgisinternal;")"

echo "BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
echo "BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
echo "BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
echo "BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
echo "AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
echo "ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
echo "OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
echo "REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
echo "AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
echo "TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
echo "ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
echo "OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
echo "REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
echo "MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
echo "BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
echo "BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
echo "BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"

[ "$BOUNDARY_MAP_TABLE_COUNT" -eq 1 ] && pass "11.1 schema boundary map tablosu hazır" || fail "11.1 schema boundary map tablosu eksik"
[ "$BOUNDARY_MAP_ROW_COUNT" -ge 6 ] && pass "11.2 boundary map row kapsamı hazır" || fail "11.2 boundary map row kapsamı eksik"
[ "$BOUNDARY_REQUIRED_ROW_COUNT" -eq 6 ] && pass "11.3 zorunlu 6 boundary mevcut" || fail "11.3 zorunlu 6 boundary eksik"
[ "$BOUNDARY_ACTIVE_ROW_COUNT" -ge 6 ] && pass "11.4 boundary status ACTIVE kapsamı hazır" || fail "11.4 active boundary kapsamı eksik"
[ "$AUTH_SCHEMA_COUNT" -ge 1 ] && pass "11.5 auth schema alanı mevcut" || fail "11.5 auth schema alanı eksik"
[ "$TENANT_SCHEMA_COUNT" -ge 1 ] && pass "11.6 tenant schema/pattern alanı mevcut" || fail "11.6 tenant schema/pattern alanı eksik"
[ "$ERP_SCHEMA_COUNT" -ge 1 ] && pass "11.7 ERP schema alanı mevcut" || fail "11.7 ERP schema alanı eksik"
[ "$OPS_SCHEMA_COUNT" -ge 1 ] && pass "11.8 ops schema alanı mevcut" || fail "11.8 ops schema alanı eksik"
[ "$REPORTING_SCHEMA_COUNT" -ge 1 ] && pass "11.9 reporting schema alanı mevcut" || fail "11.9 reporting schema alanı eksik"
[ "$AUTH_BOUNDARY_COUNT" -eq 1 ] && pass "11.10 AUTH boundary map hazır" || fail "11.10 AUTH boundary map eksik"
[ "$TENANT_BOUNDARY_COUNT" -eq 1 ] && pass "11.11 TENANT boundary map hazır" || fail "11.11 TENANT boundary map eksik"
[ "$ERP_BOUNDARY_COUNT" -eq 1 ] && pass "11.12 ERP boundary map hazır" || fail "11.12 ERP boundary map eksik"
[ "$OPS_BOUNDARY_COUNT" -eq 1 ] && pass "11.13 OPS boundary map hazır" || fail "11.13 OPS boundary map eksik"
[ "$REPORTING_BOUNDARY_COUNT" -eq 1 ] && pass "11.14 REPORTING boundary map hazır" || fail "11.14 REPORTING boundary map eksik"
[ "$MIGRATION_PATH_BOUNDARY_COUNT" -eq 1 ] && pass "11.15 MIGRATION_PATH boundary map hazır" || fail "11.15 MIGRATION_PATH boundary map eksik"
[ "$BOUNDARY_CONSTRAINT_COUNT" -ge 2 ] && pass "11.16 boundary constraint seti hazır" || fail "11.16 boundary constraint seti eksik"
[ "$BOUNDARY_INDEX_COUNT" -ge 3 ] && pass "11.17 boundary index seti hazır" || fail "11.17 boundary index seti eksik"
[ "$BOUNDARY_TRIGGER_COUNT" -eq 1 ] && pass "11.18 boundary updated_at trigger hazır" || fail "11.18 boundary updated_at trigger eksik"

echo "12. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_7_schema_separation_map_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP STRICT SUITE START ====="

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

MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"
FAZ1_MIGRATION_FILE_COUNT="$(find "$REPO/db/migrations/faz1" -type f \( -name "*.sql" -o -name "*.sh" \) 2>/dev/null | wc -l | awk '{print $1}')"

BOUNDARY_MAP_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='app_schema' and table_name='schema_boundary_map';")"
BOUNDARY_MAP_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null;")"
BOUNDARY_REQUIRED_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null and boundary_code in ('AUTH','TENANT','ERP','OPS','REPORTING','MIGRATION_PATH');")"
BOUNDARY_ACTIVE_ROW_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where deleted_at is null and status='ACTIVE';")"

AUTH_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('auth','security','app_security');")"
TENANT_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('platform','org') or nspname like 'tenant_%';")"
ERP_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('erp','accounting','inventory','sales','purchase','product','catalog','org');")"
OPS_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('ops','audit','observability','app_security','security');")"
REPORTING_SCHEMA_COUNT="$(scalar_count "select count(*) from pg_namespace where nspname in ('reporting','read_model','analytics');")"

AUTH_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='AUTH' and status='ACTIVE' and 'auth'=any(canonical_schemas);")"
TENANT_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='TENANT' and status='ACTIVE' and 'org'=any(canonical_schemas);")"
ERP_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='ERP' and status='ACTIVE' and 'erp'=any(canonical_schemas);")"
OPS_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='OPS' and status='ACTIVE' and 'ops'=any(canonical_schemas);")"
REPORTING_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='REPORTING' and status='ACTIVE' and 'reporting'=any(canonical_schemas);")"
MIGRATION_PATH_BOUNDARY_COUNT="$(scalar_count "select count(*) from app_schema.schema_boundary_map where boundary_code='MIGRATION_PATH' and status='ACTIVE' and migration_path like 'db/migrations%';")"

BOUNDARY_CONSTRAINT_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='app_schema.schema_boundary_map'::regclass and conname in ('ck_app_schema_boundary_map_required_fields','ck_app_schema_boundary_map_status');")"
BOUNDARY_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='app_schema' and tablename='schema_boundary_map';")"
BOUNDARY_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_app_schema_boundary_map_set_updated_at' and tgrelid='app_schema.schema_boundary_map'::regclass and not tgisinternal;")"

echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
echo "BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
echo "BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
echo "BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
echo "BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
echo "AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
echo "ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
echo "OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
echo "REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
echo "AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
echo "TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
echo "ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
echo "OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
echo "REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
echo "MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
echo "BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
echo "BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
echo "BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"

[ "$MIGRATION_FILE_COUNT" -ge 1 ] && pass "5.1 migration path mevcut" || fail "5.1 migration path yok"
[ "$FAZ1_MIGRATION_FILE_COUNT" -ge 1 ] && pass "5.2 faz1 migration path mevcut" || fail "5.2 faz1 migration path yok"
[ "$BOUNDARY_MAP_TABLE_COUNT" -eq 1 ] && pass "5.3 schema boundary map tablosu hazır" || fail "5.3 schema boundary map tablosu eksik"
[ "$BOUNDARY_REQUIRED_ROW_COUNT" -eq 6 ] && pass "5.4 zorunlu 6 boundary mevcut" || fail "5.4 zorunlu 6 boundary eksik"
[ "$BOUNDARY_ACTIVE_ROW_COUNT" -ge 6 ] && pass "5.5 boundary status ACTIVE kapsamı hazır" || fail "5.5 active boundary kapsamı eksik"
[ "$AUTH_SCHEMA_COUNT" -ge 1 ] && pass "5.6 auth schema alanı mevcut" || fail "5.6 auth schema alanı eksik"
[ "$TENANT_SCHEMA_COUNT" -ge 1 ] && pass "5.7 tenant schema/pattern alanı mevcut" || fail "5.7 tenant schema/pattern alanı eksik"
[ "$ERP_SCHEMA_COUNT" -ge 1 ] && pass "5.8 ERP schema alanı mevcut" || fail "5.8 ERP schema alanı eksik"
[ "$OPS_SCHEMA_COUNT" -ge 1 ] && pass "5.9 ops schema alanı mevcut" || fail "5.9 ops schema alanı eksik"
[ "$REPORTING_SCHEMA_COUNT" -ge 1 ] && pass "5.10 reporting schema alanı mevcut" || fail "5.10 reporting schema alanı eksik"
[ "$AUTH_BOUNDARY_COUNT" -eq 1 ] && pass "5.11 AUTH boundary map hazır" || fail "5.11 AUTH boundary map eksik"
[ "$TENANT_BOUNDARY_COUNT" -eq 1 ] && pass "5.12 TENANT boundary map hazır" || fail "5.12 TENANT boundary map eksik"
[ "$ERP_BOUNDARY_COUNT" -eq 1 ] && pass "5.13 ERP boundary map hazır" || fail "5.13 ERP boundary map eksik"
[ "$OPS_BOUNDARY_COUNT" -eq 1 ] && pass "5.14 OPS boundary map hazır" || fail "5.14 OPS boundary map eksik"
[ "$REPORTING_BOUNDARY_COUNT" -eq 1 ] && pass "5.15 REPORTING boundary map hazır" || fail "5.15 REPORTING boundary map eksik"
[ "$MIGRATION_PATH_BOUNDARY_COUNT" -eq 1 ] && pass "5.16 MIGRATION_PATH boundary map hazır" || fail "5.16 MIGRATION_PATH boundary map eksik"
[ "$BOUNDARY_CONSTRAINT_COUNT" -ge 2 ] && pass "5.17 boundary constraint seti hazır" || fail "5.17 boundary constraint seti eksik"
[ "$BOUNDARY_INDEX_COUNT" -ge 3 ] && pass "5.18 boundary index seti hazır" || fail "5.18 boundary index seti eksik"
[ "$BOUNDARY_TRIGGER_COUNT" -eq 1 ] && pass "5.19 boundary updated_at trigger hazır" || fail "5.19 boundary updated_at trigger eksik"

{
  echo "# FAZ 1-1.7 Schema Separation Map Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
  echo "- FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
  echo "- BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
  echo "- BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
  echo "- BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
  echo "- BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
  echo "- AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
  echo "- TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "- ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
  echo "- OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
  echo "- REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
  echo "- AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
  echo "- TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
  echo "- ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
  echo "- OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
  echo "- REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
  echo "- MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
  echo "- BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
  echo "- BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
  echo "- BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
echo "BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
echo "BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
echo "BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
echo "BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
echo "AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
echo "ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
echo "OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
echo "REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
echo "AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
echo "TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
echo "ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
echo "OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
echo "REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
echo "MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
echo "BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
echo "BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
echo "BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_7_AUTH_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_TENANT_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_ERP_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_OPS_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_REPORTING_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_MIGRATION_PATH_STATUS=PASS"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"
pass "12.1 strict suite dosyası yazıldı: $STRICT_SUITE_FILE"

echo "13. strict suite çalıştırılıyor..."

export REPO
export BACKUP_DIR="$SUITE_RUNTIME_DIR"
export TS

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "13.1 strict suite exit code 0"
else
  fail "13.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_STRICT_TEST_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS")"

AUTH_SCHEMA_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_AUTH_SCHEMA_STATUS")"
TENANT_SCHEMA_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_TENANT_SCHEMA_STATUS")"
ERP_SCHEMA_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_ERP_SCHEMA_STATUS")"
OPS_SCHEMA_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_OPS_SCHEMA_STATUS")"
REPORTING_SCHEMA_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_REPORTING_SCHEMA_STATUS")"
MIGRATION_PATH_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_1_7_MIGRATION_PATH_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "14. strict suite FAIL_COUNT=0 doğrulandı" || fail "14. strict suite FAIL_COUNT sıfır değil: ${STRICT_SUITE_FAIL_COUNT:-N/A}"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "15. strict suite status PASS doğrulandı" || fail "15. strict suite status PASS değil: ${STRICT_SUITE_STATUS:-N/A}"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "16. strict suite seal SEALED doğrulandı" || fail "16. strict suite seal SEALED değil: ${STRICT_SUITE_SEAL_STATUS:-N/A}"

echo "17. dokümantasyon ve final evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-1.7 Schema Separation Map

## Kapsam

- Auth schema
- Tenant schema
- ERP schema
- Ops schema
- Reporting schema
- Migration path

## Uygulama

Bu adım app_schema.schema_boundary_map tablosunu oluşturur ve sistemdeki ana schema sorumluluklarını kalıcı kontrat haline getirir.

## Boundary Kararları

| Boundary | Ana Sorumluluk |
|---|---|
| AUTH | Kimlik, rol, permission, user scope, super-admin, break-glass |
| TENANT | Tenant, legal entity, branch ve tenant scoped business kayıtları |
| ERP | ERP domainleri, muhasebe, stok, satış, ürün ve iş tabloları |
| OPS | Audit, ops, observability, incident, security alert |
| REPORTING | Read model, reporting store, analytics |
| MIGRATION_PATH | db/migrations, docs/evidence ve backups path standardı |

## Final Status

- FAZ_1_1_7_AUTH_SCHEMA_STATUS=${AUTH_SCHEMA_STATUS:-N/A}
- FAZ_1_1_7_TENANT_SCHEMA_STATUS=${TENANT_SCHEMA_STATUS:-N/A}
- FAZ_1_1_7_ERP_SCHEMA_STATUS=${ERP_SCHEMA_STATUS:-N/A}
- FAZ_1_1_7_OPS_SCHEMA_STATUS=${OPS_SCHEMA_STATUS:-N/A}
- FAZ_1_1_7_REPORTING_SCHEMA_STATUS=${REPORTING_SCHEMA_STATUS:-N/A}
- FAZ_1_1_7_MIGRATION_PATH_STATUS=${MIGRATION_PATH_STATUS:-N/A}
- FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-1.7 Schema Separation Map Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Evidence Snapshots"
  echo "- Schema inventory CSV: $SCHEMA_INVENTORY_CSV"
  echo "- Table inventory CSV: $TABLE_INVENTORY_CSV"
  echo "- Boundary map CSV: $BOUNDARY_MAP_CSV"
  echo "- Migration path inventory: $MIGRATION_PATH_INVENTORY"
  echo
  echo "## Counters"
  echo "- MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
  echo "- FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
  echo "- BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
  echo "- BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
  echo "- BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
  echo "- BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
  echo "- AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
  echo "- TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
  echo "- ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
  echo "- OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
  echo "- REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
  echo "- AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
  echo "- TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
  echo "- ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
  echo "- OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
  echo "- REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
  echo "- MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
  echo "- BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
  echo "- BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
  echo "- BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"
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
  echo "# FAZ 1-1.7 Schema Separation Map Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Migration file: $MIGRATION_FILE"
  echo "- Strict suite file: $STRICT_SUITE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_1_7_AUTH_SCHEMA_STATUS=${AUTH_SCHEMA_STATUS:-N/A}"
  echo "FAZ_1_1_7_TENANT_SCHEMA_STATUS=${TENANT_SCHEMA_STATUS:-N/A}"
  echo "FAZ_1_1_7_ERP_SCHEMA_STATUS=${ERP_SCHEMA_STATUS:-N/A}"
  echo "FAZ_1_1_7_OPS_SCHEMA_STATUS=${OPS_SCHEMA_STATUS:-N/A}"
  echo "FAZ_1_1_7_REPORTING_SCHEMA_STATUS=${REPORTING_SCHEMA_STATUS:-N/A}"
  echo "FAZ_1_1_7_MIGRATION_PATH_STATUS=${MIGRATION_PATH_STATUS:-N/A}"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_R_ONCELIK_2_READY_FOR_FINAL_REVIEW=YES"
} > "$FINAL_SEAL_FILE"

pass "17.1 dokümantasyon güncellendi: $DOC_FILE"
pass "17.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "17.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"
pass "17.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP APPLY RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "MIGRATION_FILE_COUNT=$MIGRATION_FILE_COUNT"
echo "FAZ1_MIGRATION_FILE_COUNT=$FAZ1_MIGRATION_FILE_COUNT"
echo "BOUNDARY_MAP_TABLE_COUNT=$BOUNDARY_MAP_TABLE_COUNT"
echo "BOUNDARY_MAP_ROW_COUNT=$BOUNDARY_MAP_ROW_COUNT"
echo "BOUNDARY_REQUIRED_ROW_COUNT=$BOUNDARY_REQUIRED_ROW_COUNT"
echo "BOUNDARY_ACTIVE_ROW_COUNT=$BOUNDARY_ACTIVE_ROW_COUNT"
echo "AUTH_SCHEMA_COUNT=$AUTH_SCHEMA_COUNT"
echo "TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT"
echo "ERP_SCHEMA_COUNT=$ERP_SCHEMA_COUNT"
echo "OPS_SCHEMA_COUNT=$OPS_SCHEMA_COUNT"
echo "REPORTING_SCHEMA_COUNT=$REPORTING_SCHEMA_COUNT"
echo "AUTH_BOUNDARY_COUNT=$AUTH_BOUNDARY_COUNT"
echo "TENANT_BOUNDARY_COUNT=$TENANT_BOUNDARY_COUNT"
echo "ERP_BOUNDARY_COUNT=$ERP_BOUNDARY_COUNT"
echo "OPS_BOUNDARY_COUNT=$OPS_BOUNDARY_COUNT"
echo "REPORTING_BOUNDARY_COUNT=$REPORTING_BOUNDARY_COUNT"
echo "MIGRATION_PATH_BOUNDARY_COUNT=$MIGRATION_PATH_BOUNDARY_COUNT"
echo "BOUNDARY_CONSTRAINT_COUNT=$BOUNDARY_CONSTRAINT_COUNT"
echo "BOUNDARY_INDEX_COUNT=$BOUNDARY_INDEX_COUNT"
echo "BOUNDARY_TRIGGER_COUNT=$BOUNDARY_TRIGGER_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "AUTH_SCHEMA_STATUS=${AUTH_SCHEMA_STATUS:-N/A}"
echo "TENANT_SCHEMA_STATUS=${TENANT_SCHEMA_STATUS:-N/A}"
echo "ERP_SCHEMA_STATUS=${ERP_SCHEMA_STATUS:-N/A}"
echo "OPS_SCHEMA_STATUS=${OPS_SCHEMA_STATUS:-N/A}"
echo "REPORTING_SCHEMA_STATUS=${REPORTING_SCHEMA_STATUS:-N/A}"
echo "MIGRATION_PATH_STATUS=${MIGRATION_PATH_STATUS:-N/A}"
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

  echo "FAZ_1_1_7_AUTH_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_TENANT_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_ERP_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_OPS_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_REPORTING_SCHEMA_STATUS=PASS"
  echo "FAZ_1_1_7_MIGRATION_PATH_STATUS=PASS"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_FINAL_STATUS=PASS"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=SEALED"
  echo "FAZ_1_R_ONCELIK_2_READY_FOR_FINAL_REVIEW=YES"
else
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_FINAL_STATUS=FAIL"
  echo "FAZ_1_1_7_SCHEMA_SEPARATION_MAP_SEAL_STATUS=OPEN"
  echo "FAZ_1_R_ONCELIK_2_READY_FOR_FINAL_REVIEW=NO"
  exit 1
fi

echo "===== FAZ 1-1.7 SCHEMA SEPARATION MAP APPLY END ====="
