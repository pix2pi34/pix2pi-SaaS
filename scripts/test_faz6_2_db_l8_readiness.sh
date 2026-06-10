#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_2_DB_L8_HA_SCALE_OPS_READINESS.md"
AUDIT_SCRIPT="scripts/audit_faz6_2_db_l8_readiness.sh"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_2_DB_L8_AUDIT_EVIDENCE.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 6-2 DB-L8 TEST BASLADI ====="

check_file "6-2 DB-L8 master dokumani mevcut" "$DOC_FILE"
check_file "6-2 DB-L8 audit script mevcut" "$AUDIT_SCRIPT"
check_exec "6-2 DB-L8 audit script executable" "$AUDIT_SCRIPT"

check_grep "6-2 ana karar tanimli" "$DOC_FILE" "Pix2pi icin DB-L8 hedefi"
check_grep "6-2.1 Read / Write Split Readiness tanimli" "$DOC_FILE" "6-2.1 Read / Write Split Readiness"
check_grep "6-2.1.1 Write Path tanimli" "$DOC_FILE" "6-2.1.1 Write Path"
check_grep "6-2.1.2 Read Path tanimli" "$DOC_FILE" "6-2.1.2 Read Path"
check_grep "6-2.1.3 Fallback tanimli" "$DOC_FILE" "6-2.1.3 Fallback"

check_grep "6-2.2 Replica Routing tanimli" "$DOC_FILE" "6-2.2 Replica Routing / Read Pool Stratejisi"
check_grep "6-2.3 Connection Pool tanimli" "$DOC_FILE" "6-2.3 Connection Pool Stratejisi"
check_grep "6-2.4 Index Query Performance tanimli" "$DOC_FILE" "6-2.4 Index / Query Performance Tuning"
check_grep "6-2.5 PITR Restore Drill tanimli" "$DOC_FILE" "6-2.5 PITR / Restore Drill Readiness"
check_grep "6-2.6 Partition Shard tanimli" "$DOC_FILE" "6-2.6 Partition / Shard Readiness Modeli"
check_grep "6-2.7 DB Observability tanimli" "$DOC_FILE" "6-2.7 DB Observability / Performance Evidence Seti"
check_grep "6-2.8 DB Final Closure Gate tanimli" "$DOC_FILE" "6-2.8 DB Final Closure Gate"

check_grep "6-2 risk notlari destructive DB yok tanimli" "$DOC_FILE" "DB silinmez"
check_grep "6-2 migration calistirilmaz tanimli" "$DOC_FILE" "Migration calistirilmaz"
check_grep "6-2 schema degistirilmez tanimli" "$DOC_FILE" "Schema degistirilmez"

check_grep "6-2 muhur doc status tanimli" "$DOC_FILE" "FAZ_6_2_DOC_STATUS=READY"
check_grep "6-2 muhur audit script tanimli" "$DOC_FILE" "FAZ_6_2_AUDIT_SCRIPT=READY"
check_grep "6-2 muhur evidence tanimli" "$DOC_FILE" "FAZ_6_2_EVIDENCE_STATUS=READY"
check_grep "6-2 muhur test status tanimli" "$DOC_FILE" "FAZ_6_2_TEST_STATUS=PASS"
check_grep "6-2 muhur final status tanimli" "$DOC_FILE" "FAZ_6_2_FINAL_STATUS=PASS"
check_grep "6-3 ready tanimli" "$DOC_FILE" "FAZ_6_3_READY=YES"

echo
echo "===== FAZ 6-2 AUDIT SCRIPT CALISTIRILIYOR ====="
bash "$AUDIT_SCRIPT"

check_file "6-2 audit evidence dosyasi olustu" "$EVIDENCE_FILE"
check_grep "6-2 audit evidence ready muhru var" "$EVIDENCE_FILE" "FAZ_6_2_AUDIT_EVIDENCE=READY"
check_grep "6-2.1 evidence environment inventory var" "$EVIDENCE_FILE" "6-2.1 Environment Files Inventory"
check_grep "6-2.2 evidence DSN kontrolu var" "$EVIDENCE_FILE" "6-2.2 DB DSN Presence Check"
check_grep "6-2.5 evidence port kontrolu var" "$EVIDENCE_FILE" "6-2.5 DB Port Listening Check"
check_grep "6-2.7 evidence pg_isready probe var" "$EVIDENCE_FILE" "6-2.7 pg_isready Container Probe"
check_grep "6-2.9 evidence readiness result var" "$EVIDENCE_FILE" "6-2.9 DB-L8 Readiness Result"

echo
echo "===== FAZ 6-2 TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_2_DOC_STATUS=READY ✅"
  echo "FAZ_6_2_AUDIT_SCRIPT=READY ✅"
  echo "FAZ_6_2_EVIDENCE_STATUS=READY ✅"
  echo "FAZ_6_2_TEST_STATUS=PASS ✅"
  echo "FAZ_6_2_FINAL_STATUS=PASS ✅"
  echo "FAZ_6_3_READY=YES ✅"
  echo "OK ✅ FAZ 6-2 DB-L8 HA / Scale / Ops Readiness tamamlandi"
  exit 0
else
  echo "FAZ_6_2_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-2 testlerinde eksik var"
  exit 1
fi
