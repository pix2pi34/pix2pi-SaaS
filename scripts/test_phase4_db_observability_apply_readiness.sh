#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_observability_apply_readiness.sh"
REPORT="docs/phase4/14_3_3_db_observability_apply_readiness_report.md"
PATCH_PLAN="docs/phase4/14_3_3_db_observability_config_patch_candidate.sh"
ROLLBACK_PLAN="docs/phase4/14_3_3_db_observability_rollback_plan.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ DB observability apply readiness script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_3_3_apply_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ apply readiness script hata verdi"
  cat /tmp/pix2pi_14_3_3_apply_readiness.log || true
  sed -n '1,300p' "$REPORT" || true
  exit 1
}

grep -q "DB_OBSERVABILITY_APPLY_READINESS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ apply readiness PASS degil"
  sed -n '1,300p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_DB_OBSERVABILITY=0" "$REPORT" || {
  echo "TEST_FAIL ❌ APPLY_DB_OBSERVABILITY=0 kaniti yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_OBSERVABILITY_APPLY_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ apply executed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "POSTGRES_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ config changed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "EXTENSION_CREATED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ extension created NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "CONTAINER_RESTARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ container restarted NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "CONFIG_PATCH_PLAN_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ config patch plan created yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "ROLLBACK_PLAN_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ rollback plan created yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PATCH_PLAN" ]; then
  echo "TEST_FAIL ❌ patch plan yok"
  exit 1
fi

if [ ! -f "$ROLLBACK_PLAN" ]; then
  echo "TEST_FAIL ❌ rollback plan yok"
  exit 1
fi

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$PATCH_PLAN" || {
  echo "TEST_FAIL ❌ patch plan default blocked degil"
  sed -n '1,100p' "$PATCH_PLAN" || true
  exit 1
}

grep -q "exit 99" "$PATCH_PLAN" || {
  echo "TEST_FAIL ❌ patch plan safety exit yok"
  sed -n '1,100p' "$PATCH_PLAN" || true
  exit 1
}

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$ROLLBACK_PLAN" || {
  echo "TEST_FAIL ❌ rollback plan default blocked degil"
  sed -n '1,100p' "$ROLLBACK_PLAN" || true
  exit 1
}

grep -q "exit 99" "$ROLLBACK_PLAN" || {
  echo "TEST_FAIL ❌ rollback plan safety exit yok"
  sed -n '1,100p' "$ROLLBACK_PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_OBSERVABILITY_APPLY_READINESS_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_PATCH_PLAN_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_ROLLBACK_PLAN_TEST=PASS ✅"
echo "PHASE4_DB_OBSERVABILITY_SECRET_TEST=PASS ✅"
