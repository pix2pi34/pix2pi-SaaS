#!/bin/bash
set -e

echo "=== STEP 375 / AUTO HEAL CRON ==="

CRON_LINE='* * * * * /opt/pix2pi/bin/pix2pi_auto_heal.sh >/dev/null 2>&1'

TMP="$(mktemp)"
crontab -l 2>/dev/null > "$TMP" || true

if grep -Fq "pix2pi_auto_heal.sh" "$TMP"; then
  echo "OK ✅ zaten var"
else
  echo "$CRON_LINE" >> "$TMP"
  crontab "$TMP"
  echo "OK ✅ cron eklendi"
fi

rm -f "$TMP"

echo
crontab -l

echo
echo "=== STEP 375 TAMAM ✅ ==="
