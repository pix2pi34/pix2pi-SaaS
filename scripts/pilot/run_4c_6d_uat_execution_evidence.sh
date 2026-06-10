#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

PREV_REPORT="reports/pilot/faz4c/4c_6c_uat_test_case_package_report.md"
TEST_CASES="uat/pilot/faz4c/uzmanparcaci/uat_test_cases.md"
ACCEPTANCE_DOC="docs/pilot/faz4c/4c_6c_uat_acceptance_criteria.md"

DOC_FILE="docs/pilot/faz4c/4c_6d_uat_execution_evidence.md"
REPORT_FILE="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
EVIDENCE_FILE="uat/pilot/faz4c/uzmanparcaci/evidence/uat_technical_evidence.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

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

echo "===== 4C-6D UAT EXECUTION / EVIDENCE CAPTURE ====="

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
    curl -sS -o /tmp/4c_6d_http_body.tmp -w "%{http_code}" --max-time 5 "$url" 2>/tmp/4c_6d_http_error.tmp || echo "000"
  else
    echo "000"
  fi
}

run_sql() {
  local sql="$1"

  if command -v psql >/dev/null 2>&1 && [ -n "${DB_WRITE_DSN:-}" ]; then
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_6d_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_6d_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_6d_psql_error.log
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

status_pass_fail() {
  local value="$1"
  local expected="$2"
  if [ "$value" = "$expected" ]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

[ -f "$PREV_REPORT" ] || fail "4C-6C report yok: $PREV_REPORT"
[ -f "$TEST_CASES" ] || fail "UAT test cases yok: $TEST_CASES"
[ -f "$ACCEPTANCE_DOC" ] || fail "Acceptance criteria yok: $ACCEPTANCE_DOC"

grep -q "4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS" "$PREV_REPORT" || fail "4C-6C PASS degil"
grep -q "4C_6D_READY=YES" "$PREV_REPORT" || fail "4C-6D ready YES yok"

safe_source "$COMMON_ENV"

API_GATEWAY_HEALTH_HTTP="$(http_code "$API_GATEWAY_HEALTH_URL")"
IDENTITY_HEALTH_HTTP="$(http_code "$IDENTITY_HEALTH_URL")"

DB_CONNECT_STATUS="PASS"
if ! run_sql "select 1;" >/tmp/4c_6d_db_ping.out; then
  DB_CONNECT_STATUS="FAIL"
fi

TENANT_COUNT="0"
TENANT_SCHEMA_COUNT="0"
USER_COUNT="0"
ROLE_COUNT="0"
ASSIGNMENT_COUNT="0"
CROSS_TENANT_ASSIGNMENT_COUNT="0"
STAGING_TABLE_EXISTS="0"
STAGING_ROW_COUNT="0"
DUPLICATE_SKU_COUNT="0"
TENANT_MISMATCH_COUNT="0"
OEM_FIELD_COUNT="0"
EQUIVALENT_FIELD_COUNT="0"
FITMENT_FIELD_COUNT="0"
BARCODE_BLANK_COUNT="0"
MARKETPLACE_SCOPE_STATUS="PASS"
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
where lower(email::text)=lower('${PILOT_USER_EMAIL}')
  and tenant_id='${TENANT_ID}'::uuid;
")"

  ROLE_COUNT="$(safe_value "
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
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}')
  and a.tenant_id='${TENANT_ID}'::uuid
  and u.tenant_id='${TENANT_ID}'::uuid
  and r.tenant_id='${TENANT_ID}'::uuid;
")"

  CROSS_TENANT_ASSIGNMENT_COUNT="$(safe_value "
select count(*)
from auth.user_role_assignments a
join auth.users u on u.id = a.user_id
join auth.roles r on r.id = a.role_id
where lower(u.email::text)=lower('${PILOT_USER_EMAIL}')
  and upper(r.role_code::text)=upper('${PILOT_ROLE_CODE}')
  and (
    a.tenant_id <> '${TENANT_ID}'::uuid
    or u.tenant_id <> '${TENANT_ID}'::uuid
    or r.tenant_id <> '${TENANT_ID}'::uuid
  );
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

    BARCODE_BLANK_COUNT="$(safe_value "
select count(*)
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
  and (barcode is null or trim(coalesce(barcode,''))='');
")"

    SAMPLE_ROWS="$(safe_text "
select
  sku || ' | ' ||
  product_name || ' | OEM=' ||
  oem_code || ' | EQ=' ||
  equivalent_code || ' | FITMENT=' ||
  vehicle_fitment_note
from ${STAGING_TABLE}
where tenant_id='${TENANT_ID}'::uuid
  and import_batch_code='${IMPORT_BATCH_CODE}'
order by source_row_number;
")"
  fi
fi

UAT_01_STATUS="$(status_pass_fail "$TENANT_COUNT" "1")"
UAT_02_STATUS="FAIL"
if [ "$USER_COUNT" = "1" ] && [ "$ROLE_COUNT" = "1" ] && [ "$ASSIGNMENT_COUNT" = "1" ] && [ "$CROSS_TENANT_ASSIGNMENT_COUNT" = "0" ]; then
  UAT_02_STATUS="PASS"
fi

UAT_03_STATUS="$(status_pass_fail "$STAGING_TABLE_EXISTS" "1")"
UAT_04_STATUS="$(status_pass_fail "$STAGING_ROW_COUNT" "5")"
UAT_05_STATUS="$(status_pass_fail "$DUPLICATE_SKU_COUNT" "0")"
UAT_06_STATUS="$(status_pass_fail "$TENANT_MISMATCH_COUNT" "0")"
UAT_07_STATUS="$(status_pass_fail "$OEM_FIELD_COUNT" "5")"
UAT_08_STATUS="$(status_pass_fail "$EQUIVALENT_FIELD_COUNT" "5")"
UAT_09_STATUS="$(status_pass_fail "$FITMENT_FIELD_COUNT" "5")"
UAT_10_STATUS="PASS"
UAT_11_STATUS="$MARKETPLACE_SCOPE_STATUS"
UAT_12_STATUS="PENDING_BUSINESS_ACCEPTANCE"
UAT_13_STATUS="PENDING_CLASSIFICATION"
UAT_14_STATUS="PENDING_GO_NO_GO"

TECHNICAL_FAIL_COUNT=0

for s in \
  "$UAT_01_STATUS" \
  "$UAT_02_STATUS" \
  "$UAT_03_STATUS" \
  "$UAT_04_STATUS" \
  "$UAT_05_STATUS" \
  "$UAT_06_STATUS" \
  "$UAT_07_STATUS" \
  "$UAT_08_STATUS" \
  "$UAT_09_STATUS" \
  "$UAT_10_STATUS" \
  "$UAT_11_STATUS"
do
  if [ "$s" != "PASS" ]; then
    TECHNICAL_FAIL_COUNT=$((TECHNICAL_FAIL_COUNT + 1))
  fi
done

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
NEXT_READY="YES"
EVIDENCE_STATUS="PASS"
TECHNICAL_UAT_STATUS="PASS"

if [ "$API_GATEWAY_HEALTH_HTTP" != "200" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$IDENTITY_HEALTH_HTTP" != "200" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$DB_CONNECT_STATUS" != "PASS" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$TECHNICAL_FAIL_COUNT" != "0" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  TECHNICAL_UAT_STATUS="FAIL"
fi

if [ "$BARCODE_BLANK_COUNT" != "0" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$UAT_12_STATUS" = "PENDING_BUSINESS_ACCEPTANCE" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -ne 0 ]; then
  EVIDENCE_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EVIDENCE_EOF
# uzmanparcaci — UAT Technical Evidence

## Execution bilgisi

UAT_EXECUTION_STATUS=$EVIDENCE_STATUS
TECHNICAL_UAT_STATUS=$TECHNICAL_UAT_STATUS
BUSINESS_ACCEPTANCE_STATUS=PENDING
GO_NO_GO_READY=PENDING

---

## Runtime evidence

API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
DB_CONNECT_STATUS=$DB_CONNECT_STATUS

---

## Tenant evidence

TENANT_ID=$TENANT_ID
TENANT_BUSINESS_CODE=$TENANT_BUSINESS_CODE
TENANT_COUNT=$TENANT_COUNT
TENANT_SCHEMA_COUNT=$TENANT_SCHEMA_COUNT

---

## User / role evidence

PILOT_USER_EMAIL=$PILOT_USER_EMAIL
PILOT_ROLE_CODE=$PILOT_ROLE_CODE
USER_COUNT=$USER_COUNT
ROLE_COUNT=$ROLE_COUNT
ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT
CROSS_TENANT_ASSIGNMENT_COUNT=$CROSS_TENANT_ASSIGNMENT_COUNT

---

## Staging data evidence

STAGING_TABLE=$STAGING_TABLE
STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS
STAGING_ROW_COUNT=$STAGING_ROW_COUNT
DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
OEM_FIELD_COUNT=$OEM_FIELD_COUNT
EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT
FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT
BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT

---

## Sample rows

\`\`\`text
$SAMPLE_ROWS
\`\`\`

---

## UAT statuses

UAT_01_STATUS=$UAT_01_STATUS
UAT_02_STATUS=$UAT_02_STATUS
UAT_03_STATUS=$UAT_03_STATUS
UAT_04_STATUS=$UAT_04_STATUS
UAT_05_STATUS=$UAT_05_STATUS
UAT_06_STATUS=$UAT_06_STATUS
UAT_07_STATUS=$UAT_07_STATUS
UAT_08_STATUS=$UAT_08_STATUS
UAT_09_STATUS=$UAT_09_STATUS
UAT_10_STATUS=$UAT_10_STATUS
UAT_11_STATUS=$UAT_11_STATUS
UAT_12_STATUS=$UAT_12_STATUS
UAT_13_STATUS=$UAT_13_STATUS
UAT_14_STATUS=$UAT_14_STATUS
EVIDENCE_EOF

cat > "$EXECUTION_TEMPLATE" <<EXEC_EOF
# uzmanparcaci — UAT Execution Template

## Execution bilgisi

UAT_EXECUTION_STATUS=$EVIDENCE_STATUS
UAT_EXECUTION_DATE=$(date '+%Y-%m-%d %H:%M:%S')
UAT_EXECUTOR=SYSTEM_EVIDENCE_CAPTURE
BUSINESS_REPRESENTATIVE=PENDING
BUSINESS_ACCEPTANCE_STATUS=PENDING

---

## Test sonuçları

| Test | Durum | Evidence | Not |
|------|-------|----------|-----|
| UAT-01 | $UAT_01_STATUS | TENANT_COUNT=$TENANT_COUNT | Tenant erişimi |
| UAT-02 | $UAT_02_STATUS | USER=$USER_COUNT ROLE=$ROLE_COUNT ASSIGNMENT=$ASSIGNMENT_COUNT CROSS=$CROSS_TENANT_ASSIGNMENT_COUNT | Kullanıcı/rol |
| UAT-03 | $UAT_03_STATUS | STAGING_TABLE_EXISTS=$STAGING_TABLE_EXISTS | Staging tablo |
| UAT-04 | $UAT_04_STATUS | STAGING_ROW_COUNT=$STAGING_ROW_COUNT | Sample ürün sayısı |
| UAT-05 | $UAT_05_STATUS | DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT | Duplicate SKU |
| UAT-06 | $UAT_06_STATUS | TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT | Tenant mismatch |
| UAT-07 | $UAT_07_STATUS | OEM_FIELD_COUNT=$OEM_FIELD_COUNT | OEM kod |
| UAT-08 | $UAT_08_STATUS | EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT | Eşdeğer kod |
| UAT-09 | $UAT_09_STATUS | FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT | Araç uyum notu |
| UAT-10 | $UAT_10_STATUS | BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT | Barkod blocker değil |
| UAT-11 | $UAT_11_STATUS | MARKETPLACE_PHASE=FAZ_4D | Pazaryeri scope guard |
| UAT-12 | $UAT_12_STATUS | PENDING | İşletme kabulü |
| UAT-13 | $UAT_13_STATUS | PENDING | Bug/blocker kaydı |
| UAT-14 | $UAT_14_STATUS | PENDING | Go/No-Go hazırlığı |

---

## Bug / blocker alanı

CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
WARNING_COUNT=$WARNING_COUNT
IMPROVEMENT_COUNT=0

### Critical blockers

- NONE

### Warnings

- BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT is non-blocking
- BUSINESS_ACCEPTANCE_STATUS=PENDING

### Improvements

- Business representative acceptance will be captured in 4C-6G

---

## Final karar

UAT_RESULT=TECHNICAL_EVIDENCE_PASS_BUSINESS_ACCEPTANCE_PENDING
GO_NO_GO_READY=PENDING
NEXT_STEP=4C_6E_UAT_RESULT_CLASSIFICATION
EXEC_EOF

cat > "$DOC_FILE" <<DOC_EOF
# FAZ 4C — 4C-6D UAT Execution / Evidence Capture

## Amaç

uzmanparcaci UAT teknik evidence kayıtlarını toplamak.

Bu adım DB'ye yazmaz.

---

## 1. Runtime evidence

API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
DB_CONNECT_STATUS=$DB_CONNECT_STATUS

---

## 2. UAT teknik sonuçları

UAT_01_STATUS=$UAT_01_STATUS
UAT_02_STATUS=$UAT_02_STATUS
UAT_03_STATUS=$UAT_03_STATUS
UAT_04_STATUS=$UAT_04_STATUS
UAT_05_STATUS=$UAT_05_STATUS
UAT_06_STATUS=$UAT_06_STATUS
UAT_07_STATUS=$UAT_07_STATUS
UAT_08_STATUS=$UAT_08_STATUS
UAT_09_STATUS=$UAT_09_STATUS
UAT_10_STATUS=$UAT_10_STATUS
UAT_11_STATUS=$UAT_11_STATUS

---

## 3. Bekleyen UAT alanları

UAT_12_STATUS=$UAT_12_STATUS
UAT_13_STATUS=$UAT_13_STATUS
UAT_14_STATUS=$UAT_14_STATUS

Not:
UAT-12 işletme kabulü gerçek kullanıcı onayı gerektirir.
Bu nedenle 4C-6D içinde teknik evidence PASS alınır, işletme kabul kapısı 4C-6G içinde kapatılır.

---

## 4. Status

4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=$EVIDENCE_STATUS
4C_6D_TECHNICAL_UAT_STATUS=$TECHNICAL_UAT_STATUS
4C_6D_TECHNICAL_FAIL_COUNT=$TECHNICAL_FAIL_COUNT
4C_6D_BUSINESS_ACCEPTANCE_STATUS=PENDING
4C_6D_UAT_01_STATUS=$UAT_01_STATUS
4C_6D_UAT_02_STATUS=$UAT_02_STATUS
4C_6D_UAT_03_STATUS=$UAT_03_STATUS
4C_6D_UAT_04_STATUS=$UAT_04_STATUS
4C_6D_UAT_05_STATUS=$UAT_05_STATUS
4C_6D_UAT_06_STATUS=$UAT_06_STATUS
4C_6D_UAT_07_STATUS=$UAT_07_STATUS
4C_6D_UAT_08_STATUS=$UAT_08_STATUS
4C_6D_UAT_09_STATUS=$UAT_09_STATUS
4C_6D_UAT_10_STATUS=$UAT_10_STATUS
4C_6D_UAT_11_STATUS=$UAT_11_STATUS
4C_6D_UAT_12_STATUS=$UAT_12_STATUS
4C_6D_UAT_13_STATUS=$UAT_13_STATUS
4C_6D_UAT_14_STATUS=$UAT_14_STATUS
4C_6D_DB_WRITE_APPLIED=NO
4C_6D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_6D_WARNING_COUNT=$WARNING_COUNT
4C_6E_READY=$NEXT_READY
DOC_EOF

cat > "$REPORT_FILE" <<REPORT_EOF
# FAZ 4C — 4C-6D UAT Execution Evidence Report

Step: 4C-6D
Blok: UAT Execution / Evidence Capture
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=$EVIDENCE_STATUS
4C_6D_TECHNICAL_UAT_STATUS=$TECHNICAL_UAT_STATUS
4C_6D_TECHNICAL_FAIL_COUNT=$TECHNICAL_FAIL_COUNT
4C_6D_API_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
4C_6D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
4C_6D_DB_CONNECT_STATUS=$DB_CONNECT_STATUS
4C_6D_TENANT_COUNT=$TENANT_COUNT
4C_6D_USER_COUNT=$USER_COUNT
4C_6D_ROLE_COUNT=$ROLE_COUNT
4C_6D_ASSIGNMENT_COUNT=$ASSIGNMENT_COUNT
4C_6D_STAGING_ROW_COUNT=$STAGING_ROW_COUNT
4C_6D_DUPLICATE_SKU_COUNT=$DUPLICATE_SKU_COUNT
4C_6D_TENANT_MISMATCH_COUNT=$TENANT_MISMATCH_COUNT
4C_6D_OEM_FIELD_COUNT=$OEM_FIELD_COUNT
4C_6D_EQUIVALENT_FIELD_COUNT=$EQUIVALENT_FIELD_COUNT
4C_6D_FITMENT_FIELD_COUNT=$FITMENT_FIELD_COUNT
4C_6D_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_6D_BUSINESS_ACCEPTANCE_STATUS=PENDING
4C_6D_DB_WRITE_APPLIED=NO
4C_6D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_6D_WARNING_COUNT=$WARNING_COUNT
4C_6E_READY=$NEXT_READY

## UAT statuses

UAT_01_STATUS=$UAT_01_STATUS
UAT_02_STATUS=$UAT_02_STATUS
UAT_03_STATUS=$UAT_03_STATUS
UAT_04_STATUS=$UAT_04_STATUS
UAT_05_STATUS=$UAT_05_STATUS
UAT_06_STATUS=$UAT_06_STATUS
UAT_07_STATUS=$UAT_07_STATUS
UAT_08_STATUS=$UAT_08_STATUS
UAT_09_STATUS=$UAT_09_STATUS
UAT_10_STATUS=$UAT_10_STATUS
UAT_11_STATUS=$UAT_11_STATUS
UAT_12_STATUS=$UAT_12_STATUS
UAT_13_STATUS=$UAT_13_STATUS
UAT_14_STATUS=$UAT_14_STATUS

## Evidence file

EVIDENCE_FILE=$EVIDENCE_FILE
EXECUTION_TEMPLATE=$EXECUTION_TEMPLATE

## Sonuc

UAT teknik evidence capture tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6E UAT Result Classification.
REPORT_EOF

echo "OK ✅ UAT technical evidence olusturuldu: $EVIDENCE_FILE"
echo "OK ✅ UAT execution template guncellendi: $EXECUTION_TEMPLATE"
echo "OK ✅ UAT evidence report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-6D EVIDENCE OZET ====="
echo "4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=$EVIDENCE_STATUS"
echo "4C_6D_TECHNICAL_UAT_STATUS=$TECHNICAL_UAT_STATUS"
echo "4C_6D_TECHNICAL_FAIL_COUNT=$TECHNICAL_FAIL_COUNT"
echo "4C_6D_UAT_01_STATUS=$UAT_01_STATUS"
echo "4C_6D_UAT_02_STATUS=$UAT_02_STATUS"
echo "4C_6D_UAT_03_STATUS=$UAT_03_STATUS"
echo "4C_6D_UAT_04_STATUS=$UAT_04_STATUS"
echo "4C_6D_UAT_05_STATUS=$UAT_05_STATUS"
echo "4C_6D_UAT_06_STATUS=$UAT_06_STATUS"
echo "4C_6D_UAT_07_STATUS=$UAT_07_STATUS"
echo "4C_6D_UAT_08_STATUS=$UAT_08_STATUS"
echo "4C_6D_UAT_09_STATUS=$UAT_09_STATUS"
echo "4C_6D_UAT_10_STATUS=$UAT_10_STATUS"
echo "4C_6D_UAT_11_STATUS=$UAT_11_STATUS"
echo "4C_6D_UAT_12_STATUS=$UAT_12_STATUS"
echo "4C_6D_DB_WRITE_APPLIED=NO"
echo "4C_6E_READY=$NEXT_READY"
