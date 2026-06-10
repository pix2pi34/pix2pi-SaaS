#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_master_evidence_collector.sh"
REPORT="docs/phase4/14_5_1_db_master_evidence_collector_report.md"
INVENTORY="docs/phase4/14_5_1_db_master_evidence_inventory.tsv"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ master evidence collector script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_5_1_master_evidence.log 2>&1 || {
  echo "TEST_FAIL ❌ master evidence collector script hata verdi"
  cat /tmp/pix2pi_14_5_1_master_evidence.log || true
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "DB_MASTER_EVIDENCE_COLLECTOR=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ master evidence collector PASS degil"
  sed -n '1,360p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_14_1_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.1 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_14_2_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.2 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_14_3_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.3 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FAZ4_14_4_STATUS=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ 14.4 PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB connection PASS yok"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ final DB role primary write yok"
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

if [ ! -f "$INVENTORY" ]; then
  echo "TEST_FAIL ❌ inventory file yok"
  exit 1
fi

grep -q $'block\titem\tstatus\tkey\tvalue\tfile\tsize_bytes' "$INVENTORY" || {
  echo "TEST_FAIL ❌ inventory header hatali"
  sed -n '1,20p' "$INVENTORY" || true
  exit 1
}

grep -q $'14.4\tPERFORMANCE_RISK\tPASS\tDB_PERFORMANCE_RISK_FINAL\tLOW' "$INVENTORY" || {
  echo "TEST_FAIL ❌ inventory 14.4 final risk LOW yok"
  sed -n '1,80p' "$INVENTORY" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$INVENTORY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_MASTER_EVIDENCE_COLLECTOR_TEST=PASS ✅"
echo "PHASE4_DB_MASTER_EVIDENCE_INVENTORY_TEST=PASS ✅"
echo "PHASE4_DB_MASTER_EVIDENCE_NO_MUTATION_TEST=PASS ✅"
echo "PHASE4_DB_MASTER_EVIDENCE_SECRET_TEST=PASS ✅"
