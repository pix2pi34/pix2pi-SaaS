#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_archive_partition_retention.sh"
PY_SCRIPT="scripts/phase4b_archive_partition_retention.py"
REPORT="docs/phase4/14_5_archive_partition_retention_report.md"
MATRIX="docs/phase4/14_5_archive_partition_retention_matrix.tsv"
MANIFEST="config/retention/archive_partition_retention_manifest.tsv"
DOC_MANIFEST="docs/phase4/14_5_archive_partition_retention_manifest.tsv"
PLAN="docs/phase4/14_5_archive_partition_retention_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ archive retention wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ archive retention python executable degil"
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

bash "$SCRIPT" . >/tmp/pix2pi_14_5_archive_partition_retention.log 2>&1 || {
  echo "TEST_FAIL ❌ archive partition retention script hata verdi"
  cat /tmp/pix2pi_14_5_archive_partition_retention.log || true
  sed -n '1,900p' "$REPORT" || true
  exit 1
}

for required in \
  "ARCHIVE_PARTITION_RETENTION_MODEL=PASS" \
  "FAZ4B_14_5_FINAL_STATUS=PASS" \
  "PREVIOUS_14_1_FINAL_STATUS=PASS" \
  "PREVIOUS_14_2_FINAL_STATUS=PASS" \
  "PREVIOUS_14_3_FINAL_STATUS=PASS" \
  "PREVIOUS_14_4_FINAL_STATUS=PASS" \
  "RETENTION_MANIFEST_STATUS=PASS" \
  "RETENTION_PARTITION_CANDIDATE_STATUS=PASS" \
  "RETENTION_TENANT_SAFETY_STATUS=PASS" \
  "RETENTION_KVKK_STATUS=PASS" \
  "RETENTION_LEGAL_HOLD_STATUS=PASS" \
  "RETENTION_CANDIDATE_PLAN_STATUS=PASS" \
  "DB_MUTATION=NO" \
  "ARCHIVE_APPLY_EXECUTED=NO" \
  "PARTITION_APPLY_EXECUTED=NO" \
  "RETENTION_PURGE_EXECUTED=NO" \
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

for target in \
  event_store_events \
  audit_log_events \
  application_logs \
  import_batches \
  import_files \
  import_staging_rows \
  import_validation_errors \
  notification_history \
  webhook_delivery_history \
  jobs_queue_history \
  reporting_marts \
  readmodel_snapshots
do
  grep -q "$target" "$MANIFEST" || {
    echo "TEST_FAIL ❌ retention target eksik: $target"
    cat "$MANIFEST" || true
    exit 1
  }
done

PLAN_OUT="$(bash "$PLAN")"
echo "$PLAN_OUT" | grep -q "RETENTION_PLAN_BLOCKED_BY_DEFAULT=YES" || {
  echo "TEST_FAIL ❌ candidate plan blocked by default degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "ARCHIVE_APPLY_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ archive apply no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "PARTITION_APPLY_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ partition apply no degil"
  echo "$PLAN_OUT"
  exit 1
}

echo "$PLAN_OUT" | grep -q "RETENTION_PURGE_EXECUTED=NO" || {
  echo "TEST_FAIL ❌ retention purge no degil"
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

echo "PHASE4B_ARCHIVE_PARTITION_RETENTION_STANDARD_TEST=PASS ✅"
echo "PHASE4B_RETENTION_KVKK_LEGAL_HOLD_TEST=PASS ✅"
echo "PHASE4B_RETENTION_PARTITION_CANDIDATE_TEST=PASS ✅"
echo "PHASE4B_RETENTION_NO_APPLY_TEST=PASS ✅"
echo "PHASE4B_RETENTION_SECRET_TEST=PASS ✅"
