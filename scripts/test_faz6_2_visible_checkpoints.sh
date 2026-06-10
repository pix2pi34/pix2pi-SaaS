#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_2_DB_L8_VISIBLE_CHECKPOINTS.md"

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

echo "===== FAZ 6-2 VISIBLE CHECKPOINT TEST BASLADI ====="

check_file "6-2 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"

check_grep "6-2.1 Read / Write Split visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_1_READ_WRITE_SPLIT_STATUS=PASS"
check_grep "6-2.2 Replica Routing visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_2_REPLICA_ROUTING_STATUS=PASS"
check_grep "6-2.3 Connection Pool visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_3_CONNECTION_POOL_STATUS=PASS"
check_grep "6-2.4 Index Query visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_4_INDEX_QUERY_STATUS=PASS"
check_grep "6-2.5 PITR Restore visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_5_PITR_RESTORE_STATUS=PASS"
check_grep "6-2.6 Partition Shard visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_6_PARTITION_SHARD_STATUS=PASS"
check_grep "6-2.7 DB Observability visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_7_DB_OBSERVABILITY_STATUS=PASS"
check_grep "6-2.8 Final Closure Gate visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_2_8_FINAL_CLOSURE_GATE_STATUS=PASS"

check_grep "6-2.3 detay max open connections var" "$CHECKPOINT_FILE" "max open connections kontrolü yazıldı"
check_grep "6-2.3 detay pool saturation var" "$CHECKPOINT_FILE" "pool saturation metric ihtiyacı yazıldı"
check_grep "6-2.4 detay slow query var" "$CHECKPOINT_FILE" "slow query log kontrolü yazıldı"
check_grep "6-2.4 detay tenant_id index var" "$CHECKPOINT_FILE" "tenant_id index stratejisi yazıldı"
check_grep "6-2.6 detay event store partition var" "$CHECKPOINT_FILE" "event store partition adayı olarak yazıldı"
check_grep "6-2.6 detay shard tetikleyicileri var" "$CHECKPOINT_FILE" "shard tetikleyicileri yazıldı"
check_grep "6-2.8 detay destructive DB yok var" "$CHECKPOINT_FILE" "Runtime destructive DB işlemi yapılmadı"

check_grep "6-2 visible checkpoints final PASS var" "$CHECKPOINT_FILE" "FAZ_6_2_VISIBLE_CHECKPOINTS_STATUS=PASS"
check_grep "6-2 final PASS var" "$CHECKPOINT_FILE" "FAZ_6_2_FINAL_STATUS=PASS"
check_grep "6-3 ready var" "$CHECKPOINT_FILE" "FAZ_6_3_READY=YES"

echo
echo "===== FAZ 6-2 VISIBLE CHECKPOINT TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_2_3_CONNECTION_POOL_STATUS=PASS ✅"
  echo "FAZ_6_2_4_INDEX_QUERY_STATUS=PASS ✅"
  echo "FAZ_6_2_6_PARTITION_SHARD_STATUS=PASS ✅"
  echo "FAZ_6_2_8_FINAL_CLOSURE_GATE_STATUS=PASS ✅"
  echo "FAZ_6_2_VISIBLE_CHECKPOINTS_STATUS=PASS ✅"
  echo "FAZ_6_2_FINAL_STATUS=PASS ✅"
  echo "FAZ_6_3_READY=YES ✅"
  echo "OK ✅ FAZ 6-2 visible checkpoint fix tamamlandi"
  exit 0
else
  echo "FAZ_6_2_VISIBLE_CHECKPOINTS_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-2 visible checkpoint eksigi var"
  exit 1
fi
