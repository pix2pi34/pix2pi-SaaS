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
