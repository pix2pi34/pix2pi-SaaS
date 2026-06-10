#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

CANDIDATE_PACKAGES=(
  "./internal/erp/core/journal/service"
  "./internal/erp/core/ledger/service"
  "./internal/erp/core/rules/service"
  "./internal/erp/core/kernel/ufk/service"
)

FAIL_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0
FAILED_PACKAGES=()

echo "===== LVL7 ERP FLOW FINAL SUITE ====="
echo "REPO: $REPO_ROOT"
echo

FOUND_ANY=0

for PKG in "${CANDIDATE_PACKAGES[@]}"; do
  DIR_PATH="${PKG#./}"

  if [ ! -d "$DIR_PATH" ]; then
    echo "ATLANDI ⏭️  Dizin yok: $PKG"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo
    continue
  fi

  FOUND_ANY=1

  echo "----- TEST BASLIYOR: $PKG -----"
  echo

  if go test "$PKG" -v; then
    echo
    echo "OK ✅ GECTI: $PKG"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo
    echo "HATA ❌ KALDI: $PKG"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_PACKAGES+=("$PKG")
  fi

  echo
  echo "----------------------------------------"
  echo
done

echo "===== LVL7 ERP FLOW FINAL SUITE OZET ====="
echo "GECEN PAKET SAYISI   : $PASS_COUNT"
echo "KALAN PAKET SAYISI   : $FAIL_COUNT"
echo "ATLANAN PAKET SAYISI : $SKIP_COUNT"

if [ "$FOUND_ANY" -eq 0 ]; then
  echo
  echo "HATA ❌ Test kosacak ERP flow paketi bulunamadi"
  exit 1
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo
  echo "KALAN PAKETLER:"
  for PKG in "${FAILED_PACKAGES[@]}"; do
    echo "- $PKG"
  done
  exit 1
fi

echo
echo "OK ✅ LVL7 ERP flow final suite temiz gecti"
