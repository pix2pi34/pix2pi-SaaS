#!/bin/bash
set -e

FILE="$1"

if [ -z "$FILE" ]; then
  echo "HATA: dosya yolu verilmadi"
  echo "Kullanim: ~/pix2pi/pix2pi-SaaS/step_324_backup_status_engine.sh DOSYA"
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "HATA: dosya bulunamadi -> $FILE"
  exit 1
fi

TS="$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "${FILE}.bak_${TS}"

echo "OK ✅ yedek alindi -> ${FILE}.bak_${TS}"
