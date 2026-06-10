#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
PHASE="FAZ_1_2_5_ROLE_PERMISSION"

BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_5_role_permission_suite_fix_v3_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_SUITE_RESULT_FIX_V3_$TS.md"

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

echo "===== FAZ 1-2.5 ROLE / PERMISSION SUITE FIX V3 START ====="

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

AUTH_ROLE_TABLE_COUNT="$(scalar_count "select count(*) from information_schema.tables where table_schema='auth' and table_name in ('roles','permissions','role_permissions','user_roles');")"

AUTH_ROLE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('roles','permissions','role_permissions','user_roles')
    and column_name in (
      'tenant_id','role_id','role_key','role_name','permission_id','permission_key',
      'permission_name','role_permission_id','user_role_id','user_id','scope_type',
      'scope_value','status','is_system','metadata','created_at','updated_at',
      'granted_at','revoked_at'
    );
")"

AUTH_ROLE_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','role_permissions','user_roles')
    and c.relrowsecurity=true;
")"

AUTH_ROLE_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','role_permissions','user_roles')
    and c.relforcerowsecurity=true;
")"

AUTH_ROLE_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in ('roles','permissions','role_permissions','user_roles')
    and policyname in ('pix2pi_tenant_isolation_allow','pix2pi_tenant_isolation_enforce');
")"

AUTH_ROLE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and p.proname in (
      'rbac_link_role_permission',
      'rbac_grant_role_to_user',
      'rbac_revoke_user_role',
      'rbac_user_has_role',
      'rbac_user_has_permission',
      'rbac_assert_permission'
    );
")"

RBAC_REF_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and p.proname in (
      'rbac_role_ref_value',
      'rbac_permission_ref_value',
      'rbac_permission_ref_matches'
    );
")"

VERIFY_ROLE_COUNT="$(scalar_count "select count(*) from pg_roles where rolname='pix2pi_role_permission_verify_role';")"

VERIFY_ROLE_AUTH_USAGE="$(scalar_text "select case when has_schema_privilege('pix2pi_role_permission_verify_role','auth','USAGE') then 'YES' else 'NO' end;")"
VERIFY_ROLE_APPSEC_USAGE="$(scalar_text "select case when has_schema_privilege('pix2pi_role_permission_verify_role','app_security','USAGE') then 'YES' else 'NO' end;")"
VERIFY_ROLE_SECURITY_USAGE="$(scalar_text "select case when has_schema_privilege('pix2pi_role_permission_verify_role','security','USAGE') then 'YES' else 'NO' end;")"

BRIDGE_UUID_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('role_permissions','user_roles')
    and column_name in ('role_id','permission_id')
    and udt_name='uuid';
")"

echo "AUTH_ROLE_TABLE_COUNT=$AUTH_ROLE_TABLE_COUNT"
echo "AUTH_ROLE_COLUMN_COUNT=$AUTH_ROLE_COLUMN_COUNT"
echo "AUTH_ROLE_RLS_ENABLED_COUNT=$AUTH_ROLE_RLS_ENABLED_COUNT"
echo "AUTH_ROLE_RLS_FORCED_COUNT=$AUTH_ROLE_RLS_FORCED_COUNT"
echo "AUTH_ROLE_POLICY_COUNT=$AUTH_ROLE_POLICY_COUNT"
echo "AUTH_ROLE_FUNCTION_COUNT=$AUTH_ROLE_FUNCTION_COUNT"
echo "RBAC_REF_FUNCTION_COUNT=$RBAC_REF_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
echo "VERIFY_ROLE_AUTH_USAGE=$VERIFY_ROLE_AUTH_USAGE"
echo "VERIFY_ROLE_APPSEC_USAGE=$VERIFY_ROLE_APPSEC_USAGE"
echo "VERIFY_ROLE_SECURITY_USAGE=$VERIFY_ROLE_SECURITY_USAGE"
echo "BRIDGE_UUID_COLUMN_COUNT=$BRIDGE_UUID_COLUMN_COUNT"

[ "$AUTH_ROLE_TABLE_COUNT" = "4" ] && pass "5.1 canonical role/permission tablo seti hazır" || fail "5.1 canonical tablo seti eksik actual=$AUTH_ROLE_TABLE_COUNT"
[ "$AUTH_ROLE_COLUMN_COUNT" -ge 30 ] && pass "5.2 canonical role/permission kolon kapsamı yeterli" || fail "5.2 canonical kolon kapsamı eksik actual=$AUTH_ROLE_COLUMN_COUNT"
[ "$AUTH_ROLE_RLS_ENABLED_COUNT" = "4" ] && pass "5.3 role/permission RLS enabled kapsamı tam" || fail "5.3 RLS enabled eksik actual=$AUTH_ROLE_RLS_ENABLED_COUNT"
[ "$AUTH_ROLE_RLS_FORCED_COUNT" = "4" ] && pass "5.4 role/permission RLS forced kapsamı tam" || fail "5.4 RLS forced eksik actual=$AUTH_ROLE_RLS_FORCED_COUNT"
[ "$AUTH_ROLE_POLICY_COUNT" = "8" ] && pass "5.5 role/permission tenant isolation policy kapsamı tam" || fail "5.5 policy kapsamı eksik actual=$AUTH_ROLE_POLICY_COUNT"
[ "$AUTH_ROLE_FUNCTION_COUNT" = "6" ] && pass "5.6 RBAC runtime function seti hazır" || fail "5.6 RBAC function seti eksik actual=$AUTH_ROLE_FUNCTION_COUNT"
[ "$RBAC_REF_FUNCTION_COUNT" = "3" ] && pass "5.7 RBAC legacy id bridge function seti hazır" || fail "5.7 RBAC legacy id bridge function seti eksik actual=$RBAC_REF_FUNCTION_COUNT"
[ "$VERIFY_ROLE_COUNT" = "1" ] && pass "5.8 verify role hazır" || fail "5.8 verify role eksik"
[ "$VERIFY_ROLE_AUTH_USAGE" = "YES" ] && pass "5.9 verify role auth usage sahibi" || fail "5.9 auth usage eksik"
[ "$VERIFY_ROLE_APPSEC_USAGE" = "YES" ] && pass "5.10 verify role app_security usage sahibi" || fail "5.10 app_security usage eksik"
[ "$VERIFY_ROLE_SECURITY_USAGE" = "YES" ] && pass "5.11 verify role security usage sahibi" || fail "5.11 security usage eksik"
[ "$BRIDGE_UUID_COLUMN_COUNT" -ge 1 ] && pass "5.12 bridge UUID kolonları algılandı; legacy id bridge aktif" || pass "5.12 bridge UUID kolon yok; text bridge uyumu aktif"

echo "6. RBAC lifecycle / abuse SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/role_permission_lifecycle_suite_fix_v3.sql"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_tenant_uuid uuid;
  v_tenant_text text;
  v_user_id uuid;
  v_role_row_ref text;
  v_permission_row_ref text;
  v_suffix text;
BEGIN
  SELECT id INTO v_tenant_uuid
  FROM platform.tenants
  WHERE id IS NOT NULL
  ORDER BY created_at NULLS LAST, id
  LIMIT 1;

  IF v_tenant_uuid IS NULL THEN
    RAISE EXCEPTION 'platform.tenants içinde test için tenant bulunamadı';
  END IF;

  v_tenant_text := v_tenant_uuid::text;

  PERFORM app_security.set_tenant_context(v_tenant_text);

  v_suffix := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));

  INSERT INTO auth.users (
    tenant_id,
    email,
    full_name,
    password_hash,
    is_active,
    is_super_admin
  )
  VALUES (
    v_tenant_uuid,
    lower('rbac.' || v_suffix || '@pix2pi.test'),
    'Pix2pi RBAC Test User',
    'test_hash_not_for_login',
    true,
    false
  )
  RETURNING id INTO v_user_id;

  SELECT role_id::text
  INTO v_role_row_ref
  FROM auth.roles
  WHERE role_id IS NOT NULL
  LIMIT 1;

  IF v_role_row_ref IS NULL THEN
    RAISE EXCEPTION 'auth.roles içinde test için role row bulunamadı';
  END IF;

  SELECT permission_id::text
  INTO v_permission_row_ref
  FROM auth.permissions
  WHERE permission_id IS NOT NULL
  LIMIT 1;

  IF v_permission_row_ref IS NULL THEN
    RAISE EXCEPTION 'auth.permissions içinde test için permission row bulunamadı';
  END IF;

  UPDATE auth.roles
  SET
    tenant_id = v_tenant_uuid,
    role_key = 'PIX2PI_RBAC_ROLE_' || v_suffix,
    role_name = 'Pix2pi RBAC Test Role',
    status = 'ACTIVE',
    updated_at = now()
  WHERE role_id::text = v_role_row_ref;

  UPDATE auth.permissions
  SET
    tenant_id = v_tenant_uuid,
    permission_key = 'PIX2PI_RBAC_PERMISSION_' || v_suffix,
    permission_name = 'Pix2pi RBAC Test Permission',
    module_key = 'SECURITY',
    action_key = 'READ',
    status = 'ACTIVE',
    updated_at = now()
  WHERE permission_id::text = v_permission_row_ref;

  PERFORM set_config('app.test_tenant_id', v_tenant_text, true);
  PERFORM set_config('app.test_user_id', v_user_id::text, true);
  PERFORM set_config('app.test_role_key', 'PIX2PI_RBAC_ROLE_' || v_suffix, true);
  PERFORM set_config('app.test_permission_key', 'PIX2PI_RBAC_PERMISSION_' || v_suffix, true);
END $$;

SET LOCAL ROLE pix2pi_role_permission_verify_role;

DO $$
DECLARE
  v_tenant_id text := current_setting('app.test_tenant_id', true);
  v_user_id text := current_setting('app.test_user_id', true);
  v_role_key text := current_setting('app.test_role_key', true);
  v_permission_key text := current_setting('app.test_permission_key', true);
  v_role_permission_id text;
  v_user_role_id text;
  v_role_ref text;
  v_permission_ref text;
  v_count integer;
BEGIN
  BEGIN
    PERFORM auth.rbac_grant_role_to_user('', v_role_key);
    RAISE EXCEPTION 'empty user_id unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.rbac_grant_role_to_user(v_user_id, '');
    RAISE EXCEPTION 'empty role_key unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.rbac_grant_role_to_user(v_user_id, v_role_key, 'INVALID_SCOPE', NULL);
    RAISE EXCEPTION 'invalid scope unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.rbac_link_role_permission('MISSING_ROLE_FOR_TEST', v_permission_key);
    RAISE EXCEPTION 'missing role unexpectedly linked';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  BEGIN
    PERFORM auth.rbac_link_role_permission(v_role_key, 'MISSING_PERMISSION_FOR_TEST');
    RAISE EXCEPTION 'missing permission unexpectedly linked';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  v_role_ref := auth.rbac_role_ref_value(v_role_key, 'role_permissions', 'role_id');
  v_permission_ref := auth.rbac_permission_ref_value(v_permission_key, 'role_permissions', 'permission_id');

  IF v_role_ref IS NULL OR btrim(v_role_ref) = '' THEN
    RAISE EXCEPTION 'role bridge reference empty';
  END IF;

  IF v_permission_ref IS NULL OR btrim(v_permission_ref) = '' THEN
    RAISE EXCEPTION 'permission bridge reference empty';
  END IF;

  v_role_permission_id := auth.rbac_link_role_permission(v_role_key, v_permission_key);

  IF v_role_permission_id IS NULL OR btrim(v_role_permission_id) = '' THEN
    RAISE EXCEPTION 'role_permission_id not returned';
  END IF;

  v_user_role_id := auth.rbac_grant_role_to_user(
    v_user_id,
    v_role_key,
    'TENANT',
    v_tenant_id,
    NULL,
    '{"source":"faz_1_2_5_suite_fix_v3"}'::jsonb
  );

  IF v_user_role_id IS NULL OR btrim(v_user_role_id) = '' THEN
    RAISE EXCEPTION 'user_role_id not returned';
  END IF;

  IF NOT auth.rbac_user_has_role(v_user_id, v_role_key) THEN
    RAISE EXCEPTION 'user role check failed';
  END IF;

  IF NOT auth.rbac_user_has_permission(v_user_id, v_permission_key) THEN
    RAISE EXCEPTION 'user permission check failed';
  END IF;

  PERFORM auth.rbac_assert_permission(v_user_id, v_permission_key);

  BEGIN
    PERFORM auth.rbac_assert_permission(v_user_id, 'MISSING_PERMISSION_ASSERT');
    RAISE EXCEPTION 'missing permission assertion unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    PERFORM auth.rbac_revoke_user_role(v_user_role_id, NULL, 'short');
    RAISE EXCEPTION 'short revoke reason unexpectedly allowed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  PERFORM auth.rbac_revoke_user_role(v_user_role_id, NULL, 'Revoking RBAC test role after verification');

  IF auth.rbac_user_has_role(v_user_id, v_role_key) THEN
    RAISE EXCEPTION 'revoked role still active';
  END IF;

  IF auth.rbac_user_has_permission(v_user_id, v_permission_key) THEN
    RAISE EXCEPTION 'revoked role permission still active';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id
    AND revoked_at IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'revoked user_role row not found count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context('00000000-0000-0000-0000-0000000000b9');

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS tenant boundary failed; foreign tenant saw user_roles count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context(v_tenant_id);

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id;

  IF v_count < 1 THEN
    RAISE EXCEPTION 'tenant should see own user_roles count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/role_permission_lifecycle_suite_fix_v3.out" 2>&1; then
  pass "6.1 RBAC lifecycle / abuse SQL suite geçti"
else
  fail "6.1 RBAC lifecycle / abuse SQL suite başarısız"
  cat "$BACKUP_DIR/role_permission_lifecycle_suite_fix_v3.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/role_permission_lifecycle_suite_fix_v3.out"; then
  pass "6.2 lifecycle test rollback ile temizlendi"
else
  fail "6.2 lifecycle test rollback kanıtı bulunamadı"
fi

{
  echo "# FAZ 1-2.5 Role / Permission Suite Result FIX V3"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Counters"
  echo "- AUTH_ROLE_TABLE_COUNT=$AUTH_ROLE_TABLE_COUNT"
  echo "- AUTH_ROLE_COLUMN_COUNT=$AUTH_ROLE_COLUMN_COUNT"
  echo "- AUTH_ROLE_RLS_ENABLED_COUNT=$AUTH_ROLE_RLS_ENABLED_COUNT"
  echo "- AUTH_ROLE_RLS_FORCED_COUNT=$AUTH_ROLE_RLS_FORCED_COUNT"
  echo "- AUTH_ROLE_POLICY_COUNT=$AUTH_ROLE_POLICY_COUNT"
  echo "- AUTH_ROLE_FUNCTION_COUNT=$AUTH_ROLE_FUNCTION_COUNT"
  echo "- RBAC_REF_FUNCTION_COUNT=$RBAC_REF_FUNCTION_COUNT"
  echo "- VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
  echo "- BRIDGE_UUID_COLUMN_COUNT=$BRIDGE_UUID_COLUMN_COUNT"
  echo
  echo "## Test Coverage"
  echo "- role_permission link: tested"
  echo "- legacy role_id/id bridge: tested"
  echo "- legacy permission_id/id bridge: tested"
  echo "- user role grant: tested"
  echo "- user role revoke: tested"
  echo "- user has role: tested"
  echo "- user has permission: tested"
  echo "- assert permission: tested"
  echo "- negative abuse cases: tested"
  echo "- RLS tenant boundary: tested"
  echo "- rollback cleanup: tested"
  echo
  echo "## Final"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. suite evidence dosyası yazıldı"

echo "===== FAZ 1-2.5 ROLE / PERMISSION SUITE FIX V3 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "AUTH_ROLE_TABLE_COUNT=$AUTH_ROLE_TABLE_COUNT"
echo "AUTH_ROLE_COLUMN_COUNT=$AUTH_ROLE_COLUMN_COUNT"
echo "AUTH_ROLE_RLS_ENABLED_COUNT=$AUTH_ROLE_RLS_ENABLED_COUNT"
echo "AUTH_ROLE_RLS_FORCED_COUNT=$AUTH_ROLE_RLS_FORCED_COUNT"
echo "AUTH_ROLE_POLICY_COUNT=$AUTH_ROLE_POLICY_COUNT"
echo "AUTH_ROLE_FUNCTION_COUNT=$AUTH_ROLE_FUNCTION_COUNT"
echo "RBAC_REF_FUNCTION_COUNT=$RBAC_REF_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
echo "BRIDGE_UUID_COLUMN_COUNT=$BRIDGE_UUID_COLUMN_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_5_ROLE_PERMISSION_TEST_STATUS=PASS"
  echo "FAZ_1_2_5_ROLE_PERMISSION_FINAL_STATUS=PASS"
  echo "FAZ_1_2_5_ROLE_PERMISSION_SEAL_STATUS=SEALED"
  echo "FAZ_1_2_7_READY=YES"
else
  echo "FAZ_1_2_5_ROLE_PERMISSION_TEST_STATUS=FAIL"
  echo "FAZ_1_2_5_ROLE_PERMISSION_FINAL_STATUS=FAIL"
  echo "FAZ_1_2_5_ROLE_PERMISSION_SEAL_STATUS=OPEN"
  echo "FAZ_1_2_7_READY=NO"
  exit 1
fi

echo "===== FAZ 1-2.5 ROLE / PERMISSION SUITE FIX V3 END ====="
