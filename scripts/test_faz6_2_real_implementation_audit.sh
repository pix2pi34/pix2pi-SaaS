#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

AUDIT_SCRIPT="scripts/audit_faz6_2_real_implementation.sh"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_2_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 6-2 REAL IMPLEMENTATION AUDIT TEST BASLADI ====="

check_file "6-2 real implementation audit script mevcut" "$AUDIT_SCRIPT"
check_exec "6-2 real implementation audit script executable" "$AUDIT_SCRIPT"

echo
echo "===== AUDIT CALISTIRILIYOR ====="
bash "$AUDIT_SCRIPT"

check_file "6-2 real implementation evidence mevcut" "$EVIDENCE_FILE"
check_grep "6-2.1.1 DB_WRITE_DSN kontrolu evidence var" "$EVIDENCE_FILE" "6-2.1.1 DB_WRITE_DSN"
check_grep "6-2.1.2 DB_READ_DSN kontrolu evidence var" "$EVIDENCE_FILE" "6-2.1.2 DB_READ_DSN"
check_grep "6-2.2 Replica routing kontrolu evidence var" "$EVIDENCE_FILE" "6-2.2 Replica routing"
check_grep "6-2.3.1 SetMaxOpenConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.1 Connection pool SetMaxOpenConns"
check_grep "6-2.3.2 SetMaxIdleConns kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.2 Connection pool SetMaxIdleConns"
check_grep "6-2.3.3 lifetime idle kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.3 Connection pool lifetime / idle time"
check_grep "6-2.3.4 timeout kontrolu evidence var" "$EVIDENCE_FILE" "6-2.3.4 Query timeout / context timeout"
check_grep "6-2.4.1 SQL index kontrolu evidence var" "$EVIDENCE_FILE" "6-2.4.1 SQL index migration"
check_grep "6-2.4.2 tenant_id index kontrolu evidence var" "$EVIDENCE_FILE" "6-2.4.2 tenant_id index"
check_grep "6-2.5 PITR backup restore kontrolu evidence var" "$EVIDENCE_FILE" "6-2.5 PITR / backup / restore"
check_grep "6-2.6 Partition shard kontrolu evidence var" "$EVIDENCE_FILE" "6-2.6 Partition / shard"
check_grep "6-2.7 DB observability kontrolu evidence var" "$EVIDENCE_FILE" "6-2.7 DB observability"
check_grep "6-2 final interpretation var" "$EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-2 audit complete muhru var" "$EVIDENCE_FILE" "FAZ_6_2_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-2 REAL IMPLEMENTATION AUDIT TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_2_REAL_IMPLEMENTATION_AUDIT_TEST_STATUS=PASS ✅"
  echo "OK ✅ FAZ 6-2 real implementation audit testi tamamlandi"
  exit 0
else
  echo "FAZ_6_2_REAL_IMPLEMENTATION_AUDIT_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-2 real implementation audit testinde eksik var"
  exit 1
fi
