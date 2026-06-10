#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_performance_final_closure.sh"
REPORT="docs/phase4/14_4_5_db_performance_final_closure_report.md"
CLOSURE="docs/phase4/14_4_final_db_performance_closure_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ DB performance final closure script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_4_5_final_closure.log 2>&1 || {
  echo "TEST_FAIL ❌ final closure script hata verdi"
  cat /tmp/pix2pi_14_4_5_final_closure.log || true
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "DB_PERFORMANCE_FINAL_CLOSURE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final closure PASS degil"
  sed -n '1,320p' "$REPORT" || true
  exit 1
}

grep -q "14_4_1_QUERY_PERFORMANCE_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.4.1 PASS kaniti yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "14_4_2_INDEX_USAGE_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.4.2 PASS kaniti yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "14_4_3_VACUUM_BLOAT_READINESS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.4.3 PASS kaniti yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "14_4_4_DB_HEALTH_BASELINE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.4.4 PASS kaniti yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "DB_PERFORMANCE_RISK_FINAL=LOW" "$REPORT" || {
  echo "TEST_FAIL ❌ final risk LOW degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB role primary write degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "QUERY_TEXT_PRINTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ query text printed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$CLOSURE" ]; then
  echo "TEST_FAIL ❌ 14.4 final closure file yok"
  exit 1
fi

grep -q "FAZ4_14_4_FINAL_STATUS=PASS" "$CLOSURE" || {
  echo "TEST_FAIL ❌ 14.4 final status PASS degil"
  sed -n '1,260p' "$CLOSURE" || true
  exit 1
}

grep -q "DB_PERFORMANCE_STACK_STATUS=BASELINED" "$CLOSURE" || {
  echo "TEST_FAIL ❌ performance stack baselined degil"
  sed -n '1,260p' "$CLOSURE" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$CLOSURE"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_PERFORMANCE_FINAL_CLOSURE_TEST=PASS ✅"
echo "PHASE4_DB_PERFORMANCE_FINAL_RISK_TEST=PASS ✅"
echo "PHASE4_DB_PERFORMANCE_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_PERFORMANCE_SECRET_TEST=PASS ✅"
