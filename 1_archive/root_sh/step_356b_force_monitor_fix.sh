#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 356B / FORCE MONITOR FIX ==="

echo
echo "1. backup..."
cp "$FILE" "$FILE.bak_force_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. normalize helper enjekte..."

sed -i '0,/<script>/s|<script>|<script>\n\nfunction pick(obj, keys, fallback = "") {\n  for (const k of keys) {\n    if (obj && obj[k] !== undefined && obj[k] !== null) return obj[k];\n  }\n  return fallback;\n}\n\nfunction normalizeService(s) {\n  return {\n    name: pick(s, ["name","Name"]),\n    status: pick(s, ["status","Status"]),\n    method: pick(s, ["method","Method"]),\n    detail: pick(s, ["detail","Detail"]),\n    response_ms: Number(pick(s, ["response_ms","ResponseMS"], 0)) || 0,\n    checked_at: pick(s, ["checked_at","CheckedAt"]),\n    state: pick(s, ["state","State"], {}) || {}\n  };\n}\n|' "$FILE"

echo "OK ✅ helper inject"

echo
echo "3. services mapping fix..."

sed -i 's|data.services || \[\]|(data.services || data.Services || []).map(normalizeService)|g' "$FILE"

echo "OK ✅ services fix"

echo
echo "4. updatedAt fix..."

sed -i 's|data.updated_at|data.updated_at || data.UpdatedAt|g' "$FILE"

echo "OK ✅ updatedAt fix"

echo
echo "5. quick check..."

grep -n "normalizeService" "$FILE"
grep -n "data.Services" "$FILE"

echo
echo "OK ✅ step 356B tamam"
