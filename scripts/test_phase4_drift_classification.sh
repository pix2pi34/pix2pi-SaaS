#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_drift_classification.sh"
REPORT="docs/phase4/14_1_6B_drift_classification_report.md"
DRIFT_REPORT="docs/phase4/14_1_6_migration_drift_evidence_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ drift classification script executable degil"
  exit 1
fi

if [ ! -f "$DRIFT_REPORT" ]; then
  echo "TEST_FAIL ❌ input drift evidence report yok"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_6B_classification.log 2>&1 || {
  echo "TEST_FAIL ❌ drift classification script hata verdi"
  cat /tmp/pix2pi_14_1_6B_classification.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DRIFT_CLASSIFICATION=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ classification PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "COUNT_MODE=DEDUPED_UNIQUE_MISSING_LINES" "$REPORT" || {
  echo "TEST_FAIL ❌ dedupe count mode raporda yok"
  sed -n '1,120p' "$REPORT" || true
  exit 1
}

DEDUP_COUNT="$(grep '^MISSING|' "$DRIFT_REPORT" | sort -u | wc -l | tr -d ' ')"
REPORT_COUNT="$(grep '^MISSING_TOTAL_COUNT=' "$REPORT" | tail -n 1 | cut -d= -f2 | tr -d ' ')"

if [ "$DEDUP_COUNT" != "$REPORT_COUNT" ]; then
  echo "TEST_FAIL ❌ dedupe count mismatch: expected=$DEDUP_COUNT report=$REPORT_COUNT"
  sed -n '1,160p' "$REPORT" || true
  exit 1
fi

grep -q "DRIFT_RISK_LEVEL=" "$REPORT" || {
  echo "TEST_FAIL ❌ risk level yok"
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

grep -q "MISSING_TABLE_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ missing table count yok"
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

grep -q "MISSING_INDEX_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ missing index count yok"
  sed -n '1,160p' "$REPORT" || true
  exit 1
}

echo "PHASE4_DRIFT_CLASSIFICATION_TEST=PASS ✅"
echo "PHASE4_DRIFT_CLASSIFICATION_DEDUPE_TEST=PASS ✅"
