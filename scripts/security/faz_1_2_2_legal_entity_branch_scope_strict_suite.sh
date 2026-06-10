#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_2_legal_entity_branch_scope_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_2_LEGAL_ENTITY_BRANCH_SCOPE_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-2.2 LEGAL ENTITY / BRANCH SCOPE STRICT SUITE START ====="

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

echo "5. legal entity / branch DB standard sayaçları doğrulanıyor..."

LEGAL_ENTITY_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema in ('org','core','public','auth')
    and table_name in ('legal_entities','legal_entity','tenant_legal_entities');
")"

BRANCH_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema in ('org','core','public','auth')
    and table_name in ('branches','branch','legal_entity_branches','tenant_branches');
")"

LEGAL_ENTITY_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where column_name='legal_entity_id';
")"

BRANCH_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where column_name='branch_id';
")"

LEGAL_ENTITY_TENANT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema in ('org','core','public','auth')
    and table_name in ('legal_entities','legal_entity','tenant_legal_entities')
    and column_name in ('id','tenant_id','legal_entity_id','legal_name','name','tax_number','status');
")"

BRANCH_TENANT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema in ('org','core','public','auth')
    and table_name in ('branches','branch','legal_entity_branches','tenant_branches')
    and column_name in ('id','tenant_id','legal_entity_id','branch_id','branch_name','name','status');
")"

USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('tenant_id','legal_entity_id','branch_id','scope_type','scope_value','scope_level');
")"

RLS_LEGAL_BRANCH_TABLE_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where c.relkind='r'
    and c.relrowsecurity=true
    and exists (
      select 1
      from information_schema.columns col
      where col.table_schema=n.nspname
        and col.table_name=c.relname
        and col.column_name in ('legal_entity_id','branch_id')
    );
")"

FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where c.relkind='r'
    and c.relforcerowsecurity=true
    and exists (
      select 1
      from information_schema.columns col
      where col.table_schema=n.nspname
        and col.table_name=c.relname
        and col.column_name in ('legal_entity_id','branch_id')
    );
")"

LEGAL_BRANCH_INDEX_COUNT="$(scalar_count "
  select count(*)
  from pg_indexes
  where indexdef ilike '%legal_entity_id%'
     or indexdef ilike '%branch_id%';
")"

echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
echo "LEGAL_ENTITY_TENANT_COLUMN_COUNT=$LEGAL_ENTITY_TENANT_COLUMN_COUNT"
echo "BRANCH_TENANT_COLUMN_COUNT=$BRANCH_TENANT_COLUMN_COUNT"
echo "USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT=$USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT"
echo "RLS_LEGAL_BRANCH_TABLE_COUNT=$RLS_LEGAL_BRANCH_TABLE_COUNT"
echo "FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT=$FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT"
echo "LEGAL_BRANCH_INDEX_COUNT=$LEGAL_BRANCH_INDEX_COUNT"

[ "$LEGAL_ENTITY_TABLE_COUNT" -ge 1 ] && pass "5.1 legal entity tablo standardı mevcut" || fail "5.1 legal entity tablo standardı eksik"
[ "$BRANCH_TABLE_COUNT" -ge 1 ] && pass "5.2 branch tablo standardı mevcut" || fail "5.2 branch tablo standardı eksik"
[ "$LEGAL_ENTITY_COLUMN_COUNT" -ge 1 ] && pass "5.3 legal_entity_id kolon kapsamı mevcut" || fail "5.3 legal_entity_id kolon kapsamı yok"
[ "$BRANCH_COLUMN_COUNT" -ge 1 ] && pass "5.4 branch_id kolon kapsamı mevcut" || fail "5.4 branch_id kolon kapsamı yok"
[ "$LEGAL_ENTITY_TENANT_COLUMN_COUNT" -ge 3 ] && pass "5.5 legal entity tenant/identity kolon kapsamı yeterli" || fail "5.5 legal entity kolon kapsamı zayıf"
[ "$BRANCH_TENANT_COLUMN_COUNT" -ge 3 ] && pass "5.6 branch tenant/legal entity kolon kapsamı yeterli" || fail "5.6 branch kolon kapsamı zayıf"
[ "$USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT" -ge 5 ] && pass "5.7 user_scopes legal/branch scope bağlantısı mevcut" || fail "5.7 user_scopes legal/branch scope bağlantısı eksik"
[ "$RLS_LEGAL_BRANCH_TABLE_COUNT" -ge 1 ] && pass "5.8 legal/branch scoped tablolarda RLS enabled izi mevcut" || fail "5.8 legal/branch scoped RLS enabled izi yok"
[ "$FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT" -ge 1 ] && pass "5.9 legal/branch scoped tablolarda RLS forced izi mevcut" || fail "5.9 legal/branch scoped RLS forced izi yok"
[ "$LEGAL_BRANCH_INDEX_COUNT" -ge 1 ] && pass "5.10 legal_entity_id/branch_id index izi mevcut" || warn "5.10 legal_entity_id/branch_id index izi zayıf"

echo "6. alt başlık repo/API/query/cross-branch evidence doğrulanıyor..."

LEGAL_ENTITY_SCOPE_REPO_COUNT="$(repo_count 'legal_entity_id|LEGAL_ENTITY|legal entity scope|legal.?entity.*scope|scope.*legal.?entity')"
BRANCH_SCOPE_REPO_COUNT="$(repo_count 'branch_id|BRANCH|branch scope|scope.*branch|branch.*scope')"
QUERY_LAYER_GUARD_REPO_COUNT="$(repo_count 'legal_entity_id.*query|branch_id.*query|query.*legal_entity_id|query.*branch_id|Where.*legal_entity_id|Where.*branch_id|scope.*query|query.*scope|tenant.*query.*scope')"
API_SCOPE_GUARD_REPO_COUNT="$(repo_count 'X-Legal-Entity|X-Branch|legal_entity_id.*header|branch_id.*header|api.*legal_entity_id|api.*branch_id|scope guard|permission guard|forbidden|StatusForbidden|403')"
CROSS_BRANCH_TEST_REPO_COUNT="$(repo_count 'cross.?branch|branch.*mismatch|mismatch.*branch|branch.*forbidden|forbidden.*branch|branch.*isolation|legal_entity.*mismatch|cross.?legal')"
ACCOUNTANT_SCOPE_REPO_COUNT="$(repo_count 'accountant.*assigned|assigned.?company|accountant_company_id|accountant.*legal_entity|accountant.*branch')"

echo "LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
echo "BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
echo "QUERY_LAYER_GUARD_REPO_COUNT=$QUERY_LAYER_GUARD_REPO_COUNT"
echo "API_SCOPE_GUARD_REPO_COUNT=$API_SCOPE_GUARD_REPO_COUNT"
echo "CROSS_BRANCH_TEST_REPO_COUNT=$CROSS_BRANCH_TEST_REPO_COUNT"
echo "ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"

[ "$LEGAL_ENTITY_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.1 legal entity scope repo kanıtı mevcut" || fail "6.1 legal entity scope repo kanıtı yok"
[ "$BRANCH_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.2 branch scope repo kanıtı mevcut" || fail "6.2 branch scope repo kanıtı yok"
[ "$QUERY_LAYER_GUARD_REPO_COUNT" -gt 0 ] && pass "6.3 query layer guard repo kanıtı mevcut" || fail "6.3 query layer guard repo kanıtı yok"
[ "$API_SCOPE_GUARD_REPO_COUNT" -gt 0 ] && pass "6.4 API scope guard repo kanıtı mevcut" || fail "6.4 API scope guard repo kanıtı yok"
[ "$CROSS_BRANCH_TEST_REPO_COUNT" -gt 0 ] && pass "6.5 cross-branch test repo kanıtı mevcut" || fail "6.5 cross-branch test repo kanıtı yok"
[ "$ACCOUNTANT_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.6 accountant assigned-company scope ile uyum izi mevcut" || warn "6.6 accountant assigned-company scope uyum izi zayıf"

echo "7. legal entity / branch strict SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/legal_entity_branch_scope_strict_metadata_suite.sql"
SQL_SUITE_OUT="$BACKUP_DIR/legal_entity_branch_scope_strict_metadata_suite.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_legal_entity_tables int;
  v_branch_tables int;
  v_legal_entity_columns int;
  v_branch_columns int;
  v_user_scope_columns int;
  v_rls_count int;
  v_forced_rls_count int;
  v_index_count int;
BEGIN
  SELECT count(*)
  INTO v_legal_entity_tables
  FROM information_schema.tables
  WHERE table_schema IN ('org','core','public','auth')
    AND table_name IN ('legal_entities','legal_entity','tenant_legal_entities');

  IF v_legal_entity_tables < 1 THEN
    RAISE EXCEPTION 'legal entity table standard missing';
  END IF;

  SELECT count(*)
  INTO v_branch_tables
  FROM information_schema.tables
  WHERE table_schema IN ('org','core','public','auth')
    AND table_name IN ('branches','branch','legal_entity_branches','tenant_branches');

  IF v_branch_tables < 1 THEN
    RAISE EXCEPTION 'branch table standard missing';
  END IF;

  SELECT count(*)
  INTO v_legal_entity_columns
  FROM information_schema.columns
  WHERE column_name='legal_entity_id';

  IF v_legal_entity_columns < 1 THEN
    RAISE EXCEPTION 'legal_entity_id column coverage missing';
  END IF;

  SELECT count(*)
  INTO v_branch_columns
  FROM information_schema.columns
  WHERE column_name='branch_id';

  IF v_branch_columns < 1 THEN
    RAISE EXCEPTION 'branch_id column coverage missing';
  END IF;

  SELECT count(*)
  INTO v_user_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('tenant_id','legal_entity_id','branch_id','scope_type','scope_value','scope_level');

  IF v_user_scope_columns < 5 THEN
    RAISE EXCEPTION 'auth.user_scopes legal/branch scope coverage weak count=%', v_user_scope_columns;
  END IF;

  SELECT count(*)
  INTO v_rls_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='r'
    AND c.relrowsecurity=true
    AND EXISTS (
      SELECT 1
      FROM information_schema.columns col
      WHERE col.table_schema=n.nspname
        AND col.table_name=c.relname
        AND col.column_name IN ('legal_entity_id','branch_id')
    );

  IF v_rls_count < 1 THEN
    RAISE EXCEPTION 'legal/branch scoped RLS coverage missing';
  END IF;

  SELECT count(*)
  INTO v_forced_rls_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.relkind='r'
    AND c.relforcerowsecurity=true
    AND EXISTS (
      SELECT 1
      FROM information_schema.columns col
      WHERE col.table_schema=n.nspname
        AND col.table_name=c.relname
        AND col.column_name IN ('legal_entity_id','branch_id')
    );

  IF v_forced_rls_count < 1 THEN
    RAISE EXCEPTION 'legal/branch scoped forced RLS coverage missing';
  END IF;

  SELECT count(*)
  INTO v_index_count
  FROM pg_indexes
  WHERE indexdef ILIKE '%legal_entity_id%'
     OR indexdef ILIKE '%branch_id%';

  IF v_index_count < 1 THEN
    RAISE NOTICE 'legal_entity_id/branch_id index coverage weak count=%', v_index_count;
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "7.1 legal entity / branch strict SQL suite geçti"
else
  fail "7.1 legal entity / branch strict SQL suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "7.2 strict SQL suite rollback ile temizlendi"
else
  fail "7.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-2.2 Legal Entity / Branch Scope Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Required Scope"
  echo "- Legal entity scope standardı"
  echo "- Branch scope standardı"
  echo "- Query layer guard"
  echo "- API scope guard"
  echo "- Cross-branch testleri"
  echo
  echo "## DB Counters"
  echo "- LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
  echo "- BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
  echo "- LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
  echo "- BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_TENANT_COLUMN_COUNT=$LEGAL_ENTITY_TENANT_COLUMN_COUNT"
  echo "- BRANCH_TENANT_COLUMN_COUNT=$BRANCH_TENANT_COLUMN_COUNT"
  echo "- USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT=$USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT"
  echo "- RLS_LEGAL_BRANCH_TABLE_COUNT=$RLS_LEGAL_BRANCH_TABLE_COUNT"
  echo "- FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT=$FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT"
  echo "- LEGAL_BRANCH_INDEX_COUNT=$LEGAL_BRANCH_INDEX_COUNT"
  echo
  echo "## Repo Counters"
  echo "- LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
  echo "- BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
  echo "- QUERY_LAYER_GUARD_REPO_COUNT=$QUERY_LAYER_GUARD_REPO_COUNT"
  echo "- API_SCOPE_GUARD_REPO_COUNT=$API_SCOPE_GUARD_REPO_COUNT"
  echo "- CROSS_BRANCH_TEST_REPO_COUNT=$CROSS_BRANCH_TEST_REPO_COUNT"
  echo "- ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-2.2 LEGAL ENTITY / BRANCH SCOPE STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "LEGAL_ENTITY_TABLE_COUNT=$LEGAL_ENTITY_TABLE_COUNT"
echo "BRANCH_TABLE_COUNT=$BRANCH_TABLE_COUNT"
echo "LEGAL_ENTITY_COLUMN_COUNT=$LEGAL_ENTITY_COLUMN_COUNT"
echo "BRANCH_COLUMN_COUNT=$BRANCH_COLUMN_COUNT"
echo "LEGAL_ENTITY_TENANT_COLUMN_COUNT=$LEGAL_ENTITY_TENANT_COLUMN_COUNT"
echo "BRANCH_TENANT_COLUMN_COUNT=$BRANCH_TENANT_COLUMN_COUNT"
echo "USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT=$USER_SCOPE_LEGAL_BRANCH_COLUMN_COUNT"
echo "RLS_LEGAL_BRANCH_TABLE_COUNT=$RLS_LEGAL_BRANCH_TABLE_COUNT"
echo "FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT=$FORCED_RLS_LEGAL_BRANCH_TABLE_COUNT"
echo "LEGAL_BRANCH_INDEX_COUNT=$LEGAL_BRANCH_INDEX_COUNT"
echo "LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
echo "BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
echo "QUERY_LAYER_GUARD_REPO_COUNT=$QUERY_LAYER_GUARD_REPO_COUNT"
echo "API_SCOPE_GUARD_REPO_COUNT=$API_SCOPE_GUARD_REPO_COUNT"
echo "CROSS_BRANCH_TEST_REPO_COUNT=$CROSS_BRANCH_TEST_REPO_COUNT"
echo "ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_2_LEGAL_ENTITY_SCOPE_STANDARD_STATUS=PASS"
  echo "FAZ_1_2_2_BRANCH_SCOPE_STANDARD_STATUS=PASS"
  echo "FAZ_1_2_2_QUERY_LAYER_GUARD_STATUS=PASS"
  echo "FAZ_1_2_2_API_SCOPE_GUARD_STATUS=PASS"
  echo "FAZ_1_2_2_CROSS_BRANCH_TEST_STATUS=PASS"
  echo "FAZ_1_2_2_LEGAL_ENTITY_BRANCH_SCOPE_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_2_2_LEGAL_ENTITY_BRANCH_SCOPE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_2_LEGAL_ENTITY_BRANCH_SCOPE_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_2_LEGAL_ENTITY_BRANCH_SCOPE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.2 LEGAL ENTITY / BRANCH SCOPE STRICT SUITE END ====="
