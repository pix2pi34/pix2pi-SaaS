#!/bin/bash
set -e

echo "=== STEP 372 / TEST EARLY WARNING ==="

echo
echo "1. json pretty print..."
jq . /opt/pix2pi/runtime/watchdog_alerts.json

echo
echo "2. severity cekiliyor..."
jq -r '.severity' /opt/pix2pi/runtime/watchdog_alerts.json

echo
echo "3. counts cekiliyor..."
jq '.counts' /opt/pix2pi/runtime/watchdog_alerts.json

echo
echo "4. stopped servisler..."
jq -r '.stopped_names' /opt/pix2pi/runtime/watchdog_alerts.json

echo
echo "5. son log..."
tail -n 5 /opt/pix2pi/runtime/watchdog_alerts.log || true

echo
echo "OK ✅ step 372 test bitti"
