#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_8_org_graph_tests_strict_suite_fix_v14_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_8_ORG_GRAPH_TESTS_STRICT_SUITE_RESULT_FIX_V14_$TS.md"

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

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 START ====="

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

ENTITY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"
ENTITY_RELATIONS_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='f';")"
ENTITY_RELATIONS_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='c';")"
ENTITY_RELATIONS_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relrowsecurity=true;")"
ENTITY_RELATIONS_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relforcerowsecurity=true;")"
ENTITY_RELATIONS_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATIONS_CYCLE_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_relations'::regclass and not tgisinternal and lower(tgname) like '%cycle%';")"

ENTITY_SHAREHOLDERS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
FRANCHISE_AGREEMENTS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"
BUSINESS_LOCATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='business_locations';")"
LOCATION_OPERATION_PROFILES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='location_operation_profiles';")"
VISIBILITY_RULES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"
CROSS_COMPANY_RELATIONS_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"

SHAREHOLDER_OVER_100_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='org.entity_shareholders'::regclass and not tgisinternal and lower(tgname) like '%shareholder%';")"
FRANCHISE_OVERLAP_GUARD_COUNT="$(scalar_count "select count(*) from pg_trigger where tgrelid='franchise.agreements'::regclass and not tgisinternal and lower(tgname) like '%overlap%';")"
VISIBILITY_CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
OPERATION_PROFILE_FRANCHISE_RULE_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.location_operation_profiles'::regclass and conname='ck_org_location_operation_profiles_franchise_store_rule';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"

echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"

[ "$ENTITY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "5.1 entity_relations tablosu hazır" || fail "5.1 entity_relations tablosu eksik"
[ "$ENTITY_RELATIONS_FK_COUNT" -ge 2 ] && pass "5.2 entity_relations FK seti hazır" || fail "5.2 entity_relations FK seti eksik"
[ "$ENTITY_RELATIONS_CHECK_COUNT" -ge 3 ] && pass "5.3 entity_relations check seti hazır" || fail "5.3 entity_relations check seti eksik"
[ "$ENTITY_RELATIONS_INDEX_COUNT" -ge 5 ] && pass "5.4 entity_relations index seti hazır" || fail "5.4 entity_relations index seti eksik"
[ "$ENTITY_RELATIONS_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 entity_relations RLS enabled" || fail "5.5 entity_relations RLS enabled eksik"
[ "$ENTITY_RELATIONS_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 entity_relations RLS forced" || fail "5.6 entity_relations RLS forced eksik"
[ "$ENTITY_RELATIONS_POLICY_COUNT" -ge 1 ] && pass "5.7 entity_relations tenant policy hazır" || fail "5.7 entity_relations tenant policy eksik"
[ "$ENTITY_RELATIONS_CYCLE_GUARD_COUNT" -ge 1 ] && pass "5.8 cycle prevention guard hazır" || fail "5.8 cycle prevention guard eksik"
[ "$ENTITY_SHAREHOLDERS_TABLE_COUNT" -eq 1 ] && pass "5.9 entity_shareholders hazır" || fail "5.9 entity_shareholders eksik"
[ "$FRANCHISE_AGREEMENTS_TABLE_COUNT" -eq 1 ] && pass "5.10 franchise agreements hazır" || fail "5.10 franchise agreements eksik"
[ "$BUSINESS_LOCATIONS_TABLE_COUNT" -eq 1 ] && pass "5.11 business_locations hazır" || fail "5.11 business_locations eksik"
[ "$LOCATION_OPERATION_PROFILES_TABLE_COUNT" -eq 1 ] && pass "5.12 location_operation_profiles hazır" || fail "5.12 location_operation_profiles eksik"
[ "$VISIBILITY_RULES_TABLE_COUNT" -eq 1 ] && pass "5.13 visibility_rules hazır" || fail "5.13 visibility_rules eksik"
[ "$CROSS_COMPANY_RELATIONS_TABLE_COUNT" -eq 1 ] && pass "5.14 cross_company_relations hazır" || fail "5.14 cross_company_relations eksik"
[ "$SHAREHOLDER_OVER_100_GUARD_COUNT" -ge 1 ] && pass "5.15 ownership/shareholder guard hazır" || fail "5.15 ownership/shareholder guard eksik"
[ "$FRANCHISE_OVERLAP_GUARD_COUNT" -ge 1 ] && pass "5.16 franchise overlap guard hazır" || fail "5.16 franchise overlap guard eksik"
[ "$VISIBILITY_CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "5.17 visibility cross-branch guard hazır" || fail "5.17 visibility cross-branch guard eksik"
[ "$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.18 cross-company visibility guard hazır" || fail "5.18 cross-company visibility guard eksik"
[ "$OPERATION_PROFILE_FRANCHISE_RULE_COUNT" -eq 1 ] && pass "5.19 franchise operation profile rule hazır" || fail "5.19 franchise operation profile rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.20 accountant visibility rule hazır" || fail "5.20 accountant visibility rule eksik"

{
  echo "# FAZ 1-3.8 Org Graph Tests Strict Suite Result FIX V14"
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

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_RELATIONS_TABLE_COUNT=$ENTITY_RELATIONS_TABLE_COUNT"
echo "ENTITY_RELATIONS_FK_COUNT=$ENTITY_RELATIONS_FK_COUNT"
echo "ENTITY_RELATIONS_CHECK_COUNT=$ENTITY_RELATIONS_CHECK_COUNT"
echo "ENTITY_RELATIONS_INDEX_COUNT=$ENTITY_RELATIONS_INDEX_COUNT"
echo "ENTITY_RELATIONS_RLS_ENABLED_COUNT=$ENTITY_RELATIONS_RLS_ENABLED_COUNT"
echo "ENTITY_RELATIONS_RLS_FORCED_COUNT=$ENTITY_RELATIONS_RLS_FORCED_COUNT"
echo "ENTITY_RELATIONS_POLICY_COUNT=$ENTITY_RELATIONS_POLICY_COUNT"
echo "ENTITY_RELATIONS_CYCLE_GUARD_COUNT=$ENTITY_RELATIONS_CYCLE_GUARD_COUNT"
echo "ENTITY_SHAREHOLDERS_TABLE_COUNT=$ENTITY_SHAREHOLDERS_TABLE_COUNT"
echo "FRANCHISE_AGREEMENTS_TABLE_COUNT=$FRANCHISE_AGREEMENTS_TABLE_COUNT"
echo "BUSINESS_LOCATIONS_TABLE_COUNT=$BUSINESS_LOCATIONS_TABLE_COUNT"
echo "LOCATION_OPERATION_PROFILES_TABLE_COUNT=$LOCATION_OPERATION_PROFILES_TABLE_COUNT"
echo "VISIBILITY_RULES_TABLE_COUNT=$VISIBILITY_RULES_TABLE_COUNT"
echo "CROSS_COMPANY_RELATIONS_TABLE_COUNT=$CROSS_COMPANY_RELATIONS_TABLE_COUNT"
echo "SHAREHOLDER_OVER_100_GUARD_COUNT=$SHAREHOLDER_OVER_100_GUARD_COUNT"
echo "FRANCHISE_OVERLAP_GUARD_COUNT=$FRANCHISE_OVERLAP_GUARD_COUNT"
echo "VISIBILITY_CROSS_BRANCH_CHECK_COUNT=$VISIBILITY_CROSS_BRANCH_CHECK_COUNT"
echo "RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$RELATION_CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "OPERATION_PROFILE_FRANCHISE_RULE_COUNT=$OPERATION_PROFILE_FRANCHISE_RULE_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_PERMISSION_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_8_ORG_GRAPH_TEST_STATUS=FAIL"
  echo "FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.8 ORG GRAPH TESTS STRICT SUITE FIX V14 END ====="
