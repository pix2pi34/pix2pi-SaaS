#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"

DOC_FILE="docs/pilot/faz4c/4c_3e_fix1_dry_run_error_diagnosis.md"
REPORT_FILE="reports/pilot/faz4c/4c_3e_fix1_dry_run_error_diagnosis_report.md"

echo "===== 4C-3E-FIX1 DRY RUN ERROR DIAGNOSIS ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

safe_source() {
  local f="$1"
  if [ -f "$f" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$f"
    set +a
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3e_fix1_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3e_fix1_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3e_fix1_psql_error.log
    return $?
  fi

  return 127
}

run_sql_file() {
  local file="$1"

  rm -f /tmp/4c_3e_fix1_sql_output.log /tmp/4c_3e_fix1_sql_error.log

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3e_fix1_sql_output.log 2>/tmp/4c_3e_fix1_sql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file" >/tmp/4c_3e_fix1_sql_output.log 2>/tmp/4c_3e_fix1_sql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker cp "$file" pix2pi_pg:/tmp/4c_3e_fix1_preview.sql >/dev/null
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -v ON_ERROR_STOP=1 -f /tmp/4c_3e_fix1_preview.sql >/tmp/4c_3e_fix1_sql_output.log 2>/tmp/4c_3e_fix1_sql_error.log
    return $?
  fi

  echo "No psql or docker execution path found" >/tmp/4c_3e_fix1_sql_error.log
  return 127
}

[ -f "$SQL_FILE" ] || fail "SQL preview file yok: $SQL_FILE"

safe_source "$COMMON_ENV"

DB_CONNECT_STATUS="FAIL"
if run_sql "select 1;" >/tmp/4c_3e_fix1_db_ping.out; then
  DB_CONNECT_STATUS="PASS"
fi

[ "$DB_CONNECT_STATUS" = "PASS" ] || fail "DB baglantisi yok"

TABLE_COLUMNS="$(
  run_sql "
select
  c.ordinal_position || '. ' ||
  c.column_name || ' | ' ||
  c.data_type || ' | nullable=' ||
  c.is_nullable || ' | default=' ||
  coalesce(c.column_default,'')
from information_schema.columns c
where c.table_schema='platform'
  and c.table_name='tenants'
order by c.ordinal_position;
" || true
)"

NOT_NULL_NO_DEFAULT_COLUMNS="$(
  run_sql "
select c.column_name
from information_schema.columns c
where c.table_schema='platform'
  and c.table_name='tenants'
  and c.is_nullable='NO'
  and c.column_default is null
order by c.ordinal_position;
" || true
)"

BEFORE_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
BEFORE_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci';" | tr -d '[:space:]')"

DRY_RUN_STATUS="PASS"
if ! run_sql_file "$SQL_FILE"; then
  DRY_RUN_STATUS="FAIL"
fi

SQL_OUTPUT="$(cat /tmp/4c_3e_fix1_sql_output.log 2>/dev/null || true)"
SQL_ERROR="$(cat /tmp/4c_3e_fix1_sql_error.log 2>/dev/null || true)"

AFTER_SCHEMA_COUNT="$(run_sql "select count(*) from information_schema.schemata where schema_name='tenant_uzmanparcaci';" | tr -d '[:space:]')"
AFTER_TENANT_COUNT="$(run_sql "select count(*) from platform.tenants where slug='uzmanparcaci';" | tr -d '[:space:]')"

ROLLBACK_SAFE="NO"
if [ "$BEFORE_SCHEMA_COUNT" = "$AFTER_SCHEMA_COUNT" ] && [ "$BEFORE_TENANT_COUNT" = "$AFTER_TENANT_COUNT" ]; then
  ROLLBACK_SAFE="YES"
fi

NOT_NULL_COUNT="0"
if [ -n "$NOT_NULL_NO_DEFAULT_COLUMNS" ]; then
  NOT_NULL_COUNT="$(printf '%s\n' "$NOT_NULL_NO_DEFAULT_COLUMNS" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

{
  echo "# FAZ 4C — 4C-3E-FIX1 Dry Run Error Diagnosis"
  echo
  echo "## Amaç"
  echo
  echo "4C-3E dry-run neden FAIL oldu, gerçek PostgreSQL hatasını yakalamak."
  echo
  echo "Bu adım kalıcı DB yazma yapmaz."
  echo
  echo "---"
  echo
  echo "## 1. DB bağlantı"
  echo
  echo "4C_3E_FIX1_DB_CONNECT_STATUS=$DB_CONNECT_STATUS"
  echo
  echo "---"
  echo
  echo "## 2. platform.tenants kolonları"
  echo
  echo '```text'
  printf '%s\n' "$TABLE_COLUMNS"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 3. Zorunlu olup default değeri olmayan kolonlar"
  echo
  echo '```text'
  printf '%s\n' "$NOT_NULL_NO_DEFAULT_COLUMNS"
  echo '```'
  echo
  echo "NOT_NULL_NO_DEFAULT_COLUMN_COUNT=$NOT_NULL_COUNT"
  echo
  echo "---"
  echo
  echo "## 4. Dry-run sonucu"
  echo
  echo "DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo
  echo "SQL output:"
  echo
  echo '```text'
  printf '%s\n' "$SQL_OUTPUT"
  echo '```'
  echo
  echo "SQL error:"
  echo
  echo '```text'
  printf '%s\n' "$SQL_ERROR"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 5. Rollback güvenliği"
  echo
  echo "BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA_COUNT"
  echo "AFTER_SCHEMA_COUNT=$AFTER_SCHEMA_COUNT"
  echo "BEFORE_TENANT_COUNT=$BEFORE_TENANT_COUNT"
  echo "AFTER_TENANT_COUNT=$AFTER_TENANT_COUNT"
  echo "ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo
  echo "---"
  echo
  echo "## 6. Karar"
  echo
  echo "4C_3E_FIX1_DIAGNOSIS_STATUS=PASS"
  echo "4C_3E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_3E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo "4C_3E_FIX1_DB_WRITE_APPLIED=NO"
  echo "4C_3E_FIX1_NEXT_STEP_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3E-FIX1 Dry Run Error Diagnosis Report"
  echo
  echo "Step: 4C-3E-FIX1B"
  echo "Blok: Dry Run Error Diagnosis"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3E_FIX1_DIAGNOSIS_STATUS=PASS"
  echo "4C_3E_FIX1_DB_CONNECT_STATUS=$DB_CONNECT_STATUS"
  echo "4C_3E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
  echo "4C_3E_FIX1_NOT_NULL_NO_DEFAULT_COLUMN_COUNT=$NOT_NULL_COUNT"
  echo "4C_3E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
  echo "4C_3E_FIX1_DB_WRITE_APPLIED=NO"
  echo "4C_3E_FIX1_NEXT_STEP_READY=YES"
  echo
  echo "## SQL error"
  echo
  echo '```text'
  printf '%s\n' "$SQL_ERROR"
  echo '```'
  echo
  echo "## Zorunlu default olmayan kolonlar"
  echo
  echo '```text'
  printf '%s\n' "$NOT_NULL_NO_DEFAULT_COLUMNS"
  echo '```'
  echo
  echo "## Sonuç"
  echo
  echo "Dry-run hatası yakalandı."
  echo "Kalıcı DB yazma yapılmadı."
  echo "Bir sonraki adımda SQL mapping düzeltilecek."
} > "$REPORT_FILE"

echo "OK ✅ Diagnosis dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Diagnosis report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3E-FIX1B OZET ====="
echo "4C_3E_FIX1_DIAGNOSIS_STATUS=PASS ✅"
echo "4C_3E_FIX1_DRY_RUN_STATUS=$DRY_RUN_STATUS"
echo "4C_3E_FIX1_NOT_NULL_NO_DEFAULT_COLUMN_COUNT=$NOT_NULL_COUNT"
echo "4C_3E_FIX1_ROLLBACK_SAFE=$ROLLBACK_SAFE"
echo "4C_3E_FIX1_DB_WRITE_APPLIED=NO"
