#!/bin/bash
set -e

echo "STEP4 watcher starting (ALL PROJECT)"

ROOT="."
EXCLUDE="(\.git/|\.backups/|vendor/|node_modules/)"

# Repo kökünde bk.sh var mı?
if [ ! -x "scripts/backups/bk.sh" ]; then
  echo "ERR: scripts/backups/bk.sh not found or not executable"
  exit 1
fi

echo "OK ✅ watching: $ROOT"
echo "OK ✅ exclude: $EXCLUDE"
echo "OK ✅ events: close_write,move,create"

# -m: sürekli
# -r: recursive
# close_write: dosya kaydedildi
# move/create: rename/new file
inotifywait -m -r -e close_write,move,create \
  --format '%w%f' \
  --exclude "$EXCLUDE" \
  "$ROOT" | while read -r FILE; do

  # sadece dosya ise yedekle
  if [ -f "$FILE" ]; then
    scripts/backups/bk.sh "$FILE" || true
  fi
done
