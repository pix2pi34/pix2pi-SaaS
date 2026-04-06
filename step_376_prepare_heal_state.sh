#!/bin/bash
set -euo pipefail

echo "=== STEP 376 / PREPARE HEAL STATE ==="

BASE="/opt/pix2pi/runtime"
STATE_DIR="$BASE/auto_heal"
LOCK_DIR="$STATE_DIR/lock"
FAIL_DIR="$STATE_DIR/fail_counts"
ALERT_DIR="$STATE_DIR/alerts"
SCALE_DIR="$STATE_DIR/scale"
LOG_DIR="$STATE_DIR/logs"

echo
echo "1. klasorler hazirlaniyor..."
mkdir -p "$STATE_DIR" "$LOCK_DIR" "$FAIL_DIR" "$ALERT_DIR" "$SCALE_DIR" "$LOG_DIR"
echo "OK ✅ klasorler hazir"

echo
echo "2. izinler ayarlaniyor..."
chmod 700 "$STATE_DIR" "$LOCK_DIR" "$FAIL_DIR" "$ALERT_DIR" "$SCALE_DIR" "$LOG_DIR"
echo "OK ✅ izinler ayarlandi"

echo
echo "3. ilk state dosyalari..."
touch "$LOG_DIR/auto_heal.log"
touch "$LOG_DIR/alert_engine.log"
touch "$LOG_DIR/scale_hook.log"
chmod 600 "$LOG_DIR/"*.log
echo "OK ✅ state dosyalari hazir"

echo
echo "4. kontrol..."
ls -ld "$STATE_DIR" "$LOCK_DIR" "$FAIL_DIR" "$ALERT_DIR" "$SCALE_DIR" "$LOG_DIR"
ls -l "$LOG_DIR"

echo
echo "=== STEP 376 TAMAM ✅ ==="
