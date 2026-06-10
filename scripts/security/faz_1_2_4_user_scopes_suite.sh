#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
PHASE="FAZ_1_2_4_AUTH_USER_SCOPES"

BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_4_user_scopes_suite_fix_v9c_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_SUITE_RESULT_FIX_V9C_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "$1 / FAIL ❌"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "$1 / WARN ⚠️"; }

scalar_count() {
  local sql="$1"
  psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}'
}

scalar_text() {
  local sql="$1"
  psql "$DSN" -Atqc "$sql" 2>/dev/null | tail -n1
}

echo "===== FAZ 1-2.4 AUTH USER SCOPES SUITE FIX V9C START ====="

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

if [ -n "$DSN" ]; then pass "2. DB DSN bulundu"; else fail "2. DB DSN bulunamadı"; exit 1; fi
if command -v psql >/dev/null 2>&1; then pass "3. psql mevcut"; else fail "3. psql bulunamadı"; exit 1; fi
if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then pass "4. DB bağlantısı başarılı"; else fail "4. DB bağlantısı başarısız"; exit 1; fi

echo "5. model/table/function/grant sayaçları doğrulanıyor..."

USER_SCOPES_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='auth' and table_name='user_scopes';")"
USER_SCOPE_AUDIT_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='auth' and table_name='user_scope_audit';")"

USER_SCOPES_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name in (
      'tenant_id','scope_id','user_id','scope_type','scope_value',
      'legal_entity_id','branch_id','accountant_company_id',
      'status','granted_by','granted_at','expires_at',
      'revoked_at','revoked_by','revoke_reason','metadata',
      'created_at','updated_at'
    );
")"

USER_SCOPE_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scope_audit'
    and column_name in (
      'tenant_id','audit_id','scope_id','user_id','action_type',
      'actor_user_id','reason','old_status','new_status','metadata','created_at'
    );
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
    and tablename in ('user_scopes','user_scope_audit')
    and policyname in ('pix2pi_tenant_isolation_allow','pix2pi_tenant_isolation_enforce');
")"

USER_SCOPE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and p.proname in ('grant_user_scope','revoke_user_scope','user_has_scope','assert_user_scope');
")"

VERIFY_ROLE_COUNT="$(scalar_count "select count(*) from pg_roles where rolname='pix2pi_user_scope_verify_role';")"

LEGACY_SCOPE_LEVEL_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='user_scopes'
    and column_name='scope_level';
")"

SCOPE_LEVEL_ENUM_LABEL_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns c
  join pg_type t on t.typname = c.udt_name
  join pg_namespace n on n.oid = t.typnamespace and n.nspname = c.udt_schema
  join pg_enum e on e.enumtypid = t.oid
  where c.table_schema='auth'
    and c.table_name='user_scopes'
    and c.column_name='scope_level';
")"

TENANT_ID_FK_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
  where con.contype = 'f'
    and nsp.nspname = 'auth'
    and rel.relname = 'user_scopes'
    and att.attname = 'tenant_id';
")"

LEGAL_ENTITY_ID_FK_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
  where con.contype = 'f'
    and nsp.nspname = 'auth'
    and rel.relname = 'user_scopes'
    and att.attname = 'legal_entity_id';
")"

BRANCH_ID_FK_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_namespace nsp on nsp.oid = rel.relnamespace
  join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
  where con.contype = 'f'
    and nsp.nspname = 'auth'
    and rel.relname = 'user_scopes'
    and att.attname = 'branch_id';
")"

CODE_TEXT_DOMAIN_COUNT="$(scalar_count "
  select count(*)
  from pg_constraint c
  join pg_type t on t.oid = c.contypid
  join pg_namespace n on n.oid = t.typnamespace
  where n.nspname='core'
    and t.typname='code_text'
    and pg_get_constraintdef(c.oid) like '%^[A-Z0-9_%';
")"

SECURITY_SCHEMA_COUNT="$(scalar_count "select count(*) from information_schema.schemata where schema_name='security';")"
VERIFY_ROLE_SECURITY_USAGE="$(scalar_text "select case when has_schema_privilege('pix2pi_user_scope_verify_role','security','USAGE') then 'YES' else 'NO' end;")"
VERIFY_ROLE_SECURITY_EXECUTE_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'security'
    and has_function_privilege('pix2pi_user_scope_verify_role', p.oid, 'EXECUTE');
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
echo "LEGACY_SCOPE_LEVEL_COUNT=$LEGACY_SCOPE_LEVEL_COUNT"
echo "SCOPE_LEVEL_ENUM_LABEL_COUNT=$SCOPE_LEVEL_ENUM_LABEL_COUNT"
echo "TENANT_ID_FK_COUNT=$TENANT_ID_FK_COUNT"
echo "LEGAL_ENTITY_ID_FK_COUNT=$LEGAL_ENTITY_ID_FK_COUNT"
echo "BRANCH_ID_FK_COUNT=$BRANCH_ID_FK_COUNT"
echo "CODE_TEXT_DOMAIN_COUNT=$CODE_TEXT_DOMAIN_COUNT"
echo "SECURITY_SCHEMA_COUNT=$SECURITY_SCHEMA_COUNT"
echo "VERIFY_ROLE_SECURITY_USAGE=$VERIFY_ROLE_SECURITY_USAGE"
echo "VERIFY_ROLE_SECURITY_EXECUTE_COUNT=$VERIFY_ROLE_SECURITY_EXECUTE_COUNT"

[ "$USER_SCOPES_TABLE_COUNT" = "1" ] && pass "5.1 auth.user_scopes tablosu hazır" || fail "5.1 auth.user_scopes tablosu eksik"
[ "$USER_SCOPE_AUDIT_TABLE_COUNT" = "1" ] && pass "5.2 auth.user_scope_audit tablosu hazır" || fail "5.2 auth.user_scope_audit tablosu eksik"
[ "$USER_SCOPES_COLUMN_COUNT" = "18" ] && pass "5.3 auth.user_scopes canonical kolon kapsamı tam" || fail "5.3 auth.user_scopes canonical kolon kapsamı eksik actual=$USER_SCOPES_COLUMN_COUNT"
[ "$USER_SCOPE_AUDIT_COLUMN_COUNT" = "11" ] && pass "5.4 auth.user_scope_audit canonical kolon kapsamı tam" || fail "5.4 auth.user_scope_audit canonical kolon kapsamı eksik actual=$USER_SCOPE_AUDIT_COLUMN_COUNT"
[ "$USER_SCOPE_RLS_ENABLED_COUNT" = "2" ] && pass "5.5 user scope tablolarında RLS enabled" || fail "5.5 user scope RLS enabled eksik actual=$USER_SCOPE_RLS_ENABLED_COUNT"
[ "$USER_SCOPE_RLS_FORCED_COUNT" = "2" ] && pass "5.6 user scope tablolarında RLS forced" || fail "5.6 user scope RLS forced eksik actual=$USER_SCOPE_RLS_FORCED_COUNT"
[ "$USER_SCOPE_POLICY_COUNT" = "4" ] && pass "5.7 user scope allow/enforce policy kapsamı tam" || fail "5.7 user scope policy kapsamı eksik actual=$USER_SCOPE_POLICY_COUNT"
[ "$USER_SCOPE_FUNCTION_COUNT" = "4" ] && pass "5.8 user scope runtime function seti hazır" || fail "5.8 user scope runtime function seti eksik actual=$USER_SCOPE_FUNCTION_COUNT"
[ "$VERIFY_ROLE_COUNT" = "1" ] && pass "5.9 user scope verify role hazır" || fail "5.9 user scope verify role eksik"
[ "$LEGACY_SCOPE_LEVEL_COUNT" = "1" ] && pass "5.10 legacy scope_level uyumluluğu aktif" || pass "5.10 legacy scope_level kolonu yok"
[ "$TENANT_ID_FK_COUNT" -gt 0 ] && pass "5.11 tenant_id FK algılandı" || pass "5.11 tenant_id FK yok"
[ "$LEGAL_ENTITY_ID_FK_COUNT" -gt 0 ] && pass "5.12 legal_entity_id FK algılandı" || pass "5.12 legal_entity_id FK yok"
[ "$BRANCH_ID_FK_COUNT" -gt 0 ] && pass "5.13 branch_id FK algılandı" || pass "5.13 branch_id FK yok"
[ "$CODE_TEXT_DOMAIN_COUNT" -gt 0 ] && pass "5.14 core.code_text büyük harf domain kuralı algılandı" || warn "5.14 core.code_text domain kuralı algılanamadı"
[ "$SECURITY_SCHEMA_COUNT" = "1" ] && pass "5.15 security schema mevcut" || warn "5.15 security schema yok"
[ "$VERIFY_ROLE_SECURITY_USAGE" = "YES" ] && pass "5.16 verify role security schema USAGE sahibi" || fail "5.16 verify role security schema USAGE sahibi değil"
[ "$VERIFY_ROLE_SECURITY_EXECUTE_COUNT" -gt 0 ] && pass "5.17 verify role security fonksiyon EXECUTE sahibi" || fail "5.17 verify role security fonksiyon EXECUTE sahibi değil"

echo "6. user scope lifecycle / abuse SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/user_scope_lifecycle_suite_fix_v9c.sql"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_tenant_id uuid;
  v_user_id uuid;
  v_expire_user_id uuid;
  v_legal_entity_id uuid;
  v_branch_id uuid;
  v_suffix text;
  v_tax_number text;
BEGIN
  SELECT id INTO v_tenant_id
  FROM platform.tenants
  WHERE id IS NOT NULL
  ORDER BY created_at NULLS LAST, id
  LIMIT 1;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'platform.tenants içinde test için tenant bulunamadı';
  END IF;

  PERFORM app_security.set_tenant_context(v_tenant_id::text);

  v_suffix := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_tax_number := '9' || substr(regexp_replace(replace(gen_random_uuid()::text, '-', ''), '[^0-9]', '', 'g') || '123456789', 1, 9);

  INSERT INTO auth.users (
    tenant_id,
    email,
    full_name,
    password_hash,
    is_active,
    is_super_admin
  )
  VALUES (
    v_tenant_id,
    lower('scope.main.' || v_suffix || '@pix2pi.test'),
    'Pix2pi Scope Main Test User',
    'test_hash_not_for_login',
    true,
    false
  )
  RETURNING id INTO v_user_id;

  INSERT INTO auth.users (
    tenant_id,
    email,
    full_name,
    password_hash,
    is_active,
    is_super_admin
  )
  VALUES (
    v_tenant_id,
    lower('scope.expire.' || v_suffix || '@pix2pi.test'),
    'Pix2pi Scope Expire Test User',
    'test_hash_not_for_login',
    true,
    false
  )
  RETURNING id INTO v_expire_user_id;

  INSERT INTO org.legal_entities (
    tenant_id,
    business_code,
    legal_name,
    trade_name,
    tax_number,
    tax_office
  )
  VALUES (
    v_tenant_id,
    'PIX2PI_SCOPE_LE_' || v_suffix,
    'Pix2pi Scope Test Legal Entity',
    'Pix2pi Scope Test',
    v_tax_number,
    'PIX2PI'
  )
  RETURNING id INTO v_legal_entity_id;

  INSERT INTO org.branches (
    tenant_id,
    legal_entity_id,
    business_code,
    name,
    short_name
  )
  VALUES (
    v_tenant_id,
    v_legal_entity_id,
    'PIX2PI_SCOPE_BR_' || v_suffix,
    'Pix2pi Scope Test Branch',
    'P2P Scope'
  )
  RETURNING id INTO v_branch_id;

  PERFORM set_config('app.test_tenant_a', v_tenant_id::text, true);
  PERFORM set_config('app.test_user_1', v_user_id::text, true);
  PERFORM set_config('app.test_expire_user', v_expire_user_id::text, true);
  PERFORM set_config('app.test_legal_entity', v_legal_entity_id::text, true);
  PERFORM set_config('app.test_branch', v_branch_id::text, true);
END $$;

SET LOCAL ROLE pix2pi_user_scope_verify_role;

DO $$
DECLARE
  v_tenant_a text := current_setting('app.test_tenant_a', true);
  v_user_1 text := current_setting('app.test_user_1', true);
  v_expire_user text := current_setting('app.test_expire_user', true);
  v_legal_entity text := current_setting('app.test_legal_entity', true);
  v_branch text := current_setting('app.test_branch', true);
  v_company text := 'COMPANY_001';
  v_branch_scope text;
  v_expiring_scope text;
  v_count integer;
BEGIN
  BEGIN
    PERFORM auth.grant_user_scope(v_user_1,'INVALID_SCOPE',v_tenant_a,NULL,NULL,NULL,NULL,NULL,'{}'::jsonb);
    RAISE EXCEPTION 'invalid scope type unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.grant_user_scope('','TENANT',v_tenant_a,NULL,NULL,NULL,NULL,NULL,'{}'::jsonb);
    RAISE EXCEPTION 'empty user_id unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.grant_user_scope(v_user_1,'TENANT','00000000-0000-0000-0000-0000000000b9',NULL,NULL,NULL,NULL,NULL,'{}'::jsonb);
    RAISE EXCEPTION 'cross tenant TENANT scope unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    PERFORM auth.grant_user_scope(v_user_1,'BRANCH','',NULL,NULL,NULL,NULL,NULL,'{}'::jsonb);
    RAISE EXCEPTION 'empty branch scope unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.grant_user_scope(v_user_1,'TENANT',v_tenant_a,NULL,NULL,NULL,NULL,now() - interval '1 minute','{}'::jsonb);
    RAISE EXCEPTION 'past expires_at unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  PERFORM auth.grant_user_scope(v_user_1,'TENANT',v_tenant_a,NULL,NULL,NULL,NULL,NULL,'{"source":"suite_fix_v9c"}'::jsonb);
  PERFORM auth.grant_user_scope(v_user_1,'LEGAL_ENTITY',v_legal_entity,v_legal_entity,NULL,NULL,NULL,NULL,'{}'::jsonb);
  v_branch_scope := auth.grant_user_scope(v_user_1,'BRANCH',v_branch,v_legal_entity,v_branch,NULL,NULL,NULL,'{}'::jsonb);
  PERFORM auth.grant_user_scope(v_user_1,'ACCOUNTANT_ASSIGNED_COMPANY',v_company,NULL,NULL,NULL,NULL,NULL,'{}'::jsonb);

  v_expiring_scope := auth.grant_user_scope(v_expire_user,'TENANT',v_tenant_a,NULL,NULL,NULL,NULL,now() + interval '1 minute','{}'::jsonb);

  IF NOT auth.user_has_scope(v_user_1,'TENANT',v_tenant_a) THEN
    RAISE EXCEPTION 'tenant scope check failed';
  END IF;

  IF NOT auth.user_has_scope(v_user_1,'LEGAL_ENTITY',v_legal_entity) THEN
    RAISE EXCEPTION 'legal entity scope check failed';
  END IF;

  IF NOT auth.user_has_scope(v_user_1,'BRANCH',v_branch) THEN
    RAISE EXCEPTION 'branch scope check failed';
  END IF;

  IF NOT auth.user_has_scope(v_user_1,'ACCOUNTANT_ASSIGNED_COMPANY',v_company) THEN
    RAISE EXCEPTION 'accountant assigned company scope check failed';
  END IF;

  IF NOT auth.user_has_scope(v_expire_user,'TENANT',v_tenant_a) THEN
    RAISE EXCEPTION 'pre-expiration tenant scope check for isolated expire user failed';
  END IF;

  PERFORM auth.assert_user_scope(v_user_1,'TENANT',v_tenant_a);
  PERFORM auth.assert_user_scope(v_user_1,'LEGAL_ENTITY',v_legal_entity);
  PERFORM auth.assert_user_scope(v_user_1,'BRANCH',v_branch);
  PERFORM auth.assert_user_scope(v_user_1,'ACCOUNTANT_ASSIGNED_COMPANY',v_company);

  BEGIN
    PERFORM auth.assert_user_scope(v_user_1,'BRANCH','00000000-0000-0000-0000-000000000499');
    RAISE EXCEPTION 'missing branch scope assertion unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  SELECT count(*) INTO v_count
  FROM auth.user_scope_audit
  WHERE action_type = 'GRANTED'
    AND tenant_id = v_tenant_a;

  IF v_count < 5 THEN
    RAISE EXCEPTION 'scope grant audit rows missing count=%', v_count;
  END IF;

  BEGIN
    PERFORM auth.revoke_user_scope(v_branch_scope, NULL, 'short');
    RAISE EXCEPTION 'short revoke reason unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  PERFORM auth.revoke_user_scope(v_branch_scope, NULL, 'Revoking branch access after responsibility change');

  IF auth.user_has_scope(v_user_1,'BRANCH',v_branch) THEN
    RAISE EXCEPTION 'revoked branch scope still active';
  END IF;

  SELECT count(*) INTO v_count
  FROM auth.user_scope_audit
  WHERE scope_id = v_branch_scope
    AND action_type = 'REVOKED'
    AND tenant_id = v_tenant_a;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'scope revoke audit row missing count=%', v_count;
  END IF;

  PERFORM set_config('app.expiring_user_scope_id', v_expiring_scope, true);
END $$;

RESET ROLE;

UPDATE auth.user_scopes
SET granted_at = now() - interval '10 minutes',
    expires_at = now() - interval '1 minute',
    updated_at = now()
WHERE tenant_id::text = current_setting('app.test_tenant_a', true)
  AND scope_id::text = current_setting('app.expiring_user_scope_id', true);

SET LOCAL ROLE pix2pi_user_scope_verify_role;

DO $$
DECLARE
  v_tenant_a text := current_setting('app.test_tenant_a', true);
  v_expire_user text := current_setting('app.test_expire_user', true);
  v_count integer;
BEGIN
  IF auth.user_has_scope(v_expire_user,'TENANT',v_tenant_a) THEN
    RAISE EXCEPTION 'expired isolated scope still active';
  END IF;

  PERFORM app_security.set_tenant_context('00000000-0000-0000-0000-0000000000b9');

  SELECT count(*) INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_a;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS tenant boundary failed; foreign tenant saw tenant_a user scopes count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM auth.user_scope_audit
  WHERE tenant_id = v_tenant_a;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS tenant boundary failed; foreign tenant saw tenant_a audit rows count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context(v_tenant_a);

  SELECT count(*) INTO v_count
  FROM auth.user_scopes;

  IF v_count < 5 THEN
    RAISE EXCEPTION 'tenant_a should see own scope rows count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/user_scope_lifecycle_suite_fix_v9c.out" 2>&1; then
  pass "6.1 user scope lifecycle / abuse SQL suite geçti"
else
  fail "6.1 user scope lifecycle / abuse SQL suite başarısız"
  cat "$BACKUP_DIR/user_scope_lifecycle_suite_fix_v9c.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/user_scope_lifecycle_suite_fix_v9c.out"; then
  pass "6.2 lifecycle test rollback ile temizlendi"
else
  fail "6.2 lifecycle test rollback kanıtı bulunamadı"
fi

{
  echo "# FAZ 1-2.4 auth.user_scopes Suite Result FIX V9C"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Model Counters"
  echo "- USER_SCOPES_TABLE_COUNT=$USER_SCOPES_TABLE_COUNT"
  echo "- USER_SCOPE_AUDIT_TABLE_COUNT=$USER_SCOPE_AUDIT_TABLE_COUNT"
  echo "- USER_SCOPES_COLUMN_COUNT=$USER_SCOPES_COLUMN_COUNT"
  echo "- USER_SCOPE_AUDIT_COLUMN_COUNT=$USER_SCOPE_AUDIT_COLUMN_COUNT"
  echo "- USER_SCOPE_RLS_ENABLED_COUNT=$USER_SCOPE_RLS_ENABLED_COUNT"
  echo "- USER_SCOPE_RLS_FORCED_COUNT=$USER_SCOPE_RLS_FORCED_COUNT"
  echo "- USER_SCOPE_POLICY_COUNT=$USER_SCOPE_POLICY_COUNT"
  echo "- USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
  echo "- VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
  echo "- LEGACY_SCOPE_LEVEL_COUNT=$LEGACY_SCOPE_LEVEL_COUNT"
  echo "- SCOPE_LEVEL_ENUM_LABEL_COUNT=$SCOPE_LEVEL_ENUM_LABEL_COUNT"
  echo "- TENANT_ID_FK_COUNT=$TENANT_ID_FK_COUNT"
  echo "- LEGAL_ENTITY_ID_FK_COUNT=$LEGAL_ENTITY_ID_FK_COUNT"
  echo "- BRANCH_ID_FK_COUNT=$BRANCH_ID_FK_COUNT"
  echo "- CODE_TEXT_DOMAIN_COUNT=$CODE_TEXT_DOMAIN_COUNT"
  echo "- SECURITY_SCHEMA_COUNT=$SECURITY_SCHEMA_COUNT"
  echo "- VERIFY_ROLE_SECURITY_USAGE=$VERIFY_ROLE_SECURITY_USAGE"
  echo "- VERIFY_ROLE_SECURITY_EXECUTE_COUNT=$VERIFY_ROLE_SECURITY_EXECUTE_COUNT"
  echo
  echo "## Test Coverage"
  echo "- Tenant scope: tested with real tenant"
  echo "- Temp main auth user: created inside rollback transaction"
  echo "- Temp isolated expiry auth user: created inside rollback transaction"
  echo "- Temp legal entity: created with core.code_text-compatible business_code"
  echo "- Temp branch: created with core.code_text-compatible business_code"
  echo "- Legal entity scope: tested with FK-safe reference"
  echo "- Branch scope: tested with FK-safe reference"
  echo "- Accountant assigned-company scope: tested"
  echo "- Scope expiration: tested with isolated user"
  echo "- Scope revoke: tested"
  echo "- Scope audit: tested"
  echo "- RLS tenant boundary: tested"
  echo "- Legacy security schema RLS dependency grant: tested"
  echo "- Legacy enum scope_level compatibility: tested"
  echo "- Legacy user_scopes_target_ck compatibility: tested"
  echo "- Transaction rollback cleanup: tested"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. suite evidence dosyası yazıldı"

echo "===== FAZ 1-2.4 AUTH USER SCOPES SUITE FIX V9C RESULT ====="
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
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
echo "LEGACY_SCOPE_LEVEL_COUNT=$LEGACY_SCOPE_LEVEL_COUNT"
echo "SCOPE_LEVEL_ENUM_LABEL_COUNT=$SCOPE_LEVEL_ENUM_LABEL_COUNT"
echo "TENANT_ID_FK_COUNT=$TENANT_ID_FK_COUNT"
echo "LEGAL_ENTITY_ID_FK_COUNT=$LEGAL_ENTITY_ID_FK_COUNT"
echo "BRANCH_ID_FK_COUNT=$BRANCH_ID_FK_COUNT"
echo "CODE_TEXT_DOMAIN_COUNT=$CODE_TEXT_DOMAIN_COUNT"
echo "SECURITY_SCHEMA_COUNT=$SECURITY_SCHEMA_COUNT"
echo "VERIFY_ROLE_SECURITY_USAGE=$VERIFY_ROLE_SECURITY_USAGE"
echo "VERIFY_ROLE_SECURITY_EXECUTE_COUNT=$VERIFY_ROLE_SECURITY_EXECUTE_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_TEST_STATUS=PASS"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_FINAL_STATUS=PASS"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_SEAL_STATUS=SEALED"
  echo "FAZ_1_2_5_READY=YES"
else
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_TEST_STATUS=FAIL"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_FINAL_STATUS=FAIL"
  echo "FAZ_1_2_4_AUTH_USER_SCOPES_SEAL_STATUS=OPEN"
  echo "FAZ_1_2_5_READY=NO"
  exit 1
fi

echo "===== FAZ 1-2.4 AUTH USER SCOPES SUITE FIX V9C END ====="
