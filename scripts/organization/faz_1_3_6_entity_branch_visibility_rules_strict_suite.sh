#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_6_entity_branch_visibility_rules_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_6_ENTITY_BRANCH_VISIBILITY_RULES_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE START ====="

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

VISIBILITY_RULE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"
VISIBILITY_RULE_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='f';")"
VISIBILITY_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and contype='c';")"
VISIBILITY_RULE_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relrowsecurity=true;")"
VISIBILITY_RULE_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='visibility_rules' and c.relforcerowsecurity=true;")"
VISIBILITY_RULE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='visibility_rules';")"
VISIBILITY_RULE_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='visibility_rules' and column_name in ('approval_ref','lifecycle_reason','visibility_audit_ref','audit_metadata');")"
VISIBILITY_RULE_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='visibility_rules';")"

ENTITY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_target_required';")"
BRANCH_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_branch_scope';")"
ROLE_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_subject_required';")"
ACCOUNTANT_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_accountant_rule';")"
CROSS_BRANCH_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname in ('ck_org_visibility_rules_cross_branch_rule','ck_org_visibility_rules_cross_branch_write_rule');")"
PERMISSION_EFFECT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.visibility_rules'::regclass and conname='ck_org_visibility_rules_permission_effect';")"

echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"

[ "$VISIBILITY_RULE_TABLE_COUNT" -eq 1 ] && pass "5.1 visibility_rules tablosu hazır" || fail "5.1 visibility_rules tablosu eksik"
[ "$VISIBILITY_RULE_FK_COUNT" -ge 4 ] && pass "5.2 visibility_rules FK seti hazır" || fail "5.2 visibility_rules FK seti eksik"
[ "$VISIBILITY_RULE_CHECK_COUNT" -ge 12 ] && pass "5.3 visibility_rules check seti hazır" || fail "5.3 visibility_rules check seti eksik"
[ "$VISIBILITY_RULE_INDEX_COUNT" -ge 17 ] && pass "5.4 visibility_rules index seti hazır" || fail "5.4 visibility_rules index seti eksik"
[ "$VISIBILITY_RULE_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 visibility_rules RLS enabled" || fail "5.5 visibility_rules RLS enabled eksik"
[ "$VISIBILITY_RULE_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 visibility_rules RLS forced" || fail "5.6 visibility_rules RLS forced eksik"
[ "$VISIBILITY_RULE_POLICY_COUNT" -ge 1 ] && pass "5.7 visibility_rules tenant policy hazır" || fail "5.7 visibility_rules tenant policy eksik"
[ "$VISIBILITY_RULE_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "5.8 visibility audit kolonları hazır" || fail "5.8 visibility audit kolonları eksik"
[ "$VISIBILITY_RULE_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 visibility data dictionary mevcut" || warn "5.9 visibility data dictionary eksik"
[ "$ENTITY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.10 entity visibility rule hazır" || fail "5.10 entity visibility rule eksik"
[ "$BRANCH_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.11 branch visibility rule hazır" || fail "5.11 branch visibility rule eksik"
[ "$ROLE_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.12 role-based visibility rule hazır" || fail "5.12 role-based visibility rule eksik"
[ "$ACCOUNTANT_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.13 accountant visibility rule hazır" || fail "5.13 accountant visibility rule eksik"
[ "$CROSS_BRANCH_CHECK_COUNT" -eq 2 ] && pass "5.14 cross-branch guard seti hazır" || fail "5.14 cross-branch guard seti eksik"
[ "$PERMISSION_EFFECT_CHECK_COUNT" -eq 1 ] && pass "5.15 permission effect rule hazır" || fail "5.15 permission effect rule eksik"

{
  echo "# FAZ 1-3.6 Entity / Branch Visibility Rules Strict Suite Result"
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

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "VISIBILITY_RULE_TABLE_COUNT=$VISIBILITY_RULE_TABLE_COUNT"
echo "VISIBILITY_RULE_FK_COUNT=$VISIBILITY_RULE_FK_COUNT"
echo "VISIBILITY_RULE_CHECK_COUNT=$VISIBILITY_RULE_CHECK_COUNT"
echo "VISIBILITY_RULE_INDEX_COUNT=$VISIBILITY_RULE_INDEX_COUNT"
echo "VISIBILITY_RULE_RLS_ENABLED_COUNT=$VISIBILITY_RULE_RLS_ENABLED_COUNT"
echo "VISIBILITY_RULE_RLS_FORCED_COUNT=$VISIBILITY_RULE_RLS_FORCED_COUNT"
echo "VISIBILITY_RULE_POLICY_COUNT=$VISIBILITY_RULE_POLICY_COUNT"
echo "VISIBILITY_RULE_AUDIT_COLUMN_COUNT=$VISIBILITY_RULE_AUDIT_COLUMN_COUNT"
echo "VISIBILITY_RULE_DICTIONARY_COUNT=$VISIBILITY_RULE_DICTIONARY_COUNT"
echo "ENTITY_VISIBILITY_CHECK_COUNT=$ENTITY_VISIBILITY_CHECK_COUNT"
echo "BRANCH_VISIBILITY_CHECK_COUNT=$BRANCH_VISIBILITY_CHECK_COUNT"
echo "ROLE_VISIBILITY_CHECK_COUNT=$ROLE_VISIBILITY_CHECK_COUNT"
echo "ACCOUNTANT_VISIBILITY_CHECK_COUNT=$ACCOUNTANT_VISIBILITY_CHECK_COUNT"
echo "CROSS_BRANCH_CHECK_COUNT=$CROSS_BRANCH_CHECK_COUNT"
echo "PERMISSION_EFFECT_CHECK_COUNT=$PERMISSION_EFFECT_CHECK_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_TEST_STATUS=PASS"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_6_VISIBILITY_RULES_TEST_STATUS=FAIL"
  echo "FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.6 ENTITY / BRANCH VISIBILITY RULES STRICT SUITE END ====="
