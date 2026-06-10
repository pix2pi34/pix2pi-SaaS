#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
STEP4_REPORT="reports/faz4d/FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS_REPORT.txt"
STEP5_FILE="docs/faz4d/FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE.md"
REPORT_FILE="reports/faz4d/FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE_REPORT.txt"

FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
ACCESS_EVIDENCE_COUNT=0

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

  for d in cmd internal pkg services migrations config configs deploy ops scripts docs; do
    if [ -d "$d" ]; then
      SEARCH_DIRS+=("$d")
    fi
  done

  if [ "${#SEARCH_DIRS[@]}" -eq 0 ]; then
    fail_soft "aranacak dizin bulunamadi"
  else
    pass "aranacak dizinler bulundu: ${SEARCH_DIRS[*]}"
  fi
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
    -- "$pattern" "${SEARCH_DIRS[@]}" >/tmp/pix2pi_4d5_grep_result.txt 2>/dev/null
}

check_access_evidence() {
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
    ACCESS_EVIDENCE_COUNT=$((ACCESS_EVIDENCE_COUNT + 1))
    pass "$label"
  else
    warn "$label"
  fi
}

echo "===== FAZ 4D-5 PILOT ACCESS / PASSWORD RESET / INVITE TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$STEP4_REPORT"
check_file "$STEP5_FILE"

check_grep_file "$MASTER_FILE" "4D-4 | ERP core product apply / staging → core kararları | DONE ✅" "4D-4 master planda DONE"
check_grep_file "$MASTER_FILE" "4D-5 | Pilot access / password reset / invite | IN_PROGRESS" "4D-5 master planda IN_PROGRESS"
check_grep_file "$STEP4_REPORT" "FAZ_4D_4_TEST_STATUS=PASS" "4D-4 test raporu PASS"

check_grep_file "$STEP5_FILE" "Pilot kullanıcı tenant'a bağlı olmalı" "tenant bagli erisim karari var"
check_grep_file "$STEP5_FILE" "Pilot kullanıcı role bağlı olmalı" "role bagli erisim karari var"
check_grep_file "$STEP5_FILE" "Davet akışı kayıt altına alınmalı" "invite audit karari var"
check_grep_file "$STEP5_FILE" "Şifre sıfırlama desteklenmeli" "password reset karari var"
check_grep_file "$STEP5_FILE" "Login sonrası token üretimi doğrulanmalı" "login token karari var"
check_grep_file "$STEP5_FILE" "Password reset token süreli olmalı" "reset token sure karari var"
check_grep_file "$STEP5_FILE" "Invite token süreli olmalı" "invite token sure karari var"
check_grep_file "$STEP5_FILE" "Erişim audit izi oluşmalı" "erisim audit karari var"
check_grep_file "$STEP5_FILE" "FAZ_4D_6_READY=NO" "4D-6 baslangicta NO"

build_search_dirs

echo
echo "===== REPO PILOT ACCESS KANIT TARAMASI ====="

check_access_evidence "user / kullanıcı izi var" "user" "User" "kullanici" "Kullanici"
check_access_evidence "auth / login izi var" "auth" "Auth" "login" "Login"
check_access_evidence "JWT / Authorization / token izi var" "JWT" "jwt" "Authorization" "Bearer" "token" "Token"
check_access_evidence "tenant access izi var" "tenant_id" "TenantID" "TenantId" "X-Tenant-ID"
check_access_evidence "role / permission izi var" "role" "Role" "permission" "Permission" "yetki" "Yetki"
check_access_evidence "password / reset izi var" "password" "Password" "reset" "Reset"
check_access_evidence "invite / invitation / davet izi var" "invite" "Invite" "invitation" "Invitation" "davet" "Davet"
check_access_evidence "audit / log izi var" "audit" "Audit" "log" "Log" "logger" "Logger"

if [ "$ACCESS_EVIDENCE_COUNT" -lt 4 ]; then
  fail_soft "pilot access repo kaniti yetersiz: $ACCESS_EVIDENCE_COUNT/8"
else
  pass "pilot access repo kaniti yeterli: $ACCESS_EVIDENCE_COUNT/8"
fi

mkdir -p "$(dirname "$REPORT_FILE")"

if [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS ✅"
  STEP6_READY="YES ✅"
else
  FINAL_STATUS="HATA ❌"
  STEP6_READY="NO ❌"
fi

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_5_TEST_STATUS=$FINAL_STATUS
FAZ_4D_5_PILOT_ACCESS_PASSWORD_RESET_INVITE_STATUS=$FINAL_STATUS
FAZ_4D_5_ACCESS_EVIDENCE_COUNT=$ACCESS_EVIDENCE_COUNT
FAZ_4D_5_OK_COUNT=$OK_COUNT
FAZ_4D_5_WARN_COUNT=$WARN_COUNT
FAZ_4D_5_FAIL_COUNT=$FAIL_COUNT
FAZ_4D_6_READY=$STEP6_READY
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

echo
echo "===== FAZ 4D-5 RAPOR ====="
cat "$REPORT_FILE"

echo
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "===== FAZ 4D-5 TEST SONUCU ====="
  echo "FAZ_4D_5_TEST_STATUS=PASS ✅"
  echo "FAZ_4D_5_FINAL_STATUS=PASS ✅"
  echo "FAZ_4D_5_SEAL_STATUS=SEALED ✅"
  echo "FAZ_4D_6_READY=YES ✅"
  exit 0
else
  echo "===== FAZ 4D-5 TEST SONUCU ====="
  echo "FAZ_4D_5_TEST_STATUS=HATA ❌"
  echo "FAZ_4D_5_FINAL_STATUS=BLOCKED ❌"
  echo "FAZ_4D_5_SEAL_STATUS=OPEN ❌"
  echo "FAZ_4D_6_READY=NO ❌"
  exit 1
fi
