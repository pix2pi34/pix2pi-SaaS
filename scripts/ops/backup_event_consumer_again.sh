#!/bin/bash
set -e

FILE="/root/pix2pi/pix2pi-SaaS/cmd/event-consumer/event_consumer_main.go"
BACKUP_DIR="/root/pix2pi/pix2pi-SaaS/_backup_archive"

mkdir -p "$BACKUP_DIR"
cp "$FILE" "$BACKUP_DIR/event_consumer_main.go.$(date +%Y%m%d_%H%M%S).bak"

echo "OK ✅ consumer tekrar yedeklendi"
