#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_materialized_cache_projection_standard.sh"
PY_SCRIPT="scripts/phase4b_materialized_cache_projection_standard.py"
REPORT="docs/phase4/15_6_materialized_cache_projection_report.md"
MATRIX="docs/phase4/15_6_materialized_cache_projection_matrix.tsv"
MANIFEST="config/projection/materialized_cache_projection_manifest.tsv"
DOC_MANIFEST="docs/phase4/15_6_materialized_cache_projection_manifest.tsv"
PLAN="docs/phase4/15_6_materialized_cache_projection_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ materialized/cache wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ materialized/cache python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_15_6_materialized_cache_projection.log 2>&1 || {
  echo "TEST_FAIL ❌ materialized/cache projection script hata verdi"
  cat /tmp/pix2pi_15_6_materialized_cache_projection.log || true
  sed -n '1,1000p' "$REPORT" || true
  exit 1
}

for required in \
  "MATERIALIZED_CACHE_PROJECTION_STANDARD=PASS" \
  "FAZ4B_15_6_FINAL_STATUS=PASS" \
  "PREVIOUS_14_FINAL_STATUS=PASS" \
  "PREVIOUS_15_2_FINAL_STATUS=PASS" \
  "PREVIOUS_15_3_FINAL_STATUS=PASS" \
  "PREVIOUS_15_4_FINAL_STATUS=PASS" \
  "PREVIOUS_15_5_FINAL_STATUS=PASS" \
  "MATERIALIZED_CACHE_MANIFEST_STATUS=PASS" \
  "MATERIALIZED_CACHE_TENANT_KEY_STATUS=PASS" \
  "MATERIALIZED_CACHE_REFRESH_STATUS=PASS" \
  "MATERIALIZED_CACHE_REBUILD_STATUS=PASS" \
  "MATERIALIZED_CACHE_INVALIDATION_STATUS=PASS" \
  "MATERIALIZED_CACHE_CANDIDATE_PLAN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "REDIS_MUTATION=NO" \
  "MATERIALIZED_VIEW_REFRESH_EXECUTED=NO" \
  "CACHE_WRITE_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,1000p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$MANIFEST" "$DOC_MANIFEST" "$PLAN"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for projection in \
  finance_daily_dashboard \
  finance_period_kpi_cache \
  ebelge_status_dashboard \
  payment_reconciliation_dashboard \
  party_search_cache \
  product_search_cache \
  inventory_balance_cache \
  global_search_cache \
  reporting_home_snapshot \
  pilot_ops_health_cache
do
  grep -q "$projection" "$MANIFEST" || {
    echo "TEST_FAIL ❌ projection eksik: $projection"
    cat "$MANIFEST" || true
    exit 1
  }
done

grep -q "tenant:{tenant_id}:" "$MANIFEST" || {
  echo "TEST_FAIL ❌ tenant cache key namespace yok"
  exit 1
}

PLAN_OUT="$(bash "$PLAN")"

echo "$PLAN_OUT" | grep -q "MATERIALIZED_CACHE_PLAN_BLOCKED_BY_DEFAULT=YES" || {
  echo "TEST_FAIL ❌ candidate plan blocked by default degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "REDIS_MUTATION=NO" || {
  echo "TEST_FAIL ❌ Redis mutation no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "MATERIALIZED_VIEW_REFRESH_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ materialized view refresh no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "CACHE_WRITE_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ cache write no degil"
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

echo "PHASE4B_MATERIALIZED_CACHE_PROJECTION_STANDARD_TEST=PASS ✅"
echo "PHASE4B_MATERIALIZED_CACHE_TENANT_KEY_TEST=PASS ✅"
echo "PHASE4B_MATERIALIZED_CACHE_REFRESH_REBUILD_TEST=PASS ✅"
echo "PHASE4B_MATERIALIZED_CACHE_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_MATERIALIZED_CACHE_SECRET_TEST=PASS ✅"
