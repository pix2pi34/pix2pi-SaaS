#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_restore_drill_test.sh"
REPORT="docs/phase4/14_2_4_restore_drill_test_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ restore drill test script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_4_restore_drill_test.log 2>&1 || {
  echo "TEST_FAIL ❌ restore drill test script hata verdi"
  cat /tmp/pix2pi_14_2_4_restore_drill_test.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "RESTORE_DRILL_TEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ restore drill PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "LIVE_DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ live DB mutation NO yok"
  sed -n '1,200p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION_SCOPE=SANDBOX_ONLY" "$REPORT" || {
  echo "TEST_FAIL ❌ mutation scope sandbox only yok"
  sed -n '1,200p' "$REPORT" || true
  exit 1
}

grep -q "SANDBOX_RESTORE_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ sandbox restore PASS yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "SANDBOX_CLEANUP_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ sandbox cleanup PASS yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "SANDBOX_CONTAINER_REMAINING=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ sandbox container cleanup sonrasi kalmis"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "SANDBOX_VOLUME_REMAINING=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ sandbox volume cleanup sonrasi kalmis"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

TABLE_COUNT="$(grep '^RESTORED_TABLE_COUNT=' "$REPORT" | tail -n 1 | cut -d= -f2-)"
case "$TABLE_COUNT" in
  ''|*[!0-9]*)
    echo "TEST_FAIL ❌ restored table count sayi degil: $TABLE_COUNT"
    sed -n '1,220p' "$REPORT" || true
    exit 1
    ;;
  *)
    if [ "$TABLE_COUNT" -le 0 ]; then
      echo "TEST_FAIL ❌ restored table count 0"
      sed -n '1,220p' "$REPORT" || true
      exit 1
    fi
    ;;
esac

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_RESTORE_DRILL_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_SANDBOX_ONLY_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_CLEANUP_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_SECRET_TEST=PASS ✅"
