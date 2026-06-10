#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_reporting_query_smoke_final_closure.sh"
REPORT="docs/phase4/16_5_reporting_query_smoke_final_closure_report.md"
INVENTORY="docs/phase4/16_5_reporting_query_smoke_inventory.tsv"
CLOSURE="docs/phase4/16_reporting_final_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ reporting query smoke final closure script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_16_5_reporting_smoke.log 2>&1 || {
  echo "TEST_FAIL ❌ reporting query smoke final closure script hata verdi"
  cat /tmp/pix2pi_16_5_reporting_smoke.log || true
  sed -n '1,560p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_QUERY_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting query smoke PASS degil"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_FINAL_CLOSURE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting final closure PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "REPORTING_GO_TEST_SUITE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ reporting go test suite PASS yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_READ_SMOKE_PASS_COUNT=6" "$REPORT" || {
  echo "TEST_FAIL ❌ read smoke pass count 6 yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "READMODEL_READ_SMOKE_FAIL_COUNT=0" "$REPORT" || {
  echo "TEST_FAIL ❌ read smoke fail count 0 yok"
  sed -n '1,520p' "$REPORT" || true
  exit 1
}

grep -q "DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB connection PASS yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB role PRIMARY_WRITE yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "SERVICE_RUNTIME_STARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ service runtime started NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,420p' "$REPORT" || true
  exit 1
}

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ smoke inventory yok"
  exit 1
fi

for smoke in \
  operational_summary \
  daily_metrics \
  inventory_status \
  document_work_queue \
  reconciliation_status \
  projection_state
do
  grep -q "$smoke.*PASS" "$INVENTORY" || {
    echo "TEST_FAIL ❌ smoke inventory PASS eksik: $smoke"
    cat "$INVENTORY" || true
    exit 1
  }
done

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ closure file yok"
  exit 1
fi

grep -q "REPORTING_FINAL_CLOSURE=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ closure final PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

grep -q "FAZ4_16_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ FAZ4 16 final status PASS yok"
  cat "$CLOSURE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "SELECT .* FROM readmodel" "$REPORT" "$INVENTORY" "$CLOSURE"; then
  echo "TEST_FAIL ❌ query text rapora basildi"
  exit 1
fi

echo "PHASE4_REPORTING_QUERY_SMOKE_TEST=PASS ✅"
echo "PHASE4_REPORTING_GO_TEST_SUITE_TEST=PASS ✅"
echo "PHASE4_REPORTING_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_REPORTING_NO_DB_MUTATION_TEST=PASS ✅"
echo "PHASE4_REPORTING_SECRET_TEST=PASS ✅"
