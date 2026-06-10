#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 356C / SAFE FIX ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_safe_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. helper ekleniyor..."

awk '
BEGIN { injected=0 }
/<script>/ && injected==0 {
  print;
  print "";
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
echo "OK ✅ helper eklendi"

echo
echo "3. services mapping fix..."

sed -i 's/data.services/(data.services || data.Services || []).map(normalizeService)/g' "$FILE"

echo "OK ✅ services fix"

echo
echo "4. updatedAt fix..."

sed -i 's/data.updated_at/data.updated_at || data.UpdatedAt/g' "$FILE"

echo "OK ✅ updatedAt fix"

echo
echo "5. kontrol..."

grep -n normalizeService "$FILE" || true

echo
echo "OK ✅ step 356C tamam"
