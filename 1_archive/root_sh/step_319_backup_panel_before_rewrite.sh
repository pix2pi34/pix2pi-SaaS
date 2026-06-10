#!/bin/bash
set -e

PANEL_FILE="/opt/pix2pi/nginx/panel_index.html"
BACKUP_DIR="/root/pix2pi/pix2pi-SaaS/_panel_backups"
TS="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

if [ -f "$PANEL_FILE" ]; then
  cp "$PANEL_FILE" "$BACKUP_DIR/panel_index.html.before_rewrite_${TS}.bak"
  echo "OK ✅ panel yedegi alindi -> $BACKUP_DIR/panel_index.html.before_rewrite_${TS}.bak"
else
  echo "OK ✅ panel dosyasi bulunamadi, yeni dosya yazilacak"
fi
