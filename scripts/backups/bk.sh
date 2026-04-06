#!/bin/bash
set -e

F="$1"

if [ -z "$F" ]; then
 echo "ERR: file path required"
 exit 1
fi

if [ ! -f "$F" ]; then
 echo "ERR: file not found $F"
 exit 1
fi

YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
TS=$(date +%H%M%S)

SAFE=$(echo "$F" | sed 's#/#__#g')

DEST_DIR=".backups/$YEAR/$MONTH/$DAY"
mkdir -p "$DEST_DIR"

DEST="$DEST_DIR/${SAFE}_${TS}.bak"

cp -a "$F" "$DEST"

echo "OK ✅ backup -> $DEST"
