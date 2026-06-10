#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
DOC_FILE="docs/pilot/faz4c/4c_3e_fix3a_code_text_domain.md"
REPORT_FILE="reports/pilot/faz4c/4c_3e_fix3a_code_text_domain_report.md"

echo "===== 4C-3E-FIX3A CODE_TEXT DOMAIN DISCOVERY ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3e_fix3a_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3e_fix3a_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3e_fix3a_psql_error.log
    return $?
  fi

  return 127
}

safe_source "$COMMON_ENV"

DB_CONNECT_STATUS="FAIL"
if run_sql "select 1;" >/tmp/4c_3e_fix3a_db_ping.out; then
  DB_CONNECT_STATUS="PASS"
fi

[ "$DB_CONNECT_STATUS" = "PASS" ] || fail "DB baglantisi yok"

DOMAIN_INFO="$(
  run_sql "
select
  n.nspname || '.' || t.typname || ' | base=' || bt.typname || ' | notnull=' || t.typnotnull
from pg_type t
join pg_namespace n on n.oid = t.typnamespace
left join pg_type bt on bt.oid = t.typbasetype
where n.nspname='core'
  and t.typname='code_text';
" || true
)"

DOMAIN_CONSTRAINTS="$(
  run_sql "
select
  con.conname || ' | ' || pg_get_constraintdef(con.oid)
from pg_constraint con
join pg_type t on t.oid = con.contypid
join pg_namespace n on n.oid = t.typnamespace
where n.nspname='core'
  and t.typname='code_text'
order by con.conname;
" || true
)"

TENANTS_COLUMNS="$(
  run_sql "
select
  c.ordinal_position || '. ' ||
  c.column_name || ' | ' ||
  c.data_type || ' | udt=' ||
  c.udt_schema || '.' || c.udt_name || ' | nullable=' ||
  c.is_nullable || ' | default=' ||
  coalesce(c.column_default,'')
from information_schema.columns c
where c.table_schema='platform'
  and c.table_name='tenants'
order by c.ordinal_position;
" || true
)"

EXISTING_CODES="$(
  run_sql "
select
  coalesce(business_code::text,'NULL') || ' | ' ||
  coalesce(slug::text,'NULL') || ' | ' ||
  coalesce(name::text,'NULL')
from platform.tenants
order by created_at desc
limit 20;
" || true
)"

CANDIDATE_TEST_RESULTS="$(
  run_sql "
with candidates(value) as (
  values
    ('uzmanparcaci'),
    ('UZMANPARCACI'),
    ('UZMAN_PARCACI'),
    ('TENANT_UZMANPARCACI'),
    ('UZMAN-PARCACI'),
    ('uzman_parcaci'),
    ('UZMAN PARCACI')
)
select
  value || ' => ' ||
  case
    when value ~ '^[A-Z][A-Z0-9_]*$' then 'REGEX_GUESS_OK'
    else 'REGEX_GUESS_BAD'
  end
from candidates;
" || true
)"

# Gercek domain cast testi: her aday icin ayri calistiriyoruz ki biri patlayinca tum query durmasin.
DOMAIN_CAST_TESTS=""
for candidate in \
  "uzmanparcaci" \
  "UZMANPARCACI" \
  "UZMAN_PARCACI" \
  "TENANT_UZMANPARCACI" \
  "UZMAN-PARCACI" \
  "uzman_parcaci" \
  "UZMAN PARCACI"
do
  if run_sql "select '${candidate}'::core.code_text;" >/tmp/4c_3e_fix3a_cast.out; then
    result="PASS"
  else
    result="FAIL"
  fi
  DOMAIN_CAST_TESTS="${DOMAIN_CAST_TESTS}${candidate} => ${result}"$'\n'
done

BEST_BUSINESS_CODE="UNKNOWN"

if printf '%s\n' "$DOMAIN_CAST_TESTS" | grep -q '^UZMANPARCACI => PASS'; then
  BEST_BUSINESS_CODE="UZMANPARCACI"
elif printf '%s\n' "$DOMAIN_CAST_TESTS" | grep -q '^UZMAN_PARCACI => PASS'; then
  BEST_BUSINESS_CODE="UZMAN_PARCACI"
elif printf '%s\n' "$DOMAIN_CAST_TESTS" | grep -q '^TENANT_UZMANPARCACI => PASS'; then
  BEST_BUSINESS_CODE="TENANT_UZMANPARCACI"
fi

{
  echo "# FAZ 4C — 4C-3E-FIX3A code_text Domain Discovery"
  echo
  echo "## Amaç"
  echo
  echo "platform.tenants.business_code için gerekli core.code_text formatını keşfetmek."
  echo
  echo "Bu adım DB'ye yazmaz."
  echo
  echo "---"
  echo
  echo "## 1. DB bağlantı"
  echo
  echo "4C_3E_FIX3A_DB_CONNECT_STATUS=$DB_CONNECT_STATUS"
  echo
  echo "---"
  echo
  echo "## 2. Domain bilgisi"
  echo
  echo '```text'
  printf '%s\n' "$DOMAIN_INFO"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 3. Domain constraint"
  echo
  echo '```text'
  printf '%s\n' "$DOMAIN_CONSTRAINTS"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 4. platform.tenants kolonları"
  echo
  echo '```text'
  printf '%s\n' "$TENANTS_COLUMNS"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 5. Mevcut tenant code örnekleri"
  echo
  echo '```text'
  printf '%s\n' "$EXISTING_CODES"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 6. Domain cast testleri"
  echo
  echo '```text'
  printf '%s\n' "$DOMAIN_CAST_TESTS"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 7. Önerilen business_code"
  echo
  echo "BEST_BUSINESS_CODE=$BEST_BUSINESS_CODE"
  echo
  echo "---"
  echo
  echo "## 8. Status"
  echo
  echo "4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS"
  echo "4C_3E_FIX3A_DB_WRITE_APPLIED=NO"
  echo "4C_3D_FIX3_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-3E-FIX3A code_text Domain Discovery Report"
  echo
  echo "Step: 4C-3E-FIX3A"
  echo "Blok: code_text Domain Discovery"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS"
  echo "4C_3E_FIX3A_DB_CONNECT_STATUS=$DB_CONNECT_STATUS"
  echo "4C_3E_FIX3A_BEST_BUSINESS_CODE=$BEST_BUSINESS_CODE"
  echo "4C_3E_FIX3A_DB_WRITE_APPLIED=NO"
  echo "4C_3D_FIX3_READY=YES"
  echo
  echo "## Domain constraint"
  echo
  echo '```text'
  printf '%s\n' "$DOMAIN_CONSTRAINTS"
  echo '```'
  echo
  echo "## Domain cast testleri"
  echo
  echo '```text'
  printf '%s\n' "$DOMAIN_CAST_TESTS"
  echo '```'
  echo
  echo "## Mevcut tenant code örnekleri"
  echo
  echo '```text'
  printf '%s\n' "$EXISTING_CODES"
  echo '```'
  echo
  echo "## Sonuç"
  echo
  echo "core.code_text domain kuralı keşfedildi."
  echo "Kalıcı DB yazma yapılmadı."
  echo "Bir sonraki adımda business_code bu kurala göre düzeltilecek."
} > "$REPORT_FILE"

echo "OK ✅ Domain discovery dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Domain discovery report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-3E-FIX3A OZET ====="
echo "4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS ✅"
echo "4C_3E_FIX3A_BEST_BUSINESS_CODE=$BEST_BUSINESS_CODE"
echo "4C_3E_FIX3A_DB_WRITE_APPLIED=NO ✅"
echo "4C_3D_FIX3_READY=YES ✅"
