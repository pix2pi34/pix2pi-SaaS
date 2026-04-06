#!/bin/bash
set -e

TS="$(date +%Y%m%d_%H%M%S)"
SRC="$HOME/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"
DST="$HOME/pix2pi/pix2pi-SaaS/.backups/service_watchdog_main.go.before_fail_memory_${TS}.bak"

mkdir -p "$HOME/pix2pi/pix2pi-SaaS/.backups"
cp "$SRC" "$DST"

echo "OK ✅ yedek alindi -> $DST"
