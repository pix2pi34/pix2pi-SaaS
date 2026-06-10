#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_3_rls_bypass_cross_tenant_suite_fix_v3b_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_3_RLS_BYPASS_CROSS_TENANT_SUITE_RESULT_FIX_V3B_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "$1 / FAIL ❌"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "$1 / WARN ⚠️"; }

echo "===== FAZ 1-2.3 RLS BYPASS / CROSS-TENANT SUITE FIX V3B START ====="

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

SQL_SUITE_FILE="$BACKUP_DIR/rls_bypass_cross_tenant_sql_suite_fix_v3b.sql"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_tenant_uuid uuid;
  v_tenant_text text;
  v_other_tenant text := '00000000-0000-0000-0000-0000000000b9';
  v_user_id uuid;
  v_role_row_ref text;
  v_suffix text;
  v_user_role_id text;
  v_scope_id text;
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
    lower('rls.verify.' || v_suffix || '@pix2pi.test'),
    'Pix2pi RLS Verify User',
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

  UPDATE auth.roles
  SET
    tenant_id = v_tenant_uuid,
    role_key = 'PIX2PI_RLS_VERIFY_ROLE_' || v_suffix,
    role_name = 'Pix2pi RLS Verify Role',
    status = 'ACTIVE',
    updated_at = now()
  WHERE role_id::text = v_role_row_ref;

  v_user_role_id := auth.rbac_grant_role_to_user(
    v_user_id::text,
    'PIX2PI_RLS_VERIFY_ROLE_' || v_suffix,
    'TENANT',
    v_tenant_text,
    NULL,
    '{"source":"faz_1_2_3_rls_bypass_cross_tenant_fix_v3b"}'::jsonb
  );

  v_scope_id := auth.grant_user_scope(
    v_user_id::text,
    'TENANT',
    v_tenant_text,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '{"source":"faz_1_2_3_rls_bypass_cross_tenant_fix_v3b"}'::jsonb
  );

  PERFORM set_config('app.test_tenant_id', v_tenant_text, true);
  PERFORM set_config('app.test_other_tenant_id', v_other_tenant, true);
  PERFORM set_config('app.test_user_role_id', v_user_role_id, true);
  PERFORM set_config('app.test_scope_id', v_scope_id, true);
END $$;

SET LOCAL ROLE pix2pi_rls_verify_role;

DO $$
DECLARE
  v_tenant_id text := current_setting('app.test_tenant_id', true);
  v_other_tenant_id text := current_setting('app.test_other_tenant_id', true);
  v_user_role_id text := current_setting('app.test_user_role_id', true);
  v_scope_id text := current_setting('app.test_scope_id', true);
  v_count integer;
BEGIN
  -- Empty tenant context rejection is a PASS condition.
  BEGIN
    PERFORM app_security.set_tenant_context('');
    RAISE EXCEPTION 'empty tenant context unexpectedly allowed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%tenant context cannot be empty%' THEN
      RAISE;
    END IF;
  END;

  PERFORM app_security.set_tenant_context(v_tenant_id);

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'same-tenant user_roles visibility failed count=%', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = v_scope_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'same-tenant user_scopes visibility failed count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context(v_other_tenant_id);

  SELECT count(*)
  INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'cross-tenant RLS failed on user_roles; visible_count=%', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = v_scope_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'cross-tenant RLS failed on user_scopes; visible_count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/rls_bypass_cross_tenant_sql_suite_fix_v3b.out" 2>&1; then
  pass "5. RLS bypass / cross-tenant SQL suite geçti"
else
  fail "5. RLS bypass / cross-tenant SQL suite başarısız"
  cat "$BACKUP_DIR/rls_bypass_cross_tenant_sql_suite_fix_v3b.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/rls_bypass_cross_tenant_sql_suite_fix_v3b.out"; then
  pass "6. lifecycle test rollback ile temizlendi"
else
  fail "6. lifecycle test rollback kanıtı bulunamadı"
fi

{
  echo "# FAZ 1-2.3 RLS Bypass / Cross-Tenant DB Suite Result FIX V3B"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Test Coverage"
  echo "- empty tenant context rejection: tested"
  echo "- same-tenant user_roles visibility: tested"
  echo "- same-tenant user_scopes visibility: tested"
  echo "- cross-tenant user_roles invisibility: tested"
  echo "- cross-tenant user_scopes invisibility: tested"
  echo "- rollback cleanup: tested"
  echo
  echo "## Final"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7. suite evidence dosyası yazıldı"

echo "===== FAZ 1-2.3 RLS BYPASS / CROSS-TENANT SUITE FIX V3B RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_3_RLS_BYPASS_CROSS_TENANT_TEST_STATUS=PASS"
  echo "FAZ_1_2_3_RLS_BYPASS_CROSS_TENANT_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_3_RLS_BYPASS_CROSS_TENANT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_3_RLS_BYPASS_CROSS_TENANT_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.3 RLS BYPASS / CROSS-TENANT SUITE FIX V3B END ====="
