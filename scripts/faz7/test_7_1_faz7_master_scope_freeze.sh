#!/usr/bin/env bash
set -Eeuo pipefail

FAIL_COUNT=0
PASS_COUNT=0

ok() {
  PASS_COUNT=$((PASS_COUNT+1))
  echo "$1 OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT+1))
  echo "$1 HATA ❌"
}

check_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    ok "$label file mevcut: $path"
  else
    fail "$label file eksik: $path"
  fi
}

check_grep() {
  local label="$1"
  local path="$2"
  local pattern="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    ok "$label bulundu"
  else
    fail "$label bulunamadi"
  fi
}

echo "===== FAZ 7-1 TEST BASLADI ====="

check_file "7-1" "docs/faz7/FAZ_7_MASTER_PLAN.md"
check_file "7-1" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md"
check_file "7-1" "docs/faz7/evidence/FAZ_7_1_SCOPE_FREEZE_EVIDENCE.md"
check_file "7-1" "scripts/faz7/test_7_1_faz7_master_scope_freeze.sh"
check_file "7-1" "scripts/faz7/audit_7_1_real_implementation.sh"

check_grep "7-1.1 FAZ 7 amaci" "docs/faz7/FAZ_7_MASTER_PLAN.md" "FAZ 7 Amaci"
check_grep "7-1.1.1 Moduler buyume kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Moduler buyume"
check_grep "7-1.1.2 Public launch hazirligi" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Public launch"
check_grep "7-1.1.3 Urunlestirme kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Urunlestirme"
check_grep "7-1.1.4 Ticari runtime kapsami" "docs/faz7/FAZ_7_MASTER_PLAN.md" "Ticari runtime"

check_grep "7-1.2 Scope freeze" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Scope Freeze"
check_grep "7-1.2.1 FAZ 7 dahil isler" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 dahil isler"
check_grep "7-1.2.2 FAZ 7 disi isler" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "FAZ 7 disi isler"
check_grep "7-1.2.3 Production public launch on sartlari" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Production public launch icin on sartlar"
check_grep "7-1.2.4 Cloudflare green mode gecis kapisi" "docs/faz7/FAZ_7_1_MASTER_SCOPE_FREEZE.md" "Cloudflare green mode"

check_grep "7-2 Product Packaging siradaki adim" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-2 — Product Packaging"
check_grep "7-3 Entitlement runtime kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-3 — Entitlement Runtime"
check_grep "7-4 Subscription runtime kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-4 — Commercial Account"
check_grep "7-5 Billing readiness kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-5 — Billing Readiness"
check_grep "7-13 Public launch gate kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-13 — Public Launch Gate"
check_grep "7-14 Final closure kapsamda" "docs/faz7/FAZ_7_MASTER_PLAN.md" "7-14 — FAZ 7 Final Closure"

echo
echo "===== FAZ 7-1 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7_1_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 7-1 testleri basariyla gecti"
else
  echo "FAZ_7_1_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 7-1 testlerinde hata var"
  exit 1
fi
