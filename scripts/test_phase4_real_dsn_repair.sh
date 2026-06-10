#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_real_dsn_repair.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ real dsn repair script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_4A_real_dsn_repair.log 2>&1 || {
  echo "TEST_FAIL ❌ real dsn repair script hata verdi"
  cat /tmp/pix2pi_14_1_4A_real_dsn_repair.log || true
  exit 1
}

grep -Eq 'REAL_DSN_REPAIR=(PASS|NEEDS_MANUAL_DSN)' docs/phase4/14_1_4A_real_dsn_repair_report.md || {
  echo "TEST_FAIL ❌ repair raporu beklenen sonucu icermiyor"
  sed -n '1,180p' docs/phase4/14_1_4A_real_dsn_repair_report.md || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" docs/phase4/14_1_4A_real_dsn_repair_report.md; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_REAL_DSN_REPAIR_TEST=PASS ✅"
