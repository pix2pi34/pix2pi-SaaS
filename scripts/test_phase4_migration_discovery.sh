#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_discover_migration_chain.sh"
REPORT="docs/phase4/14_1_migration_chain_discovery.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ discovery script executable degil: $SCRIPT"
  exit 1
fi

bash "$SCRIPT" >/tmp/pix2pi_phase4_migration_discovery_test.log 2>&1

if [ ! -f "$REPORT" ]; then
  echo "TEST_FAIL ❌ report olusmadi: $REPORT"
  cat /tmp/pix2pi_phase4_migration_discovery_test.log || true
  exit 1
fi

grep -q "FAZ 4 / 14.1" "$REPORT" || {
  echo "TEST_FAIL ❌ report basligi eksik"
  exit 1
}

grep -q "Migration SQL adaylari" "$REPORT" || {
  echo "TEST_FAIL ❌ migration SQL adaylari bolumu eksik"
  exit 1
}

grep -q "Duplicate numeric version kontrolu" "$REPORT" || {
  echo "TEST_FAIL ❌ duplicate kontrol bolumu eksik"
  exit 1
}

grep -q "Up / Down pair kontrolu" "$REPORT" || {
  echo "TEST_FAIL ❌ up/down pair kontrol bolumu eksik"
  exit 1
}

echo "PHASE4_MIGRATION_DISCOVERY_TEST=PASS ✅"
echo "REPORT=$REPORT"
