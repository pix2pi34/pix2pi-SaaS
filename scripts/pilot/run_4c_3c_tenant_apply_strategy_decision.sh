#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TENANT_ENV="docs/pilot/faz4c/4c_3a_tenant_identity_setup_plan.env"
PRECHECK_REPORT="reports/pilot/faz4c/4c_3b_db_tenant_precheck_report.md"
DOC_FILE="docs/pilot/faz4c/4c_3c_tenant_apply_strategy_decision.md"
REPORT_FILE="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_report.md"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

echo "===== 4C-3C TENANT APPLY STRATEGY DECISION ====="

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
    psql "$DB_WRITE_DSN" -Atc "$sql" 2>/tmp/4c_3c_psql_error.log
    return $?
  fi

  if command -v psql >/dev/null 2>&1 && [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -Atc "$sql" 2>/tmp/4c_3c_psql_error.log
    return $?
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q '^pix2pi_pg$'; then
    docker exec pix2pi_pg psql -U pix2pi -d pix2pi -Atc "$sql" 2>/tmp/4c_3c_psql_error.log
    return $?
  fi

  return 127
}

get_report_value() {
  local key="$1"
  local file="$2"
  local value
  value="$(grep "^${key}=" "$file" | tail -n 1 | cut -d'=' -f2- | tr -d '\r' || true)"
  if [ -z "$value" ]; then
    echo "UNKNOWN"
  else
    echo "$value"
  fi
}

[ -f "$TENANT_ENV" ] || fail "Tenant env yok: $TENANT_ENV"
[ -f "$PRECHECK_REPORT" ] || fail "4C-3B precheck report yok: $PRECHECK_REPORT"

safe_source "$COMMON_ENV"
safe_source "$TENANT_ENV"

TENANT_CODE="${TENANT_CODE:-uzmanparcaci}"
TENANT_SCHEMA="${TENANT_SCHEMA:-tenant_uzmanparcaci}"
TENANT_DISPLAY_NAME="${TENANT_DISPLAY_NAME:-uzmanparcaci}"
TENANT_OWNER_EMAIL="${TENANT_OWNER_EMAIL:-uzmanparcaci1@gmail.com}"
TENANT_OWNER_PHONE="${TENANT_OWNER_PHONE:-5377457536}"

PRECHECK_STATUS="$(get_report_value 4C_3B_DB_TENANT_PRECHECK_STATUS "$PRECHECK_REPORT")"
DB_CONNECT_STATUS="$(get_report_value 4C_3B_DB_CONNECT_STATUS "$PRECHECK_REPORT")"
TENANT_SCHEMA_STATUS="$(get_report_value 4C_3B_TENANT_SCHEMA_STATUS "$PRECHECK_REPORT")"
TENANT_TABLE_COUNT="$(get_report_value 4C_3B_TENANT_TABLE_COUNT "$PRECHECK_REPORT")"

if [ "$PRECHECK_STATUS" != "PASS" ]; then
  fail "4C-3B precheck PASS degil"
fi

if [ "$DB_CONNECT_STATUS" != "PASS" ]; then
  fail "DB connect PASS degil"
fi

if ! run_sql "select 1;" >/tmp/4c_3c_db_ping.out; then
  ERR="$(cat /tmp/4c_3c_psql_error.log 2>/dev/null || true)"
  cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3C Tenant Apply Strategy Decision Report

Step: 4C-3C
Blok: Tenant Apply Strategy Decision
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3C_STRATEGY_STATUS=BLOCKED
4C_3C_DB_CONNECT_STATUS=FAIL
4C_3C_CRITICAL_BLOCKER_COUNT=1
4C_3C_BLOCKER_REASON=DB_CONNECTION_FAILED
4C_3C_DB_WRITE_APPLIED=NO
4C_3D_READY=NO

## Hata

\`\`\`text
$ERR
\`\`\`
REPORT_EOF

  echo "HATA ❌ DB baglantisi kurulamadi"
  exit 0
fi

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

TABLE_DETAILS=""
BEST_TABLE=""
BEST_SCORE="-1"

while IFS= read -r full_table; do
  [ -z "$full_table" ] && continue

  schema_name="${full_table%%.*}"
  table_name="${full_table#*.}"

  columns="$(run_sql "
select column_name || ':' || data_type
from information_schema.columns
where table_schema='${schema_name}'
  and table_name='${table_name}'
order by ordinal_position;
" || true)"

  score=0

  case "$(printf '%s' "$table_name" | tr '[:upper:]' '[:lower:]')" in
    tenants) score=$((score + 50)) ;;
    tenant) score=$((score + 45)) ;;
    organizations) score=$((score + 30)) ;;
    companies) score=$((score + 25)) ;;
    businesses) score=$((score + 25)) ;;
    *tenant*) score=$((score + 20)) ;;
  esac

  echo "$columns" | grep -qi '^id:' && score=$((score + 10))
  echo "$columns" | grep -qi '^tenant_id:' && score=$((score + 10))
  echo "$columns" | grep -qi '^code:' && score=$((score + 10))
  echo "$columns" | grep -qi '^slug:' && score=$((score + 8))
  echo "$columns" | grep -qi '^name:' && score=$((score + 8))
  echo "$columns" | grep -qi '^display_name:' && score=$((score + 8))
  echo "$columns" | grep -qi '^schema_name:' && score=$((score + 8))
  echo "$columns" | grep -qi '^status:' && score=$((score + 5))
  echo "$columns" | grep -qi '^created_at:' && score=$((score + 3))

  TABLE_DETAILS="${TABLE_DETAILS}
## ${full_table}

SCORE=${score}

\`\`\`text
${columns}
\`\`\`
"

  if [ "$score" -gt "$BEST_SCORE" ]; then
    BEST_SCORE="$score"
    BEST_TABLE="$full_table"
  fi
done <<< "$POSSIBLE_TENANT_TABLES"

if [ -z "$BEST_TABLE" ]; then
  BEST_TABLE="NONE"
  BEST_SCORE="0"
fi

SCHEMA_CREATE_NEEDED="NO"
if [ "$TENANT_SCHEMA_STATUS" = "MISSING" ]; then
  SCHEMA_CREATE_NEEDED="YES"
fi

TENANT_METADATA_INSERT_NEEDED="YES"
TENANT_SCHEMA_APPLY_NEEDED="$SCHEMA_CREATE_NEEDED"
TENANT_TABLE_STRATEGY="USE_EXISTING_CANDIDATE_TABLE"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0

if [ "$BEST_TABLE" = "NONE" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  TENANT_TABLE_STRATEGY="BLOCKED_NO_TENANT_TABLE"
fi

if [ "$SCHEMA_CREATE_NEEDED" = "YES" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$CRITICAL_BLOCKER_COUNT" -eq 0 ]; then
  STRATEGY_STATUS="PASS"
  NEXT_READY="YES"
else
  STRATEGY_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-3C Tenant Apply Strategy Decision

## Blok

4C-3C — Tenant Apply Strategy Decision

## Amac

Bu adim uzmanparcaci tenant kurulumu icin uygulanacak DB stratejisini belirler.

Bu adim DB'ye yazmaz.
Bu adim schema olusturmaz.
Bu adim tenant kaydi olusturmaz.
Bu adim sadece strateji karari uretir.

---

## 1. Onceki adim durumu

4C_3B_DB_TENANT_PRECHECK_STATUS=$PRECHECK_STATUS
4C_3B_DB_CONNECT_STATUS=$DB_CONNECT_STATUS
4C_3B_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT

---

## 2. Tenant identity

TENANT_DISPLAY_NAME=$TENANT_DISPLAY_NAME
TENANT_CODE=$TENANT_CODE
TENANT_SCHEMA=$TENANT_SCHEMA
TENANT_OWNER_EMAIL=$TENANT_OWNER_EMAIL
TENANT_OWNER_PHONE=$TENANT_OWNER_PHONE

---

## 3. Tenant tablo adaylari

Aday tenant tablolar:

\`\`\`text
$POSSIBLE_TENANT_TABLES
\`\`\`

Detay ve skor:

$TABLE_DETAILS

---

## 4. Secilen strateji

En uygun tenant metadata tablo adayi:

SELECTED_TENANT_TABLE=$BEST_TABLE
SELECTED_TENANT_TABLE_SCORE=$BEST_SCORE

Karar:

TENANT_TABLE_STRATEGY=$TENANT_TABLE_STRATEGY
TENANT_METADATA_INSERT_NEEDED=$TENANT_METADATA_INSERT_NEEDED
TENANT_SCHEMA_APPLY_NEEDED=$TENANT_SCHEMA_APPLY_NEEDED
TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED

---

## 5. Apply sirasi

4C-3D adiminda sadece apply paketi hazirlanacak.

Onerilen apply sirasi:

1. DB yedek/guard kontrolu
2. Tenant metadata tablo kolon mapping kontrolu
3. Tenant zaten var mi tekrar kontrolu
4. Tenant schema zaten var mi tekrar kontrolu
5. CREATE SCHEMA guardli SQL hazirligi
6. Tenant metadata INSERT guardli SQL hazirligi
7. Verification SQL hazirligi
8. Dry-run / preview
9. Sonra ayri adimda apply

---

## 6. SQL apply preview

Bu adimda apply yoktur.

Gelecek adimda hazirlanacak SQL mantigi:

\`\`\`sql
-- 1. tenant schema guard
CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci;

-- 2. tenant metadata insert
-- selected table: $BEST_TABLE
-- kolon mapping 4C-3D adiminda netlestirilecek
\`\`\`

---

## 7. Risk karari

Schema missing durumu normaldir.
Bu, yeni pilot tenant icin beklenen durumdur.

Tenant table count 3 oldugu icin dogrudan insert yapilmaz.
Once selected table kolonlari netlestirilecek.

---

## 8. Status

4C_3C_TENANT_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS
4C_3C_SELECTED_TENANT_TABLE=$BEST_TABLE
4C_3C_SELECTED_TENANT_TABLE_SCORE=$BEST_SCORE
4C_3C_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED
4C_3C_TENANT_METADATA_INSERT_NEEDED=$TENANT_METADATA_INSERT_NEEDED
4C_3C_TENANT_TABLE_STRATEGY=$TENANT_TABLE_STRATEGY
4C_3C_DB_WRITE_APPLIED=NO
4C_3C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3C_WARNING_COUNT=$WARNING_COUNT
4C_3C_NEXT_STEP_READY=$NEXT_READY
4C_3D_READY=$NEXT_READY

---

## 9. Sonraki adim

Sonraki adim:

4C-3D — Tenant Apply SQL Package / Dry Run Plan

Bu adimda DB apply scripti hazirlanacak ama dogrudan apply edilmeyecek.
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3C Tenant Apply Strategy Decision Report

Step: 4C-3C
Blok: Tenant Apply Strategy Decision
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3C_TENANT_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS
4C_3C_SELECTED_TENANT_TABLE=$BEST_TABLE
4C_3C_SELECTED_TENANT_TABLE_SCORE=$BEST_SCORE
4C_3C_TENANT_SCHEMA_STATUS=$TENANT_SCHEMA_STATUS
4C_3C_TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED
4C_3C_TENANT_METADATA_INSERT_NEEDED=$TENANT_METADATA_INSERT_NEEDED
4C_3C_TENANT_TABLE_STRATEGY=$TENANT_TABLE_STRATEGY
4C_3C_DB_WRITE_APPLIED=NO
4C_3C_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_3C_WARNING_COUNT=$WARNING_COUNT
4C_3D_READY=$NEXT_READY

## Sonuc

Tenant apply stratejisi belirlendi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-3D Tenant Apply SQL Package / Dry Run Plan.
REPORT_EOF

echo "OK ✅ Tenant apply strategy dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Tenant apply strategy report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-3C STRATEGY OZETI ====="
echo "4C_3C_TENANT_APPLY_STRATEGY_STATUS=$STRATEGY_STATUS"
echo "4C_3C_SELECTED_TENANT_TABLE=$BEST_TABLE"
echo "4C_3C_TENANT_SCHEMA_CREATE_NEEDED=$SCHEMA_CREATE_NEEDED"
echo "4C_3C_DB_WRITE_APPLIED=NO"
echo "4C_3D_READY=$NEXT_READY"
