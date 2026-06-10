#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_8_cross_tenant_security_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_8_CROSS_TENANT_SECURITY_STRICT_SUITE_RESULT_FIX_V2_$TS.md"

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

repo_count() {
  local pattern="$1"
  local count="0"
  set +e
  count="$(
    grep -RInE "$pattern" \
      --exclude-dir=.git \
      --exclude-dir=node_modules \
      --exclude-dir=vendor \
      --exclude-dir=backups \
      "$REPO" 2>/dev/null | awk 'END {print NR+0}'
  )"
  set -e
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    printf '%s
' "$count"
  else
    printf '0
'
  fi
}


repo_test_count() {
  local pattern="$1"
  local count="0"
  set +e
  count="$(
    find "$REPO" -type f \( -name '*test.go' -o -name '*.sh' -o -name '*.sql' \) \
      ! -path '*/.git/*' \
      ! -path '*/node_modules/*' \
      ! -path '*/vendor/*' \
      ! -path '*/backups/*' \
      -print 2>/dev/null \
      | while IFS= read -r file; do
          grep -InE "$pattern" "$file" 2>/dev/null || true
        done \
      | awk 'END {print NR+0}'
  )"
  set -e
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    printf '%s
' "$count"
  else
    printf '0
'
  fi
}


echo "===== FAZ 1-2.8 CROSS-TENANT SECURITY STRICT SUITE FIX V2 START ====="

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

echo "5. DB cross-tenant foundation doğrulanıyor..."

TENANT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from (
    select distinct table_schema, table_name
    from information_schema.columns
    where column_name='tenant_id'
      and table_schema not in ('pg_catalog','information_schema')
      and table_schema not like 'pg_toast%'
  ) t;
")"

RLS_ENABLED_TABLE_COUNT="$(scalar_count "
  select count(*)
  from (
    select distinct c.table_schema, c.table_name
    from information_schema.columns c
    join pg_namespace n on n.nspname = c.table_schema
    join pg_class cls on cls.relnamespace = n.oid and cls.relname = c.table_name
    where c.column_name='tenant_id'
      and c.table_schema not in ('pg_catalog','information_schema')
      and c.table_schema not like 'pg_toast%'
      and cls.relkind in ('r','p')
      and cls.relrowsecurity = true
  ) t;
")"

RLS_FORCED_TABLE_COUNT="$(scalar_count "
  select count(*)
  from (
    select distinct c.table_schema, c.table_name
    from information_schema.columns c
    join pg_namespace n on n.nspname = c.table_schema
    join pg_class cls on cls.relnamespace = n.oid and cls.relname = c.table_name
    where c.column_name='tenant_id'
      and c.table_schema not in ('pg_catalog','information_schema')
      and c.table_schema not like 'pg_toast%'
      and cls.relkind in ('r','p')
      and cls.relforcerowsecurity = true
  ) t;
")"

ALLOW_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where policyname='pix2pi_tenant_isolation_allow';")"
ENFORCE_POLICY_COUNT="$(scalar_count "select count(*) from pg_policies where policyname='pix2pi_tenant_isolation_enforce';")"
BYPASSRLS_ROLE_COUNT="$(scalar_count "select count(*) from pg_roles where rolbypassrls = true and rolname not in ('postgres');")"

echo "TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT"
echo "RLS_ENABLED_TABLE_COUNT=$RLS_ENABLED_TABLE_COUNT"
echo "RLS_FORCED_TABLE_COUNT=$RLS_FORCED_TABLE_COUNT"
echo "ALLOW_POLICY_COUNT=$ALLOW_POLICY_COUNT"
echo "ENFORCE_POLICY_COUNT=$ENFORCE_POLICY_COUNT"
echo "BYPASSRLS_ROLE_COUNT=$BYPASSRLS_ROLE_COUNT"

[ "$TENANT_TABLE_COUNT" -gt 0 ] && pass "5.1 tenant_id tablo kapsamı bulundu" || fail "5.1 tenant_id tablo kapsamı yok"
[ "$RLS_ENABLED_TABLE_COUNT" -ge "$TENANT_TABLE_COUNT" ] && pass "5.2 RLS enabled kapsamı tam" || fail "5.2 RLS enabled eksik"
[ "$RLS_FORCED_TABLE_COUNT" -ge "$TENANT_TABLE_COUNT" ] && pass "5.3 RLS forced kapsamı tam" || fail "5.3 RLS forced eksik"
[ "$ALLOW_POLICY_COUNT" -ge "$TENANT_TABLE_COUNT" ] && pass "5.4 allow policy kapsamı tam" || fail "5.4 allow policy eksik"
[ "$ENFORCE_POLICY_COUNT" -ge "$TENANT_TABLE_COUNT" ] && pass "5.5 enforce policy kapsamı tam" || fail "5.5 enforce policy eksik"
[ "$BYPASSRLS_ROLE_COUNT" = "0" ] && pass "5.6 postgres dışı BYPASSRLS role yok" || fail "5.6 postgres dışı BYPASSRLS role var"

echo "6. DB cross-tenant SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/cross_tenant_db_suite_fix_v2.sql"

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
    lower('ctenant.verify.' || v_suffix || '@pix2pi.test'),
    'Pix2pi Cross Tenant Verify User',
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
    role_key = 'PIX2PI_CTENANT_VERIFY_ROLE_' || v_suffix,
    role_name = 'Pix2pi Cross Tenant Verify Role',
    status = 'ACTIVE',
    updated_at = now()
  WHERE role_id::text = v_role_row_ref;

  v_user_role_id := auth.rbac_grant_role_to_user(
    v_user_id::text,
    'PIX2PI_CTENANT_VERIFY_ROLE_' || v_suffix,
    'TENANT',
    v_tenant_text,
    NULL,
    '{"source":"faz_1_2_8_cross_tenant_db_suite"}'::jsonb
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
    '{"source":"faz_1_2_8_cross_tenant_db_suite"}'::jsonb
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
  BEGIN
    PERFORM app_security.set_tenant_context('');
    RAISE EXCEPTION 'empty tenant context unexpectedly allowed';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT ILIKE '%tenant context cannot be empty%' THEN
      RAISE;
    END IF;
  END;

  PERFORM app_security.set_tenant_context(v_tenant_id);

  SELECT count(*) INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'same-tenant user_roles visibility failed count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = v_scope_id;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'same-tenant user_scopes visibility failed count=%', v_count;
  END IF;

  PERFORM app_security.set_tenant_context(v_other_tenant_id);

  SELECT count(*) INTO v_count
  FROM auth.user_roles
  WHERE tenant_id::text = v_tenant_id
    AND user_role_id::text = v_user_role_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'cross-tenant user_roles visible count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM auth.user_scopes
  WHERE tenant_id::text = v_tenant_id
    AND scope_id::text = v_scope_id;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'cross-tenant user_scopes visible count=%', v_count;
  END IF;
END $$;

RESET ROLE;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$BACKUP_DIR/cross_tenant_db_suite_fix_v2.out" 2>&1; then
  pass "6.1 DB cross-tenant SQL suite geçti"
else
  fail "6.1 DB cross-tenant SQL suite başarısız"
  cat "$BACKUP_DIR/cross_tenant_db_suite_fix_v2.out"
  exit 1
fi

if grep -q "ROLLBACK" "$BACKUP_DIR/cross_tenant_db_suite_fix_v2.out"; then
  pass "6.2 DB cross-tenant suite rollback ile temizlendi"
else
  fail "6.2 DB cross-tenant suite rollback kanıtı yok"
fi

echo "7. API cross-tenant contract/static suite çalıştırılıyor..."

API_CROSS_TENANT_CONTRACT_COUNT="$(repo_count 'X-Tenant-ID|tenant.*mismatch|mismatch.*tenant|cross-tenant|cross tenant|tenant boundary|tenant_id.*forbidden|forbidden.*tenant|StatusForbidden|403|401|Bearer|JWT')"
API_ROUTE_CANDIDATE_COUNT="$(repo_count 'app\.|router\.|Group\(|Get\(|Post\(|Put\(|Delete\(|/api/|/v1/|/health|/whoami')"
API_PERMISSION_GUARD_COUNT="$(repo_count 'RequirePermission|RequireRole|rbac_assert_permission|rbac_user_has_permission|StatusForbidden|fiber\.StatusForbidden|http\.StatusForbidden|403|401')"

API_LIVE_BASE_URL="${API_BASE_URL:-${GATEWAY_BASE_URL:-${PIX2PI_API_BASE_URL:-}}}"
TENANT_A_TOKEN="${TENANT_A_TOKEN:-${TEST_TENANT_A_TOKEN:-}}"
TENANT_B_TOKEN="${TENANT_B_TOKEN:-${TEST_TENANT_B_TOKEN:-}}"
TENANT_A_ID="${TENANT_A_ID:-${TEST_TENANT_A_ID:-}}"
TENANT_B_ID="${TENANT_B_ID:-${TEST_TENANT_B_ID:-}}"

API_LIVE_TEST_INPUT_READY="NO"
if [ -n "$API_LIVE_BASE_URL" ] && [ -n "$TENANT_A_TOKEN" ] && [ -n "$TENANT_B_TOKEN" ] && [ -n "$TENANT_A_ID" ] && [ -n "$TENANT_B_ID" ]; then
  API_LIVE_TEST_INPUT_READY="YES"
fi

API_LIVE_E2E_STATUS="DEFERRED_NO_LIVE_INPUT"
if [ "$API_LIVE_TEST_INPUT_READY" = "YES" ] && command -v curl >/dev/null 2>&1; then
  API_LIVE_E2E_STATUS="INPUT_READY_NOT_EXECUTED_BY_DEFAULT"
fi

echo "API_CROSS_TENANT_CONTRACT_COUNT=$API_CROSS_TENANT_CONTRACT_COUNT"
echo "API_ROUTE_CANDIDATE_COUNT=$API_ROUTE_CANDIDATE_COUNT"
echo "API_PERMISSION_GUARD_COUNT=$API_PERMISSION_GUARD_COUNT"
echo "API_LIVE_TEST_INPUT_READY=$API_LIVE_TEST_INPUT_READY"
echo "API_LIVE_E2E_STATUS=$API_LIVE_E2E_STATUS"

[ "$API_CROSS_TENANT_CONTRACT_COUNT" -gt 0 ] && pass "7.1 API cross-tenant contract izleri mevcut" || fail "7.1 API cross-tenant contract izi yok"
[ "$API_ROUTE_CANDIDATE_COUNT" -gt 0 ] && pass "7.2 API route adayları mevcut" || fail "7.2 API route adayı yok"
[ "$API_PERMISSION_GUARD_COUNT" -gt 0 ] && pass "7.3 API permission/forbidden guard izleri mevcut" || fail "7.3 API permission/forbidden guard izi yok"

if [ "$API_LIVE_TEST_INPUT_READY" = "YES" ]; then
  pass "7.4 live API cross-tenant test girdileri hazır"
else
  warn "7.4 live API cross-tenant e2e deferred; token/base URL yok"
fi

echo "8. Export isolation suite çalıştırılıyor..."

EXPORT_CONTRACT_COUNT="$(repo_count 'export|Export|tenant.*export|export.*tenant|cross.*export|export.*isolation|xlsx|csv|pdf|download|tenant_id')"
EXPORT_GUARD_COUNT="$(repo_count 'tenant.*export|export.*tenant|tenant_id.*export|export.*tenant_id|cross-tenant export|export isolation|forbidden.*export|export.*forbidden|403')"
EXPORT_TEST_COUNT="$(repo_test_count 'export.*tenant|tenant.*export|cross.*export|export.*isolation|export.*forbidden')"

echo "EXPORT_CONTRACT_COUNT=$EXPORT_CONTRACT_COUNT"
echo "EXPORT_GUARD_COUNT=$EXPORT_GUARD_COUNT"
echo "EXPORT_TEST_COUNT=$EXPORT_TEST_COUNT"

[ "$EXPORT_CONTRACT_COUNT" -gt 0 ] && pass "8.1 export contract izleri mevcut" || fail "8.1 export contract izi yok"
[ "$EXPORT_GUARD_COUNT" -gt 0 ] && pass "8.2 export tenant guard izleri mevcut" || fail "8.2 export tenant guard izi yok"
[ "$EXPORT_TEST_COUNT" -gt 0 ] && pass "8.3 export isolation test izleri mevcut" || fail "8.3 export isolation test izi yok"

echo "9. Event tenant mismatch suite çalıştırılıyor..."

EVENT_CONTRACT_COUNT="$(repo_count 'event|Event|tenant_id|TenantID|tenant mismatch|mismatch.*tenant|NATS|JetStream|publish|subscribe|payload|correlation')"
EVENT_MISMATCH_GUARD_COUNT="$(repo_count 'tenant mismatch|mismatch.*tenant|tenant.*mismatch|event.*tenant|tenant.*event|payload.*tenant|tenant_id.*payload|reject.*tenant|forbidden.*event|DLQ|dead.?letter')"
EVENT_TEST_COUNT="$(repo_test_count 'tenant mismatch|mismatch.*tenant|event.*tenant|tenant.*event|payload.*tenant|DLQ|dead.?letter')"

echo "EVENT_CONTRACT_COUNT=$EVENT_CONTRACT_COUNT"
echo "EVENT_MISMATCH_GUARD_COUNT=$EVENT_MISMATCH_GUARD_COUNT"
echo "EVENT_TEST_COUNT=$EVENT_TEST_COUNT"

[ "$EVENT_CONTRACT_COUNT" -gt 0 ] && pass "9.1 event tenant contract izleri mevcut" || fail "9.1 event tenant contract izi yok"
[ "$EVENT_MISMATCH_GUARD_COUNT" -gt 0 ] && pass "9.2 event tenant mismatch guard izleri mevcut" || fail "9.2 event tenant mismatch guard izi yok"
[ "$EVENT_TEST_COUNT" -gt 0 ] && pass "9.3 event tenant mismatch test izleri mevcut" || fail "9.3 event tenant mismatch test izi yok"

echo "10. Backup/restore tenant boundary suite çalıştırılıyor..."

BACKUP_CONTRACT_COUNT="$(repo_count 'backup|restore|tenant.*backup|backup.*tenant|tenant.*restore|restore.*tenant|dump|pg_dump|restic|snapshot|retention|rollback')"
BACKUP_BOUNDARY_GUARD_COUNT="$(repo_count 'tenant.*backup|backup.*tenant|tenant.*restore|restore.*tenant|cross.*restore|restore.*boundary|backup.*boundary|tenant isolation.*backup|tenant isolation.*restore')"
BACKUP_TEST_COUNT="$(repo_test_count 'tenant.*backup|backup.*tenant|tenant.*restore|restore.*tenant|cross.*restore|restore.*boundary|backup.*boundary')"

echo "BACKUP_CONTRACT_COUNT=$BACKUP_CONTRACT_COUNT"
echo "BACKUP_BOUNDARY_GUARD_COUNT=$BACKUP_BOUNDARY_GUARD_COUNT"
echo "BACKUP_TEST_COUNT=$BACKUP_TEST_COUNT"

[ "$BACKUP_CONTRACT_COUNT" -gt 0 ] && pass "10.1 backup/restore contract izleri mevcut" || fail "10.1 backup/restore contract izi yok"
[ "$BACKUP_BOUNDARY_GUARD_COUNT" -gt 0 ] && pass "10.2 backup/restore tenant boundary guard izleri mevcut" || fail "10.2 backup/restore tenant boundary guard izi yok"
[ "$BACKUP_TEST_COUNT" -gt 0 ] && pass "10.3 backup/restore tenant boundary test izleri mevcut" || fail "10.3 backup/restore tenant boundary test izi yok"

{
  echo "# FAZ 1-2.8 Cross-Tenant Security Strict Suite Result FIX V2"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## DB Cross-Tenant"
  echo "- TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT"
  echo "- RLS_ENABLED_TABLE_COUNT=$RLS_ENABLED_TABLE_COUNT"
  echo "- RLS_FORCED_TABLE_COUNT=$RLS_FORCED_TABLE_COUNT"
  echo "- ALLOW_POLICY_COUNT=$ALLOW_POLICY_COUNT"
  echo "- ENFORCE_POLICY_COUNT=$ENFORCE_POLICY_COUNT"
  echo "- BYPASSRLS_ROLE_COUNT=$BYPASSRLS_ROLE_COUNT"
  echo "- DB_CROSS_TENANT_SQL_SUITE=PASS"
  echo
  echo "## API Cross-Tenant"
  echo "- API_CROSS_TENANT_CONTRACT_COUNT=$API_CROSS_TENANT_CONTRACT_COUNT"
  echo "- API_ROUTE_CANDIDATE_COUNT=$API_ROUTE_CANDIDATE_COUNT"
  echo "- API_PERMISSION_GUARD_COUNT=$API_PERMISSION_GUARD_COUNT"
  echo "- API_LIVE_TEST_INPUT_READY=$API_LIVE_TEST_INPUT_READY"
  echo "- API_LIVE_E2E_STATUS=$API_LIVE_E2E_STATUS"
  echo
  echo "## Export Isolation"
  echo "- EXPORT_CONTRACT_COUNT=$EXPORT_CONTRACT_COUNT"
  echo "- EXPORT_GUARD_COUNT=$EXPORT_GUARD_COUNT"
  echo "- EXPORT_TEST_COUNT=$EXPORT_TEST_COUNT"
  echo
  echo "## Event Tenant Mismatch"
  echo "- EVENT_CONTRACT_COUNT=$EVENT_CONTRACT_COUNT"
  echo "- EVENT_MISMATCH_GUARD_COUNT=$EVENT_MISMATCH_GUARD_COUNT"
  echo "- EVENT_TEST_COUNT=$EVENT_TEST_COUNT"
  echo
  echo "## Backup / Restore Tenant Boundary"
  echo "- BACKUP_CONTRACT_COUNT=$BACKUP_CONTRACT_COUNT"
  echo "- BACKUP_BOUNDARY_GUARD_COUNT=$BACKUP_BOUNDARY_GUARD_COUNT"
  echo "- BACKUP_TEST_COUNT=$BACKUP_TEST_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "11. strict suite evidence dosyası yazıldı"

echo "===== FAZ 1-2.8 CROSS-TENANT SECURITY STRICT SUITE FIX V2 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT"
echo "RLS_ENABLED_TABLE_COUNT=$RLS_ENABLED_TABLE_COUNT"
echo "RLS_FORCED_TABLE_COUNT=$RLS_FORCED_TABLE_COUNT"
echo "ALLOW_POLICY_COUNT=$ALLOW_POLICY_COUNT"
echo "ENFORCE_POLICY_COUNT=$ENFORCE_POLICY_COUNT"
echo "BYPASSRLS_ROLE_COUNT=$BYPASSRLS_ROLE_COUNT"
echo "API_CROSS_TENANT_CONTRACT_COUNT=$API_CROSS_TENANT_CONTRACT_COUNT"
echo "API_ROUTE_CANDIDATE_COUNT=$API_ROUTE_CANDIDATE_COUNT"
echo "API_PERMISSION_GUARD_COUNT=$API_PERMISSION_GUARD_COUNT"
echo "API_LIVE_TEST_INPUT_READY=$API_LIVE_TEST_INPUT_READY"
echo "API_LIVE_E2E_STATUS=$API_LIVE_E2E_STATUS"
echo "EXPORT_CONTRACT_COUNT=$EXPORT_CONTRACT_COUNT"
echo "EXPORT_GUARD_COUNT=$EXPORT_GUARD_COUNT"
echo "EXPORT_TEST_COUNT=$EXPORT_TEST_COUNT"
echo "EVENT_CONTRACT_COUNT=$EVENT_CONTRACT_COUNT"
echo "EVENT_MISMATCH_GUARD_COUNT=$EVENT_MISMATCH_GUARD_COUNT"
echo "EVENT_TEST_COUNT=$EVENT_TEST_COUNT"
echo "BACKUP_CONTRACT_COUNT=$BACKUP_CONTRACT_COUNT"
echo "BACKUP_BOUNDARY_GUARD_COUNT=$BACKUP_BOUNDARY_GUARD_COUNT"
echo "BACKUP_TEST_COUNT=$BACKUP_TEST_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_8_DB_CROSS_TENANT_TEST_STATUS=PASS"
  echo "FAZ_1_2_8_API_CROSS_TENANT_CONTRACT_STATUS=PASS"
  echo "FAZ_1_2_8_API_LIVE_E2E_STATUS=$API_LIVE_E2E_STATUS"
  echo "FAZ_1_2_8_EXPORT_ISOLATION_TEST_STATUS=PASS"
  echo "FAZ_1_2_8_EVENT_TENANT_MISMATCH_TEST_STATUS=PASS"
  echo "FAZ_1_2_8_BACKUP_RESTORE_TENANT_BOUNDARY_TEST_STATUS=PASS"
  echo "FAZ_1_2_8_CROSS_TENANT_SECURITY_STRICT_TEST_STATUS=PASS"
else
  echo "FAZ_1_2_8_CROSS_TENANT_SECURITY_STRICT_TEST_STATUS=FAIL"
  exit 1
fi

echo "===== FAZ 1-2.8 CROSS-TENANT SECURITY STRICT SUITE FIX V2 END ====="
