#!/usr/bin/env bash
set -euo pipefail

cd ~/pix2pi/pix2pi-SaaS

REPORT_DIR=~/pix2pi/pix2pi-SaaS/reports
mkdir -p "$REPORT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/ops_health_${TS}.txt"
LATEST_FILE="$REPORT_DIR/ops_health_latest.txt"

{
  echo "===== STEP 57C / OPS HEALTH REPORT ====="
  echo "time=$(date '+%Y-%m-%d %H:%M:%S')"
  echo

  echo "===== 1) SERVICE STATUS ====="
  systemctl is-active --quiet pix2pi-api-gateway.service
  echo "OK ✅ api-gateway active"

  systemctl is-active --quiet pix2pi-user-created-consumer.service
  echo "OK ✅ user-created-consumer active"

  systemctl is-active --quiet pix2pi-accounting.service
  echo "OK ✅ accounting active"

  echo
  echo "===== 2) PROD OPS SUITE ====="
  ~/pix2pi/pix2pi-SaaS/scripts/prod_ops_suite.sh

  echo
  echo "===== 3) LAST API GATEWAY LOG ====="
  journalctl -u pix2pi-api-gateway.service -n 10 --no-pager

  echo
  echo "===== 4) LAST USER-CREATED-CONSUMER LOG ====="
  journalctl -u pix2pi-user-created-consumer.service -n 10 --no-pager

  echo
  echo "===== 5) LAST ACCOUNTING LOG ====="
  journalctl -u pix2pi-accounting.service -n 10 --no-pager

  echo
  echo "OK ✅ step_57c_ops_health_report gecti"
} | tee "$REPORT_FILE"

cp "$REPORT_FILE" "$LATEST_FILE"

echo
echo "OK ✅ rapor dosyasi olustu -> $REPORT_FILE"
echo "OK ✅ latest rapor guncellendi -> $LATEST_FILE"
