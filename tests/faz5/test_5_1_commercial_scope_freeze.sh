#!/usr/bin/env bash
set -u

DOC="docs/faz5/5_1_commercial_master_plan_scope_freeze.md"
MASTER="docs/faz5/faz5_master_plan.md"
FAIL=0

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    echo "OK ✅ $label mevcut: $file"
  else
    echo "HATA ❌ $label yok: $file"
    FAIL=1
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    echo "OK ✅ $label"
  else
    echo "HATA ❌ $label bulunamadi: $pattern"
    FAIL=1
  fi
}

echo "===== FAZ 5-1 SCOPE FREEZE TEST BASLADI ====="

check_file "$MASTER" "FAZ 5 master plan"
check_file "$DOC" "5-1 scope freeze dokumani"

check_grep "$MASTER" "FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED" "master plan sealed"
check_grep "$MASTER" "FAZ_5_1_READY=YES" "5-1 giris izni"

check_grep "$DOC" "STEP_NO=5-1" "step no"
check_grep "$DOC" "STEP_NAME=Commercial Master Plan / Scope Freeze" "step name"
check_grep "$DOC" "STEP_STATUS=PASS" "step pass"
check_grep "$DOC" "STEP_SEAL_STATUS=SEALED" "step sealed"
check_grep "$DOC" "FAZ_5_1_SCOPE_FREEZE_STATUS=PASS" "scope freeze pass"
check_grep "$DOC" "FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED" "scope freeze sealed"
check_grep "$DOC" "FAZ_5_2_READY=YES" "5-2 ready"

check_grep "$DOC" "Karar 1 — FAZ 5 teknik büyütme fazı değildir" "teknik buyutme disi"
check_grep "$DOC" "Karar 2 — Paketleme önce gelir" "paketleme once gelir"
check_grep "$DOC" "Karar 3 — Abonelik operasyonu entitlement üstüne kurulacak" "abonelik entitlement bagimli"
check_grep "$DOC" "Karar 4 — Muhasebeci paketi ayrı ticari ürün kabul edilir" "muhasebeci paketi ayri"
check_grep "$DOC" "Karar 5 — Demo tenant kontrollü olacak" "demo tenant kontrollu"
check_grep "$DOC" "Karar 6 — Hukuki belgeler teknik yayın öncesi checklist olarak tutulacak" "hukuki checklist"
check_grep "$DOC" "Karar 7 — Support / SLA ticari pakete bağlı olacak" "support sla paket bagli"
check_grep "$DOC" "Karar 8 — Public yüzey commercial kararlar bitmeden yazılmaz" "public yuzey sonra"

check_grep "$DOC" "Durum:" "durum alanlari"
check_grep "$DOC" "IN_SCOPE" "kapsam ici"
check_grep "$DOC" "OUT_OF_SCOPE" "kapsam disi"
check_grep "$DOC" "5-2 Packages / Pricing" "5-2 bagimlilik"

if [ "$FAIL" -eq 0 ]; then
  echo "===== FAZ 5-1 SCOPE FREEZE TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5-1 SCOPE FREEZE TEST SONUCU: HATA ❌ ====="
  exit 1
fi
