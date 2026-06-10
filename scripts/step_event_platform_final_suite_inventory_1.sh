#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$ROOT/reports/event_platform_final_suite_inventory_${TS}.txt"
LATEST="$ROOT/reports/event_platform_final_suite_inventory_latest.txt"
TMP_DIR="$ROOT/tmp/event_platform_final_suite_inventory_${TS}"

mkdir -p "$ROOT/reports" "$ROOT/tmp" "$TMP_DIR"

echo "===== EVENT PLATFORM FINAL SUITE INVENTORY 1 ====="
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Root: $ROOT"
echo

echo "===== STEP 1 - TEST DOSYALARINI TOPLA ====="
find . \
  -type f \
  -name '*_test.go' \
  ! -path './backups/*' \
  ! -path './tmp/*' \
  ! -path './reports/*' \
  | sort > "$TMP_DIR/all_test_files.txt"

ALL_TEST_COUNT="$(wc -l < "$TMP_DIR/all_test_files.txt" | tr -d ' ')"
echo "ALL_TEST_COUNT=$ALL_TEST_COUNT"
echo "OK ✅ tum test dosyalari toplandi"
echo

echo "===== STEP 2 - EVENT PLATFORM ADAYLARINI AYIKLA ====="
: > "$TMP_DIR/event_test_files.txt"

while IFS= read -r file; do
  if printf '%s\n' "$file" | grep -Eiq 'event|replay|idempot|dlq|retry|nats|jetstream|store'
  then
    echo "$file" >> "$TMP_DIR/event_test_files.txt"
    continue
  fi

  if grep -Eiq 'Event|Replay|Idempot|DLQ|Retry|JetStream|NATS|event store|event platform|dead.?letter|consumer|publisher' "$file"
  then
    echo "$file" >> "$TMP_DIR/event_test_files.txt"
    continue
  fi
done < "$TMP_DIR/all_test_files.txt"

sort -u "$TMP_DIR/event_test_files.txt" -o "$TMP_DIR/event_test_files.txt"

EVENT_TEST_FILE_COUNT="$(wc -l < "$TMP_DIR/event_test_files.txt" | tr -d ' ')"
echo "EVENT_TEST_FILE_COUNT=$EVENT_TEST_FILE_COUNT"
sed -n '1,80p' "$TMP_DIR/event_test_files.txt" || true
echo
echo "OK ✅ event platform aday test dosyalari ayiklandi"
echo

echo "===== STEP 3 - TEST FUNC ENVANTERI ====="
: > "$TMP_DIR/event_test_funcs.txt"

while IFS= read -r file; do
  echo "### $file" >> "$TMP_DIR/event_test_funcs.txt"
  grep -n '^func Test' "$file" >> "$TMP_DIR/event_test_funcs.txt" || true
  echo >> "$TMP_DIR/event_test_funcs.txt"
done < "$TMP_DIR/event_test_files.txt"

sed -n '1,160p' "$TMP_DIR/event_test_funcs.txt" || true
echo
echo "OK ✅ test fonksiyon envanteri cikartildi"
echo

echo "===== STEP 4 - EVENT ANAHTAR KELIME SAYIMI ====="
{
  echo "event=$(grep -RIn --include='*_test.go' -i 'event' . | wc -l | tr -d ' ')"
  echo "replay=$(grep -RIn --include='*_test.go' -i 'replay' . | wc -l | tr -d ' ')"
  echo "idempot=$(grep -RIn --include='*_test.go' -i 'idempot' . | wc -l | tr -d ' ')"
  echo "retry=$(grep -RIn --include='*_test.go' -i 'retry' . | wc -l | tr -d ' ')"
  echo "dlq=$(grep -RIn --include='*_test.go' -i 'dlq' . | wc -l | tr -d ' ')"
  echo "nats=$(grep -RIn --include='*_test.go' -i 'nats' . | wc -l | tr -d ' ')"
  echo "jetstream=$(grep -RIn --include='*_test.go' -i 'jetstream' . | wc -l | tr -d ' ')"
  echo "store=$(grep -RIn --include='*_test.go' -i 'store' . | wc -l | tr -d ' ')"
} | tee "$TMP_DIR/event_keyword_counts.txt"
echo
echo "OK ✅ anahtar kelime sayimi tamam"
echo

echo "===== STEP 5 - RAPOR YAZ ====="
{
  echo "time=$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "root=$ROOT"
  echo "all_test_count=$ALL_TEST_COUNT"
  echo "event_test_file_count=$EVENT_TEST_FILE_COUNT"
  echo
  echo "[event_test_files]"
  cat "$TMP_DIR/event_test_files.txt"
  echo
  echo "[event_test_functions]"
  cat "$TMP_DIR/event_test_funcs.txt"
  echo
  echo "[keyword_counts]"
  cat "$TMP_DIR/event_keyword_counts.txt"
} > "$REPORT"

cp -f "$REPORT" "$LATEST"

echo "OK ✅ rapor yazildi: $REPORT"
echo "OK ✅ latest rapor: $LATEST"
echo

echo "===== STEP 6 - FINAL ====="
echo "ALL_TEST_COUNT=$ALL_TEST_COUNT"
echo "EVENT_TEST_FILE_COUNT=$EVENT_TEST_FILE_COUNT"

if [ "$EVENT_TEST_FILE_COUNT" -gt 0 ]; then
  echo "OK ✅ EVENT-PLATFORM-FINAL-SUITE-INVENTORY-1 basarili"
else
  echo "HATA ❌ event platform aday test dosyasi bulunamadi"
  exit 1
fi
