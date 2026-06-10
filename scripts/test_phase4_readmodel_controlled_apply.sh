#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_readmodel_controlled_apply.sh"
MIGRATION_BASE="20260427_151001_readmodel_operational_tables"
REPORT="docs/phase4/15_3_readmodel_controlled_apply_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ controlled apply script executable degil"
  exit 1
fi

APPLY_READMODEL=0 bash "$SCRIPT" . "$MIGRATION_BASE" >/tmp/pix2pi_15_3_dry_run.log 2>&1 || {
  echo "TEST_FAIL ❌ dry-run controlled apply script hata verdi"
  cat /tmp/pix2pi_15_3_dry_run.log || true
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_CONTROLLED_APPLY=DRY_RUN_PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run pass yok"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_APPLY_MODE=DRY_RUN_BLOCKED_BY_DEFAULT" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run blocked mode yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run DB apply NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_READMODEL_CONTROLLED_APPLY_DRY_RUN_TEST=PASS ✅"
echo "PHASE4_READMODEL_CONTROLLED_APPLY_BLOCK_TEST=PASS ✅"
echo "PHASE4_READMODEL_CONTROLLED_APPLY_SECRET_TEST=PASS ✅"
