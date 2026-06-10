#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"
PREV_REPORT="reports/pilot/faz4c/4c_6a_uat_execution_plan_report.md"
UAT_ENV="docs/pilot/faz4c/4c_6a_uat_execution_scope.env"
CHECKLIST="uat/pilot/faz4c/uzmanparcaci/uat_checklist.md"

DOC_FILE="docs/pilot/faz4c/4c_6b_uat_runtime_precheck.md"
REPORT_FILE="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_report.md"

TENANT_ID="6dfe8d22-035a-401f-807c-507408d2e439"
TENANT_BUSINESS_CODE="UZMANPARCACI"
TENANT_SLUG="uzmanparcaci"
TENANT_SCHEMA="tenant_uzmanparcaci"
PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"
PILOT_ROLE_CODE="PILOT_ADMIN"
STAGING_TABLE="tenant_uzmanparcaci.pilot_product_import_staging"
IMPORT_BATCH_CODE="UZMANPARCACI_SAMPLE_4C5E"

API_GATEWAY_HEALTH_URL="http://127.0.0.1:9010/health"
IDENTITY_HEALTH_URL="http://127.0.0.1:9002/health"

echo "===== 4C-6B UAT RUNTIME PRECHECK ====="

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

http_code() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -sS -o /tmp/4c_6b_http_body.tmp -w "%{http_code}" --max-time 5 "$url" 2>/tmp/4c_6b_http_error.tmp || echo "000"
  else
    echo "000"
  fi
}

port_status() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    if ss -ltn | awk '{print $4}' | grep -Eq "[:.]${port}$"; then
      echo "LISTEN"
    else
      echo "NOT_LISTEN"
    fi
  else
    echo "UNKNOWN"
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_6b_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_6b_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_6b_psql_error.log
    return $?
  fi

  return 127
}

safe_value() {
  local sql="$1"
  local out
  out="$(run_sql "$sql" 2>/dev/null || true)"
  out="$(printf "%s" "$out" | tr -d '[:space:]')"
  if [ -z "$out" ]; then
    echo "0"
  else
    echo "$out"
  fi
}

safe_text() {
  local sql="$1"
  run_sql "$sql" 2>/dev/null || true
}

[ -f "$PREV_REPORT" ] || fail "4C-6A report yok: $PREV_REPORT"
[ -f "$UAT_ENV" ] || fail "4C-6A env yok: $UAT_ENV"
[ -f "$CHECKLIST" ] || fail "UAT checklist yok: $CHECKLIST"

grep -q "4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-6A PASS degil"
grep -q "4C_6B_READY=YES" "$PREV_REPORT" || fail "4C-6B ready YES yok"

safe_source "$COMMON_ENV"

API_GATEWAY_PORT_STATUS="$(port_status 9010)"
IDENTITY_PORT_STATUS="$(port_status 9002)"
POSTGRES_PORT_STATUS="$(port_status 5433)"

API_GATEWAY_HEALTH_HTTP="$(http_code "$API_GATEWAY_HEALTH_URL")"
IDENTITY_HEALTH_HTTP="$(http_code "$IDENTITY_HEALTH_URL")"

DB_CONNECT_STATUS="PASS"
DB_PING_OUTPUT=""

if ! DB_PING_OUTPUT="$(run_sql "select 1;" 2>/dev/null)"; then
  DB_CONNECT_STATUS="FAIL"
fi

TENANT_COUNT="0"
TENANT_SCHEMA_COUNT="0"
USER_COUNT="0"
USER_TENANT_MATCH_COUNT="0"
ROLE_COUNT="0"
ROLE_TENANT_MATCH_COUNT="0"
ASSIGNMENT_COUNT="0"
ASSIGNMENT_TENANT_MATCH_COUNT="0"
STAGING_TABLE_EXISTS="0"
STAGING_ROW_COUNT="0"
DUPLICATE_SKU_COUNT="0"
TENANT_MISMATCH_COUNT="0"
EXPECTED_SKU_MATCH_COUNT="0"
OEM_FIELD_COUNT="0"
EQUIVALENT_FIELD_COUNT="0"
FITMENT_FIELD_COUNT="0"
VALIDATION_STATUS_COUNT="0"
SAMPLE_ROWS=""

if [ "$DB_CONNECT_STATUS" = "PASS" ]; then
  TENANT_COUNT="$(safe_value "
select count(*)
from platform.tenants
where id='${TENANT_ID}'::uuid
  and business_code='${TENANT_BUSINESS_CODE}'::core.code_text
  and slug='${TENANT_SLUG}';
")"

  TENANT_SCHEMA_COUNT="$(safe_value "
select count(*)
from information_schema.schemata
where schema_name='${TENANT_SCHEMA}';
")"

  USER_COUNT="$(safe_value "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}');
")"

  USER_TENANT_MATCH_COUNT="$(safe_value "
select count(*)
from auth.users
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
  and tenant_id='${TENANT_ID}'::uuid;
")"

  ROLE_COUNT="$(safe_value "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

  ROLE_TENANT_MATCH_COUNT="$(safe_value "
select count(*)
from auth.roles
where upper(role_code::text)=upper('${PILOT_ROLE_CODE}')
  and tenant_id='${TENANT_ID}'::uuid;
")"

  ASSIGNMENT_COUNT="$(safe_value "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}');
")"

  ASSIGNMENT_TENANT_MATCH_COUNT="$(safe_value "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}')
  and a.tenant_id='${TENANT_ID}'::uuid
  and u.tenant_id='${TENANT_ID}'::uuid
  and r.tenant_id='${TENANT_ID}'::uuid;
")"

  STAGING_TABLE_EXISTS="$(safe_value "
select count(*)
from information_schema.tables
where table_schema='tenant_uzmanparcaci'
  and table_name='pilot_product_import_staging'
  and table_type='BASE TABLE';
")"

  if [ "$STAGING_TABLE_EXISTS" = "1" ]; then
    STAGING_ROW_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}';
")"

    DUPLICATE_SKU_COUNT="$(safe_value "
select count(*)
from (
  select sku
  from ${STAGING_TABLE}
  where tenant_id='${TENANT_ID}'::uuid
    and import_batch_code='${IMPORT_BATCH_CODE}'
  group by sku
  having count(*) > 1
) d;
")"

    TENANT_MISMATCH_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id <> '${TENANT_ID}'::uuid;
")"

    EXPECTED_SKU_MATCH_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and sku in (
    'UZP-FREN-0001',
    'UZP-FILTRE-0002',
    'UZP-FILTRE-0003',
    'UZP-SUSP-0004',
    'UZP-MOTOR-0005'
  );
")"

    OEM_FIELD_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and trim(coalesce(oem_code,'')) <> '';
")"

    EQUIVALENT_FIELD_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and trim(coalesce(equivalent_code,'')) <> '';
")"

    FITMENT_FIELD_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and trim(coalesce(vehicle_fitment_note,'')) <> '';
")"

    VALIDATION_STATUS_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and validation_status='VALIDATED';
")"

    SAMPLE_ROWS="$(safe_text "
select
  sku || ' | ' ||
  product_name || ' | ' ||
  oem_code || ' | ' ||
  equivalent_code || ' | ' ||
  vehicle_fitment_note
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
order by source_row_number;
")"
  fi
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
PRECHECK_STATUS="PASS"

if [ "$DB_CONNECT_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$API_GATEWAY_HEALTH_HTTP" != "200" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$IDENTITY_HEALTH_HTTP" != "200" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_SCHEMA_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$USER_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLE_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ROLE_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ASSIGNMENT_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$ASSIGNMENT_TENANT_MATCH_COUNT" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$STAGING_TABLE_EXISTS" != "1" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$STAGING_ROW_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$DUPLICATE_SKU_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TENANT_MISMATCH_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$EXPECTED_SKU_MATCH_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$OEM_FIELD_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$EQUIVALENT_FIELD_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$FITMENT_FIELD_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$VALIDATION_STATUS_COUNT" != "5" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$API_GATEWAY_PORT_STATUS" != "LISTEN" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$IDENTITY_PORT_STATUS" != "LISTEN" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$POSTGRES_PORT_STATUS" != "LISTEN" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  PRECHECK_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat > "$DOC_FILE" <<DOC_EOF
# FAZ 4C — 4C-6B UAT Runtime Precheck

## Amaç

UAT başlamadan önce uzmanparcaci runtime, tenant, kullanıcı/rol ve staging ürün verisinin hazır olduğunu doğrulamak.

Bu adım DB'ye yazmaz.

---

## 1. Runtime endpoint kontrolleri

API_GATEWAY_PORT_STATUS=$API_GATEWAY_PORT_STATUS
API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP

IDENTITY_PORT_STATUS=$IDENTITY_PORT_STATUS
IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP

POSTGRES_PORT_STATUS=$POSTGRES_PORT_STATUS
DB_CONNECT_STATUS=$DB_CONNECT_STATUS

---

## 2. Tenant kontrolleri

TENANT_ID=$TENANT_ID
TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE
TENANT_COUNT=$TENANT_COUNT
TENANT_SCHEMA=$TENANT_SCHEMA
TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT

---

## 3. User / Role kontrolleri

PILOT_USER_EMAIL=$PILOT_USER_EMAIL
PILOT_ROLE_CODE=$PILOT_ROLE_CODE

USER_COUNT=$USER_COUNT
USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT
ROLE_COUNT=$ROLE_COUNT
ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT
ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT
ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT

---

## 4. Staging ürün veri kontrolleri

STAGING_TABLE=$STAGING_TABLE
STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS
STAGING_ROW_COUNT=$STAGING_ROW_COUNT
DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT
VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT

---

## 5. Oto yedek parça alanları

OEM_FIELD_COUNT=$OEM_FIELD_COUNT
EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT
FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT

Sample rows:

\`\`\`text
$SAMPLE_ROWS
\`\`\`

---

## 6. Status

4C_6B_UAT_RUNTIME_PRECHECK_STATUS=$PRECHECK_STATUS
4C_6B_API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
4C_6B_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
4C_6B_DB_CONNECT_STATUS=$DB_CONNECT_STATUS
4C_6B_TENANT_COUNT=$TENANT_COUNT
4C_6B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT
4C_6B_USER_COUNT=$USER_COUNT
4C_6B_ROLE_COUNT=$ROLE_COUNT
4C_6B_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT
4C_6B_STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS
4C_6B_STAGING_ROW_COUNT=$STAGING_ROW_COUNT
4C_6B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
4C_6B_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
4C_6B_OEM_FIELD_COUNT=$OEM_FIELD_COUNT
4C_6B_EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT
4C_6B_FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT
4C_6B_DB_WRITE_APPLIED=NO
4C_6B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_6B_WARNING_COUNT=$WARNING_COUNT
4C_6C_READY=$NEXT_READY
DOC_EOF

cat > "$REPORT_FILE" <<REPORT_EOF
# FAZ 4C — 4C-6B UAT Runtime Precheck Report

Step: 4C-6B
Blok: UAT Runtime Precheck
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6B_UAT_RUNTIME_PRECHECK_STATUS=$PRECHECK_STATUS
4C_6B_API_GATEWAY_PORT_STATUS=$API_GATEWAY_PORT_STATUS
4C_6B_API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
4C_6B_IDENTITY_PORT_STATUS=$IDENTITY_PORT_STATUS
4C_6B_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
4C_6B_POSTGRES_PORT_STATUS=$POSTGRES_PORT_STATUS
4C_6B_DB_CONNECT_STATUS=$DB_CONNECT_STATUS
4C_6B_TENANT_COUNT=$TENANT_COUNT
4C_6B_TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT
4C_6B_USER_COUNT=$USER_COUNT
4C_6B_USER_TENANT_MATCH_COUNT=$USER_TENANT_MATCH_COUNT
4C_6B_ROLE_COUNT=$ROLE_COUNT
4C_6B_ROLE_TENANT_MATCH_COUNT=$ROLE_TENANT_MATCH_COUNT
4C_6B_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT
4C_6B_ASSIGNMENT_TENANT_MATCH_COUNT=$ASSIGNMENT_TENANT_MATCH_COUNT
4C_6B_STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS
4C_6B_STAGING_ROW_COUNT=$STAGING_ROW_COUNT
4C_6B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
4C_6B_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
4C_6B_EXPECTED_SKU_MATCH_COUNT=$EXPECTED_SKU_MATCH_COUNT
4C_6B_OEM_FIELD_COUNT=$OEM_FIELD_COUNT
4C_6B_EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT
4C_6B_FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT
4C_6B_VALIDATION_STATUS_COUNT=$VALIDATION_STATUS_COUNT
4C_6B_DB_WRITE_APPLIED=NO
4C_6B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_6B_WARNING_COUNT=$WARNING_COUNT
4C_6C_READY=$NEXT_READY

## Sample rows

\`\`\`text
$SAMPLE_ROWS
\`\`\`

## Sonuc

UAT runtime precheck tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6C UAT Test Case Package.
REPORT_EOF

echo "OK ✅ UAT runtime precheck dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ UAT runtime precheck report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-6B RUNTIME PRECHECK OZET ====="
echo "4C_6B_UAT_RUNTIME_PRECHECK_STATUS=$PRECHECK_STATUS"
echo "4C_6B_API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP"
echo "4C_6B_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP"
echo "4C_6B_DB_CONNECT_STATUS=$DB_CONNECT_STATUS"
echo "4C_6B_TENANT_COUNT=$TENANT_COUNT"
echo "4C_6B_USER_COUNT=$USER_COUNT"
echo "4C_6B_ROLE_COUNT=$ROLE_COUNT"
echo "4C_6B_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT"
echo "4C_6B_STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS"
echo "4C_6B_STAGING_ROW_COUNT=$STAGING_ROW_COUNT"
echo "4C_6B_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT"
echo "4C_6B_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT"
echo "4C_6B_OEM_FIELD_COUNT=$OEM_FIELD_COUNT"
echo "4C_6B_EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT"
echo "4C_6B_FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT"
echo "4C_6B_DB_WRITE_APPLIED=NO"
echo "4C_6C_READY=$NEXT_READY"
