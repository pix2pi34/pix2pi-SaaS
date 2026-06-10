#!/usr/bin/env bash
set -euo pipefail

TS="$(date '+%Y%m%d_%H%M%S')"
ROOT_DIR="/root/pix2pi/pix2pi-SaaS"
LIVE_LOG_DIR="/var/log/pix2pi"
BACKUP_DIR="$ROOT_DIR/backups/57x_${TS}"
ARCHIVE_DIR="$LIVE_LOG_DIR/archive/${TS}"

mkdir -p "$BACKUP_DIR"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$LIVE_LOG_DIR"

handle_log() {
  local name="$1"
  local src="$LIVE_LOG_DIR/$name"

  if [ -f "$src" ]; then
    cp "$src" "$BACKUP_DIR/${name}.bak"
    cp "$src" "$ARCHIVE_DIR/${name}"
    : > "$src"
    echo "OK ✅ archived+truncated $src"
  else
    : > "$src"
    echo "OK ✅ created clean $src"
  fi
}

echo "===== STEP 57X / OPS LOG HYGIENE ONCE ====="
echo "backup_dir=$BACKUP_DIR"
echo "archive_dir=$ARCHIVE_DIR"

handle_log "ops_health_cron.log"
handle_log "ops_health_alert.log"
handle_log "ops_notify.log"
handle_log "ops_service_watch.log"

echo
echo "===== LIVE LOG BYTE CHECK ====="
wc -c \
  "$LIVE_LOG_DIR/ops_health_cron.log" \
  "$LIVE_LOG_DIR/ops_health_alert.log" \
  "$LIVE_LOG_DIR/ops_notify.log" \
  "$LIVE_LOG_DIR/ops_service_watch.log"

echo
echo "OK ✅ step_57x_ops_log_hygiene_once gecti"
