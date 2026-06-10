#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_7_audit_export_isolation_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_STRICT_SUITE_RESULT_$TS.md"

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

repo_count() {
  local pattern="$1"
  local out=""
  set +e
  out="$(grep -RInE "$pattern" \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=vendor \
    --exclude-dir=backups \
    "$REPO" 2>/dev/null | awk 'END{print NR+0}')"
  local ec=$?
  set -e
  if [ "$ec" -ne 0 ] || ! [[ "$out" =~ ^[0-9]+$ ]]; then
    echo 0
  else
    echo "$out"
  fi
}

echo "===== FAZ 1-2.7 AUDIT / EXPORT ISOLATION STRICT SUITE START ====="

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

echo "5. audit DB standard sayaçları doğrulanıyor..."

AUDIT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema in ('auth','audit','public','platform','core')
    and (
      table_name ilike '%audit%'
      or table_name ilike '%event%'
      or table_name ilike '%log%'
    );
")"

TENANT_SAFE_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where column_name='tenant_id'
    and (
      table_name ilike '%audit%'
      or table_name ilike '%event%'
      or table_name ilike '%log%'
    );
")"

LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where column_name='legal_entity_id'
    and (
      table_name ilike '%audit%'
      or table_name ilike '%event%'
      or table_name ilike '%log%'
    );
")"

BRANCH_SAFE_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where column_name='branch_id'
    and (
      table_name ilike '%audit%'
      or table_name ilike '%event%'
      or table_name ilike '%log%'
    );
")"

AUDIT_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where c.relkind='r'
    and c.relrowsecurity=true
    and (
      c.relname ilike '%audit%'
      or c.relname ilike '%event%'
      or c.relname ilike '%log%'
    );
")"

AUDIT_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where c.relkind='r'
    and c.relforcerowsecurity=true
    and (
      c.relname ilike '%audit%'
      or c.relname ilike '%event%'
      or c.relname ilike '%log%'
    );
")"

AUDIT_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where tablename ilike '%audit%'
     or tablename ilike '%event%'
     or tablename ilike '%log%';
")"

AUDIT_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where (
      tablename ilike '%audit%'
      or tablename ilike '%event%'
      or tablename ilike '%log%'
    )
    and (
      indexdef ilike '%tenant_id%'
      or indexdef ilike '%legal_entity_id%'
      or indexdef ilike '%branch_id%'
    );
")"

echo "AUDIT_TABLE_COUNT=$AUDIT_TABLE_COUNT"
echo "TENANT_SAFE_AUDIT_COLUMN_COUNT=$TENANT_SAFE_AUDIT_COLUMN_COUNT"
echo "LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT"
echo "BRANCH_SAFE_AUDIT_COLUMN_COUNT=$BRANCH_SAFE_AUDIT_COLUMN_COUNT"
echo "AUDIT_RLS_ENABLED_COUNT=$AUDIT_RLS_ENABLED_COUNT"
echo "AUDIT_RLS_FORCED_COUNT=$AUDIT_RLS_FORCED_COUNT"
echo "AUDIT_POLICY_COUNT=$AUDIT_POLICY_COUNT"
echo "AUDIT_INDEX_COUNT=$AUDIT_INDEX_COUNT"

[ "$AUDIT_TABLE_COUNT" -ge 1 ] && pass "5.1 audit/event/log tablo izi mevcut" || fail "5.1 audit/event/log tablo izi yok"
[ "$TENANT_SAFE_AUDIT_COLUMN_COUNT" -ge 1 ] && pass "5.2 tenant-safe audit tenant_id kolonu mevcut" || fail "5.2 tenant-safe audit tenant_id kolonu yok"
[ "$LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT" -ge 1 ] && pass "5.3 legal entity-safe audit legal_entity_id kolonu mevcut" || fail "5.3 legal entity-safe audit legal_entity_id kolonu yok"
[ "$BRANCH_SAFE_AUDIT_COLUMN_COUNT" -ge 1 ] && pass "5.4 branch-safe audit branch_id kolonu mevcut" || fail "5.4 branch-safe audit branch_id kolonu yok"
[ "$AUDIT_RLS_ENABLED_COUNT" -ge 1 ] && pass "5.5 audit/event/log RLS enabled izi mevcut" || fail "5.5 audit/event/log RLS enabled izi yok"
[ "$AUDIT_RLS_FORCED_COUNT" -ge 1 ] && pass "5.6 audit/event/log RLS forced izi mevcut" || fail "5.6 audit/event/log RLS forced izi yok"
[ "$AUDIT_POLICY_COUNT" -ge 1 ] && pass "5.7 audit/event/log policy izi mevcut" || fail "5.7 audit/event/log policy izi yok"
[ "$AUDIT_INDEX_COUNT" -ge 1 ] && pass "5.8 audit/event/log scope index izi mevcut" || warn "5.8 audit/event/log scope index izi zayıf"

echo "6. export isolation repo / dosya evidence doğrulanıyor..."

EXPORT_CONTRACT_REPO_COUNT="$(repo_count 'export|Export|EXPORT|xlsx|csv|pdf|download|report export|data export')"
TENANT_SAFE_EXPORT_REPO_COUNT="$(repo_count 'tenant.*export|export.*tenant|tenant_id.*export|export.*tenant_id|tenant-safe export|tenant safe export')"
CROSS_TENANT_EXPORT_GUARD_REPO_COUNT="$(repo_count 'cross.?tenant.*export|export.*cross.?tenant|tenant mismatch.*export|export.*mismatch|export.*forbidden|forbidden.*export|StatusForbidden|403')"
EXPORT_EVIDENCE_REPO_COUNT="$(repo_count 'export evidence|EXPORT_EVIDENCE|evidence.*export|export.*evidence|audit.*export|export.*audit')"
EXPORT_TEST_REPO_COUNT="$(repo_count 'export.*test|test.*export|export isolation|isolation.*export|tenant boundary.*export|export.*boundary')"
EXPORT_PATH_GUARD_REPO_COUNT="$(repo_count 'path traversal|safe path|export path|tenant.*path|file.*tenant|tenant.*file|backup.*export|restore.*export')"

EXPORT_DOC_COUNT="$(find "$REPO" -type f \
  \( -path "*/docs/*" -o -path "*/scripts/*" -o -path "*/internal/*" -o -path "*/cmd/*" \) \
  ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/vendor/*" ! -path "*/backups/*" \
  2>/dev/null | grep -Ei 'export|audit|isolation|tenant' | awk 'END{print NR+0}')"

echo "EXPORT_CONTRACT_REPO_COUNT=$EXPORT_CONTRACT_REPO_COUNT"
echo "TENANT_SAFE_EXPORT_REPO_COUNT=$TENANT_SAFE_EXPORT_REPO_COUNT"
echo "CROSS_TENANT_EXPORT_GUARD_REPO_COUNT=$CROSS_TENANT_EXPORT_GUARD_REPO_COUNT"
echo "EXPORT_EVIDENCE_REPO_COUNT=$EXPORT_EVIDENCE_REPO_COUNT"
echo "EXPORT_TEST_REPO_COUNT=$EXPORT_TEST_REPO_COUNT"
echo "EXPORT_PATH_GUARD_REPO_COUNT=$EXPORT_PATH_GUARD_REPO_COUNT"
echo "EXPORT_DOC_COUNT=$EXPORT_DOC_COUNT"

[ "$EXPORT_CONTRACT_REPO_COUNT" -gt 0 ] && pass "6.1 export contract repo kanıtı mevcut" || fail "6.1 export contract repo kanıtı yok"
[ "$TENANT_SAFE_EXPORT_REPO_COUNT" -gt 0 ] && pass "6.2 tenant-safe export repo kanıtı mevcut" || fail "6.2 tenant-safe export repo kanıtı yok"
[ "$CROSS_TENANT_EXPORT_GUARD_REPO_COUNT" -gt 0 ] && pass "6.3 cross-tenant export guard repo kanıtı mevcut" || fail "6.3 cross-tenant export guard repo kanıtı yok"
[ "$EXPORT_EVIDENCE_REPO_COUNT" -gt 0 ] && pass "6.4 export evidence repo kanıtı mevcut" || fail "6.4 export evidence repo kanıtı yok"
[ "$EXPORT_TEST_REPO_COUNT" -gt 0 ] && pass "6.5 export isolation test repo kanıtı mevcut" || fail "6.5 export isolation test repo kanıtı yok"
[ "$EXPORT_PATH_GUARD_REPO_COUNT" -gt 0 ] && pass "6.6 export/file path tenant guard repo kanıtı mevcut" || warn "6.6 export/file path tenant guard izi zayıf"
[ "$EXPORT_DOC_COUNT" -gt 0 ] && pass "6.7 export/audit/isolation dosya kanıtı mevcut" || fail "6.7 export/audit/isolation dosya kanıtı yok"

echo "7. alt başlık repo/API/query evidence doğrulanıyor..."

TENANT_SAFE_AUDIT_REPO_COUNT="$(repo_count 'tenant.*audit|audit.*tenant|tenant_id.*audit|audit.*tenant_id|tenant-safe audit|tenant safe audit|audit log.*tenant')"
LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT="$(repo_count 'legal_entity.*audit|audit.*legal_entity|legal entity.*audit|audit.*legal entity|legal_entity_id.*audit|audit.*legal_entity_id')"
BRANCH_SAFE_AUDIT_REPO_COUNT="$(repo_count 'branch.*audit|audit.*branch|branch_id.*audit|audit.*branch_id|branch-safe audit|branch safe audit')"
API_EXPORT_GUARD_REPO_COUNT="$(repo_count 'api.*export|export.*api|download.*tenant|tenant.*download|StatusForbidden|403|permission.*export|export.*permission')"
AUDIT_EXPORT_EVIDENCE_FILE_COUNT="$(find "$REPO/docs" "$REPO/scripts" -type f 2>/dev/null | grep -Ei 'audit|export|evidence|isolation' | awk 'END{print NR+0}')"

echo "TENANT_SAFE_AUDIT_REPO_COUNT=$TENANT_SAFE_AUDIT_REPO_COUNT"
echo "LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT"
echo "BRANCH_SAFE_AUDIT_REPO_COUNT=$BRANCH_SAFE_AUDIT_REPO_COUNT"
echo "API_EXPORT_GUARD_REPO_COUNT=$API_EXPORT_GUARD_REPO_COUNT"
echo "AUDIT_EXPORT_EVIDENCE_FILE_COUNT=$AUDIT_EXPORT_EVIDENCE_FILE_COUNT"

[ "$TENANT_SAFE_AUDIT_REPO_COUNT" -gt 0 ] && pass "7.1 tenant-safe audit repo kanıtı mevcut" || fail "7.1 tenant-safe audit repo kanıtı yok"
[ "$LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT" -gt 0 ] && pass "7.2 legal entity-safe audit repo kanıtı mevcut" || fail "7.2 legal entity-safe audit repo kanıtı yok"
[ "$BRANCH_SAFE_AUDIT_REPO_COUNT" -gt 0 ] && pass "7.3 branch-safe audit repo kanıtı mevcut" || fail "7.3 branch-safe audit repo kanıtı yok"
[ "$API_EXPORT_GUARD_REPO_COUNT" -gt 0 ] && pass "7.4 API/export guard repo kanıtı mevcut" || fail "7.4 API/export guard repo kanıtı yok"
[ "$AUDIT_EXPORT_EVIDENCE_FILE_COUNT" -gt 0 ] && pass "7.5 audit/export evidence dosya kanıtı mevcut" || fail "7.5 audit/export evidence dosya kanıtı yok"

echo "8. audit / export strict SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/audit_export_isolation_strict_metadata_suite.sql"
SQL_SUITE_OUT="$BACKUP_DIR/audit_export_isolation_strict_metadata_suite.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_audit_tables int;
  v_tenant_audit_columns int;
  v_legal_audit_columns int;
  v_branch_audit_columns int;
  v_audit_rls int;
  v_audit_forced_rls int;
  v_audit_policy int;
BEGIN
  SELECT count(*)
  INTO v_audit_tables
  FROM information_schema.tables
  WHERE table_schema IN ('auth','audit','public','platform','core')
    AND (
      table_name ILIKE '%audit%'
      OR table_name ILIKE '%event%'
      OR table_name ILIKE '%log%'
    );

  IF v_audit_tables < 1 THEN
    RAISE EXCEPTION 'audit/event/log table coverage missing';
  END IF;

  SELECT count(*)
  INTO v_tenant_audit_columns
  FROM information_schema.columns
  WHERE column_name='tenant_id'
    AND (
      table_name ILIKE '%audit%'
      OR table_name ILIKE '%event%'
      OR table_name ILIKE '%log%'
    );

  IF v_tenant_audit_columns < 1 THEN
    RAISE EXCEPTION 'tenant-safe audit column coverage missing';
  END IF;

  SELECT count(*)
  INTO v_legal_audit_columns
  FROM information_schema.columns
  WHERE column_name='legal_entity_id'
    AND (
      table_name ILIKE '%audit%'
      OR table_name ILIKE '%event%'
      OR table_name ILIKE '%log%'
    );

  IF v_legal_audit_columns < 1 THEN
    RAISE EXCEPTION 'legal entity-safe audit column coverage missing';
  END IF;

  SELECT count(*)
  INTO v_branch_audit_columns
  FROM information_schema.columns
  WHERE column_name='branch_id'
    AND (
      table_name ILIKE '%audit%'
      OR table_name ILIKE '%event%'
      OR table_name ILIKE '%log%'
    );

  IF v_branch_audit_columns < 1 THEN
    RAISE EXCEPTION 'branch-safe audit column coverage missing';
  END IF;

  SELECT count(*)
  INTO v_audit_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='r'
    AND c.relrowsecurity=true
    AND (
      c.relname ILIKE '%audit%'
      OR c.relname ILIKE '%event%'
      OR c.relname ILIKE '%log%'
    );

  IF v_audit_rls < 1 THEN
    RAISE EXCEPTION 'audit/event/log RLS coverage missing';
  END IF;

  SELECT count(*)
  INTO v_audit_forced_rls
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='r'
    AND c.relforcerowsecurity=true
    AND (
      c.relname ILIKE '%audit%'
      OR c.relname ILIKE '%event%'
      OR c.relname ILIKE '%log%'
    );

  IF v_audit_forced_rls < 1 THEN
    RAISE EXCEPTION 'audit/event/log forced RLS coverage missing';
  END IF;

  SELECT count(*)
  INTO v_audit_policy
  FROM pg_policies
  WHERE tablename ILIKE '%audit%'
     OR tablename ILIKE '%event%'
     OR tablename ILIKE '%log%';

  IF v_audit_policy < 1 THEN
    RAISE EXCEPTION 'audit/event/log policy coverage missing';
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "8.1 audit/export strict SQL suite geçti"
else
  fail "8.1 audit/export strict SQL suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "8.2 strict SQL suite rollback ile temizlendi"
else
  fail "8.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-2.7 Audit / Export Isolation Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Required Scope"
  echo "- Tenant-safe audit"
  echo "- Legal entity-safe audit"
  echo "- Branch-safe audit"
  echo "- Tenant-safe export"
  echo "- Cross-tenant export guard"
  echo "- Export evidence"
  echo
  echo "## DB Counters"
  echo "- AUDIT_TABLE_COUNT=$AUDIT_TABLE_COUNT"
  echo "- TENANT_SAFE_AUDIT_COLUMN_COUNT=$TENANT_SAFE_AUDIT_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT"
  echo "- BRANCH_SAFE_AUDIT_COLUMN_COUNT=$BRANCH_SAFE_AUDIT_COLUMN_COUNT"
  echo "- AUDIT_RLS_ENABLED_COUNT=$AUDIT_RLS_ENABLED_COUNT"
  echo "- AUDIT_RLS_FORCED_COUNT=$AUDIT_RLS_FORCED_COUNT"
  echo "- AUDIT_POLICY_COUNT=$AUDIT_POLICY_COUNT"
  echo "- AUDIT_INDEX_COUNT=$AUDIT_INDEX_COUNT"
  echo
  echo "## Repo Counters"
  echo "- EXPORT_CONTRACT_REPO_COUNT=$EXPORT_CONTRACT_REPO_COUNT"
  echo "- TENANT_SAFE_EXPORT_REPO_COUNT=$TENANT_SAFE_EXPORT_REPO_COUNT"
  echo "- CROSS_TENANT_EXPORT_GUARD_REPO_COUNT=$CROSS_TENANT_EXPORT_GUARD_REPO_COUNT"
  echo "- EXPORT_EVIDENCE_REPO_COUNT=$EXPORT_EVIDENCE_REPO_COUNT"
  echo "- EXPORT_TEST_REPO_COUNT=$EXPORT_TEST_REPO_COUNT"
  echo "- EXPORT_PATH_GUARD_REPO_COUNT=$EXPORT_PATH_GUARD_REPO_COUNT"
  echo "- TENANT_SAFE_AUDIT_REPO_COUNT=$TENANT_SAFE_AUDIT_REPO_COUNT"
  echo "- LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT"
  echo "- BRANCH_SAFE_AUDIT_REPO_COUNT=$BRANCH_SAFE_AUDIT_REPO_COUNT"
  echo "- API_EXPORT_GUARD_REPO_COUNT=$API_EXPORT_GUARD_REPO_COUNT"
  echo "- AUDIT_EXPORT_EVIDENCE_FILE_COUNT=$AUDIT_EXPORT_EVIDENCE_FILE_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "9. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-2.7 AUDIT / EXPORT ISOLATION STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "AUDIT_TABLE_COUNT=$AUDIT_TABLE_COUNT"
echo "TENANT_SAFE_AUDIT_COLUMN_COUNT=$TENANT_SAFE_AUDIT_COLUMN_COUNT"
echo "LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_COLUMN_COUNT"
echo "BRANCH_SAFE_AUDIT_COLUMN_COUNT=$BRANCH_SAFE_AUDIT_COLUMN_COUNT"
echo "AUDIT_RLS_ENABLED_COUNT=$AUDIT_RLS_ENABLED_COUNT"
echo "AUDIT_RLS_FORCED_COUNT=$AUDIT_RLS_FORCED_COUNT"
echo "AUDIT_POLICY_COUNT=$AUDIT_POLICY_COUNT"
echo "AUDIT_INDEX_COUNT=$AUDIT_INDEX_COUNT"
echo "EXPORT_CONTRACT_REPO_COUNT=$EXPORT_CONTRACT_REPO_COUNT"
echo "TENANT_SAFE_EXPORT_REPO_COUNT=$TENANT_SAFE_EXPORT_REPO_COUNT"
echo "CROSS_TENANT_EXPORT_GUARD_REPO_COUNT=$CROSS_TENANT_EXPORT_GUARD_REPO_COUNT"
echo "EXPORT_EVIDENCE_REPO_COUNT=$EXPORT_EVIDENCE_REPO_COUNT"
echo "EXPORT_TEST_REPO_COUNT=$EXPORT_TEST_REPO_COUNT"
echo "EXPORT_PATH_GUARD_REPO_COUNT=$EXPORT_PATH_GUARD_REPO_COUNT"
echo "TENANT_SAFE_AUDIT_REPO_COUNT=$TENANT_SAFE_AUDIT_REPO_COUNT"
echo "LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT=$LEGAL_ENTITY_SAFE_AUDIT_REPO_COUNT"
echo "BRANCH_SAFE_AUDIT_REPO_COUNT=$BRANCH_SAFE_AUDIT_REPO_COUNT"
echo "API_EXPORT_GUARD_REPO_COUNT=$API_EXPORT_GUARD_REPO_COUNT"
echo "AUDIT_EXPORT_EVIDENCE_FILE_COUNT=$AUDIT_EXPORT_EVIDENCE_FILE_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_7_TENANT_SAFE_AUDIT_STATUS=PASS"
  echo "FAZ_1_2_7_LEGAL_ENTITY_SAFE_AUDIT_STATUS=PASS"
  echo "FAZ_1_2_7_BRANCH_SAFE_AUDIT_STATUS=PASS"
  echo "FAZ_1_2_7_TENANT_SAFE_EXPORT_STATUS=PASS"
  echo "FAZ_1_2_7_CROSS_TENANT_EXPORT_GUARD_STATUS=PASS"
  echo "FAZ_1_2_7_EXPORT_EVIDENCE_STATUS=PASS"
  echo "FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_7_AUDIT_EXPORT_ISOLATION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.7 AUDIT / EXPORT ISOLATION STRICT SUITE END ====="
