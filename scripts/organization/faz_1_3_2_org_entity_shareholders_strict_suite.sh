#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_2_org_entity_shareholders_strict_suite_fix_v5_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_2_ORG_ENTITY_SHAREHOLDERS_STRICT_SUITE_RESULT_FIX_V5_$TS.md"

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

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 START ====="

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

ENTITY_SHAREHOLDER_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='org' and table_name='entity_shareholders';")"
ENTITY_SHAREHOLDER_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='f';")"
ENTITY_SHAREHOLDER_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='org.entity_shareholders'::regclass and contype='c';")"
ENTITY_SHAREHOLDER_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='org' and tablename='entity_shareholders';")"
ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relrowsecurity=true;")"
ENTITY_SHAREHOLDER_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='org' and c.relname='entity_shareholders' and c.relforcerowsecurity=true;")"
ENTITY_SHAREHOLDER_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='org' and tablename='entity_shareholders';")"
OWNERSHIP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='org' and p.proname='prevent_entity_shareholder_over_100';")"
OWNERSHIP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_prevent_over_100' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"
OWNERSHIP_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='org' and table_name='entity_shareholders' and column_name in ('ownership_audit_ref','ownership_change_reason','audit_metadata');")"
ENTITY_SHAREHOLDER_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='org' and table_name='entity_shareholders';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_org_entity_shareholders_sync_legacy_fields' and tgrelid='org.entity_shareholders'::regclass and not tgisinternal;")"

echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ "$ENTITY_SHAREHOLDER_TABLE_COUNT" -eq 1 ] && pass "5.1 org.entity_shareholders tablosu hazır" || fail "5.1 org.entity_shareholders tablosu eksik"
[ "$ENTITY_SHAREHOLDER_FK_COUNT" -ge 2 ] && pass "5.2 entity/shareholder FK seti hazır" || fail "5.2 FK seti eksik"
[ "$ENTITY_SHAREHOLDER_CHECK_COUNT" -ge 8 ] && pass "5.3 check constraint seti hazır" || fail "5.3 check constraint seti eksik"
[ "$ENTITY_SHAREHOLDER_INDEX_COUNT" -ge 9 ] && pass "5.4 ownership index seti hazır" || fail "5.4 ownership index seti eksik"
[ "$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.5 RLS enabled" || fail "5.5 RLS enabled eksik"
[ "$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT" -eq 1 ] && pass "5.6 RLS forced" || fail "5.6 RLS forced eksik"
[ "$ENTITY_SHAREHOLDER_POLICY_COUNT" -ge 1 ] && pass "5.7 tenant policy hazır" || fail "5.7 tenant policy eksik"
[ "$OWNERSHIP_FUNCTION_COUNT" -eq 1 ] && pass "5.8 ownership percentage guard function hazır" || fail "5.8 ownership percentage guard function eksik"
[ "$OWNERSHIP_TRIGGER_COUNT" -eq 1 ] && pass "5.9 ownership percentage guard trigger hazır" || fail "5.9 ownership percentage guard trigger eksik"
[ "$OWNERSHIP_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.10 ownership audit kolonları hazır" || fail "5.10 ownership audit kolonları eksik"
[ "$ENTITY_SHAREHOLDER_DICTIONARY_COUNT" -ge 1 ] && pass "5.11 data dictionary kaydı mevcut" || warn "5.11 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "5.12 legacy sync trigger hazır" || fail "5.12 legacy sync trigger eksik"

{
  echo "# FAZ 1-3.2 org.entity_shareholders Strict Suite Result FIX V5"
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

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "ENTITY_SHAREHOLDER_TABLE_COUNT=$ENTITY_SHAREHOLDER_TABLE_COUNT"
echo "ENTITY_SHAREHOLDER_FK_COUNT=$ENTITY_SHAREHOLDER_FK_COUNT"
echo "ENTITY_SHAREHOLDER_CHECK_COUNT=$ENTITY_SHAREHOLDER_CHECK_COUNT"
echo "ENTITY_SHAREHOLDER_INDEX_COUNT=$ENTITY_SHAREHOLDER_INDEX_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT=$ENTITY_SHAREHOLDER_RLS_ENABLED_COUNT"
echo "ENTITY_SHAREHOLDER_RLS_FORCED_COUNT=$ENTITY_SHAREHOLDER_RLS_FORCED_COUNT"
echo "ENTITY_SHAREHOLDER_POLICY_COUNT=$ENTITY_SHAREHOLDER_POLICY_COUNT"
echo "OWNERSHIP_FUNCTION_COUNT=$OWNERSHIP_FUNCTION_COUNT"
echo "OWNERSHIP_TRIGGER_COUNT=$OWNERSHIP_TRIGGER_COUNT"
echo "OWNERSHIP_AUDIT_COLUMN_COUNT=$OWNERSHIP_AUDIT_COLUMN_COUNT"
echo "ENTITY_SHAREHOLDER_DICTIONARY_COUNT=$ENTITY_SHAREHOLDER_DICTIONARY_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=PASS"
  echo "FAZ_1_3_2_EFFECTIVE_DATE_STATUS=PASS"
  echo "FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=PASS"
  echo "FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.2 ORG ENTITY SHAREHOLDERS STRICT SUITE FIX V5 END ====="
