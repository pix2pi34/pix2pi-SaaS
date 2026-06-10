#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_observability_controlled_apply.sh"
REPORT="docs/phase4/14_3_4_db_observability_controlled_apply_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ controlled apply script executable degil"
  exit 1
fi

APPLY_DB_OBSERVABILITY=0 bash "$SCRIPT" . >/tmp/pix2pi_14_3_4_dry_run.log 2>&1 || {
  echo "TEST_FAIL ❌ controlled apply dry-run hata verdi"
  cat /tmp/pix2pi_14_3_4_dry_run.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_OBSERVABILITY_CONTROLLED_APPLY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "CONTROLLED_APPLY_MODE=DRY_RUN_NOOP" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run mode yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "POSTGRES_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run config changed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "CONTAINER_RESTARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run restart NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "EXTENSION_CREATED_OR_EXISTS=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ dry-run extension NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_OBSERVABILITY_CONTROLLED_APPLY_DRY_RUN_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_CONTROLLED_APPLY_SECRET_TEST=PASS ✅"
