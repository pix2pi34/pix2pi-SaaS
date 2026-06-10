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
