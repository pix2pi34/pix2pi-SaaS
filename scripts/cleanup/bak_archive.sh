#!/bin/bash

BASE="/root/pix2pi/pix2pi-SaaS"
ARCHIVE="$BASE/_backup_archive"

echo "=== BAK CLEANUP START ==="

mkdir -p "$ARCHIVE"

find "$BASE" -type f -name "*.bak*" -print -exec mv {} "$ARCHIVE" \;

echo "BAK files moved to archive"

find "$ARCHIVE" -type f -mtime +7 -delete

echo "Old archive files deleted"

echo "=== DONE ==="
