#!/bin/bash
set -euo pipefail

echo "=== STEP 380 / BIND ALL CRONS ==="

TMP="$(mktemp)"
crontab -l 2>/dev/null > "$TMP" || true

add_line() {
  local line="$1"
  if grep -Fq "$line" "$TMP"; then
    echo "OK ✅ zaten var -> $line"
  else
    echo "$line" >> "$TMP"
    echo "OK ✅ eklendi -> $line"
  fi
}

echo
echo "1. cron satirlari ekleniyor..."

add_line '* * * * * /opt/pix2pi/bin/pix2pi_early_warning.sh >/dev/null 2>&1'
add_line '* * * * * /opt/pix2pi/bin/pix2pi_auto_heal.sh >/dev/null 2>&1'
add_line '* * * * * /opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1'

crontab "$TMP"
rm -f "$TMP"

echo
echo "2. aktif cron:"
crontab -l

echo
echo "3. son loglar:"
tail -n 10 /opt/pix2pi/runtime/auto_heal/logs/auto_heal.log || true
tail -n 10 /opt/pix2pi/runtime/auto_heal/logs/scale_hook.log || true
tail -n 10 /opt/pix2pi/runtime/auto_heal/logs/alert_engine.log || true

echo
echo "=== STEP 380 TAMAM ✅ ==="
