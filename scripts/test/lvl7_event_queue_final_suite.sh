#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

PACKAGES=(
  "./internal/platform/eventbus/service"
  "./internal/platform/eventstore/service"
  "./internal/platform/eventbus/domain"
  "./internal/platform/eventstore/domain"
  "./internal/platform/eventreplay/service"
  "./internal/platform"
)

FAIL_COUNT=0
PASS_COUNT=0
FAILED_PACKAGES=()

echo "===== LVL7 EVENT + QUEUE FINAL SUITE ====="
echo "REPO: $REPO_ROOT"
echo

for PKG in "${PACKAGES[@]}"; do
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

echo "===== LVL7 EVENT + QUEUE FINAL SUITE OZET ====="
echo "GECEN PAKET SAYISI : $PASS_COUNT"
echo "KALAN PAKET SAYISI : $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo
  echo "KALAN PAKETLER:"
  for PKG in "${FAILED_PACKAGES[@]}"; do
    echo "- $PKG"
  done
  exit 1
fi

echo
echo "OK ✅ LVL7 event + queue final suite temiz gecti"
