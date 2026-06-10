#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_TXT="$ROOT/reports/event_platform_final_close_${TS}.txt"
REPORT_MD="$ROOT/reports/event_platform_final_close_${TS}.md"
LATEST_TXT="$ROOT/reports/event_platform_final_close_latest.txt"
LATEST_MD="$ROOT/reports/event_platform_final_close_latest.md"

INV_LATEST="$ROOT/reports/event_platform_final_suite_inventory_latest.txt"
RUN_LATEST="$ROOT/reports/event_platform_final_suite_run_latest.txt"

echo "===== EVENT PLATFORM FINAL CLOSE 1 FIX ====="
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Root: $ROOT"
echo

echo "===== STEP 1 - RAPOR DOSYALARI KONTROL ====="
[ -f "$INV_LATEST" ]
[ -f "$RUN_LATEST" ]
echo "OK ✅ inventory latest bulundu: $INV_LATEST"
echo "OK ✅ run latest bulundu: $RUN_LATEST"
echo

echo "===== STEP 2 - DOGRUDAN DOSYA SISTEMI SAYIMI ====="
ALL_TEST_COUNT="$(find . -type f -name '*_test.go' | wc -l | tr -d ' ')"

EVENT_TEST_FILE_COUNT="$(
  {
    find ./cmd/api-gateway -type f -name '*_test.go' 2>/dev/null
    find ./cmd/user-created-consumer -type f -name '*_test.go' 2>/dev/null
    find ./internal/platform -type f -name '*_test.go' 2>/dev/null
    find ./test/internal/finance/test/ledger -type f -name '*_test.go' 2>/dev/null
  } | sed '/^[[:space:]]*$/d' | sort -u | wc -l | tr -d ' '
)"

echo "ALL_TEST_COUNT=$ALL_TEST_COUNT"
echo "EVENT_TEST_FILE_COUNT=$EVENT_TEST_FILE_COUNT"

[ -n "${ALL_TEST_COUNT:-}" ]
[ -n "${EVENT_TEST_FILE_COUNT:-}" ]
[ "$EVENT_TEST_FILE_COUNT" -ge 1 ]
echo "OK ✅ dosya sistemi sayimi alindi"
echo

echo "===== STEP 3 - RUN OZET ====="
RUN_PKG_COUNT="$(grep -E '^(PKG_COUNT|pkg_count)=' "$RUN_LATEST" | tail -n1 | cut -d= -f2 | tr -d '[:space:]' || true)"
RUN_PASS_PKG_COUNT="$(grep -E '^(PASS_PKG_COUNT|pass_pkg_count)=' "$RUN_LATEST" | tail -n1 | cut -d= -f2 | tr -d '[:space:]' || true)"
RUN_FAIL_PKG_COUNT="$(grep -E '^(FAIL_PKG_COUNT|fail_pkg_count)=' "$RUN_LATEST" | tail -n1 | cut -d= -f2 | tr -d '[:space:]' || true)"

echo "PKG_COUNT=${RUN_PKG_COUNT:-NA}"
echo "PASS_PKG_COUNT=${RUN_PASS_PKG_COUNT:-NA}"
echo "FAIL_PKG_COUNT=${RUN_FAIL_PKG_COUNT:-NA}"

[ -n "${RUN_PKG_COUNT:-}" ]
[ -n "${RUN_PASS_PKG_COUNT:-}" ]
[ -n "${RUN_FAIL_PKG_COUNT:-}" ]
echo "OK ✅ run ozeti alindi"
echo

echo "===== STEP 4 - KAPANIS KRITERI ====="
if [ "$RUN_PKG_COUNT" -lt 1 ]; then
  echo "HATA ❌ run pkg count sifir"
  exit 1
fi

if [ "$RUN_FAIL_PKG_COUNT" != "0" ]; then
  echo "HATA ❌ final suite icinde failing paket var"
  exit 1
fi

echo "OK ✅ kapanis kriterleri saglandi"
echo

echo "===== STEP 5 - TXT RAPOR ====="
{
  echo "time=$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "root=$ROOT"
  echo "inventory_report=$INV_LATEST"
  echo "run_report=$RUN_LATEST"
  echo "all_test_count=$ALL_TEST_COUNT"
  echo "event_test_file_count=$EVENT_TEST_FILE_COUNT"
  echo "pkg_count=$RUN_PKG_COUNT"
  echo "pass_pkg_count=$RUN_PASS_PKG_COUNT"
  echo "fail_pkg_count=$RUN_FAIL_PKG_COUNT"
  echo "closure_status=SUCCESS"
  echo
  echo "[final_decision]"
  echo "event_platform_final_suite=closed"
  echo "event_platform_status=done"
  echo "remaining_open_main_work=none"
} > "$REPORT_TXT"

cp -f "$REPORT_TXT" "$LATEST_TXT"
echo "OK ✅ txt rapor yazildi: $REPORT_TXT"
echo "OK ✅ latest txt guncellendi: $LATEST_TXT"
echo

echo "===== STEP 6 - MD RAPOR ====="
{
  echo "# Event Platform Final Close Report"
  echo
  echo "- Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "- Root: $ROOT"
  echo "- Tum test dosyalari: $ALL_TEST_COUNT"
  echo "- Event test dosyalari: $EVENT_TEST_FILE_COUNT"
  echo "- Paket sayisi: $RUN_PKG_COUNT"
  echo "- Gecen paket: $RUN_PASS_PKG_COUNT"
  echo "- Hata veren paket: $RUN_FAIL_PKG_COUNT"
  echo
  echo "## Final Karar"
  echo
  echo "- Event Platform final suite kapandi"
  echo "- Event Platform ana acik isi kalmadi"
  echo "- Durum: BASARILI"
} > "$REPORT_MD"

cp -f "$REPORT_MD" "$LATEST_MD"
echo "OK ✅ md rapor yazildi: $REPORT_MD"
echo "OK ✅ latest md guncellendi: $LATEST_MD"
echo

echo "===== STEP 7 - FINAL ====="
echo "ALL_TEST_COUNT=$ALL_TEST_COUNT"
echo "EVENT_TEST_FILE_COUNT=$EVENT_TEST_FILE_COUNT"
echo "PKG_COUNT=$RUN_PKG_COUNT"
echo "PASS_PKG_COUNT=$RUN_PASS_PKG_COUNT"
echo "FAIL_PKG_COUNT=$RUN_FAIL_PKG_COUNT"
echo "OK ✅ EVENT-PLATFORM-FINAL-CLOSE-1 basarili"
