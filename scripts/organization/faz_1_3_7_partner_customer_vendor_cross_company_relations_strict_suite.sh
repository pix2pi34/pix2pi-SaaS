#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_7_partner_customer_vendor_cross_company_relations_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_7_PARTNER_CUSTOMER_VENDOR_CROSS_COMPANY_RELATIONS_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE START ====="

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

RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='cross_company_relations';")"
RELATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='f';")"
RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and contype='c';")"
RELATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='cross_company_relations';")"
RELATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relrowsecurity=true;")"
RELATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='cross_company_relations' and c.relforcerowsecurity=true;")"
RELATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='cross_company_relations';")"
RELATION_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='cross_company_relations' and column_name in ('approval_ref','lifecycle_reason','relation_audit_ref','audit_metadata');")"
RELATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='cross_company_relations';")"

PARTNER_RULE_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_flags_match_type';")"
CROSS_COMPANY_VISIBILITY_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_cross_company_visibility';")"
RELATION_AUDIT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_termination_audit';")"
COUNTERPARTY_REQUIRED_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_counterparty_required';")"
NO_SELF_RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.cross_company_relations'::regclass and conname='ck_org_cross_company_relations_no_self_relation';")"
VISIBILITY_DEPENDENCY_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='visibility_rules';")"

echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"

[ "$RELATION_TABLE_COUNT" -eq 1 ] && pass "5.1 cross_company_relations tablosu hazır" || fail "5.1 cross_company_relations tablosu eksik"
[ "$RELATION_FK_COUNT" -ge 3 ] && pass "5.2 relation FK seti hazır" || fail "5.2 relation FK seti eksik"
[ "$RELATION_CHECK_COUNT" -ge 12 ] && pass "5.3 relation check seti hazır" || fail "5.3 relation check seti eksik"
[ "$RELATION_INDEX_COUNT" -ge 14 ] && pass "5.4 relation index seti hazır" || fail "5.4 relation index seti eksik"
[ "$RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 relation RLS enabled" || fail "5.5 relation RLS enabled eksik"
[ "$RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 relation RLS forced" || fail "5.6 relation RLS forced eksik"
[ "$RELATION_POLICY_COUNT" -ge 1 ] && pass "5.7 relation tenant policy hazır" || fail "5.7 relation tenant policy eksik"
[ "$RELATION_AUDIT_COLUMN_COUNT" -eq 4 ] && pass "5.8 relation audit kolonları hazır" || fail "5.8 relation audit kolonları eksik"
[ "$RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "5.9 relation data dictionary mevcut" || warn "5.9 relation data dictionary eksik"
[ "$PARTNER_RULE_CHECK_COUNT" -eq 1 ] && pass "5.10 partner/customer/vendor rule hazır" || fail "5.10 partner/customer/vendor rule eksik"
[ "$CROSS_COMPANY_VISIBILITY_CHECK_COUNT" -eq 1 ] && pass "5.11 cross-company visibility rule hazır" || fail "5.11 cross-company visibility rule eksik"
[ "$RELATION_AUDIT_CHECK_COUNT" -eq 1 ] && pass "5.12 relation audit rule hazır" || fail "5.12 relation audit rule eksik"
[ "$COUNTERPARTY_REQUIRED_CHECK_COUNT" -eq 1 ] && pass "5.13 counterparty required rule hazır" || fail "5.13 counterparty required rule eksik"
[ "$NO_SELF_RELATION_CHECK_COUNT" -eq 1 ] && pass "5.14 self-relation prevention hazır" || fail "5.14 self-relation prevention eksik"
[ "$VISIBILITY_DEPENDENCY_COUNT" -eq 1 ] && pass "5.15 visibility dependency hazır" || fail "5.15 visibility dependency eksik"

{
  echo "# FAZ 1-3.7 Partner / Customer / Vendor Cross-company Relations Strict Suite Result"
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

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RELATION_TABLE_COUNT=$RELATION_TABLE_COUNT"
echo "RELATION_FK_COUNT=$RELATION_FK_COUNT"
echo "RELATION_CHECK_COUNT=$RELATION_CHECK_COUNT"
echo "RELATION_INDEX_COUNT=$RELATION_INDEX_COUNT"
echo "RELATION_RLS_ENABLED_COUNT=$RELATION_RLS_ENABLED_COUNT"
echo "RELATION_RLS_FORCED_COUNT=$RELATION_RLS_FORCED_COUNT"
echo "RELATION_POLICY_COUNT=$RELATION_POLICY_COUNT"
echo "RELATION_AUDIT_COLUMN_COUNT=$RELATION_AUDIT_COLUMN_COUNT"
echo "RELATION_DICTIONARY_COUNT=$RELATION_DICTIONARY_COUNT"
echo "PARTNER_RULE_CHECK_COUNT=$PARTNER_RULE_CHECK_COUNT"
echo "CROSS_COMPANY_VISIBILITY_CHECK_COUNT=$CROSS_COMPANY_VISIBILITY_CHECK_COUNT"
echo "RELATION_AUDIT_CHECK_COUNT=$RELATION_AUDIT_CHECK_COUNT"
echo "COUNTERPARTY_REQUIRED_CHECK_COUNT=$COUNTERPARTY_REQUIRED_CHECK_COUNT"
echo "NO_SELF_RELATION_CHECK_COUNT=$NO_SELF_RELATION_CHECK_COUNT"
echo "VISIBILITY_DEPENDENCY_COUNT=$VISIBILITY_DEPENDENCY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_7_PARTNER_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=PASS"
  echo "FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_TEST_STATUS=PASS"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_7_RELATION_TEST_STATUS=FAIL"
  echo "FAZ_1_3_7_RELATION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.7 PARTNER / CUSTOMER / VENDOR CROSS-COMPANY RELATIONS STRICT SUITE END ====="
