#!/bin/bash

OUT_FILE="tum_icerik.txt"
> "$OUT_FILE"

find . -type f \( -name "*.go" -o -name "*.json" -o -name "*.pid" \) | sort | while read file
do
  echo "=============================" >> "$OUT_FILE"
  echo "DOSYA: $file" >> "$OUT_FILE"
  echo "=============================" >> "$OUT_FILE"
  cat "$file" >> "$OUT_FILE"
  echo -e "\n\n" >> "$OUT_FILE"
done

echo "OK ✅ Hepsi $OUT_FILE içine yazıldı."
