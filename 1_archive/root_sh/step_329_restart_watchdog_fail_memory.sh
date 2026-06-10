#!/bin/bash
set -e

systemctl restart pix2pi-watchdog
systemctl status pix2pi-watchdog --no-pager -n 20

echo "OK ✅ watchdog restart tamam"
