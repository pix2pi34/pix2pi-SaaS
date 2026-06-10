#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

pkill -f service_watchdog_main || true
pkill -f ./cmd/service-watchdog || true

nohup go run ./cmd/service-watchdog/service_watchdog_main.go >/tmp/pix2pi_service_watchdog.log 2>&1 &
sleep 2

cat /tmp/pix2pi_service_watchdog.log
echo
curl -s http://127.0.0.1:9016/health
echo
echo
curl -s http://127.0.0.1:9016/status
echo
echo "OK ✅ watchdog run test bitti"
