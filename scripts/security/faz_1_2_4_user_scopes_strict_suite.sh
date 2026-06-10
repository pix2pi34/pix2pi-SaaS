#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_4_auth_user_scopes_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_4_AUTH_USER_SCOPES_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-2.4 AUTH USER SCOPES STRICT SUITE START ====="

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

echo "5. auth.user_scopes canonical model sayaçları doğrulanıyor..."

USER_SCOPES_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name='user_scopes';
")"

USER_SCOPE_AUDIT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name='user_scope_audit';
")"

USER_SCOPES_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes';
")"

USER_SCOPE_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scope_audit';
")"

USER_SCOPE_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('user_scopes','user_scope_audit')
    and c.relrowsecurity=true;
")"

USER_SCOPE_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('user_scopes','user_scope_audit')
    and c.relforcerowsecurity=true;
")"

USER_SCOPE_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in ('user_scopes','user_scope_audit');
")"

USER_SCOPE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and (
      p.proname ilike '%user_scope%'
      or p.proname ilike '%grant_scope%'
      or p.proname ilike '%revoke_scope%'
      or p.proname ilike '%has_scope%'
    );
")"

VERIFY_ROLE_COUNT="$(scalar_count "
  select count(*)
  from pg_roles
  where rolname in ('pix2pi_rls_verify_role','pix2pi_verify_role');
")"

echo "USER_SCOPES_TABLE_COUNT=$USER_SCOPES_TABLE_COUNT"
echo "USER_SCOPE_AUDIT_TABLE_COUNT=$USER_SCOPE_AUDIT_TABLE_COUNT"
echo "USER_SCOPES_COLUMN_COUNT=$USER_SCOPES_COLUMN_COUNT"
echo "USER_SCOPE_AUDIT_COLUMN_COUNT=$USER_SCOPE_AUDIT_COLUMN_COUNT"
echo "USER_SCOPE_RLS_ENABLED_COUNT=$USER_SCOPE_RLS_ENABLED_COUNT"
echo "USER_SCOPE_RLS_FORCED_COUNT=$USER_SCOPE_RLS_FORCED_COUNT"
echo "USER_SCOPE_POLICY_COUNT=$USER_SCOPE_POLICY_COUNT"
echo "USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"

[ "$USER_SCOPES_TABLE_COUNT" -ge 1 ] && pass "5.1 auth.user_scopes tablosu mevcut" || fail "5.1 auth.user_scopes tablosu yok"
[ "$USER_SCOPE_AUDIT_TABLE_COUNT" -ge 1 ] && pass "5.2 auth.user_scope_audit tablosu mevcut" || fail "5.2 auth.user_scope_audit tablosu yok"
[ "$USER_SCOPES_COLUMN_COUNT" -ge 12 ] && pass "5.3 auth.user_scopes kolon kapsamı yeterli" || fail "5.3 auth.user_scopes kolon kapsamı zayıf"
[ "$USER_SCOPE_AUDIT_COLUMN_COUNT" -ge 8 ] && pass "5.4 auth.user_scope_audit kolon kapsamı yeterli" || fail "5.4 auth.user_scope_audit kolon kapsamı zayıf"
[ "$USER_SCOPE_RLS_ENABLED_COUNT" -ge 2 ] && pass "5.5 user scope tablolarında RLS enabled" || fail "5.5 user scope RLS enabled eksik"
[ "$USER_SCOPE_RLS_FORCED_COUNT" -ge 2 ] && pass "5.6 user scope tablolarında RLS forced" || fail "5.6 user scope RLS forced eksik"
[ "$USER_SCOPE_POLICY_COUNT" -ge 4 ] && pass "5.7 user scope policy kapsamı yeterli" || fail "5.7 user scope policy kapsamı eksik"
[ "$USER_SCOPE_FUNCTION_COUNT" -ge 4 ] && pass "5.8 user scope runtime function seti mevcut" || fail "5.8 user scope runtime function seti eksik"
[ "$VERIFY_ROLE_COUNT" -ge 1 ] && pass "5.9 verify role mevcut" || fail "5.9 verify role yok"

echo "6. alt başlık DB kolonları ve repo izleri doğrulanıyor..."

TENANT_SCOPE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('tenant_id','scope_type','scope_value','scope_level');
")"

LEGAL_ENTITY_SCOPE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('legal_entity_id','scope_type','scope_value','scope_level');
")"

BRANCH_SCOPE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('branch_id','scope_type','scope_value','scope_level');
")"

ACCOUNTANT_SCOPE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('accountant_company_id','scope_type','scope_value','scope_level');
")"

EXPIRATION_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in ('expires_at','valid_until','revoked_at','status');
")"

AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scope_audit'
    and column_name in ('tenant_id','user_id','scope_id','action','event_type','metadata','created_at');
")"

TENANT_SCOPE_REPO_COUNT="$(repo_count 'TENANT|tenant scope|scope_type.*TENANT|scope_level.*tenant|tenant_id.*scope')"
LEGAL_ENTITY_SCOPE_REPO_COUNT="$(repo_count 'LEGAL_ENTITY|legal entity scope|legal_entity_id|scope_type.*LEGAL_ENTITY|scope_level.*legal')"
BRANCH_SCOPE_REPO_COUNT="$(repo_count 'BRANCH|branch scope|branch_id|scope_type.*BRANCH|scope_level.*branch')"
ACCOUNTANT_SCOPE_REPO_COUNT="$(repo_count 'ACCOUNTANT|accountant.*scope|accountant_company_id|assigned.?company|assigned company')"
EXPIRATION_REPO_COUNT="$(repo_count 'expires_at|valid_until|expired scope|scope expiration|expire.*scope|revoked_at')"
AUDIT_REPO_COUNT="$(repo_count 'user_scope_audit|scope audit|audit.*scope|scope.*audit')"

echo "TENANT_SCOPE_COLUMN_COUNT=$TENANT_SCOPE_COLUMN_COUNT"
echo "LEGAL_ENTITY_SCOPE_COLUMN_COUNT=$LEGAL_ENTITY_SCOPE_COLUMN_COUNT"
echo "BRANCH_SCOPE_COLUMN_COUNT=$BRANCH_SCOPE_COLUMN_COUNT"
echo "ACCOUNTANT_SCOPE_COLUMN_COUNT=$ACCOUNTANT_SCOPE_COLUMN_COUNT"
echo "EXPIRATION_COLUMN_COUNT=$EXPIRATION_COLUMN_COUNT"
echo "AUDIT_COLUMN_COUNT=$AUDIT_COLUMN_COUNT"
echo "TENANT_SCOPE_REPO_COUNT=$TENANT_SCOPE_REPO_COUNT"
echo "LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
echo "BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
echo "ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"
echo "EXPIRATION_REPO_COUNT=$EXPIRATION_REPO_COUNT"
echo "AUDIT_REPO_COUNT=$AUDIT_REPO_COUNT"

[ "$TENANT_SCOPE_COLUMN_COUNT" -ge 3 ] && [ "$TENANT_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.1 tenant scope DB/repo kanıtı mevcut" || fail "6.1 tenant scope kanıtı eksik"
[ "$LEGAL_ENTITY_SCOPE_COLUMN_COUNT" -ge 3 ] && [ "$LEGAL_ENTITY_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.2 legal entity scope DB/repo kanıtı mevcut" || fail "6.2 legal entity scope kanıtı eksik"
[ "$BRANCH_SCOPE_COLUMN_COUNT" -ge 3 ] && [ "$BRANCH_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.3 branch scope DB/repo kanıtı mevcut" || fail "6.3 branch scope kanıtı eksik"
[ "$ACCOUNTANT_SCOPE_COLUMN_COUNT" -ge 3 ] && [ "$ACCOUNTANT_SCOPE_REPO_COUNT" -gt 0 ] && pass "6.4 accountant assigned-company scope DB/repo kanıtı mevcut" || fail "6.4 accountant assigned-company scope kanıtı eksik"
[ "$EXPIRATION_COLUMN_COUNT" -ge 2 ] && [ "$EXPIRATION_REPO_COUNT" -gt 0 ] && pass "6.5 scope expiration DB/repo kanıtı mevcut" || fail "6.5 scope expiration kanıtı eksik"
[ "$AUDIT_COLUMN_COUNT" -ge 4 ] && [ "$AUDIT_REPO_COUNT" -gt 0 ] && pass "6.6 scope audit DB/repo kanıtı mevcut" || fail "6.6 scope audit kanıtı eksik"

echo "7. user scope strict metadata/lifecycle SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/user_scope_strict_metadata_suite.sql"
SQL_SUITE_OUT="$BACKUP_DIR/user_scope_strict_metadata_suite.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_user_scope_table int;
  v_audit_table int;
  v_scope_columns int;
  v_audit_columns int;
  v_expiry_columns int;
  v_tenant_scope_columns int;
  v_legal_scope_columns int;
  v_branch_scope_columns int;
  v_accountant_scope_columns int;
  v_function_count int;
  v_rls_enabled int;
  v_rls_forced int;
BEGIN
  SELECT count(*) INTO v_user_scope_table
  FROM information_schema.tables
  WHERE table_schema='auth' AND table_name='user_scopes';

  IF v_user_scope_table < 1 THEN
    RAISE EXCEPTION 'auth.user_scopes table missing';
  END IF;

  SELECT count(*) INTO v_audit_table
  FROM information_schema.tables
  WHERE table_schema='auth' AND table_name='user_scope_audit';

  IF v_audit_table < 1 THEN
    RAISE EXCEPTION 'auth.user_scope_audit table missing';
  END IF;

  SELECT count(*) INTO v_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes';

  IF v_scope_columns < 12 THEN
    RAISE EXCEPTION 'auth.user_scopes canonical column coverage weak count=%', v_scope_columns;
  END IF;

  SELECT count(*) INTO v_audit_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scope_audit';

  IF v_audit_columns < 8 THEN
    RAISE EXCEPTION 'auth.user_scope_audit canonical column coverage weak count=%', v_audit_columns;
  END IF;

  SELECT count(*) INTO v_tenant_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('tenant_id','scope_type','scope_value','scope_level');

  IF v_tenant_scope_columns < 3 THEN
    RAISE EXCEPTION 'tenant scope column coverage weak count=%', v_tenant_scope_columns;
  END IF;

  SELECT count(*) INTO v_legal_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('legal_entity_id','scope_type','scope_value','scope_level');

  IF v_legal_scope_columns < 3 THEN
    RAISE EXCEPTION 'legal entity scope column coverage weak count=%', v_legal_scope_columns;
  END IF;

  SELECT count(*) INTO v_branch_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('branch_id','scope_type','scope_value','scope_level');

  IF v_branch_scope_columns < 3 THEN
    RAISE EXCEPTION 'branch scope column coverage weak count=%', v_branch_scope_columns;
  END IF;

  SELECT count(*) INTO v_accountant_scope_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('accountant_company_id','scope_type','scope_value','scope_level');

  IF v_accountant_scope_columns < 3 THEN
    RAISE EXCEPTION 'accountant assigned-company scope column coverage weak count=%', v_accountant_scope_columns;
  END IF;

  SELECT count(*) INTO v_expiry_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='user_scopes'
    AND column_name IN ('expires_at','valid_until','revoked_at','status');

  IF v_expiry_columns < 2 THEN
    RAISE EXCEPTION 'scope expiration column coverage weak count=%', v_expiry_columns;
  END IF;

  SELECT count(*) INTO v_function_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='auth'
    AND (
      p.proname ILIKE '%user_scope%'
      OR p.proname ILIKE '%grant_scope%'
      OR p.proname ILIKE '%revoke_scope%'
      OR p.proname ILIKE '%has_scope%'
    );

  IF v_function_count < 4 THEN
    RAISE EXCEPTION 'user scope function set weak count=%', v_function_count;
  END IF;

  SELECT count(*) INTO v_rls_enabled
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='auth'
    AND c.relname IN ('user_scopes','user_scope_audit')
    AND c.relrowsecurity=true;

  IF v_rls_enabled < 2 THEN
    RAISE EXCEPTION 'user scope RLS enabled weak count=%', v_rls_enabled;
  END IF;

  SELECT count(*) INTO v_rls_forced
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='auth'
    AND c.relname IN ('user_scopes','user_scope_audit')
    AND c.relforcerowsecurity=true;

  IF v_rls_forced < 2 THEN
    RAISE EXCEPTION 'user scope RLS forced weak count=%', v_rls_forced;
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "7.1 strict metadata/lifecycle SQL suite geçti"
else
  fail "7.1 strict metadata/lifecycle SQL suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "7.2 strict SQL suite rollback ile temizlendi"
else
  fail "7.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-2.4 Auth User Scopes Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Required Scope"
  echo "- Tenant scope"
  echo "- Legal entity scope"
  echo "- Branch scope"
  echo "- Accountant assigned-company scope"
  echo "- Scope expiration"
  echo "- Scope audit"
  echo
  echo "## DB Counters"
  echo "- USER_SCOPES_TABLE_COUNT=$USER_SCOPES_TABLE_COUNT"
  echo "- USER_SCOPE_AUDIT_TABLE_COUNT=$USER_SCOPE_AUDIT_TABLE_COUNT"
  echo "- USER_SCOPES_COLUMN_COUNT=$USER_SCOPES_COLUMN_COUNT"
  echo "- USER_SCOPE_AUDIT_COLUMN_COUNT=$USER_SCOPE_AUDIT_COLUMN_COUNT"
  echo "- USER_SCOPE_RLS_ENABLED_COUNT=$USER_SCOPE_RLS_ENABLED_COUNT"
  echo "- USER_SCOPE_RLS_FORCED_COUNT=$USER_SCOPE_RLS_FORCED_COUNT"
  echo "- USER_SCOPE_POLICY_COUNT=$USER_SCOPE_POLICY_COUNT"
  echo "- USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
  echo "- TENANT_SCOPE_COLUMN_COUNT=$TENANT_SCOPE_COLUMN_COUNT"
  echo "- LEGAL_ENTITY_SCOPE_COLUMN_COUNT=$LEGAL_ENTITY_SCOPE_COLUMN_COUNT"
  echo "- BRANCH_SCOPE_COLUMN_COUNT=$BRANCH_SCOPE_COLUMN_COUNT"
  echo "- ACCOUNTANT_SCOPE_COLUMN_COUNT=$ACCOUNTANT_SCOPE_COLUMN_COUNT"
  echo "- EXPIRATION_COLUMN_COUNT=$EXPIRATION_COLUMN_COUNT"
  echo "- AUDIT_COLUMN_COUNT=$AUDIT_COLUMN_COUNT"
  echo
  echo "## Repo Counters"
  echo "- TENANT_SCOPE_REPO_COUNT=$TENANT_SCOPE_REPO_COUNT"
  echo "- LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
  echo "- BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
  echo "- ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"
  echo "- EXPIRATION_REPO_COUNT=$EXPIRATION_REPO_COUNT"
  echo "- AUDIT_REPO_COUNT=$AUDIT_REPO_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-2.4 AUTH USER SCOPES STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "USER_SCOPES_TABLE_COUNT=$USER_SCOPES_TABLE_COUNT"
echo "USER_SCOPE_AUDIT_TABLE_COUNT=$USER_SCOPE_AUDIT_TABLE_COUNT"
echo "USER_SCOPES_COLUMN_COUNT=$USER_SCOPES_COLUMN_COUNT"
echo "USER_SCOPE_AUDIT_COLUMN_COUNT=$USER_SCOPE_AUDIT_COLUMN_COUNT"
echo "USER_SCOPE_RLS_ENABLED_COUNT=$USER_SCOPE_RLS_ENABLED_COUNT"
echo "USER_SCOPE_RLS_FORCED_COUNT=$USER_SCOPE_RLS_FORCED_COUNT"
echo "USER_SCOPE_POLICY_COUNT=$USER_SCOPE_POLICY_COUNT"
echo "USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
echo "TENANT_SCOPE_COLUMN_COUNT=$TENANT_SCOPE_COLUMN_COUNT"
echo "LEGAL_ENTITY_SCOPE_COLUMN_COUNT=$LEGAL_ENTITY_SCOPE_COLUMN_COUNT"
echo "BRANCH_SCOPE_COLUMN_COUNT=$BRANCH_SCOPE_COLUMN_COUNT"
echo "ACCOUNTANT_SCOPE_COLUMN_COUNT=$ACCOUNTANT_SCOPE_COLUMN_COUNT"
echo "EXPIRATION_COLUMN_COUNT=$EXPIRATION_COLUMN_COUNT"
echo "AUDIT_COLUMN_COUNT=$AUDIT_COLUMN_COUNT"
echo "TENANT_SCOPE_REPO_COUNT=$TENANT_SCOPE_REPO_COUNT"
echo "LEGAL_ENTITY_SCOPE_REPO_COUNT=$LEGAL_ENTITY_SCOPE_REPO_COUNT"
echo "BRANCH_SCOPE_REPO_COUNT=$BRANCH_SCOPE_REPO_COUNT"
echo "ACCOUNTANT_SCOPE_REPO_COUNT=$ACCOUNTANT_SCOPE_REPO_COUNT"
echo "EXPIRATION_REPO_COUNT=$EXPIRATION_REPO_COUNT"
echo "AUDIT_REPO_COUNT=$AUDIT_REPO_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_4_TENANT_SCOPE_STATUS=PASS"
  echo "FAZ_1_2_4_LEGAL_ENTITY_SCOPE_STATUS=PASS"
  echo "FAZ_1_2_4_BRANCH_SCOPE_STATUS=PASS"
  echo "FAZ_1_2_4_ACCOUNTANT_ASSIGNED_COMPANY_SCOPE_STATUS=PASS"
  echo "FAZ_1_2_4_SCOPE_EXPIRATION_STATUS=PASS"
  echo "FAZ_1_2_4_SCOPE_AUDIT_STATUS=PASS"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.4 AUTH USER SCOPES STRICT SUITE END ====="
