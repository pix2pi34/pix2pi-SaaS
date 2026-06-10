#!/bin/bash
set -e

echo "=== BACKUP ==="
cp /etc/systemd/system/pix2pi-api-gateway.service /etc/systemd/system/pix2pi-api-gateway.service.bak || true
cp /etc/systemd/system/pix2pi-accounting.service /etc/systemd/system/pix2pi-accounting.service.bak || true
cp /etc/systemd/system/pix2pi-query-read-model.service /etc/systemd/system/pix2pi-query-read-model.service.bak || true
cp /etc/systemd/system/pix2pi-service-discovery.service /etc/systemd/system/pix2pi-service-discovery.service.bak || true

echo "=== FIXING UNITS ==="

fix_unit () {
  FILE=$1

  sed -i '/StartLimitIntervalSec/d' $FILE
  sed -i '/StartLimitBurst/d' $FILE

  sed -i '/^\[Unit\]/a StartLimitIntervalSec=60\nStartLimitBurst=10' $FILE
}

fix_unit /etc/systemd/system/pix2pi-api-gateway.service
fix_unit /etc/systemd/system/pix2pi-accounting.service
fix_unit /etc/systemd/system/pix2pi-query-read-model.service
fix_unit /etc/systemd/system/pix2pi-service-discovery.service

echo "=== RELOAD ==="
systemctl daemon-reexec
systemctl daemon-reload

echo "=== VERIFY ==="
systemd-analyze verify /etc/systemd/system/pix2pi-api-gateway.service
systemd-analyze verify /etc/systemd/system/pix2pi-accounting.service
systemd-analyze verify /etc/systemd/system/pix2pi-query-read-model.service
systemd-analyze verify /etc/systemd/system/pix2pi-service-discovery.service

echo "OK ✅ systemd fix tamam"
