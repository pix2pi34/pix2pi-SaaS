#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_runbook_incident_checklist.sh"
REPORT="docs/phase4/14_5_4_db_runbook_incident_checklist_report.md"
RUNBOOK="docs/phase4/14_5_4_db_operations_runbook.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ runbook script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_5_4_runbook.log 2>&1 || {
  echo "TEST_FAIL ❌ runbook script hata verdi"
  cat /tmp/pix2pi_14_5_4_runbook.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_RUNBOOK_INCIDENT_CHECKLIST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ runbook PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "RUNBOOK_CREATED=YES" "$REPORT" || {
  echo "TEST_FAIL ❌ runbook created YES yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

if [ ! -f "$RUNBOOK" ]; then
  echo "TEST_FAIL ❌ runbook file yok"
  exit 1
fi

for section in \
  "DB Health Quick Check" \
  "Backup / Restore Quick Check" \
  "PITR Deferred Action Runbook" \
  "Lock / Deadlock Incident Checklist" \
  "Slow Query Incident Checklist" \
  "Rollback Decision Tree" \
  "Production Sonrasi Tekrar Baseline Takvimi"
do
  grep -q "$section" "$RUNBOOK" || {
    echo "TEST_FAIL ❌ runbook section eksik: $section"
    sed -n '1,220p' "$RUNBOOK" || true
    exit 1
  }
done

if grep -Eiq 'password=|POSTGRES_PASSWORD=|PGPASSWORD=' "$RUNBOOK" "$REPORT"; then
  echo "TEST_FAIL ❌ secret benzeri ifade rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_RUNBOOK_INCIDENT_CHECKLIST_TEST=PASS ✅"
echo "PHASE4_DB_RUNBOOK_CONTENT_TEST=PASS ✅"
echo "PHASE4_DB_RUNBOOK_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_RUNBOOK_SECRET_TEST=PASS ✅"
