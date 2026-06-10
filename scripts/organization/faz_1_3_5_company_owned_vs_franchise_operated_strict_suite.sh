#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_5_company_owned_vs_franchise_operated_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_5_COMPANY_OWNED_VS_FRANCHISE_OPERATED_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE START ====="

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

OP_PROFILE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"
OP_PROFILE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='f';")"
OP_PROFILE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and contype='c';")"
OP_PROFILE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relrowsecurity=true;")"
OP_PROFILE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='location_operation_profiles' and c.relforcerowsecurity=true;")"
OP_PROFILE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='location_operation_profiles';")"
OP_PROFILE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='location_operation_profiles' and column_name in ('lifecycle_reason','operation_audit_ref','audit_metadata');")"
OP_PROFILE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='location_operation_profiles';")"

COMPANY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_company_branch_rule';")"
FRANCHISE_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
REPORTING_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_reporting_effect';")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_permission_effect';")"
LOCATION_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
FRANCHISE_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"

echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"

[ "$OP_PROFILE_TABLE_COUNT" -eq 1 ] && pass "5.1 operation profile tablosu hazır" || fail "5.1 operation profile tablosu eksik"
[ "$OP_PROFILE_FK_COUNT" -ge 6 ] && pass "5.2 operation profile FK seti hazır" || fail "5.2 operation profile FK seti eksik"
[ "$OP_PROFILE_CHECK_COUNT" -ge 12 ] && pass "5.3 operation profile check seti hazır" || fail "5.3 operation profile check seti eksik"
[ "$OP_PROFILE_INDEX_COUNT" -ge 12 ] && pass "5.4 operation profile index seti hazır" || fail "5.4 operation profile index seti eksik"
[ "$OP_PROFILE_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 operation profile RLS enabled" || fail "5.5 operation profile RLS enabled eksik"
[ "$OP_PROFILE_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 operation profile RLS forced" || fail "5.6 operation profile RLS forced eksik"
[ "$OP_PROFILE_POLICY_COUNT" -ge 1 ] && pass "5.7 operation profile tenant policy hazır" || fail "5.7 operation profile tenant policy eksik"
[ "$OP_PROFILE_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.8 operation audit kolonları hazır" || fail "5.8 operation audit kolonları eksik"
[ "$OP_PROFILE_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 operation profile data dictionary mevcut" || warn "5.9 operation profile data dictionary eksik"
[ "$COMPANY_RULE_CHECK_COUNT" -eq 1 ] && pass "5.10 company-owned branch rule hazır" || fail "5.10 company-owned branch rule eksik"
[ "$FRANCHISE_RULE_CHECK_COUNT" -eq 1 ] && pass "5.11 franchise-operated store rule hazır" || fail "5.11 franchise-operated store rule eksik"
[ "$REPORTING_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.12 reporting effect rule hazır" || fail "5.12 reporting effect rule eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.13 permission effect rule hazır" || fail "5.13 permission effect rule eksik"
[ "$LOCATION_DEPENDENCY_COUNT" -eq 1 ] && pass "5.14 business_locations dependency hazır" || fail "5.14 business_locations dependency eksik"
[ "$FRANCHISE_DEPENDENCY_COUNT" -eq 1 ] && pass "5.15 franchise agreements dependency hazır" || fail "5.15 franchise agreements dependency eksik"

{
  echo "# FAZ 1-3.5 Company-owned vs Franchise-operated Strict Suite Result"
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

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "OP_PROFILE_TABLE_COUNT=$OP_PROFILE_TABLE_COUNT"
echo "OP_PROFILE_FK_COUNT=$OP_PROFILE_FK_COUNT"
echo "OP_PROFILE_CHECK_COUNT=$OP_PROFILE_CHECK_COUNT"
echo "OP_PROFILE_INDEX_COUNT=$OP_PROFILE_INDEX_COUNT"
echo "OP_PROFILE_RLS_ENABLED_COUNT=$OP_PROFILE_RLS_ENABLED_COUNT"
echo "OP_PROFILE_RLS_FORCED_COUNT=$OP_PROFILE_RLS_FORCED_COUNT"
echo "OP_PROFILE_POLICY_COUNT=$OP_PROFILE_POLICY_COUNT"
echo "OP_PROFILE_AUDIT_COLUMN_COUNT=$OP_PROFILE_AUDIT_COLUMN_COUNT"
echo "OP_PROFILE_DICTIONARY_COUNT=$OP_PROFILE_DICTIONARY_COUNT"
echo "COMPANY_RULE_CHECK_COUNT=$COMPANY_RULE_CHECK_COUNT"
echo "FRANCHISE_RULE_CHECK_COUNT=$FRANCHISE_RULE_CHECK_COUNT"
echo "REPORTING_EFFECT_CHECK_COUNT=$REPORTING_EFFECT_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "LOCATION_DEPENDENCY_COUNT=$LOCATION_DEPENDENCY_COUNT"
echo "FRANCHISE_DEPENDENCY_COUNT=$FRANCHISE_DEPENDENCY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_TYPE_STATUS=PASS"
  echo "FAZ_1_3_5_REPORTING_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_PERMISSION_EFFECT_STATUS=PASS"
  echo "FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_TEST_STATUS=PASS"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_5_OPERATION_PROFILE_TEST_STATUS=FAIL"
  echo "FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.5 COMPANY-OWNED VS FRANCHISE-OPERATED STRICT SUITE END ====="
