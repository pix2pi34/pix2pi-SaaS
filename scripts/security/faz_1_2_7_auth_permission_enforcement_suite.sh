#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
PHASE="FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT"

BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_7_auth_permission_enforcement_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-2.7 AUTH / PERMISSION ENFORCEMENT SUITE START ====="

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

echo "5. DB enforcement foundation sayaçları doğrulanıyor..."

RBAC_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name in ('roles','permissions','role_permissions','user_roles');
")"

RBAC_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','role_permissions','user_roles')
    and c.relrowsecurity=true;
")"

RBAC_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','role_permissions','user_roles')
    and c.relforcerowsecurity=true;
")"

RBAC_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in ('roles','permissions','role_permissions','user_roles')
    and policyname in ('pix2pi_tenant_isolation_allow','pix2pi_tenant_isolation_enforce');
")"

RBAC_FUNCTION_COUNT="$(scalar_count "
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

RBAC_BRIDGE_FUNCTION_COUNT="$(scalar_count "
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

USER_SCOPE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and p.proname in (
      'grant_user_scope',
      'revoke_user_scope',
      'user_has_scope',
      'assert_user_scope'
    );
")"

VERIFY_ROLE_COUNT="$(scalar_count "
  select count(*)
  from pg_roles
  where rolname in (
    'pix2pi_role_permission_verify_role',
    'pix2pi_user_scope_verify_role'
  );
")"

echo "RBAC_TABLE_COUNT=$RBAC_TABLE_COUNT"
echo "RBAC_RLS_ENABLED_COUNT=$RBAC_RLS_ENABLED_COUNT"
echo "RBAC_RLS_FORCED_COUNT=$RBAC_RLS_FORCED_COUNT"
echo "RBAC_POLICY_COUNT=$RBAC_POLICY_COUNT"
echo "RBAC_FUNCTION_COUNT=$RBAC_FUNCTION_COUNT"
echo "RBAC_BRIDGE_FUNCTION_COUNT=$RBAC_BRIDGE_FUNCTION_COUNT"
echo "USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"

[ "$RBAC_TABLE_COUNT" = "4" ] && pass "5.1 RBAC table set hazır" || fail "5.1 RBAC table set eksik actual=$RBAC_TABLE_COUNT"
[ "$RBAC_RLS_ENABLED_COUNT" = "4" ] && pass "5.2 RBAC RLS enabled kapsamı tam" || fail "5.2 RBAC RLS enabled eksik actual=$RBAC_RLS_ENABLED_COUNT"
[ "$RBAC_RLS_FORCED_COUNT" = "4" ] && pass "5.3 RBAC RLS forced kapsamı tam" || fail "5.3 RBAC RLS forced eksik actual=$RBAC_RLS_FORCED_COUNT"
[ "$RBAC_POLICY_COUNT" = "8" ] && pass "5.4 RBAC policy kapsamı tam" || fail "5.4 RBAC policy eksik actual=$RBAC_POLICY_COUNT"
[ "$RBAC_FUNCTION_COUNT" = "6" ] && pass "5.5 RBAC runtime function seti hazır" || fail "5.5 RBAC function seti eksik actual=$RBAC_FUNCTION_COUNT"
[ "$RBAC_BRIDGE_FUNCTION_COUNT" = "3" ] && pass "5.6 RBAC bridge function seti hazır" || fail "5.6 RBAC bridge function seti eksik actual=$RBAC_BRIDGE_FUNCTION_COUNT"
[ "$USER_SCOPE_FUNCTION_COUNT" = "4" ] && pass "5.7 user scope function seti hazır" || fail "5.7 user scope function seti eksik actual=$USER_SCOPE_FUNCTION_COUNT"
[ "$VERIFY_ROLE_COUNT" -ge 2 ] && pass "5.8 verify role seti hazır" || fail "5.8 verify role seti eksik actual=$VERIFY_ROLE_COUNT"

echo "6. repo/API/gateway enforcement static audit çalıştırılıyor..."

ENFORCEMENT_REPO_HIT_COUNT="$(grep -RInE 'rbac_assert_permission|rbac_user_has_permission|rbac_user_has_role|RequirePermission|RequireRole|requirePermission|requireRole|permission guard|auth guard|authorization|forbidden|403|401|Yetki|yetki|izin|rol' \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=vendor \
  --exclude-dir=backups \
  "$REPO" 2>/dev/null | wc -l | tr -d ' ')"

API_PERMISSION_GUARD_HIT_COUNT="$(find "$REPO" -type f \( -name '*.go' -o -name '*.ts' -o -name '*.js' -o -name '*.tsx' -o -name '*.jsx' \) \
  ! -path '*/.git/*' \
  ! -path '*/node_modules/*' \
  ! -path '*/vendor/*' \
  ! -path '*/backups/*' \
  -print0 2>/dev/null | xargs -0 grep -InE 'rbac_assert_permission|rbac_user_has_permission|RequirePermission|RequireRole|requirePermission|requireRole|Forbidden|StatusForbidden|fiber\.StatusForbidden|http\.StatusForbidden|401|403' 2>/dev/null | wc -l | tr -d ' ')"

TEST_ENFORCEMENT_HIT_COUNT="$(find "$REPO" -type f \( -name '*test.go' -o -name '*.sh' -o -name '*.sql' \) \
  ! -path '*/.git/*' \
  ! -path '*/node_modules/*' \
  ! -path '*/vendor/*' \
  ! -path '*/backups/*' \
  -print0 2>/dev/null | xargs -0 grep -InE 'rbac_assert_permission|rbac_user_has_permission|RequirePermission|RequireRole|forbidden|403|401|permission denied|authorization' 2>/dev/null | wc -l | tr -d ' ')"

GATEWAY_AUTH_HIT_COUNT="$(find "$REPO" -type f \( -name '*.go' -o -name '*.md' -o -name '*.sh' \) \
  ! -path '*/.git/*' \
  ! -path '*/node_modules/*' \
  ! -path '*/vendor/*' \
  ! -path '*/backups/*' \
  -print0 2>/dev/null | xargs -0 grep -InE 'api-gateway|gateway|middleware|Bearer|JWT|tenant|X-Tenant-ID|permission|role|forbidden|unauthorized' 2>/dev/null | wc -l | tr -d ' ')"

echo "ENFORCEMENT_REPO_HIT_COUNT=$ENFORCEMENT_REPO_HIT_COUNT"
echo "API_PERMISSION_GUARD_HIT_COUNT=$API_PERMISSION_GUARD_HIT_COUNT"
echo "TEST_ENFORCEMENT_HIT_COUNT=$TEST_ENFORCEMENT_HIT_COUNT"
echo "GATEWAY_AUTH_HIT_COUNT=$GATEWAY_AUTH_HIT_COUNT"

[ "$ENFORCEMENT_REPO_HIT_COUNT" -gt 0 ] && pass "6.1 repo enforcement izleri mevcut" || fail "6.1 repo enforcement izi yok"
[ "$API_PERMISSION_GUARD_HIT_COUNT" -gt 0 ] && pass "6.2 API permission guard izleri mevcut" || fail "6.2 API permission guard izi yok"
[ "$TEST_ENFORCEMENT_HIT_COUNT" -gt 0 ] && pass "6.3 enforcement test izleri mevcut" || fail "6.3 enforcement test izi yok"
[ "$GATEWAY_AUTH_HIT_COUNT" -gt 0 ] && pass "6.4 gateway/auth/middleware izleri mevcut" || fail "6.4 gateway/auth/middleware izi yok"

grep -RInE 'rbac_assert_permission|rbac_user_has_permission|RequirePermission|RequireRole|Forbidden|StatusForbidden|401|403|permission|role' \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=vendor \
  --exclude-dir=backups \
  "$REPO" 2>/dev/null | head -n 300 > "$BACKUP_DIR/enforcement_repo_hits_sample.txt" || true

pass "6.5 static audit sample evidence yazıldı"

echo "7. DB enforcement lifecycle / abuse SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/auth_permission_enforcement_lifecycle_suite.sql"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_tenant_uuid uuid;
  v_tenant_text text;
  v_user_id uuid;
  v_no_permission_user_id uuid;
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
    lower('enforce.allowed.' || v_suffix || '@pix2pi.test'),
    'Pix2pi Enforcement Allowed User',
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
    v_tenant_uuid,
    lower('enforce.denied.' || v_suffix || '@pix2pi.test'),
    'Pix2pi Enforcement Denied User',
    'test_hash_not_for_login',
    true,
    false
  )
  RETURNING id INTO v_no_permission_user_id;

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
    role_key = 'PIX2PI_ENFORCE_ROLE_' || v_suffix,
    role_name = 'Pix2pi Enforcement Test Role',
    status = 'ACTIVE',
    updated_at = now()
  WHERE role_id::text = v_role_row_ref;

  UPDATE auth.permissions
  SET
    tenant_id = v_tenant_uuid,
    permission_key = 'PIX2PI_ENFORCE_PERMISSION_' || v_suffix,
    permission_name = 'Pix2pi Enforcement Test Permission',
    module_key = 'SECURITY',
    action_key = 'ENFORCE',
    status = 'ACTIVE',
    updated_at = now()
  WHERE permission_id::text = v_permission_row_ref;

  PERFORM set_config('app.test_tenant_id', v_tenant_text, true);
  PERFORM set_config('app.test_allowed_user_id', v_user_id::text, true);
  PERFORM set_config('app.test_denied_user_id', v_no_permission_user_id::text, true);
  PERFORM set_config('app.test_role_key', 'PIX2PI_ENFORCE_ROLE_' || v_suffix, true);
  PERFORM set_config('app.test_permission_key', 'PIX2PI_ENFORCE_PERMISSION_' || v_suffix, true);
END $$;

SET LOCAL ROLE pix2pi_role_permission_verify_role;

DO $$
DECLARE
  v_tenant_id text := current_setting('app.test_tenant_id', true);
  v_allowed_user text := current_setting('app.test_allowed_user_id', true);
  v_denied_user text := current_setting('app.test_denied_user_id', true);
  v_role_key text := current_setting('app.test_role_key', true);
  v_permission_key text := current_setting('app.test_permission_key', true);
  v_role_permission_id text;
  v_user_role_id text;
  v_user_scope_id text;
  v_count integer;
BEGIN
  -- Permission must be denied before role/permission link.
  IF auth.rbac_user_has_permission(v_allowed_user, v_permission_key) THEN
    RAISE EXCEPTION 'permission unexpectedly granted before role link';
  END IF;

  BEGIN
    PERFORM auth.rbac_assert_permission(v_allowed_user, v_permission_key);
    RAISE EXCEPTION 'permission assertion unexpectedly allowed before grant';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  v_role_permission_id := auth.rbac_link_role_permission(v_role_key, v_permission_key);

  IF v_role_permission_id IS NULL OR btrim(v_role_permission_id) = '' THEN
    RAISE EXCEPTION 'role_permission_id not returned';
  END IF;

  -- Permission still denied until role is granted to user.
  IF auth.rbac_user_has_permission(v_allowed_user, v_permission_key) THEN
    RAISE EXCEPTION 'permission unexpectedly granted before user role grant';
  END IF;

  v_user_role_id := auth.rbac_grant_role_to_user(
    v_allowed_user,
    v_role_key,
    'TENANT',
    v_tenant_id,
    NULL,
    '{"source":"faz_1_2_7_enforcement_suite"}'::jsonb
  );

  IF v_user_role_id IS NULL OR btrim(v_user_role_id) = '' THEN
    RAISE EXCEPTION 'user_role_id not returned';
  END IF;

  IF NOT auth.rbac_user_has_role(v_allowed_user, v_role_key) THEN
    RAISE EXCEPTION 'role enforcement failed after grant';
  END IF;

  IF NOT auth.rbac_user_has_permission(v_allowed_user, v_permission_key) THEN
    RAISE EXCEPTION 'permission enforcement failed after grant';
  END IF;

  PERFORM auth.rbac_assert_permission(v_allowed_user, v_permission_key);

  -- Denied user must remain denied.
  IF auth.rbac_user_has_role(v_denied_user, v_role_key) THEN
    RAISE EXCEPTION 'denied user unexpectedly has role';
  END IF;

  IF auth.rbac_user_has_permission(v_denied_user, v_permission_key) THEN
    RAISE EXCEPTION 'denied user unexpectedly has permission';
  END IF;

  BEGIN
    PERFORM auth.rbac_assert_permission(v_denied_user, v_permission_key);
    RAISE EXCEPTION 'denied user permission assertion unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- User-scope enforcement path.
  v_user_scope_id := auth.grant_user_scope(
    v_allowed_user,
    'TENANT',
    v_tenant_id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '{"source":"faz_1_2_7_scope_enforcement"}'::jsonb
  );

  IF v_user_scope_id IS NULL OR btrim(v_user_scope_id) = '' THEN
    RAISE EXCEPTION 'user_scope_id not returned';
  END IF;

  IF NOT auth.user_has_scope(v_allowed_user, 'TENANT', v_tenant_id) THEN
    RAISE EXCEPTION 'user scope enforcement failed after grant';
  END IF;

  PERFORM auth.assert_user_scope(v_allowed_user, 'TENANT', v_tenant_id);

  BEGIN
    PERFORM auth.assert_user_scope(v_denied_user, 'TENANT', v_tenant_id);
    RAISE EXCEPTION 'denied user scope assertion unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  -- Revoke role; permission must disappear.
  PERFORM auth.rbac_revoke_user_role(v_user_role_id, NULL, 'Revoking enforcement test role after verification');

  IF auth.rbac_user_has_role(v_allowed_user, v_role_key) THEN
    RAISE EXCEPTION 'revoked role still active in enforcement suite';
  END IF;

  IF auth.rbac_user_has_permission(v_allowed_user, v_permission_key) THEN
    RAISE EXCEPTION 'revoked permission still active in enforcement suite';
  END IF;

  BEGIN
    PERFORM auth.rbac_assert_permission(v_allowed_user, v_permission_key);
    RAISE EXCEPTION 'revoked permission assertion unexpectedly allowed';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id
    AND revoked_at IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'revoked enforcement user role not found count=%', v_count;
  END IF;

  -- RLS tenant boundary: foreign tenant must not see tenant rows.
  PERFORM app_security.set_tenant_context('00000000-0000-0000-0000-0000000000b9');

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS boundary failed; foreign tenant saw user_roles count=%', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS boundary failed; foreign tenant saw user_scopes count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context(v_tenant_id);

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id;

  IF v_count < 1 THEN
    RAISE EXCEPTION 'tenant should see own user_roles count=%', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id;

  IF v_count < 1 THEN
    RAISE EXCEPTION 'tenant should see own user_scopes count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/auth_permission_enforcement_lifecycle_suite.out" 2>&1; then
  pass "7.1 DB enforcement lifecycle / abuse SQL suite geçti"
else
  fail "7.1 DB enforcement lifecycle / abuse SQL suite başarısız"
  cat "$BACKUP_DIR/auth_permission_enforcement_lifecycle_suite.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/auth_permission_enforcement_lifecycle_suite.out"; then
  pass "7.2 lifecycle test rollback ile temizlendi"
else
  fail "7.2 lifecycle test rollback kanıtı bulunamadı"
fi

{
  echo "# FAZ 1-2.7 Auth / Permission Enforcement Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## DB Counters"
  echo "- RBAC_TABLE_COUNT=$RBAC_TABLE_COUNT"
  echo "- RBAC_RLS_ENABLED_COUNT=$RBAC_RLS_ENABLED_COUNT"
  echo "- RBAC_RLS_FORCED_COUNT=$RBAC_RLS_FORCED_COUNT"
  echo "- RBAC_POLICY_COUNT=$RBAC_POLICY_COUNT"
  echo "- RBAC_FUNCTION_COUNT=$RBAC_FUNCTION_COUNT"
  echo "- RBAC_BRIDGE_FUNCTION_COUNT=$RBAC_BRIDGE_FUNCTION_COUNT"
  echo "- USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
  echo "- VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
  echo
  echo "## Static Audit Counters"
  echo "- ENFORCEMENT_REPO_HIT_COUNT=$ENFORCEMENT_REPO_HIT_COUNT"
  echo "- API_PERMISSION_GUARD_HIT_COUNT=$API_PERMISSION_GUARD_HIT_COUNT"
  echo "- TEST_ENFORCEMENT_HIT_COUNT=$TEST_ENFORCEMENT_HIT_COUNT"
  echo "- GATEWAY_AUTH_HIT_COUNT=$GATEWAY_AUTH_HIT_COUNT"
  echo
  echo "## Test Coverage"
  echo "- permission denied before role link: tested"
  echo "- permission denied before user role grant: tested"
  echo "- role grant enforcement: tested"
  echo "- permission grant enforcement: tested"
  echo "- denied user forbidden path: tested"
  echo "- user scope grant enforcement: tested"
  echo "- denied user scope forbidden path: tested"
  echo "- revoke removes permission: tested"
  echo "- RLS tenant boundary for user_roles: tested"
  echo "- RLS tenant boundary for user_scopes: tested"
  echo "- rollback cleanup: tested"
  echo "- static API/gateway guard traces: tested"
  echo
  echo "## Final"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8. suite evidence dosyası yazıldı"

echo "===== FAZ 1-2.7 AUTH / PERMISSION ENFORCEMENT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "RBAC_TABLE_COUNT=$RBAC_TABLE_COUNT"
echo "RBAC_RLS_ENABLED_COUNT=$RBAC_RLS_ENABLED_COUNT"
echo "RBAC_RLS_FORCED_COUNT=$RBAC_RLS_FORCED_COUNT"
echo "RBAC_POLICY_COUNT=$RBAC_POLICY_COUNT"
echo "RBAC_FUNCTION_COUNT=$RBAC_FUNCTION_COUNT"
echo "RBAC_BRIDGE_FUNCTION_COUNT=$RBAC_BRIDGE_FUNCTION_COUNT"
echo "USER_SCOPE_FUNCTION_COUNT=$USER_SCOPE_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
echo "ENFORCEMENT_REPO_HIT_COUNT=$ENFORCEMENT_REPO_HIT_COUNT"
echo "API_PERMISSION_GUARD_HIT_COUNT=$API_PERMISSION_GUARD_HIT_COUNT"
echo "TEST_ENFORCEMENT_HIT_COUNT=$TEST_ENFORCEMENT_HIT_COUNT"
echo "GATEWAY_AUTH_HIT_COUNT=$GATEWAY_AUTH_HIT_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_TEST_STATUS=PASS"
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_FINAL_STATUS=PASS"
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_SEAL_STATUS=SEALED"
  echo "FAZ_1_2_9_READY=YES"
else
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_FINAL_STATUS=FAIL"
  echo "FAZ_1_2_7_AUTH_PERMISSION_ENFORCEMENT_SEAL_STATUS=OPEN"
  echo "FAZ_1_2_9_READY=NO"
  exit 1
fi

echo "===== FAZ 1-2.7 AUTH / PERMISSION ENFORCEMENT SUITE END ====="
