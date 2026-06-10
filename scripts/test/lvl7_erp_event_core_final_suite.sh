#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

CANDIDATE_PACKAGES=(
  "./internal/erp/core/audit/service"
  "./internal/erp/core/eventstore/domain"
  "./internal/erp/core/eventstore/engine"
  "./internal/erp/core/eventstore/service"
)

PACKAGES=()

for PKG in "${CANDIDATE_PACKAGES[@]}"; do
  DIR_PATH="${PKG#./}"
  if [ -d "$DIR_PATH" ]; then
    PACKAGES+=("$PKG")
  fi
done

FAIL_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0
FAILED_PACKAGES=()

echo "===== LVL7 ERP / EVENT CORE FINAL SUITE ====="
echo "REPO: $REPO_ROOT"
echo

if [ "${#PACKAGES[@]}" -eq 0 ]; then
  echo "HATA ❌ Test kosacak ERP/event paketi bulunamadi"
  exit 1
fi

for PKG in "${CANDIDATE_PACKAGES[@]}"; do
  DIR_PATH="${PKG#./}"

  if [ ! -d "$DIR_PATH" ]; then
    echo "ATLANDI ⏭️  Dizin yok: $PKG"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo
    continue
  fi

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

echo "===== LVL7 ERP / EVENT CORE FINAL SUITE OZET ====="
echo "GECEN PAKET SAYISI   : $PASS_COUNT"
echo "KALAN PAKET SAYISI   : $FAIL_COUNT"
echo "ATLANAN PAKET SAYISI : $SKIP_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo
  echo "KALAN PAKETLER:"
  for PKG in "${FAILED_PACKAGES[@]}"; do
    echo "- $PKG"
  done
  exit 1
fi

echo
echo "OK ✅ LVL7 ERP / event core final suite temiz gecti"
