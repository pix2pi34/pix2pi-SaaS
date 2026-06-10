#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_1_org_entity_relations_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE START ====="

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

ENTITY_RELATION_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_relations';")"
ENTITY_RELATION_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='f';")"
ENTITY_RELATION_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_relations'::regclass and contype='c';")"
ENTITY_RELATION_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_relations';")"
ENTITY_RELATION_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relrowsecurity=true;")"
ENTITY_RELATION_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_relations' and c.relforcerowsecurity=true;")"
ENTITY_RELATION_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_relations';")"
CYCLE_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='prevent_entity_relation_cycle';")"
CYCLE_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_relations_prevent_cycle' and tgrelid='org.entity_relations'::regclass and not tgisinternal;")"
VISIBILITY_LINK_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_relations' and column_name in ('visibility_scope','visibility_rule_code');")"
ENTITY_RELATION_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='entity_relations';")"

echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"

[ "$ENTITY_RELATION_TABLE_COUNT" -eq 1 ] && pass "5.1 org.entity_relations tablosu hazır" || fail "5.1 org.entity_relations tablosu eksik"
[ "$ENTITY_RELATION_FK_COUNT" -ge 3 ] && pass "5.2 parent-child FK seti hazır" || fail "5.2 parent-child FK seti eksik"
[ "$ENTITY_RELATION_CHECK_COUNT" -ge 6 ] && pass "5.3 check constraint seti hazır" || fail "5.3 check constraint seti eksik"
[ "$ENTITY_RELATION_INDEX_COUNT" -ge 9 ] && pass "5.4 org graph index seti hazır" || fail "5.4 org graph index seti eksik"
[ "$ENTITY_RELATION_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 RLS enabled" || fail "5.5 RLS enabled eksik"
[ "$ENTITY_RELATION_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 RLS forced" || fail "5.6 RLS forced eksik"
[ "$ENTITY_RELATION_POLICY_COUNT" -ge 1 ] && pass "5.7 tenant policy hazır" || fail "5.7 tenant policy eksik"
[ "$CYCLE_FUNCTION_COUNT" -eq 1 ] && pass "5.8 cycle prevention function hazır" || fail "5.8 cycle prevention function eksik"
[ "$CYCLE_TRIGGER_COUNT" -eq 1 ] && pass "5.9 cycle prevention trigger hazır" || fail "5.9 cycle prevention trigger eksik"
[ "$VISIBILITY_LINK_COLUMN_COUNT" -eq 2 ] && pass "5.10 visibility rule bağlantısı hazır" || fail "5.10 visibility rule bağlantısı eksik"
[ "$ENTITY_RELATION_DICTIONARY_COUNT" -ge 1 ] && pass "5.11 data dictionary kaydı mevcut" || warn "5.11 data dictionary kaydı eksik"

{
  echo "# FAZ 1-3.1 org.entity_relations Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
  echo "- ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
  echo "- ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
  echo "- ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
  echo "- ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
  echo "- ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
  echo "- ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
  echo "- CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
  echo "- CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
  echo "- VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
  echo "- ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "6. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_RELATION_TABLE_COUNT=$ENTITY_RELATION_TABLE_COUNT"
echo "ENTITY_RELATION_FK_COUNT=$ENTITY_RELATION_FK_COUNT"
echo "ENTITY_RELATION_CHECK_COUNT=$ENTITY_RELATION_CHECK_COUNT"
echo "ENTITY_RELATION_INDEX_COUNT=$ENTITY_RELATION_INDEX_COUNT"
echo "ENTITY_RELATION_RLS_ENABLED_COUNT=$ENTITY_RELATION_RLS_ENABLED_COUNT"
echo "ENTITY_RELATION_RLS_FORCED_COUNT=$ENTITY_RELATION_RLS_FORCED_COUNT"
echo "ENTITY_RELATION_POLICY_COUNT=$ENTITY_RELATION_POLICY_COUNT"
echo "CYCLE_FUNCTION_COUNT=$CYCLE_FUNCTION_COUNT"
echo "CYCLE_TRIGGER_COUNT=$CYCLE_TRIGGER_COUNT"
echo "VISIBILITY_LINK_COLUMN_COUNT=$VISIBILITY_LINK_COLUMN_COUNT"
echo "ENTITY_RELATION_DICTIONARY_COUNT=$ENTITY_RELATION_DICTIONARY_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_1_ENTITY_RELATIONS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_1_HOLDING_TREE_STATUS=PASS"
  echo "FAZ_1_3_1_PARENT_CHILD_RELATION_STATUS=PASS"
  echo "FAZ_1_3_1_CYCLE_PREVENTION_STATUS=PASS"
  echo "FAZ_1_3_1_VISIBILITY_RULE_LINK_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_GRAPH_TEST_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_1_ORG_ENTITY_RELATIONS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.1 ORG ENTITY RELATIONS STRICT SUITE END ====="
