#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_logical_backup_smoke.sh"
REPORT="docs/phase4/14_2_2_logical_backup_smoke_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ logical backup smoke script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_2_logical_backup_smoke.log 2>&1 || {
  echo "TEST_FAIL ❌ logical backup smoke script hata verdi"
  cat /tmp/pix2pi_14_2_2_logical_backup_smoke.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "LOGICAL_BACKUP_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ logical backup smoke PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_DUMP_SMOKE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_dump smoke PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PG_DUMP_METHOD=" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_dump method raporda yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "PG_RESTORE_LIST_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ pg_restore list PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB primary write degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

DUMP_REL="$(grep '^DUMP_FILE=' "$REPORT" | head -n 1 | cut -d= -f2-)"
if [ ! -s "$DUMP_REL" ]; then
  echo "TEST_FAIL ❌ dump file yok veya bos: $DUMP_REL"
  exit 1
fi

RESTORE_LIST_REL="$(grep '^RESTORE_LIST_FILE=' "$REPORT" | head -n 1 | cut -d= -f2-)"
if [ ! -s "$RESTORE_LIST_REL" ]; then
  echo "TEST_FAIL ❌ restore list yok veya bos: $RESTORE_LIST_REL"
  exit 1
fi

if grep -R "POSTGRES_PASSWORD" "$REPORT" "$RESTORE_LIST_REL"; then
  echo "TEST_FAIL ❌ secret rapora/list dosyasina sizdi"
  exit 1
fi

echo "PHASE4_LOGICAL_BACKUP_SMOKE_TEST=PASS ✅"
echo "PHASE4_LOGICAL_BACKUP_FALLBACK_TEST=PASS ✅"
echo "PHASE4_LOGICAL_BACKUP_SECRET_TEST=PASS ✅"
