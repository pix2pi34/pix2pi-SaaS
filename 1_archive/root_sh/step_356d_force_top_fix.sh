#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 356D / FORCE TOP FIX ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_top_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. eski normalize temizleniyor..."
sed -i '/function normalizeService/,/}/d' "$FILE"
sed -i '/function pick/,/}/d' "$FILE"

echo "OK ✅ eski temizlendi"

echo
echo "3. script içine en üste ekleniyor..."

awk '
BEGIN { injected=0 }
/<script>/ && injected==0 {
  print;
  print "function pick(obj, keys, fallback = \"\") {";
  print "  for (const k of keys) {";
  print "    if (obj && obj[k] !== undefined && obj[k] !== null) return obj[k];";
  print "  }";
  print "  return fallback;";
  print "}";
  print "";
  print "function normalizeService(s) {";
  print "  return {";
  print "    name: pick(s, [\"name\",\"Name\"]),";
  print "    status: pick(s, [\"status\",\"Status\"]),";
  print "    method: pick(s, [\"method\",\"Method\"]),";
  print "    detail: pick(s, [\"detail\",\"Detail\"]),";
  print "    response_ms: Number(pick(s, [\"response_ms\",\"ResponseMS\"], 0)) || 0,";
  print "    checked_at: pick(s, [\"checked_at\",\"CheckedAt\"]),";
  print "    state: pick(s, [\"state\",\"State\"], {}) || {}";
  print "  };";
  print "}";
  injected=1;
  next;
}
{ print }
' "$FILE" > "$FILE.tmp"

mv "$FILE.tmp" "$FILE"

echo "OK ✅ inject tamam"

echo
echo "4. kontrol..."

grep -n "normalizeService" "$FILE"

echo
echo "OK ✅ step 356D tamam"
