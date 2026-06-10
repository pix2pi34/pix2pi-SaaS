#!/bin/bash
set -e

echo "=== STEP 373 / CRON EARLY WARNING ==="

CRON_LINE='* * * * * /opt/pix2pi/bin/pix2pi_early_warning.sh >/dev/null 2>&1'

echo
echo "1. mevcut cron aliniyor..."
TMP_CRON="$(mktemp)"
crontab -l 2>/dev/null > "$TMP_CRON" || true
echo "OK ✅ cron alindi"

echo
echo "2. duplicate kontrol..."
if grep -Fq "/opt/pix2pi/bin/pix2pi_early_warning.sh" "$TMP_CRON"; then
  echo "OK ✅ cron zaten var"
else
  echo "$CRON_LINE" >> "$TMP_CRON"
  crontab "$TMP_CRON"
  echo "OK ✅ cron eklendi"
fi

rm -f "$TMP_CRON"

echo
echo "3. aktif cron gosteriliyor..."
crontab -l

echo
echo "OK ✅ step 373 tamam"
