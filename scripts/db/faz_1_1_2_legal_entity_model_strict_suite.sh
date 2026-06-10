#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_1_2_legal_entity_model_strict_suite_fix_v5_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_SUITE_RESULT_FIX_V5_$TS.md"

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

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 START ====="

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

echo "5. legal entity model sayaçları alınıyor..."

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entities';")"
LEGAL_ENTITY_ADDRESS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='legal_entity_addresses';")"

LEGAL_ENTITY_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entities'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'legal_name','trade_name','tax_number','tax_office','mersis_no',
      'phone','email','address_line','district','city','country_code',
      'postal_code','status','metadata','audit_metadata','created_at','updated_at',
      'created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_ADDRESS_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='org'
    and table_name='legal_entity_addresses'
    and column_name in (
      'id','tenant_id','legal_entity_id','branch_id','business_code',
      'address_type','address_line','district','city','country_code',
      'postal_code','is_primary','status','metadata','audit_metadata',
      'created_at','updated_at','created_by','updated_by','deleted_at'
    );
")"

LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entities'::regclass
    and conname in (
      'ck_org_legal_entities_required_company_fields',
      'ck_org_legal_entities_status',
      'ck_org_legal_entities_country_code',
      'ck_org_legal_entities_tax_number_format'
    );
")"

LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint
  where conrelid='org.legal_entity_addresses'::regclass
    and conname in (
      'fk_org_legal_entity_addresses_legal_entity_tenant',
      'ck_org_legal_entity_addresses_required_fields',
      'ck_org_legal_entity_addresses_status',
      'ck_org_legal_entity_addresses_address_type'
    );
")"

LEGAL_ENTITY_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entities'
    and indexname in (
      'ux_org_legal_entities_id_tenant_id_fk',
      'ux_org_legal_entities_tenant_business_code',
      'ux_org_legal_entities_tenant_tax_number',
      'idx_org_legal_entities_tenant_id',
      'idx_org_legal_entities_legal_name',
      'idx_org_legal_entities_status'
    );
")"

LEGAL_ENTITY_ADDRESS_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where schemaname='org'
    and tablename='legal_entity_addresses'
    and indexname in (
      'ux_org_legal_entity_addresses_tenant_business_code',
      'idx_org_legal_entity_addresses_tenant_id',
      'idx_org_legal_entity_addresses_legal_entity_id',
      'idx_org_legal_entity_addresses_status'
    );
")"

LEGAL_ENTITY_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relrowsecurity=true;
")"

LEGAL_ENTITY_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='org'
    and c.relname in ('legal_entities','legal_entity_addresses')
    and c.relforcerowsecurity=true;
")"

LEGAL_ENTITY_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='org'
    and tablename in ('legal_entities','legal_entity_addresses');
")"

LEGAL_ENTITY_DICTIONARY_TABLE_COUNT="$(scalar_count "
  select count(*)
  from app_dictionary.table_contracts
  where schema_name='org'
    and table_name in ('legal_entities','legal_entity_addresses');
")"

echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"

[ "$LEGAL_ENTITY_TABLE_COUNT" -eq 1 ] && pass "5.1 firma modeli tablosu hazır" || fail "5.1 firma modeli tablosu eksik"
[ "$LEGAL_ENTITY_ADDRESS_TABLE_COUNT" -eq 1 ] && pass "5.2 adres bağlantısı tablosu hazır" || fail "5.2 adres bağlantısı tablosu eksik"
[ "$LEGAL_ENTITY_COLUMN_COUNT" -ge 25 ] && pass "5.3 firma modeli canonical kolon kapsamı tam" || fail "5.3 firma modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT" -ge 20 ] && pass "5.4 adres modeli canonical kolon kapsamı tam" || fail "5.4 adres modeli kolon kapsamı eksik"
[ "$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT" -ge 4 ] && pass "5.5 vergi/ticari/adres required constraint seti hazır" || fail "5.5 required constraint seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT" -ge 4 ] && pass "5.6 adres FK/constraint seti hazır" || fail "5.6 adres FK/constraint seti eksik"
[ "$LEGAL_ENTITY_INDEX_COUNT" -ge 6 ] && pass "5.7 legal entity tenant-safe index seti hazır" || fail "5.7 legal entity index seti eksik"
[ "$LEGAL_ENTITY_ADDRESS_INDEX_COUNT" -ge 4 ] && pass "5.8 legal entity address index seti hazır" || fail "5.8 legal entity address index seti eksik"
[ "$LEGAL_ENTITY_RLS_ENABLED_COUNT" -eq 2 ] && pass "5.9 legal entity tablolarında RLS enabled" || fail "5.9 RLS enabled eksik"
[ "$LEGAL_ENTITY_RLS_FORCED_COUNT" -eq 2 ] && pass "5.10 legal entity tablolarında RLS forced" || fail "5.10 RLS forced eksik"
[ "$LEGAL_ENTITY_POLICY_COUNT" -ge 2 ] && pass "5.11 tenant policy seti hazır" || fail "5.11 tenant policy seti eksik"
[ "$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT" -ge 2 ] && pass "5.12 data dictionary table contract mevcut" || warn "5.12 data dictionary table contract yok"

{
  echo "# FAZ 1-1.2 Legal Entity Model Strict Suite Result FIX V5"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
  echo "- LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
  echo "- LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
  echo "- LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
  echo "- LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
  echo "- LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
  echo "- LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
  echo "- LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "LEGAL_ENTITY_ADDRESS_TABLE_COUNT=$LEGAL_ENTITY_ADDRESS_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "LEGAL_ENTITY_ADDRESS_COLUMN_COUNT=$LEGAL_ENTITY_ADDRESS_COLUMN_COUNT"
echo "LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT=$LEGAL_ENTITY_REQUIRED_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT=$LEGAL_ENTITY_ADDRESS_CONSTRAINT_COUNT"
echo "LEGAL_ENTITY_INDEX_COUNT=$LEGAL_ENTITY_INDEX_COUNT"
echo "LEGAL_ENTITY_ADDRESS_INDEX_COUNT=$LEGAL_ENTITY_ADDRESS_INDEX_COUNT"
echo "LEGAL_ENTITY_RLS_ENABLED_COUNT=$LEGAL_ENTITY_RLS_ENABLED_COUNT"
echo "LEGAL_ENTITY_RLS_FORCED_COUNT=$LEGAL_ENTITY_RLS_FORCED_COUNT"
echo "LEGAL_ENTITY_POLICY_COUNT=$LEGAL_ENTITY_POLICY_COUNT"
echo "LEGAL_ENTITY_DICTIONARY_TABLE_COUNT=$LEGAL_ENTITY_DICTIONARY_TABLE_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_1_2_COMPANY_MODEL_STATUS=PASS"
  echo "FAZ_1_1_2_TAX_INFO_STATUS=PASS"
  echo "FAZ_1_1_2_TRADE_TITLE_STATUS=PASS"
  echo "FAZ_1_1_2_ADDRESS_LINK_STATUS=PASS"
  echo "FAZ_1_1_2_TENANT_RELATION_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-1.2 LEGAL ENTITY MODEL STRICT SUITE FIX V5 END ====="
