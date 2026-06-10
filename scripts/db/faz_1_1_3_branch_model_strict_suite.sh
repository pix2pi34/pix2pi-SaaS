#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_3_branch_model_strict_suite_fix_v6_$TS}"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_3_BRANCH_MODEL_STRICT_SUITE_RESULT_FIX_V6_$TS.md"

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

echo "===== FAZ 1-1.3 BRANCH MODEL STRICT SUITE FIX V6 START ====="

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

BRANCH_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='branches';")"
BRANCH_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='branch_addresses';")"
BRANCH_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='branches' and column_name in ('id','tenant_id','legal_entity_id','branch_id','business_code','branch_code','name','branch_name','branch_type','phone','email','address_line','district','city','country_code','postal_code','scope_key','is_default','status','metadata','audit_metadata','created_at','updated_at','created_by','updated_by','deleted_at');")"
BRANCH_ADDRESS_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='branch_addresses' and column_name in ('id','tenant_id','legal_entity_id','branch_id','business_code','address_type','address_line','district','city','country_code','postal_code','is_primary','status','metadata','audit_metadata','created_at','updated_at','created_by','updated_by','deleted_at');")"
BRANCH_CONSTRAINT_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.branches'::regclass and conname in ('fk_org_branches_legal_entity_tenant','ck_org_branches_required_fields','ck_org_branches_branch_type','ck_org_branches_status');")"
BRANCH_ADDRESS_CONSTRAINT_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.branch_addresses'::regclass and conname in ('fk_org_branch_addresses_branch_tenant','fk_org_branch_addresses_legal_entity_tenant','ck_org_branch_addresses_required_fields','ck_org_branch_addresses_address_type','ck_org_branch_addresses_status');")"
BRANCH_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='branches';")"
BRANCH_ADDRESS_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='branch_addresses';")"
BRANCH_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname in ('branches','branch_addresses') and c.relrowsecurity=true;")"
BRANCH_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname in ('branches','branch_addresses') and c.relforcerowsecurity=true;")"
BRANCH_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename in ('branches','branch_addresses');")"
BRANCH_DICTIONARY_TABLE_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name in ('branches','branch_addresses');")"
BRANCH_LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_branches_sync_legacy_fields' and tgrelid='org.branches'::regclass and not tgisinternal;")"
BRANCH_LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='sync_branch_legacy_fields';")"

echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
echo "BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
echo "BRANCH_ADDRESS_COLUMN_COUNT=$BRANCH_ADDRESS_COLUMN_COUNT"
echo "BRANCH_CONSTRAINT_COUNT=$BRANCH_CONSTRAINT_COUNT"
echo "BRANCH_ADDRESS_CONSTRAINT_COUNT=$BRANCH_ADDRESS_CONSTRAINT_COUNT"
echo "BRANCH_INDEX_COUNT=$BRANCH_INDEX_COUNT"
echo "BRANCH_ADDRESS_INDEX_COUNT=$BRANCH_ADDRESS_INDEX_COUNT"
echo "BRANCH_RLS_ENABLED_COUNT=$BRANCH_RLS_ENABLED_COUNT"
echo "BRANCH_RLS_FORCED_COUNT=$BRANCH_RLS_FORCED_COUNT"
echo "BRANCH_POLICY_COUNT=$BRANCH_POLICY_COUNT"
echo "BRANCH_DICTIONARY_TABLE_COUNT=$BRANCH_DICTIONARY_TABLE_COUNT"
echo "BRANCH_LEGACY_SYNC_TRIGGER_COUNT=$BRANCH_LEGACY_SYNC_TRIGGER_COUNT"
echo "BRANCH_LEGACY_SYNC_FUNCTION_COUNT=$BRANCH_LEGACY_SYNC_FUNCTION_COUNT"

[ "$BRANCH_TABLE_COUNT" -eq 1 ] && pass "5.1 şube modeli tablosu hazır" || fail "5.1 şube modeli tablosu eksik"
[ "$BRANCH_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "5.2 şube adres tablosu hazır" || fail "5.2 şube adres tablosu eksik"
[ "$BRANCH_COLUMN_COUNT" -ge 26 ] && pass "5.3 şube canonical + legacy kolon kapsamı tam" || fail "5.3 şube kolon kapsamı eksik"
[ "$BRANCH_ADDRESS_COLUMN_COUNT" -ge 20 ] && pass "5.4 şube adres canonical kolon kapsamı tam" || fail "5.4 şube adres kolon kapsamı eksik"
[ "$BRANCH_CONSTRAINT_COUNT" -ge 4 ] && pass "5.5 şube relation/constraint seti hazır" || fail "5.5 şube relation/constraint seti eksik"
[ "$BRANCH_ADDRESS_CONSTRAINT_COUNT" -ge 5 ] && pass "5.6 şube adres relation/constraint seti hazır" || fail "5.6 şube adres relation/constraint seti eksik"
[ "$BRANCH_INDEX_COUNT" -ge 7 ] && pass "5.7 şube index seti hazır" || fail "5.7 şube index seti eksik"
[ "$BRANCH_ADDRESS_INDEX_COUNT" -ge 5 ] && pass "5.8 şube adres index seti hazır" || fail "5.8 şube adres index seti eksik"
[ "$BRANCH_RLS_ENABLED_COUNT" -eq 2 ] && pass "5.9 şube tablolarında RLS enabled" || fail "5.9 RLS enabled eksik"
[ "$BRANCH_RLS_FORCED_COUNT" -eq 2 ] && pass "5.10 şube tablolarında RLS forced" || fail "5.10 RLS forced eksik"
[ "$BRANCH_POLICY_COUNT" -ge 2 ] && pass "5.11 şube tenant policy seti hazır" || fail "5.11 tenant policy seti eksik"
[ "$BRANCH_DICTIONARY_TABLE_COUNT" -ge 2 ] && pass "5.12 data dictionary table contract mevcut" || warn "5.12 data dictionary table contract yok"
[ "$BRANCH_LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "5.13 legacy name sync trigger hazır" || fail "5.13 legacy sync trigger eksik"
[ "$BRANCH_LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "5.14 legacy name sync function hazır" || fail "5.14 legacy sync function eksik"

{
  echo "# FAZ 1-1.3 Branch Model Strict Suite Result FIX V6"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
  echo "- BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
  echo "- BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
  echo "- BRANCH_ADDRESS_COLUMN_COUNT=$BRANCH_ADDRESS_COLUMN_COUNT"
  echo "- BRANCH_CONSTRAINT_COUNT=$BRANCH_CONSTRAINT_COUNT"
  echo "- BRANCH_ADDRESS_CONSTRAINT_COUNT=$BRANCH_ADDRESS_CONSTRAINT_COUNT"
  echo "- BRANCH_INDEX_COUNT=$BRANCH_INDEX_COUNT"
  echo "- BRANCH_ADDRESS_INDEX_COUNT=$BRANCH_ADDRESS_INDEX_COUNT"
  echo "- BRANCH_RLS_ENABLED_COUNT=$BRANCH_RLS_ENABLED_COUNT"
  echo "- BRANCH_RLS_FORCED_COUNT=$BRANCH_RLS_FORCED_COUNT"
  echo "- BRANCH_POLICY_COUNT=$BRANCH_POLICY_COUNT"
  echo "- BRANCH_DICTIONARY_TABLE_COUNT=$BRANCH_DICTIONARY_TABLE_COUNT"
  echo "- BRANCH_LEGACY_SYNC_TRIGGER_COUNT=$BRANCH_LEGACY_SYNC_TRIGGER_COUNT"
  echo "- BRANCH_LEGACY_SYNC_FUNCTION_COUNT=$BRANCH_LEGACY_SYNC_FUNCTION_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.3 BRANCH MODEL STRICT SUITE FIX V6 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "BRANCH_ADDRESS_TABLE_COUNT=$BRANCH_ADDRESS_TABLE_COUNT"
echo "BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
echo "BRANCH_ADDRESS_COLUMN_COUNT=$BRANCH_ADDRESS_COLUMN_COUNT"
echo "BRANCH_CONSTRAINT_COUNT=$BRANCH_CONSTRAINT_COUNT"
echo "BRANCH_ADDRESS_CONSTRAINT_COUNT=$BRANCH_ADDRESS_CONSTRAINT_COUNT"
echo "BRANCH_INDEX_COUNT=$BRANCH_INDEX_COUNT"
echo "BRANCH_ADDRESS_INDEX_COUNT=$BRANCH_ADDRESS_INDEX_COUNT"
echo "BRANCH_RLS_ENABLED_COUNT=$BRANCH_RLS_ENABLED_COUNT"
echo "BRANCH_RLS_FORCED_COUNT=$BRANCH_RLS_FORCED_COUNT"
echo "BRANCH_POLICY_COUNT=$BRANCH_POLICY_COUNT"
echo "BRANCH_DICTIONARY_TABLE_COUNT=$BRANCH_DICTIONARY_TABLE_COUNT"
echo "BRANCH_LEGACY_SYNC_TRIGGER_COUNT=$BRANCH_LEGACY_SYNC_TRIGGER_COUNT"
echo "BRANCH_LEGACY_SYNC_FUNCTION_COUNT=$BRANCH_LEGACY_SYNC_FUNCTION_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_3_BRANCH_MODEL_STATUS=PASS"
  echo "FAZ_1_1_3_LEGAL_ENTITY_RELATION_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_CODE_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_ADDRESS_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_SCOPE_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_TEST_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_MODEL_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_3_BRANCH_MODEL_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_3_BRANCH_MODEL_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_3_BRANCH_MODEL_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.3 BRANCH MODEL STRICT SUITE FIX V6 END ====="
