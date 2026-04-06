#!/bin/bash
set -e

echo "=== UNIT DOSYALARI ==="
ls -l /etc/systemd/system/pix2pi-*.service

echo
echo "=== WRAPPER DOSYALARI ==="
ls -l /opt/pix2pi/orchestrator/bin

echo
echo "=== SYSTEMD DAEMON STATUS ==="
systemctl daemon-reload

echo
echo "=== UNIT VALIDATION ==="
systemd-analyze verify /etc/systemd/system/pix2pi-api-gateway.service
systemd-analyze verify /etc/systemd/system/pix2pi-accounting.service
systemd-analyze verify /etc/systemd/system/pix2pi-query-read-model.service
systemd-analyze verify /etc/systemd/system/pix2pi-service-discovery.service

echo
echo "OK ✅ orchestrator foundation test bitti"
