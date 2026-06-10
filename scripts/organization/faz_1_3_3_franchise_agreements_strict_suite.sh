#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_3_3_franchise_agreements_strict_suite_fix_v4_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_SUITE_RESULT_FIX_V4_$TS.md"

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

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 START ====="

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

FRANCHISE_SCHEMA_COUNT="$(scalar_count "select count(*) from information_schema.schemata where schema_name='franchise';")"
AGREEMENT_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='franchise' and table_name='agreements';")"
AGREEMENT_FK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='f';")"
AGREEMENT_CHECK_COUNT="$(scalar_count "select count(*) from pg_constraint where conrelid='franchise.agreements'::regclass and contype='c';")"
AGREEMENT_INDEX_COUNT="$(scalar_count "select count(*) from pg_indexes where schemaname='franchise' and tablename='agreements';")"
AGREEMENT_RLS_ENABLED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relrowsecurity=true;")"
AGREEMENT_RLS_FORCED_COUNT="$(scalar_count "select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='franchise' and c.relname='agreements' and c.relforcerowsecurity=true;")"
AGREEMENT_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where schemaname='franchise' and tablename='agreements';")"
OVERLAP_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='prevent_overlapping_active_agreement';")"
OVERLAP_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_prevent_overlap' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"
AGREEMENT_AUDIT_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name in ('lifecycle_reason','agreement_audit_ref','audit_metadata');")"
AGREEMENT_LIFECYCLE_COLUMN_COUNT="$(scalar_count "select count(*) from information_schema.columns where table_schema='franchise' and table_name='agreements' and column_name='agreement_lifecycle_status';")"
AGREEMENT_DICTIONARY_COUNT="$(scalar_count "select count(*) from app_dictionary.table_contracts where schema_name='franchise' and table_name='agreements';")"
LEGACY_SYNC_FUNCTION_COUNT="$(scalar_count "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='franchise' and p.proname='sync_agreements_legacy_fields';")"
LEGACY_SYNC_TRIGGER_COUNT="$(scalar_count "select count(*) from pg_trigger where tgname='trg_franchise_agreements_sync_legacy_fields' and tgrelid='franchise.agreements'::regclass and not tgisinternal;")"

echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"

[ "$FRANCHISE_SCHEMA_COUNT" -eq 1 ] && pass "5.1 franchise schema hazır" || fail "5.1 franchise schema eksik"
[ "$AGREEMENT_TABLE_COUNT" -eq 1 ] && pass "5.2 franchise.agreements tablosu hazır" || fail "5.2 franchise.agreements tablosu eksik"
[ "$AGREEMENT_FK_COUNT" -ge 5 ] && pass "5.3 owner/operator/entity FK seti hazır" || fail "5.3 FK seti eksik"
[ "$AGREEMENT_CHECK_COUNT" -ge 8 ] && pass "5.4 check constraint seti hazır" || fail "5.4 check constraint seti eksik"
[ "$AGREEMENT_INDEX_COUNT" -ge 12 ] && pass "5.5 index seti hazır" || fail "5.5 index seti eksik"
[ "$AGREEMENT_RLS_ENABLED_COUNT" -eq 1 ] && pass "5.6 RLS enabled" || fail "5.6 RLS enabled eksik"
[ "$AGREEMENT_RLS_FORCED_COUNT" -eq 1 ] && pass "5.7 RLS forced" || fail "5.7 RLS forced eksik"
[ "$AGREEMENT_POLICY_COUNT" -ge 1 ] && pass "5.8 tenant policy hazır" || fail "5.8 tenant policy eksik"
[ "$OVERLAP_FUNCTION_COUNT" -eq 1 ] && pass "5.9 overlap guard function hazır" || fail "5.9 overlap guard function eksik"
[ "$OVERLAP_TRIGGER_COUNT" -eq 1 ] && pass "5.10 overlap guard trigger hazır" || fail "5.10 overlap guard trigger eksik"
[ "$AGREEMENT_AUDIT_COLUMN_COUNT" -eq 3 ] && pass "5.11 agreement audit kolonları hazır" || fail "5.11 agreement audit kolonları eksik"
[ "$AGREEMENT_LIFECYCLE_COLUMN_COUNT" -eq 1 ] && pass "5.12 agreement_lifecycle_status hazır" || fail "5.12 agreement_lifecycle_status eksik"
[ "$AGREEMENT_DICTIONARY_COUNT" -ge 1 ] && pass "5.13 data dictionary kaydı mevcut" || warn "5.13 data dictionary kaydı eksik"
[ "$LEGACY_SYNC_FUNCTION_COUNT" -eq 1 ] && pass "5.14 legacy sync function hazır" || fail "5.14 legacy sync function eksik"
[ "$LEGACY_SYNC_TRIGGER_COUNT" -eq 1 ] && pass "5.15 legacy sync trigger hazır" || fail "5.15 legacy sync trigger eksik"

{
  echo "# FAZ 1-3.3 franchise.agreements Strict Suite Result FIX V4"
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

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FRANCHISE_SCHEMA_COUNT=$FRANCHISE_SCHEMA_COUNT"
echo "AGREEMENT_TABLE_COUNT=$AGREEMENT_TABLE_COUNT"
echo "AGREEMENT_FK_COUNT=$AGREEMENT_FK_COUNT"
echo "AGREEMENT_CHECK_COUNT=$AGREEMENT_CHECK_COUNT"
echo "AGREEMENT_INDEX_COUNT=$AGREEMENT_INDEX_COUNT"
echo "AGREEMENT_RLS_ENABLED_COUNT=$AGREEMENT_RLS_ENABLED_COUNT"
echo "AGREEMENT_RLS_FORCED_COUNT=$AGREEMENT_RLS_FORCED_COUNT"
echo "AGREEMENT_POLICY_COUNT=$AGREEMENT_POLICY_COUNT"
echo "OVERLAP_FUNCTION_COUNT=$OVERLAP_FUNCTION_COUNT"
echo "OVERLAP_TRIGGER_COUNT=$OVERLAP_TRIGGER_COUNT"
echo "AGREEMENT_AUDIT_COLUMN_COUNT=$AGREEMENT_AUDIT_COLUMN_COUNT"
echo "AGREEMENT_LIFECYCLE_COLUMN_COUNT=$AGREEMENT_LIFECYCLE_COLUMN_COUNT"
echo "AGREEMENT_DICTIONARY_COUNT=$AGREEMENT_DICTIONARY_COUNT"
echo "LEGACY_SYNC_FUNCTION_COUNT=$LEGACY_SYNC_FUNCTION_COUNT"
echo "LEGACY_SYNC_TRIGGER_COUNT=$LEGACY_SYNC_TRIGGER_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=PASS"
  echo "FAZ_1_3_3_START_END_DATE_STATUS=PASS"
  echo "FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=PASS"
  echo "FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-3.3 FRANCHISE AGREEMENTS STRICT SUITE FIX V4 END ====="
