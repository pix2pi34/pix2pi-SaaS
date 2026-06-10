#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER_FILE="docs/faz4d/FAZ_4D_MASTER_PLAN.md"
INTAKE_FILE="docs/faz4d/FAZ_4D_1_CARRY_FORWARD_INTAKE_SCOPE_FREEZE.md"
REPORT_FILE="reports/faz4d/FAZ_4D_1_SCOPE_FREEZE_REPORT.txt"

pass() {
  echo "OK ✅ $1"
}

fail() {
  echo "HATA ❌ $1"
  exit 1
}

check_file() {
  local file="$1"
  if [ -f "$file" ]; then
    pass "dosya var: $file"
  else
    fail "dosya yok: $file"
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    echo "Aranan ifade: $pattern"
    fail "$label"
  fi
}

echo "===== FAZ 4D-1 TEST BASLIYOR ====="

check_file "$MASTER_FILE"
check_file "$INTAKE_FILE"

check_grep "$MASTER_FILE" "FAZ_4D_MASTER_PLAN_STATUS=SEALED" "4D master plan sealed"
check_grep "$MASTER_FILE" "FAZ_4D_SCOPE_FREEZE_STATUS=SEALED" "4D scope freeze sealed"
check_grep "$MASTER_FILE" "FAZ_4D_START_ALLOWED=YES" "4D start allowed"
check_grep "$MASTER_FILE" "4D-1 | Carry-forward Intake / Master Scope Freeze" "4D-1 master planda var"
check_grep "$MASTER_FILE" "4D-16 | FAZ 4D Final Closure / Seal" "4D final closure master planda var"

check_grep "$INTAKE_FILE" "FAZ_4D_1_CARRY_FORWARD_INTAKE_STATUS=ACCEPTED" "4D-1 carry-forward accepted"
check_grep "$INTAKE_FILE" "FAZ_4D_1_MASTER_SCOPE_FREEZE_STATUS=SEALED" "4D-1 scope freeze sealed"
check_grep "$INTAKE_FILE" "FAZ_4D_1_NEW_MAJOR_SCOPE_ALLOWED=NO" "4D-1 yeni buyuk scope kapali"
check_grep "$INTAKE_FILE" "FAZ_4D_2_READY=YES" "4D-2 ready"

check_grep "$INTAKE_FILE" "Security / Tenant Isolation Final Pilot Check" "devreden security isi var"
check_grep "$INTAKE_FILE" "Business Chain Final Validation" "devreden business chain isi var"
check_grep "$INTAKE_FILE" "ERP core product apply / staging" "devreden ERP core isi var"
check_grep "$INTAKE_FILE" "Pilot access / password reset / invite" "devreden pilot access isi var"
check_grep "$INTAKE_FILE" "Pilot business UI surface" "devreden pilot UI isi var"
check_grep "$INTAKE_FILE" "Oto yedek parça UI" "devreden oto yedek parca UI isi var"
check_grep "$INTAKE_FILE" "Barkod opsiyonel UI notu" "devreden barkod notu var"
check_grep "$INTAKE_FILE" "Marketplace discovery" "devreden marketplace discovery var"
check_grep "$INTAKE_FILE" "Paraşüt discovery" "devreden parasut discovery var"
check_grep "$INTAKE_FILE" "Controlled Pilot Go-Live" "devreden go-live isi var"
check_grep "$INTAKE_FILE" "Pilot Monitoring / Stabilization" "devreden monitoring isi var"
check_grep "$INTAKE_FILE" "Support / Feedback Loop" "devreden feedback isi var"
check_grep "$INTAKE_FILE" "Mobile-ready PWA" "devreden mobile-ready PWA isi var"
check_grep "$INTAKE_FILE" "Release / Rollback / Backup Gate" "devreden release rollback backup gate var"

mkdir -p "$(dirname "$REPORT_FILE")"

cat <<REPORT_EOF > "$REPORT_FILE"
FAZ_4D_1_TEST_STATUS=PASS ✅
FAZ_4D_MASTER_PLAN_STATUS=SEALED ✅
FAZ_4D_1_CARRY_FORWARD_INTAKE_STATUS=ACCEPTED ✅
FAZ_4D_1_MASTER_SCOPE_FREEZE_STATUS=SEALED ✅
FAZ_4D_2_READY=YES ✅
REPORT_CREATED_AT=$(date -Is)
REPORT_EOF

pass "rapor yazildi: $REPORT_FILE"

echo "===== FAZ 4D-1 TEST SONUCU ====="
echo "FAZ_4D_1_TEST_STATUS=PASS ✅"
echo "FAZ_4D_1_FINAL_STATUS=PASS ✅"
echo "FAZ_4D_1_SEAL_STATUS=SEALED ✅"
echo "FAZ_4D_2_READY=YES ✅"
