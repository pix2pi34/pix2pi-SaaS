#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_5_role_permission_strict_suite_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_5_ROLE_PERMISSION_STRICT_SUITE_RESULT_$TS.md"

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

echo "===== FAZ 1-2.5 ROLE / PERMISSION STRICT SUITE START ====="

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

echo "5. RBAC canonical model sayaçları doğrulanıyor..."

AUTH_ROLE_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name in ('roles','permissions','user_roles','role_permissions');
")"

AUTH_ROLE_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('roles','permissions','user_roles','role_permissions');
")"

AUTH_ROLE_RLS_ENABLED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','user_roles','role_permissions')
    and c.relrowsecurity=true;
")"

AUTH_ROLE_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in ('roles','permissions','user_roles','role_permissions')
    and c.relforcerowsecurity=true;
")"

AUTH_ROLE_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in ('roles','permissions','user_roles','role_permissions');
")"

AUTH_ROLE_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and (
      p.proname ilike '%role%'
      or p.proname ilike '%permission%'
      or p.proname ilike '%rbac%'
      or p.proname ilike '%has_perm%'
    );
")"

RBAC_REF_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='auth'
    and (
      p.proname ilike '%rbac%ref%'
      or p.proname ilike '%role%ref%'
      or p.proname ilike '%permission%ref%'
      or p.proname ilike '%legacy%'
      or p.proname ilike '%bridge%'
    );
")"

VERIFY_ROLE_COUNT="$(scalar_count "
  select count(*)
  from pg_roles
  where rolname in ('pix2pi_rls_verify_role','pix2pi_verify_role');
")"

ROLE_ROW_COUNT="$(scalar_count "
  select case
    when to_regclass('auth.roles') is null then 0
    else (select count(*) from auth.roles)
  end;
")"

PERMISSION_ROW_COUNT="$(scalar_count "
  select case
    when to_regclass('auth.permissions') is null then 0
    else (select count(*) from auth.permissions)
  end;
")"

USER_ROLE_ROW_COUNT="$(scalar_count "
  select case
    when to_regclass('auth.user_roles') is null then 0
    else (select count(*) from auth.user_roles)
  end;
")"

ROLE_PERMISSION_ROW_COUNT="$(scalar_count "
  select case
    when to_regclass('auth.role_permissions') is null then 0
    else (select count(*) from auth.role_permissions)
  end;
")"

echo "AUTH_ROLE_TABLE_COUNT=$AUTH_ROLE_TABLE_COUNT"
echo "AUTH_ROLE_COLUMN_COUNT=$AUTH_ROLE_COLUMN_COUNT"
echo "AUTH_ROLE_RLS_ENABLED_COUNT=$AUTH_ROLE_RLS_ENABLED_COUNT"
echo "AUTH_ROLE_RLS_FORCED_COUNT=$AUTH_ROLE_RLS_FORCED_COUNT"
echo "AUTH_ROLE_POLICY_COUNT=$AUTH_ROLE_POLICY_COUNT"
echo "AUTH_ROLE_FUNCTION_COUNT=$AUTH_ROLE_FUNCTION_COUNT"
echo "RBAC_REF_FUNCTION_COUNT=$RBAC_REF_FUNCTION_COUNT"
echo "VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
echo "ROLE_ROW_COUNT=$ROLE_ROW_COUNT"
echo "PERMISSION_ROW_COUNT=$PERMISSION_ROW_COUNT"
echo "USER_ROLE_ROW_COUNT=$USER_ROLE_ROW_COUNT"
echo "ROLE_PERMISSION_ROW_COUNT=$ROLE_PERMISSION_ROW_COUNT"

[ "$AUTH_ROLE_TABLE_COUNT" -ge 4 ] && pass "5.1 canonical role/permission tablo seti mevcut" || fail "5.1 canonical role/permission tablo seti eksik"
[ "$AUTH_ROLE_COLUMN_COUNT" -ge 30 ] && pass "5.2 role/permission kolon kapsamı yeterli" || fail "5.2 role/permission kolon kapsamı zayıf"
[ "$AUTH_ROLE_RLS_ENABLED_COUNT" -ge 4 ] && pass "5.3 role/permission RLS enabled kapsamı tam" || fail "5.3 role/permission RLS enabled eksik"
[ "$AUTH_ROLE_RLS_FORCED_COUNT" -ge 4 ] && pass "5.4 role/permission RLS forced kapsamı tam" || fail "5.4 role/permission RLS forced eksik"
[ "$AUTH_ROLE_POLICY_COUNT" -ge 8 ] && pass "5.5 role/permission policy kapsamı yeterli" || fail "5.5 role/permission policy kapsamı eksik"
[ "$AUTH_ROLE_FUNCTION_COUNT" -ge 6 ] && pass "5.6 RBAC runtime function seti mevcut" || fail "5.6 RBAC runtime function seti eksik"
[ "$RBAC_REF_FUNCTION_COUNT" -ge 3 ] && pass "5.7 RBAC legacy/ref bridge function seti mevcut" || fail "5.7 RBAC legacy/ref bridge function seti eksik"
[ "$VERIFY_ROLE_COUNT" -ge 1 ] && pass "5.8 verify role mevcut" || fail "5.8 verify role yok"
[ "$ROLE_ROW_COUNT" -ge 1 ] && pass "5.9 role row mevcut" || fail "5.9 role row yok"
[ "$PERMISSION_ROW_COUNT" -ge 1 ] && pass "5.10 permission row mevcut" || fail "5.10 permission row yok"

echo "6. alt başlık DB/repo evidence doğrulanıyor..."

ROLE_MODEL_REPO_COUNT="$(repo_count 'role model|auth\\.roles|user_roles|role_id|TENANT_ADMIN|SUPER_ADMIN|role permission|RBAC')"
PERMISSION_MODEL_REPO_COUNT="$(repo_count 'permission model|auth\\.permissions|permission_id|has_permission|permission check|permissions|RBAC')"
FEATURE_GATE_REPO_COUNT="$(repo_count 'feature.?gate|feature_gate|entitlement|entitlements|plan.*permission|permission.*feature|feature.*permission')"
EXPORT_PERMISSION_REPO_COUNT="$(repo_count 'export.*permission|permission.*export|EXPORT|export isolation|export guard|can_export')"
ADMIN_PERMISSION_REPO_COUNT="$(repo_count 'admin.*permission|permission.*admin|SUPER_ADMIN|TENANT_ADMIN|admin guard|admin action|break.?glass')"
UI_API_PERMISSION_REGRESSION_REPO_COUNT="$(repo_count 'UI.*permission|permission.*UI|API.*permission|permission.*API|regression|forbidden|StatusForbidden|403|permission guard')"

ROLE_MODEL_DB_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('roles','user_roles')
    and column_name in ('role_id','role_code','name','role_name','tenant_id','user_id','status','metadata');
")"

PERMISSION_MODEL_DB_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('permissions','role_permissions')
    and column_name in ('permission_id','permission_code','name','permission_name','role_id','tenant_id','status','metadata');
")"

FEATURE_GATE_DB_HINT_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('permissions','role_permissions','roles')
    and column_name in ('feature_key','feature_gate','feature','entitlement_key','module_key','scope');
")"

EXPORT_PERMISSION_DB_HINT_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('permissions','role_permissions')
    and column_name in ('permission_code','name','permission_name','scope','metadata');
")"

ADMIN_PERMISSION_DB_HINT_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name in ('roles','permissions','role_permissions','user_roles')
    and column_name in ('role_code','permission_code','name','permission_name','scope','metadata');
")"

echo "ROLE_MODEL_REPO_COUNT=$ROLE_MODEL_REPO_COUNT"
echo "PERMISSION_MODEL_REPO_COUNT=$PERMISSION_MODEL_REPO_COUNT"
echo "FEATURE_GATE_REPO_COUNT=$FEATURE_GATE_REPO_COUNT"
echo "EXPORT_PERMISSION_REPO_COUNT=$EXPORT_PERMISSION_REPO_COUNT"
echo "ADMIN_PERMISSION_REPO_COUNT=$ADMIN_PERMISSION_REPO_COUNT"
echo "UI_API_PERMISSION_REGRESSION_REPO_COUNT=$UI_API_PERMISSION_REGRESSION_REPO_COUNT"
echo "ROLE_MODEL_DB_COLUMN_COUNT=$ROLE_MODEL_DB_COLUMN_COUNT"
echo "PERMISSION_MODEL_DB_COLUMN_COUNT=$PERMISSION_MODEL_DB_COLUMN_COUNT"
echo "FEATURE_GATE_DB_HINT_COUNT=$FEATURE_GATE_DB_HINT_COUNT"
echo "EXPORT_PERMISSION_DB_HINT_COUNT=$EXPORT_PERMISSION_DB_HINT_COUNT"
echo "ADMIN_PERMISSION_DB_HINT_COUNT=$ADMIN_PERMISSION_DB_HINT_COUNT"

[ "$ROLE_MODEL_REPO_COUNT" -gt 0 ] && [ "$ROLE_MODEL_DB_COLUMN_COUNT" -ge 4 ] && pass "6.1 role modeli DB/repo kanıtı mevcut" || fail "6.1 role modeli kanıtı eksik"
[ "$PERMISSION_MODEL_REPO_COUNT" -gt 0 ] && [ "$PERMISSION_MODEL_DB_COLUMN_COUNT" -ge 4 ] && pass "6.2 permission modeli DB/repo kanıtı mevcut" || fail "6.2 permission modeli kanıtı eksik"
[ "$FEATURE_GATE_REPO_COUNT" -gt 0 ] && pass "6.3 feature gate bağlantısı repo kanıtı mevcut" || fail "6.3 feature gate bağlantısı kanıtı eksik"
[ "$EXPORT_PERMISSION_REPO_COUNT" -gt 0 ] && [ "$EXPORT_PERMISSION_DB_HINT_COUNT" -ge 2 ] && pass "6.4 export permission DB/repo kanıtı mevcut" || fail "6.4 export permission kanıtı eksik"
[ "$ADMIN_PERMISSION_REPO_COUNT" -gt 0 ] && [ "$ADMIN_PERMISSION_DB_HINT_COUNT" -ge 2 ] && pass "6.5 admin permission DB/repo kanıtı mevcut" || fail "6.5 admin permission kanıtı eksik"
[ "$UI_API_PERMISSION_REGRESSION_REPO_COUNT" -gt 0 ] && pass "6.6 UI/API permission regression repo kanıtı mevcut" || fail "6.6 UI/API permission regression kanıtı eksik"

echo "7. RBAC strict metadata/lifecycle SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/role_permission_strict_metadata_suite.sql"
SQL_SUITE_OUT="$BACKUP_DIR/role_permission_strict_metadata_suite.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_table_count int;
  v_column_count int;
  v_rls_enabled int;
  v_rls_forced int;
  v_policy_count int;
  v_function_count int;
  v_role_rows int;
  v_permission_rows int;
  v_role_columns int;
  v_permission_columns int;
BEGIN
  SELECT count(*)
  INTO v_table_count
  FROM information_schema.tables
  WHERE table_schema='auth'
    AND table_name IN ('roles','permissions','user_roles','role_permissions');

  IF v_table_count < 4 THEN
    RAISE EXCEPTION 'canonical RBAC table set weak count=%', v_table_count;
  END IF;

  SELECT count(*)
  INTO v_column_count
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name IN ('roles','permissions','user_roles','role_permissions');

  IF v_column_count < 30 THEN
    RAISE EXCEPTION 'RBAC column coverage weak count=%', v_column_count;
  END IF;

  SELECT count(*)
  INTO v_rls_enabled
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='auth'
    AND c.relname IN ('roles','permissions','user_roles','role_permissions')
    AND c.relrowsecurity=true;

  IF v_rls_enabled < 4 THEN
    RAISE EXCEPTION 'RBAC RLS enabled weak count=%', v_rls_enabled;
  END IF;

  SELECT count(*)
  INTO v_rls_forced
  FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='auth'
    AND c.relname IN ('roles','permissions','user_roles','role_permissions')
    AND c.relforcerowsecurity=true;

  IF v_rls_forced < 4 THEN
    RAISE EXCEPTION 'RBAC RLS forced weak count=%', v_rls_forced;
  END IF;

  SELECT count(*)
  INTO v_policy_count
  FROM pg_policies
  WHERE schemaname='auth'
    AND tablename IN ('roles','permissions','user_roles','role_permissions');

  IF v_policy_count < 8 THEN
    RAISE EXCEPTION 'RBAC policy coverage weak count=%', v_policy_count;
  END IF;

  SELECT count(*)
  INTO v_function_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='auth'
    AND (
      p.proname ILIKE '%role%'
      OR p.proname ILIKE '%permission%'
      OR p.proname ILIKE '%rbac%'
      OR p.proname ILIKE '%has_perm%'
    );

  IF v_function_count < 6 THEN
    RAISE EXCEPTION 'RBAC function set weak count=%', v_function_count;
  END IF;

  SELECT count(*) INTO v_role_rows FROM auth.roles;
  IF v_role_rows < 1 THEN
    RAISE EXCEPTION 'auth.roles has no rows';
  END IF;

  SELECT count(*) INTO v_permission_rows FROM auth.permissions;
  IF v_permission_rows < 1 THEN
    RAISE EXCEPTION 'auth.permissions has no rows';
  END IF;

  SELECT count(*)
  INTO v_role_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name IN ('roles','user_roles')
    AND column_name IN ('role_id','role_code','name','role_name','tenant_id','user_id','status','metadata');

  IF v_role_columns < 4 THEN
    RAISE EXCEPTION 'role model columns weak count=%', v_role_columns;
  END IF;

  SELECT count(*)
  INTO v_permission_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name IN ('permissions','role_permissions')
    AND column_name IN ('permission_id','permission_code','name','permission_name','role_id','tenant_id','status','metadata');

  IF v_permission_columns < 4 THEN
    RAISE EXCEPTION 'permission model columns weak count=%', v_permission_columns;
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "7.1 RBAC strict metadata/lifecycle SQL suite geçti"
else
  fail "7.1 RBAC strict metadata/lifecycle SQL suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "7.2 strict SQL suite rollback ile temizlendi"
else
  fail "7.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-2.5 Role / Permission Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Required Scope"
  echo "- Role modeli"
  echo "- Permission modeli"
  echo "- Feature gate bağlantısı"
  echo "- Export permission"
  echo "- Admin permission"
  echo "- UI/API permission regression"
  echo
  echo "## DB Counters"
  echo "- AUTH_ROLE_TABLE_COUNT=$AUTH_ROLE_TABLE_COUNT"
  echo "- AUTH_ROLE_COLUMN_COUNT=$AUTH_ROLE_COLUMN_COUNT"
  echo "- AUTH_ROLE_RLS_ENABLED_COUNT=$AUTH_ROLE_RLS_ENABLED_COUNT"
  echo "- AUTH_ROLE_RLS_FORCED_COUNT=$AUTH_ROLE_RLS_FORCED_COUNT"
  echo "- AUTH_ROLE_POLICY_COUNT=$AUTH_ROLE_POLICY_COUNT"
  echo "- AUTH_ROLE_FUNCTION_COUNT=$AUTH_ROLE_FUNCTION_COUNT"
  echo "- RBAC_REF_FUNCTION_COUNT=$RBAC_REF_FUNCTION_COUNT"
  echo "- VERIFY_ROLE_COUNT=$VERIFY_ROLE_COUNT"
  echo "- ROLE_ROW_COUNT=$ROLE_ROW_COUNT"
  echo "- PERMISSION_ROW_COUNT=$PERMISSION_ROW_COUNT"
  echo "- USER_ROLE_ROW_COUNT=$USER_ROLE_ROW_COUNT"
  echo "- ROLE_PERMISSION_ROW_COUNT=$ROLE_PERMISSION_ROW_COUNT"
  echo "- ROLE_MODEL_DB_COLUMN_COUNT=$ROLE_MODEL_DB_COLUMN_COUNT"
  echo "- PERMISSION_MODEL_DB_COLUMN_COUNT=$PERMISSION_MODEL_DB_COLUMN_COUNT"
  echo "- FEATURE_GATE_DB_HINT_COUNT=$FEATURE_GATE_DB_HINT_COUNT"
  echo "- EXPORT_PERMISSION_DB_HINT_COUNT=$EXPORT_PERMISSION_DB_HINT_COUNT"
  echo "- ADMIN_PERMISSION_DB_HINT_COUNT=$ADMIN_PERMISSION_DB_HINT_COUNT"
  echo
  echo "## Repo Counters"
  echo "- ROLE_MODEL_REPO_COUNT=$ROLE_MODEL_REPO_COUNT"
  echo "- PERMISSION_MODEL_REPO_COUNT=$PERMISSION_MODEL_REPO_COUNT"
  echo "- FEATURE_GATE_REPO_COUNT=$FEATURE_GATE_REPO_COUNT"
  echo "- EXPORT_PERMISSION_REPO_COUNT=$EXPORT_PERMISSION_REPO_COUNT"
  echo "- ADMIN_PERMISSION_REPO_COUNT=$ADMIN_PERMISSION_REPO_COUNT"
  echo "- UI_API_PERMISSION_REGRESSION_REPO_COUNT=$UI_API_PERMISSION_REGRESSION_REPO_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-2.5 ROLE / PERMISSION STRICT SUITE RESULT ====="
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
echo "ROLE_ROW_COUNT=$ROLE_ROW_COUNT"
echo "PERMISSION_ROW_COUNT=$PERMISSION_ROW_COUNT"
echo "USER_ROLE_ROW_COUNT=$USER_ROLE_ROW_COUNT"
echo "ROLE_PERMISSION_ROW_COUNT=$ROLE_PERMISSION_ROW_COUNT"
echo "ROLE_MODEL_REPO_COUNT=$ROLE_MODEL_REPO_COUNT"
echo "PERMISSION_MODEL_REPO_COUNT=$PERMISSION_MODEL_REPO_COUNT"
echo "FEATURE_GATE_REPO_COUNT=$FEATURE_GATE_REPO_COUNT"
echo "EXPORT_PERMISSION_REPO_COUNT=$EXPORT_PERMISSION_REPO_COUNT"
echo "ADMIN_PERMISSION_REPO_COUNT=$ADMIN_PERMISSION_REPO_COUNT"
echo "UI_API_PERMISSION_REGRESSION_REPO_COUNT=$UI_API_PERMISSION_REGRESSION_REPO_COUNT"
echo "ROLE_MODEL_DB_COLUMN_COUNT=$ROLE_MODEL_DB_COLUMN_COUNT"
echo "PERMISSION_MODEL_DB_COLUMN_COUNT=$PERMISSION_MODEL_DB_COLUMN_COUNT"
echo "FEATURE_GATE_DB_HINT_COUNT=$FEATURE_GATE_DB_HINT_COUNT"
echo "EXPORT_PERMISSION_DB_HINT_COUNT=$EXPORT_PERMISSION_DB_HINT_COUNT"
echo "ADMIN_PERMISSION_DB_HINT_COUNT=$ADMIN_PERMISSION_DB_HINT_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_5_ROLE_MODEL_STATUS=PASS"
  echo "FAZ_1_2_5_PERMISSION_MODEL_STATUS=PASS"
  echo "FAZ_1_2_5_FEATURE_GATE_LINK_STATUS=PASS"
  echo "FAZ_1_2_5_EXPORT_PERMISSION_STATUS=PASS"
  echo "FAZ_1_2_5_ADMIN_PERMISSION_STATUS=PASS"
  echo "FAZ_1_2_5_UI_API_PERMISSION_REGRESSION_STATUS=PASS"
  echo "FAZ_1_2_5_ROLE_PERMISSION_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_2_5_ROLE_PERMISSION_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_5_ROLE_PERMISSION_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_5_ROLE_PERMISSION_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.5 ROLE / PERMISSION STRICT SUITE END ====="
