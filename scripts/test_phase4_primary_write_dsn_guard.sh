#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_primary_write_dsn_guard.sh"
REPORT="docs/phase4/14_1_4B_primary_write_dsn_guard_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ primary write dsn guard executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_4B_guard.log 2>&1 || {
  echo "TEST_FAIL ❌ primary write dsn guard hata verdi"
  cat /tmp/pix2pi_14_1_4B_guard.log || true
  exit 1
}

grep -Eq 'PRIMARY_WRITE_DSN_GUARD=(PASS|NEEDS_PRIMARY_DSN)' "$REPORT" || {
  echo "TEST_FAIL ❌ guard raporu beklenen sonucu icermiyor"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_PRIMARY_WRITE_DSN_GUARD_TEST=PASS ✅"
