#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_backfill_rebuild_standard.sh"
PY_SCRIPT="scripts/phase4b_backfill_rebuild_standard.py"
REPORT="docs/phase4/14_4_backfill_rebuild_report.md"
MATRIX="docs/phase4/14_4_backfill_rebuild_matrix.tsv"
MANIFEST="config/backfill/backfill_rebuild_manifest.tsv"
DOC_MANIFEST="docs/phase4/14_4_backfill_rebuild_manifest.tsv"
PLAN="docs/phase4/14_4_backfill_rebuild_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ backfill rebuild wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ backfill rebuild python executable degil"
  exit 1
fi

if [ ! -x "$PLAN" ]; then
  echo "TEST_FAIL ❌ candidate plan executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash -n "$PLAN" || {
  echo "TEST_FAIL ❌ candidate plan bash syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_14_4_backfill_rebuild_standard.log 2>&1 || {
  echo "TEST_FAIL ❌ backfill rebuild standard script hata verdi"
  cat /tmp/pix2pi_14_4_backfill_rebuild_standard.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "BACKFILL_REBUILD_STANDARD=PASS" \
  "FAZ4B_14_4_FINAL_STATUS=PASS" \
  "PREVIOUS_14_1_FINAL_STATUS=PASS" \
  "PREVIOUS_14_2_FINAL_STATUS=PASS" \
  "PREVIOUS_14_3_FINAL_STATUS=PASS" \
  "BACKFILL_REBUILD_MANIFEST_STATUS=PASS" \
  "BACKFILL_REBUILD_DRY_RUN_STATUS=PASS" \
  "BACKFILL_REBUILD_APPLY_GATE_STATUS=PASS" \
  "BACKFILL_REBUILD_IDEMPOTENCY_STATUS=PASS" \
  "BACKFILL_REBUILD_RESUME_STATUS=PASS" \
  "BACKFILL_REBUILD_TENANT_SAFETY_STATUS=PASS" \
  "BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "BACKFILL_APPLY_EXECUTED=NO" \
  "REBUILD_APPLY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,900p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$PLAN"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for job in \
  readmodel_operational_rebuild \
  reporting_finance_mart_backfill \
  reporting_export_mart_backfill \
  reporting_payment_reconciliation_backfill \
  inventory_balance_rebuild \
  search_projection_rebuild \
  materialized_cache_projection_refresh \
  import_staging_validation_rebuild
do
  grep -q "$job" "$MANIFEST" || {
    echo "TEST_FAIL ❌ job eksik: $job"
    cat "$MANIFEST" || true
    exit 1
  }
done

PLAN_OUT="$(bash "$PLAN")"
echo "$PLAN_OUT" | grep -q "BACKFILL_PLAN_BLOCKED_BY_DEFAULT=YES" || {
  echo "TEST_FAIL ❌ candidate plan blocked by default degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "BACKFILL_APPLY_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ candidate plan no apply degil"
  echo "$PLAN_OUT"
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$MANIFEST" "$DOC_MANIFEST"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_BACKFILL_REBUILD_STANDARD_TEST=PASS ✅"
echo "PHASE4B_BACKFILL_REBUILD_DRY_RUN_GATE_TEST=PASS ✅"
echo "PHASE4B_BACKFILL_REBUILD_IDEMPOTENCY_TEST=PASS ✅"
echo "PHASE4B_BACKFILL_REBUILD_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_BACKFILL_REBUILD_SECRET_TEST=PASS ✅"
