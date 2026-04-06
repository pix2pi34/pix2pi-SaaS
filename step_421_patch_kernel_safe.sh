#!/bin/bash
set -euo pipefail

echo "=== STEP 421B / PATCH KERNEL SAFE GETTERS ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/internal/platform/kernel/kernel.go"

python3 <<'PY'
from pathlib import Path
p = Path("/root/pix2pi/pix2pi-SaaS/internal/platform/kernel/kernel.go")
text = p.read_text()

old_write = '''func GetWriteDB() *gorm.DB {
\treturn DB.Write
}'''
new_write = '''func GetWriteDB() *gorm.DB {
\tif DB == nil {
\t\treturn nil
\t}
\treturn DB.Write
}'''

old_read = '''func GetReadDB() *gorm.DB {
\treturn DB.Read
}'''
new_read = '''func GetReadDB() *gorm.DB {
\tif DB == nil {
\t\treturn nil
\t}
\treturn DB.Read
}'''

if old_write not in text:
    raise SystemExit("GetWriteDB blogu bulunamadi")

if old_read not in text:
    raise SystemExit("GetReadDB blogu bulunamadi")

text = text.replace(old_write, new_write)
text = text.replace(old_read, new_read)

p.write_text(text)
PY

gofmt -w "$FILE"

echo "OK ✅ kernel safe getter eklendi"
echo "=== STEP 421B TAMAM ✅ ==="
