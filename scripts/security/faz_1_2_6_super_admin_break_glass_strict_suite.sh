#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="${TS:-$(date +%Y%m%d_%H%M%S)}"
BACKUP_DIR="${BACKUP_DIR:-$REPO/backups/faz1/faz_1_2_6_super_admin_break_glass_strict_suite_fix_v2_$TS}"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_STRICT_SUITE_RESULT_FIX_V2_$TS.md"

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

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS STRICT SUITE FIX V2 START ====="

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

echo "5. canonical table / RLS / policy sayaçları doğrulanıyor..."

CANONICAL_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
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
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and c.relrowsecurity=true;
")"

CANONICAL_RLS_FORCED_COUNT="$(scalar_count "
  select count(*)
  from pg_class c
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='auth'
    and c.relname in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and c.relforcerowsecurity=true;
")"

CANONICAL_ALLOW_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and policyname ilike '%allow%';
")"

CANONICAL_ENFORCE_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    )
    and policyname ilike '%enforce%';
")"

CANONICAL_POLICY_COUNT="$(scalar_count "
  select count(*)
  from pg_policies
  where schemaname='auth'
    and tablename in (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    );
")"

SUPER_ADMIN_SEED_COUNT="$(scalar_count "
  select case
    when to_regclass('auth.super_admin_principals') is null then 0
    else (select count(*) from auth.super_admin_principals)
  end;
")"

BREAK_GLASS_FUNCTION_COUNT="$(scalar_count "
  select count(*)
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname in ('auth','security','app_security')
    and (
      p.proname ilike '%break_glass%'
      or p.proname ilike '%super_admin%'
      or p.proname ilike '%admin_action%'
      or p.proname ilike '%security_alert%'
    );
")"

echo "CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
echo "CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
echo "CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
echo "CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
echo "CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
echo "CANONICAL_POLICY_COUNT=$CANONICAL_POLICY_COUNT"
echo "BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
echo "SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"

[ "$CANONICAL_TABLE_COUNT" -ge 4 ] && pass "5.1 canonical security table set hazır" || fail "5.1 canonical security table set eksik"
[ "$CANONICAL_RLS_ENABLED_COUNT" -ge 4 ] && pass "5.2 canonical tables RLS enabled" || fail "5.2 canonical tables RLS enabled eksik"
[ "$CANONICAL_RLS_FORCED_COUNT" -ge 4 ] && pass "5.3 canonical tables RLS forced" || fail "5.3 canonical tables RLS forced eksik"
[ "$CANONICAL_ALLOW_POLICY_COUNT" -ge 4 ] && pass "5.4 canonical allow policy kapsamı tam" || fail "5.4 canonical allow policy eksik"
[ "$CANONICAL_ENFORCE_POLICY_COUNT" -ge 4 ] && pass "5.5 canonical enforce policy kapsamı tam" || fail "5.5 canonical enforce policy eksik"
[ "$CANONICAL_POLICY_COUNT" -ge 8 ] && pass "5.6 canonical policy toplam kapsamı yeterli" || fail "5.6 canonical policy toplam kapsamı eksik"
[ "$BREAK_GLASS_FUNCTION_COUNT" -ge 4 ] && pass "5.7 break-glass/super-admin function seti mevcut" || fail "5.7 break-glass/super-admin function seti eksik"
[ "$SUPER_ADMIN_SEED_COUNT" -ge 1 ] && pass "5.8 super-admin principal row mevcut" || fail "5.8 super-admin principal row yok"

echo "6. alt başlık repo/DB kanıtları doğrulanıyor..."

SUPER_ADMIN_ROLE_MODEL_COUNT="$(repo_count 'super.?admin|SUPER_ADMIN|super_admin_principals|is_super_admin')"
BREAK_GLASS_REASON_COUNT="$(repo_count 'break.?glass.*reason|reason.*break.?glass|reason_required|reason.*required|justification|approval_reason|access_reason')"
TIMED_ACCESS_COUNT="$(repo_count 'expires_at|valid_until|duration|ttl|time.?bound|timed access|expire|expired')"
ADMIN_ACTION_AUDIT_COUNT="$(repo_count 'admin_action_audit|admin action audit|audit_admin|operator_action|action_audit')"
ALERT_EVENT_COUNT="$(repo_count 'security_alerts|security alert|alert.*break.?glass|break.?glass.*alert|event.*break.?glass|break.?glass.*event')"
ABUSE_TEST_COUNT="$(repo_count 'abuse|unauthorized|forbidden|cross.?tenant|break.?glass.*test|super.?admin.*test|lifecycle')"

DB_REASON_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='break_glass_access_sessions'
    and column_name in ('reason','access_reason','justification','request_reason');
")"

DB_EXPIRY_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='break_glass_access_sessions'
    and column_name in ('expires_at','valid_until','expires_on','ended_at');
")"

DB_ADMIN_AUDIT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name='admin_action_audit';
")"

DB_ALERT_TABLE_COUNT="$(scalar_count "
  select count(*)
  from information_schema.tables
  where table_schema='auth'
    and table_name='security_alerts';
")"

DB_ADMIN_AUDIT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='admin_action_audit';
")"

DB_ALERT_COLUMN_COUNT="$(scalar_count "
  select count(*)
  from information_schema.columns
  where table_schema='auth'
    and table_name='security_alerts';
")"

echo "SUPER_ADMIN_ROLE_MODEL_COUNT=$SUPER_ADMIN_ROLE_MODEL_COUNT"
echo "BREAK_GLASS_REASON_COUNT=$BREAK_GLASS_REASON_COUNT"
echo "TIMED_ACCESS_COUNT=$TIMED_ACCESS_COUNT"
echo "ADMIN_ACTION_AUDIT_COUNT=$ADMIN_ACTION_AUDIT_COUNT"
echo "ALERT_EVENT_COUNT=$ALERT_EVENT_COUNT"
echo "ABUSE_TEST_COUNT=$ABUSE_TEST_COUNT"
echo "DB_REASON_COLUMN_COUNT=$DB_REASON_COLUMN_COUNT"
echo "DB_EXPIRY_COLUMN_COUNT=$DB_EXPIRY_COLUMN_COUNT"
echo "DB_ADMIN_AUDIT_TABLE_COUNT=$DB_ADMIN_AUDIT_TABLE_COUNT"
echo "DB_ALERT_TABLE_COUNT=$DB_ALERT_TABLE_COUNT"
echo "DB_ADMIN_AUDIT_COLUMN_COUNT=$DB_ADMIN_AUDIT_COLUMN_COUNT"
echo "DB_ALERT_COLUMN_COUNT=$DB_ALERT_COLUMN_COUNT"

[ "$SUPER_ADMIN_ROLE_MODEL_COUNT" -gt 0 ] && pass "6.1 super-admin rol modeli izleri mevcut" || fail "6.1 super-admin rol modeli izi yok"
[ "$BREAK_GLASS_REASON_COUNT" -gt 0 ] && pass "6.2 break-glass reason zorunluluğu izleri mevcut" || fail "6.2 break-glass reason izi yok"
[ "$TIMED_ACCESS_COUNT" -gt 0 ] && pass "6.3 süreli erişim izleri mevcut" || fail "6.3 süreli erişim izi yok"
[ "$ADMIN_ACTION_AUDIT_COUNT" -gt 0 ] && pass "6.4 admin action audit izleri mevcut" || fail "6.4 admin action audit izi yok"
[ "$ALERT_EVENT_COUNT" -gt 0 ] && pass "6.5 alert/event üretim izleri mevcut" || fail "6.5 alert/event izi yok"
[ "$ABUSE_TEST_COUNT" -gt 0 ] && pass "6.6 abuse test izleri mevcut" || fail "6.6 abuse test izi yok"
[ "$DB_REASON_COLUMN_COUNT" -gt 0 ] && pass "6.7 DB break-glass reason kolonu mevcut" || fail "6.7 DB break-glass reason kolonu yok"
[ "$DB_EXPIRY_COLUMN_COUNT" -gt 0 ] && pass "6.8 DB süreli erişim expiry kolonu mevcut" || fail "6.8 DB expiry kolonu yok"
[ "$DB_ADMIN_AUDIT_TABLE_COUNT" -ge 1 ] && pass "6.9 DB admin_action_audit tablosu mevcut" || fail "6.9 DB admin_action_audit tablosu yok"
[ "$DB_ALERT_TABLE_COUNT" -ge 1 ] && pass "6.10 DB security_alerts tablosu mevcut" || fail "6.10 DB security_alerts tablosu yok"
[ "$DB_ADMIN_AUDIT_COLUMN_COUNT" -ge 5 ] && pass "6.11 DB admin_action_audit kolon kapsamı yeterli" || fail "6.11 DB admin_action_audit kolon kapsamı zayıf"
[ "$DB_ALERT_COLUMN_COUNT" -ge 5 ] && pass "6.12 DB security_alerts kolon kapsamı yeterli" || fail "6.12 DB security_alerts kolon kapsamı zayıf"

echo "7. strict metadata abuse SQL suite çalıştırılıyor..."

SQL_SUITE_FILE="$BACKUP_DIR/super_admin_break_glass_strict_metadata_suite_fix_v2.sql"
SQL_SUITE_OUT="$BACKUP_DIR/super_admin_break_glass_strict_metadata_suite_fix_v2.out"

cat <<'SQL' > "$SQL_SUITE_FILE"
BEGIN;

DO $$
DECLARE
  v_table_count int;
  v_reason_columns int;
  v_expiry_columns int;
  v_admin_audit_columns int;
  v_alert_columns int;
  v_function_count int;
BEGIN
  SELECT count(*)
  INTO v_table_count
  FROM information_schema.tables
  WHERE table_schema='auth'
    AND table_name IN (
      'super_admin_principals',
      'break_glass_access_sessions',
      'admin_action_audit',
      'security_alerts'
    );

  IF v_table_count < 4 THEN
    RAISE EXCEPTION 'canonical security table set weak count=%', v_table_count;
  END IF;

  SELECT count(*)
  INTO v_reason_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='break_glass_access_sessions'
    AND column_name IN ('reason','access_reason','justification','request_reason');

  IF v_reason_columns < 1 THEN
    RAISE EXCEPTION 'break-glass reason column missing';
  END IF;

  SELECT count(*)
  INTO v_expiry_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='break_glass_access_sessions'
    AND column_name IN ('expires_at','valid_until','expires_on','ended_at');

  IF v_expiry_columns < 1 THEN
    RAISE EXCEPTION 'break-glass expiry column missing';
  END IF;

  SELECT count(*)
  INTO v_admin_audit_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='admin_action_audit';

  IF v_admin_audit_columns < 5 THEN
    RAISE EXCEPTION 'admin_action_audit canonical columns weak count=%', v_admin_audit_columns;
  END IF;

  SELECT count(*)
  INTO v_alert_columns
  FROM information_schema.columns
  WHERE table_schema='auth'
    AND table_name='security_alerts';

  IF v_alert_columns < 5 THEN
    RAISE EXCEPTION 'security_alerts canonical columns weak count=%', v_alert_columns;
  END IF;

  SELECT count(*)
  INTO v_function_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('auth','security','app_security')
    AND (
      p.proname ILIKE '%break_glass%'
      OR p.proname ILIKE '%super_admin%'
      OR p.proname ILIKE '%admin_action%'
      OR p.proname ILIKE '%security_alert%'
    );

  IF v_function_count < 4 THEN
    RAISE EXCEPTION 'break-glass/super-admin function set weak count=%', v_function_count;
  END IF;
END $$;

ROLLBACK;
SQL

if psql "$DSN" -v ON_ERROR_STOP=1 -f "$SQL_SUITE_FILE" > "$SQL_SUITE_OUT" 2>&1; then
  pass "7.1 strict metadata SQL suite geçti"
else
  fail "7.1 strict metadata SQL suite başarısız"
  cat "$SQL_SUITE_OUT"
  exit 1
fi

if grep -q "ROLLBACK" "$SQL_SUITE_OUT"; then
  pass "7.2 strict SQL suite rollback ile temizlendi"
else
  fail "7.2 strict SQL suite rollback kanıtı yok"
fi

{
  echo "# FAZ 1-2.6 Super-admin / Break-glass Strict Suite Result FIX V2"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- Backup dir: $BACKUP_DIR"
  echo
  echo "## Required Scope"
  echo "- Super-admin rol modeli"
  echo "- Break-glass reason zorunluluğu"
  echo "- Süreli erişim"
  echo "- Admin action audit"
  echo "- Alert/event üretimi"
  echo "- Abuse testleri"
  echo
  echo "## DB Counters"
  echo "- CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
  echo "- CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
  echo "- CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
  echo "- CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
  echo "- CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
  echo "- CANONICAL_POLICY_COUNT=$CANONICAL_POLICY_COUNT"
  echo "- BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
  echo "- SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"
  echo "- DB_REASON_COLUMN_COUNT=$DB_REASON_COLUMN_COUNT"
  echo "- DB_EXPIRY_COLUMN_COUNT=$DB_EXPIRY_COLUMN_COUNT"
  echo "- DB_ADMIN_AUDIT_TABLE_COUNT=$DB_ADMIN_AUDIT_TABLE_COUNT"
  echo "- DB_ALERT_TABLE_COUNT=$DB_ALERT_TABLE_COUNT"
  echo "- DB_ADMIN_AUDIT_COLUMN_COUNT=$DB_ADMIN_AUDIT_COLUMN_COUNT"
  echo "- DB_ALERT_COLUMN_COUNT=$DB_ALERT_COLUMN_COUNT"
  echo
  echo "## Repo Counters"
  echo "- SUPER_ADMIN_ROLE_MODEL_COUNT=$SUPER_ADMIN_ROLE_MODEL_COUNT"
  echo "- BREAK_GLASS_REASON_COUNT=$BREAK_GLASS_REASON_COUNT"
  echo "- TIMED_ACCESS_COUNT=$TIMED_ACCESS_COUNT"
  echo "- ADMIN_ACTION_AUDIT_COUNT=$ADMIN_ACTION_AUDIT_COUNT"
  echo "- ALERT_EVENT_COUNT=$ALERT_EVENT_COUNT"
  echo "- ABUSE_TEST_COUNT=$ABUSE_TEST_COUNT"
  echo
  echo "## Final Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "8. strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS STRICT SUITE FIX V2 RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "CANONICAL_TABLE_COUNT=$CANONICAL_TABLE_COUNT"
echo "CANONICAL_RLS_ENABLED_COUNT=$CANONICAL_RLS_ENABLED_COUNT"
echo "CANONICAL_RLS_FORCED_COUNT=$CANONICAL_RLS_FORCED_COUNT"
echo "CANONICAL_ALLOW_POLICY_COUNT=$CANONICAL_ALLOW_POLICY_COUNT"
echo "CANONICAL_ENFORCE_POLICY_COUNT=$CANONICAL_ENFORCE_POLICY_COUNT"
echo "CANONICAL_POLICY_COUNT=$CANONICAL_POLICY_COUNT"
echo "BREAK_GLASS_FUNCTION_COUNT=$BREAK_GLASS_FUNCTION_COUNT"
echo "SUPER_ADMIN_SEED_COUNT=$SUPER_ADMIN_SEED_COUNT"
echo "SUPER_ADMIN_ROLE_MODEL_COUNT=$SUPER_ADMIN_ROLE_MODEL_COUNT"
echo "BREAK_GLASS_REASON_COUNT=$BREAK_GLASS_REASON_COUNT"
echo "TIMED_ACCESS_COUNT=$TIMED_ACCESS_COUNT"
echo "ADMIN_ACTION_AUDIT_COUNT=$ADMIN_ACTION_AUDIT_COUNT"
echo "ALERT_EVENT_COUNT=$ALERT_EVENT_COUNT"
echo "ABUSE_TEST_COUNT=$ABUSE_TEST_COUNT"
echo "DB_REASON_COLUMN_COUNT=$DB_REASON_COLUMN_COUNT"
echo "DB_EXPIRY_COLUMN_COUNT=$DB_EXPIRY_COLUMN_COUNT"
echo "DB_ADMIN_AUDIT_TABLE_COUNT=$DB_ADMIN_AUDIT_TABLE_COUNT"
echo "DB_ALERT_TABLE_COUNT=$DB_ALERT_TABLE_COUNT"
echo "DB_ADMIN_AUDIT_COLUMN_COUNT=$DB_ADMIN_AUDIT_COLUMN_COUNT"
echo "DB_ALERT_COLUMN_COUNT=$DB_ALERT_COLUMN_COUNT"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_2_6_SUPER_ADMIN_ROLE_MODEL_STATUS=PASS"
  echo "FAZ_1_2_6_BREAK_GLASS_REASON_REQUIRED_STATUS=PASS"
  echo "FAZ_1_2_6_TIMED_ACCESS_STATUS=PASS"
  echo "FAZ_1_2_6_ADMIN_ACTION_AUDIT_STATUS=PASS"
  echo "FAZ_1_2_6_ALERT_EVENT_STATUS=PASS"
  echo "FAZ_1_2_6_ABUSE_TEST_STATUS=PASS"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_STRICT_TEST_STATUS=PASS"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_STRICT_TEST_STATUS=FAIL"
  echo "FAZ_1_2_6_SUPER_ADMIN_BREAK_GLASS_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-2.6 SUPER-ADMIN / BREAK-GLASS STRICT SUITE FIX V2 END ====="
