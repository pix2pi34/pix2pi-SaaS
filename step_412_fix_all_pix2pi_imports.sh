#!/bin/bash
set -euo pipefail

echo "=== STEP 412 / FIX ALL PIX2PI IMPORTS ==="

ROOT="$HOME/pix2pi/pix2pi-SaaS"
BACKUP_DIR="$ROOT/.backups/import_fix_$(date +%Y%m%d_%H%M%S)"

echo
echo "1. backup klasoru hazirlaniyor..."
mkdir -p "$BACKUP_DIR"
echo "OK ✅ backup klasoru: $BACKUP_DIR"

echo
echo "2. eski importlar taraniyor..."
grep -RIl '\"pix2pi/internal/' "$ROOT" \
  --include='*.go' \
  --exclude-dir=.git \
  --exclude-dir=.backups \
  > "$BACKUP_DIR/files.list" || true

cat "$BACKUP_DIR/files.list" || true
echo "OK ✅ tarama bitti"

echo
echo "3. backup aliniyor..."
while IFS= read -r file; do
  [ -z "$file" ] && continue
  rel="${file#$ROOT/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp "$file" "$BACKUP_DIR/$rel"
done < "$BACKUP_DIR/files.list"
echo "OK ✅ backup alindi"

echo
echo "4. importlar duzeltiliyor..."
while IFS= read -r file; do
  [ -z "$file" ] && continue
  sed -i 's|"pix2pi/internal/|"github.com/divrigili/pix2pi-SaaS/internal/|g' "$file"
done < "$BACKUP_DIR/files.list"
echo "OK ✅ importlar duzeltildi"

echo
echo "5. kontrol..."
grep -RIn '\"pix2pi/internal/' "$ROOT" \
  --include='*.go' \
  --exclude-dir=.git \
  --exclude-dir=.backups || true
echo "OK ✅ kontrol bitti"

echo
echo "6. gofmt..."
while IFS= read -r file; do
  [ -z "$file" ] && continue
  gofmt -w "$file"
done < "$BACKUP_DIR/files.list"
echo "OK ✅ gofmt bitti"

echo
echo "=== STEP 412 TAMAM ✅ ==="
