#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP1_REPORT="reports/faz4d/FAZ_4D_1_SCOPE_FREEZE_REPORT.txt"
STEP2_FILE="docs/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_FINAL_PILOT_CHECK.md"
REPORT_FILE="reports/faz4d/FAZ_4D_2_SECURITY_TENANT_ISOLATION_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0

pass() {
  OK_COUNT=$((OK_COUNT + 1))
  echo "OK ✅ $1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "UYARI ⚠️ $1"
}

fail_soft() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "HATA ❌ $1"
}

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    pass "dosya var: $file"
  else
    fail_soft "dosya yok: $file"
  fi
}

check_grep_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail_soft "$label dosya yok: $file"
    return
  fi

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

build_search_dirs() {
  SEARCH_DIRS=()

  for d in cmd internal pkg services migrations config configs deploy ops scripts; do
    if [ -d "$d" ]; then
      SEARCH_DIRS+=("$d")
    fi
  done

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    fail_soft "aranacak kod dizini bulunamadi"
  else
    pass "aranacak kod dizinleri bulundu: ${SEARCH_DIRS[*]}"
  fi
}

repo_has_fixed() {
  local pattern="$1"

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    return 1
  fi

  grep -R -I -F -n \
    --exclude-dir=.git \
    --exclude-dir=backups \
    --exclude-dir=node_modules \
    --exclude-dir=vendor \
    --exclude-dir=tmp \
    --exclude-dir=dist \
    --exclude-dir=build \
    -- "$pattern" "${SEARCH_DIRS[@]}" >/tmp/pix2pi_4d2_grep_result.txt 2>/dev/null
}

repo_has_regex() {
  local pattern="$1"

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    return 1
  fi

  grep -R -I -E -n \
    --exclude-dir=.git \
    --exclude-dir=backups \
    --exclude-dir=node_modules \
    --exclude-dir=vendor \
    --exclude-dir=tmp \
    --exclude-dir=dist \
    --exclude-dir=build \
    -- "$pattern" "${SEARCH_DIRS[@]}" >/tmp/pix2pi_4d2_grep_result.txt 2>/dev/null
}

check_repo_any() {
  local label="$1"
  shift

  local found="NO"
  local pattern=""

  for pattern in "$@"; do
    if repo_has_fixed "$pattern"; then
      found="YES"
      break
    fi
  done

  if [ "$found" = "YES" ]; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_repo_any_regex() {
  local label="$1"
  shift

  local found="NO"
  local pattern=""

  for pattern in "$@"; do
    if repo_has_regex "$pattern"; then
      found="YES"
      break
    fi
  done

  if [ "$found" = "YES" ]; then
    pass "$label"
  else
    fail_soft "$label"
  fi
}

check_repo_optional_regex() {
  local label="$1"
  shift

  local found="NO"
  local pattern=""

  for pattern in "$@"; do
    if repo_has_regex "$pattern"; then
      found="YES"
      break
    fi
  done

  if [ "$found" = "YES" ]; then
    pass "$label"
  else
    warn "$label"
  fi
}

echo "===== FAZ 4D-2 SECURITY / TENANT ISOLATION TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP1_REPORT"
check_file "$STEP2_FILE"

check_grep_file "$MASTER_FILE" "4D-1 | Carry-forward Intake / Master Scope Freeze | DONE ✅" "4D-1 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-2 | Security / Tenant Isolation Final Pilot Check | IN_PROGRESS" "4D-2 master planda IN_PROGRESS"
check_grep_file "$STEP1_REPORT" "FAZ_4D_1_TEST_STATUS=PASS" "4D-1 test raporu PASS"
check_grep_file "$STEP2_FILE" "FAZ 4D-2" "4D-2 dokumani baslik kontrolu"

build_search_dirs

echo
echo "===== KRITIK TENANT / SECURITY KANIT TARAMASI ====="

check_repo_any_regex "tenant_id veya TenantID izi var" "tenant_id" "TenantID" "TenantId" "tenantID"
check_repo_any "X-Tenant-ID izi var" "X-Tenant-ID"
check_repo_any_regex "JWT veya Authorization izi var" "JWT" "jwt" "Authorization" "Bearer"
check_repo_any_regex "tenant middleware/context izi var" "TenantMiddleware" "tenant middleware" "TenantContext" "tenant context" "WithTenant" "GetTenant"
check_repo_any_regex "RLS / policy / tenant filter izi var" "RLS" "row level security" "CREATE POLICY" "USING.*tenant" "tenant_id.*=" "WHERE.*tenant"
check_repo_optional_regex "audit / log / security event izi var" "audit" "Audit" "security event" "SecurityEvent" "logger" "Logger"
check_repo_optional_regex "event tenant izi var" "event.*tenant" "tenant.*event" "Event.*Tenant" "Tenant.*Event" "tenant_id"
check_repo_optional_regex "super admin boundary izi var" "super.?admin" "SuperAdmin" "is_super_admin" "role.*admin"

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP3_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP3_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_2_TEST_STATUS=$FINAL_STATUS
FAZ_4D_2_SECURITY_TENANT_ISOLATION_FINAL_PILOT_CHECK_STATUS=$FINAL_STATUS
FAZ_4D_2_OK_COUNT=$OK_COUNT
FAZ_4D_2_WARN_COUNT=$WARN_COUNT
FAZ_4D_2_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_3_READY=$STEP3_READY
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-2 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-2 TEST SONUCU ====="
  echo "FAZ_4D_2_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_2_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_2_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_3_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-2 TEST SONUCU ====="
  echo "FAZ_4D_2_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_2_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_2_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_3_READY=NO ❌"
  exit 1
fi
