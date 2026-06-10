#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TENANT_ENV="docs/pilot/faz4c/4c_3a_tenant_identity_setup_plan.env"
DOC_FILE="docs/pilot/faz4c/4c_3b_db_tenant_precheck.md"
REPORT_FILE="reports/pilot/faz4c/4c_3b_db_tenant_precheck_report.md"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

echo "===== 4C-3B DB TENANT PRECHECK ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3b_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3b_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3b_psql_error.log
    return $?
  fi

  return 127
}

[ -f "$TENANT_ENV" ] || fail "Tenant env yok: $TENANT_ENV"

safe_source "$COMMON_ENV"
safe_source "$TENANT_ENV"

TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"
TENANT_CODE="${TENANT_CODE:-uzmanparcaci}"
TENANT_DISPLAY_NAME="${TENANT_DISPLAY_NAME:-uzmanparcaci}"

PSQL_AVAILABLE="NO"
if command -v psql >/dev/null 2>&1; then
  PSQL_AVAILABLE="YES"
fi

DOCKER_AVAILABLE="NO"
if command -v docker >/dev/null 2>&1; then
  DOCKER_AVAILABLE="YES"
fi

DB_CONNECT_STATUS="UNKNOWN"

if run_sql "select 1;" >/tmp/4c_3b_db_ping.out; then
  DB_CONNECT_STATUS="PASS"
else
  DB_CONNECT_STATUS="FAIL"
fi

if [ "$DB_CONNECT_STATUS" != "PASS" ]; then
  ERR="$(cat /tmp/4c_3b_psql_error.log 2>/dev/null || true)"

  cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3B DB Tenant Precheck Report

Step: 4C-3B
Blok: DB Tenant Precheck / Existing Tenant Discovery
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3B_DB_CONNECT_STATUS=FAIL
4C_3B_PSQL_AVAILABLE=$PSQL_AVAILABLE
4C_3B_DOCKER_AVAILABLE=$DOCKER_AVAILABLE
4C_3B_TENANT_SCHEMA=$TENANT_SCHEMA
4C_3B_TENANT_CODE=$TENANT_CODE
4C_3B_CRITICAL_BLOCKER_COUNT=1
4C_3B_BLOCKER_REASON=DB_CONNECTION_FAILED
4C_3B_NEXT_STEP_READY=NO
4C_3C_READY=NO

## Hata

\`\`\`text
$ERR
\`\`\`

## Sonuc

DB tenant precheck tamamlanamadi.
DB baglantisi cozulmeden tenant setup apply adimina gecilmez.
REPORT_EOF

  cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-3B DB Tenant Precheck

4C_3B_DB_CONNECT_STATUS=FAIL
4C_3B_CRITICAL_BLOCKER_COUNT=1
4C_3B_NEXT_STEP_READY=NO

DB baglantisi kurulamadigi icin tenant discovery yapilamadi.
DOC_EOF

  echo "HATA ❌ DB baglantisi kurulamadi"
  echo "4C_3B_DB_CONNECT_STATUS=FAIL"
  echo "4C_3B_CRITICAL_BLOCKER_COUNT=1"
  exit 0
fi

SCHEMA_EXISTS="$(run_sql "select count(*) from information_schema.schemata where schema_name='${TENANT_SCHEMA}';" | tr -d '[:space:]')"

TENANT_SCHEMAS="$(run_sql "
select schema_name
from information_schema.schemata
where schema_name like 'tenant%'
order by schema_name;
" || true)"

POSSIBLE_TENANT_TABLES="$(run_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('pg_catalog','information_schema')
  and (
    lower(table_name) in ('tenant','tenants','organizations','companies','businesses')
    or lower(table_name) like '%tenant%'
  )
order by table_schema, table_name;
" || true)"

PUBLIC_TABLES="$(run_sql "
select table_schema || '.' || table_name
from information_schema.tables
where table_type='BASE TABLE'
  and table_schema='public'
order by table_name;
" || true)"

TENANT_TABLE_COUNT="0"
if [ -n "$POSSIBLE_TENANT_TABLES" ]; then
  TENANT_TABLE_COUNT="$(printf '%s\n' "$POSSIBLE_TENANT_TABLES" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

PUBLIC_TABLE_COUNT="0"
if [ -n "$PUBLIC_TABLES" ]; then
  PUBLIC_TABLE_COUNT="$(printf '%s\n' "$PUBLIC_TABLES" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

TENANT_SCHEMA_COUNT="0"
if [ -n "$TENANT_SCHEMAS" ]; then
  TENANT_SCHEMA_COUNT="$(printf '%s\n' "$TENANT_SCHEMAS" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0

if [ "$TENANT_TABLE_COUNT" = "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$SCHEMA_EXISTS" = "1" ]; then
  TENANT_SCHEMA_STATUS="EXISTS"
  WARNING_COUNT=$((WARNING_COUNT + 1))
else
  TENANT_SCHEMA_STATUS="MISSING"
fi

NEXT_READY="YES"

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-3B DB Tenant Precheck / Existing Tenant Discovery

## Blok

4C-3B — DB Tenant Precheck / Existing Tenant Discovery

## Amaç

Bu adım uzmanparcaci tenant kurulumu öncesi DB tarafında mevcut tenant yapısını keşfeder.

Bu adım DB'ye yazmaz.
Bu adım schema oluşturmaz.
Bu adım tenant kaydı oluşturmaz.
Bu adım sadece okuma yapar.

---

## 1. Tenant identity

TENANT_DISPLAY_NAME=$TENANT_DISPLAY_NAME
TENANT_CODE=$TENANT_CODE
TENANT_SCHEMA=$TENANT_SCHEMA

---

## 2. DB bağlantı durumu

4C_3B_DB_CONNECT_STATUS=$DB_CONNECT_STATUS
PSQL_AVAILABLE=$PSQL_AVAILABLE
DOCKER_AVAILABLE=$DOCKER_AVAILABLE

---

## 3. Tenant schema durumu

TENANT_SCHEMA=$TENANT_SCHEMA
TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS

Mevcut tenant schema listesi:

\`\`\`text
$TENANT_SCHEMAS
\`\`\`

---

## 4. Olası tenant tabloları

Olası tenant/organization/business tabloları:

\`\`\`text
$POSSIBLE_TENANT_TABLES
\`\`\`

TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT

---

## 5. Public tablo özeti

Public schema tablo sayısı:

PUBLIC_TABLE_COUNT=$PUBLIC_TABLE_COUNT

Public tablolar:

\`\`\`text
$PUBLIC_TABLES
\`\`\`

---

## 6. Karar

4C_3B_DB_TENANT_PRECHECK_STATUS=PASS
4C_3B_DB_CONNECT_STATUS=PASS
4C_3B_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
4C_3B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT
4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT
4C_3B_PUBLIC_TABLE_COUNT=$PUBLIC_TABLE_COUNT
4C_3B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3B_WARNING_COUNT=$WARNING_COUNT
4C_3B_DB_WRITE_APPLIED=NO
4C_3B_NEXT_STEP_READY=$NEXT_READY
4C_3C_READY=$NEXT_READY

---

## 7. Sonraki adım

Sonraki adım:

4C-3C — Tenant Apply Strategy Decision

Bu adımda mevcut DB yapısına göre tenant kaydının ve schema kurulumunun nasıl yapılacağı belirlenecek.
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3B DB Tenant Precheck Report

Step: 4C-3B
Blok: DB Tenant Precheck / Existing Tenant Discovery
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3B_DB_TENANT_PRECHECK_STATUS=PASS
4C_3B_DB_CONNECT_STATUS=PASS
4C_3B_TENANT_CODE=$TENANT_CODE
4C_3B_TENANT_SCHEMA=$TENANT_SCHEMA
4C_3B_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
4C_3B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT
4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT
4C_3B_PUBLIC_TABLE_COUNT=$PUBLIC_TABLE_COUNT
4C_3B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3B_WARNING_COUNT=$WARNING_COUNT
4C_3B_DB_WRITE_APPLIED=NO
4C_3B_NEXT_STEP_READY=$NEXT_READY
4C_3C_READY=$NEXT_READY

## Sonuc

DB tenant precheck tamamlandi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-3C Tenant Apply Strategy Decision.
REPORT_EOF

echo "OK ✅ DB tenant precheck dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ DB tenant precheck report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-3B PRECHECK OZETI ====="
echo "4C_3B_DB_TENANT_PRECHECK_STATUS=PASS ✅"
echo "4C_3B_DB_CONNECT_STATUS=PASS ✅"
echo "4C_3B_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS"
echo "4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT"
echo "4C_3B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
echo "4C_3C_READY=$NEXT_READY ✅"
