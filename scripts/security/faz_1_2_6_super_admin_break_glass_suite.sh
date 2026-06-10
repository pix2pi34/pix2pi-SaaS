#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
PHASE="FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS"

BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_6_super_admin_break_glass_suite_fix_v4_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/${PHASE}_SUITE_RESULT_FIX_V4_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "$1 / FAIL ❌"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "$1 / WARN ⚠️"
}

scalar_count() {
  local sql="$1"
  psql "$DSN" -Atqc "$sql" 2>/dev/null | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}'
}

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS SUITE FIX V4 START ====="

mkdir -p "$BACKUP_DIR" "$EVIDENCE_DIR"

cd "$REPO"

if [ -f "/opt/pix2pi/orchestrator/env/common.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "/opt/pix2pi/orchestrator/env/common.env"
  set +a
  pass "1.1 common.env yüklendi"
else
  warn "1.1 common.env bulunamadı"
fi

if [ -f "$REPO/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO/.env"
  set +a
  pass "1.2 repo .env yüklendi"
else
  warn "1.2 repo .env bulunamadı"
fi

DSN="${DB_WRITE_DSN:-${DATABASE_URL:-${POSTGRES_DSN:-${PG_DSN:-}}}}"

if [ -n "$DSN" ]; then
  pass "2. DB DSN bulundu"
else
  fail "2. DB DSN bulunamadı"
  exit 1
fi

if command -v psql >/dev/null 2>&1; then
  pass "3. psql mevcut"
else
  fail "3. psql bulunamadı"
  exit 1
fi

if psql "$DSN" -Atqc "select 1;" >/dev/null 2>&1; then
  pass "4. DB bağlantısı başarılı"
else
  fail "4. DB bağlantısı başarısız"
  exit 1
fi

echo "5. model/table/function sayaçları doğrulanıyor..."

CANONICAL_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema = 'auth'
    and table_name in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    );
")"

CANONICAL_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'auth'
    and c.relname in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and c.relrowsecurity = true;
")"

CANONICAL_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'auth'
    and c.relname in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and c.relforcerowsecurity = true;
")"

CANONICAL_ALLOW_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname = 'auth'
    and tablename in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and policyname = 'pix2pi_tenant_isolation_allow';
")"

CANONICAL_ENFORCE_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname = 'auth'
    and tablename in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and policyname = 'pix2pi_tenant_isolation_enforce';
")"

BREAK_GLASS_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'auth'
    and p.proname in (
      'security_generated_id',
      'request_break_glass',
      'approve_break_glass',
      'record_admin_action',
      'close_break_glass'
    );
")"

SUPER_ADMIN_SEED_COUNT="$(
  psql "$DSN" -v ON_ERROR_STOP=1 -At <<'SQL' | awk '/^[0-9]+$/ {v=$1} END{if(v=="") print 0; else print v}'
SET app.tenant_id = 'platform';
SELECT count(*)
FROM auth.super_admin_principals
WHERE tenant_id = 'platform'
  AND principal_id = 'super_admin_role'
  AND role_code = 'SUPER_ADMIN'
  AND status = 'ACTIVE'
  AND requires_break_glass = true;
RESET app.tenant_id;
SQL
)"

echo "CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
echo "CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
echo "CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
echo "CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
echo "CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
echo "BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
echo "SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"

if [ "$CANONICAL_TABLE_COUNT" = "4" ]; then
  pass "5.1 canonical security tables hazır"
else
  fail "5.1 canonical security tables eksik"
fi

if [ "$CANONICAL_RLS_ENABLED_COUNT" = "4" ]; then
  pass "5.2 canonical tables RLS enabled"
else
  fail "5.2 canonical tables RLS enabled eksik"
fi

if [ "$CANONICAL_RLS_FORCED_COUNT" = "4" ]; then
  pass "5.3 canonical tables RLS forced"
else
  fail "5.3 canonical tables RLS forced eksik"
fi

if [ "$CANONICAL_ALLOW_POLICY_COUNT" = "4" ]; then
  pass "5.4 canonical allow policy kapsamı tam"
else
  fail "5.4 canonical allow policy kapsamı eksik"
fi

if [ "$CANONICAL_ENFORCE_POLICY_COUNT" = "4" ]; then
  pass "5.5 canonical enforce policy kapsamı tam"
else
  fail "5.5 canonical enforce policy kapsamı eksik"
fi

if [ "$BREAK_GLASS_FUNCTION_COUNT" = "5" ]; then
  pass "5.6 break-glass function seti hazır"
else
  fail "5.6 break-glass function seti eksik"
fi

if [ "$SUPER_ADMIN_SEED_COUNT" = "1" ]; then
  pass "5.7 super-admin seed row hazır"
else
  fail "5.7 super-admin seed row eksik actual=$SUPER_ADMIN_SEED_COUNT"
fi

echo "6. break-glass abuse / lifecycle SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/super_admin_break_glass_lifecycle_suite_fix_v4.sql"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

-- DO bloğu dışında SELECT doğru kullanımdır.
SELECT app_security.set_tenant_context('platform');

SET LOCAL ROLE pix2pi_break_glass_verify_role;

DO $$
DECLARE
  v_session_id text;
  v_expired_session_id text;
  v_action_id text;
  v_count integer;
BEGIN
  BEGIN
    PERFORM auth.request_break_glass(
      'user_super_admin',
      'tenant_target',
      '',
      15,
      '{}'::jsonb
    );

    RAISE EXCEPTION 'empty reason unexpectedly allowed';
  EXCEPTION
    WHEN invalid_parameter_value OR check_violation THEN
      NULL;
  END;

  BEGIN
    PERFORM auth.request_break_glass(
      'user_super_admin',
      'tenant_target',
      'short',
      15,
      '{}'::jsonb
    );

    RAISE EXCEPTION 'short reason unexpectedly allowed';
  EXCEPTION
    WHEN invalid_parameter_value OR check_violation THEN
      NULL;
  END;

  BEGIN
    PERFORM auth.request_break_glass(
      'user_super_admin',
      'tenant_target',
      'Valid emergency access reason for support case',
      500,
      '{}'::jsonb
    );

    RAISE EXCEPTION 'too long duration unexpectedly allowed';
  EXCEPTION
    WHEN invalid_parameter_value OR check_violation THEN
      NULL;
  END;

  v_session_id := auth.request_break_glass(
    'user_super_admin',
    'tenant_target',
    'Valid emergency access reason for support case',
    15,
    '{"case_id":"CASE-001"}'::jsonb
  );

  IF v_session_id IS NULL OR btrim(v_session_id) = '' THEN
    RAISE EXCEPTION 'valid break-glass request did not return session id';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.break_glass_access_sessions
  WHERE session_id = v_session_id
    AND status = 'REQUESTED'
    AND reason = 'Valid emergency access reason for support case'
    AND expires_at > now();

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'break-glass request row validation failed count=%', v_count;
  END IF;

  PERFORM auth.approve_break_glass(v_session_id, 'security_approver');

  SELECT count(*)
  INTO v_count
  FROM auth.break_glass_access_sessions
  WHERE session_id = v_session_id
    AND status = 'ACTIVE'
    AND approved_by = 'security_approver'
    AND approved_at IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'break-glass approval validation failed count=%', v_count;
  END IF;

  BEGIN
    PERFORM auth.record_admin_action(
      v_session_id,
      'TENANT_DATA_READ',
      'short',
      '{"resource":"customer"}'::jsonb
    );

    RAISE EXCEPTION 'admin action with short reason unexpectedly allowed';
  EXCEPTION
    WHEN invalid_parameter_value OR check_violation THEN
      NULL;
  END;

  v_action_id := auth.record_admin_action(
    v_session_id,
    'TENANT_DATA_READ',
    'Valid privileged action reason for incident response',
    '{"resource":"customer"}'::jsonb
  );

  IF v_action_id IS NULL OR btrim(v_action_id) = '' THEN
    RAISE EXCEPTION 'admin action did not return action id';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.admin_action_audit
  WHERE action_id = v_action_id
    AND break_glass_session_id = v_session_id
    AND action_type = 'TENANT_DATA_READ';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'admin action audit row validation failed count=%', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.security_alerts
  WHERE break_glass_session_id = v_session_id
    AND alert_type IN (
      'BREAK_GLASS_REQUESTED',
      'BREAK_GLASS_APPROVED',
      'ADMIN_ACTION_RECORDED'
    );

  IF v_count < 3 THEN
    RAISE EXCEPTION 'security alert production failed count=%', v_count;
  END IF;

  PERFORM auth.close_break_glass(
    v_session_id,
    'Closing emergency access after incident response'
  );

  SELECT count(*)
  INTO v_count
  FROM auth.break_glass_access_sessions
  WHERE session_id = v_session_id
    AND status = 'CLOSED'
    AND closed_at IS NOT NULL;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'break-glass close validation failed count=%', v_count;
  END IF;

  BEGIN
    PERFORM auth.record_admin_action(
      v_session_id,
      'AFTER_CLOSE_ACTION',
      'Valid reason but closed session must reject action',
      '{}'::jsonb
    );

    RAISE EXCEPTION 'admin action after close unexpectedly allowed';
  EXCEPTION
    WHEN insufficient_privilege THEN
      NULL;
  END;

  v_expired_session_id := auth.request_break_glass(
    'user_super_admin',
    'tenant_target',
    'Valid reason for soon expired emergency access',
    1,
    '{}'::jsonb
  );

  PERFORM auth.approve_break_glass(v_expired_session_id, 'security_approver');

  PERFORM set_config('app.expired_break_glass_session_id', v_expired_session_id, true);
END $$;

RESET ROLE;

UPDATE auth.break_glass_access_sessions
SET
  requested_at = now() - interval '10 minutes',
  approved_at = now() - interval '9 minutes',
  expires_at = now() - interval '1 minute',
  updated_at = now()
WHERE tenant_id = 'platform'
  AND session_id = current_setting('app.expired_break_glass_session_id', true);

SET LOCAL ROLE pix2pi_break_glass_verify_role;

DO $$
DECLARE
  v_expired_session_id text;
  v_count integer;
BEGIN
  v_expired_session_id := current_setting('app.expired_break_glass_session_id', true);

  IF v_expired_session_id IS NULL OR btrim(v_expired_session_id) = '' THEN
    RAISE EXCEPTION 'expired session id was not stored in app context';
  END IF;

  BEGIN
    PERFORM auth.record_admin_action(
      v_expired_session_id,
      'EXPIRED_SESSION_ACTION',
      'Valid reason but expired session must reject action',
      '{}'::jsonb
    );

    RAISE EXCEPTION 'admin action with expired session unexpectedly allowed';
  EXCEPTION
    WHEN insufficient_privilege THEN
      NULL;
  END;

  PERFORM app_security.set_tenant_context('other_tenant');

  SELECT count(*)
  INTO v_count
  FROM auth.break_glass_access_sessions
  WHERE tenant_id = 'platform';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RLS tenant boundary failed; other_tenant saw platform rows count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context('platform');

  SELECT count(*)
  INTO v_count
  FROM auth.break_glass_access_sessions;

  IF v_count < 2 THEN
    RAISE EXCEPTION 'platform tenant should see own break-glass rows count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/super_admin_break_glass_lifecycle_suite_fix_v4.out" 2>&1; then
  pass "6.1 break-glass lifecycle / abuse SQL suite geçti"
else
  fail "6.1 break-glass lifecycle / abuse SQL suite başarısız"
  cat "$BACKUP_DIR/super_admin_break_glass_lifecycle_suite_fix_v4.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/super_admin_break_glass_lifecycle_suite_fix_v4.out"; then
  pass "6.2 lifecycle test rollback ile temizlendi"
else
  fail "6.2 lifecycle test rollback kanıtı bulunamadı"
fi

{
  echo "# FAZ 1-2.6 Super-admin / Break-glass Suite Result FIX V4"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Model Counters"
  echo
  echo "- CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
  echo "- CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
  echo "- CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
  echo "- CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
  echo "- CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
  echo "- BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
  echo "- SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"
  echo
  echo "## Test Coverage"
  echo
  echo "- Super-admin role model: tested"
  echo "- Break-glass reason required: tested"
  echo "- Time-bound access: tested"
  echo "- Expired session rejection: tested without violating schema constraint"
  echo "- Closed session rejection: tested"
  echo "- Admin action audit: tested"
  echo "- Security alert production: tested"
  echo "- Tenant-safe RLS boundary: tested"
  echo "- Transaction rollback cleanup: tested"
  echo
  echo "## Final Counters"
  echo
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

if [ -s "$EVIDENCE_FILE" ]; then
  pass "7. suite evidence dosyası yazıldı"
else
  fail "7. suite evidence dosyası yazılamadı"
fi

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS SUITE FIX V4 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
echo "CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
echo "CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
echo "CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
echo "CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
echo "BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
echo "SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_TEST_STATUS=PASS"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_FINAL_STATUS=PASS"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_SEAL_STATUS=SEALED"
  echo "FAZ_1_2_4_READY=YES"
else
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_TEST_STATUS=FAIL"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_FINAL_STATUS=FAIL"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_SEAL_STATUS=OPEN"
  echo "FAZ_1_2_4_READY=NO"
  exit 1
fi

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS SUITE FIX V4 END ====="
