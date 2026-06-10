#!/bin/bash
set -e

echo "=== 1. watchdog / service monitor kaynak arama ==="

grep -RniE "service-monitor|service_watchdog|planned|services|updated_at|status" \
  ~/pix2pi/pix2pi-SaaS/cmd \
  ~/pix2pi/pix2pi-SaaS/internal \
  ~/pix2pi/pix2pi-SaaS/pkg 2>/dev/null | head -n 200 || true

echo
echo "=== 2. olasi json endpoint arama ==="
grep -RniE '"/status"|"/health"|"/internal/service-monitor"|HandleFunc|http.HandleFunc|gin.*GET' \
  ~/pix2pi/pix2pi-SaaS/cmd \
  ~/pix2pi/pix2pi-SaaS/internal \
  ~/pix2pi/pix2pi-SaaS/pkg 2>/dev/null | head -n 200 || true

echo
echo "OK ✅ kaynak tarama bitti"
