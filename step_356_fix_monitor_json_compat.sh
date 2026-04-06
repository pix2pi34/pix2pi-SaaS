#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 356 / MONITOR JSON COMPAT FIX ==="

echo
echo "1. backup aliniyor..."
cp "$FILE" "$FILE.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"

echo
echo "2. normalize helper inject ediliyor..."

python3 <<'PY'
from pathlib import Path

p = Path("/opt/pix2pi/nginx/monitor.html")
text = p.read_text()

helper = """
function pick(obj, keys, fallback = "") {
  for (const k of keys) {
    if (obj && obj[k] !== undefined && obj[k] !== null) return obj[k];
  }
  return fallback;
}

function normalizeService(s) {
  return {
    name: pick(s, ["name", "Name"]),
    status: pick(s, ["status", "Status"]),
    method: pick(s, ["method", "Method"]),
    detail: pick(s, ["detail", "Detail"]),
    response_ms: Number(pick(s, ["response_ms", "responseMs", "ResponseMS"], 0)) || 0,
    checked_at: pick(s, ["checked_at", "checkedAt", "CheckedAt"]),
    state: pick(s, ["state", "State"], {}) || {}
  };
}
""".strip()

if "function normalizeService(s)" not in text:
    marker = "const PLANNED_SERVICES = ["
    idx = text.find(marker)
    if idx != -1:
        text = text[:idx] + helper + "\n\n" + text[idx:]
    else:
        raise SystemExit("PLANNED_SERVICES marker bulunamadi")

text = text.replace(
    "const services = data.services || [];",
    'const services = (data.services || data.Services || []).map(normalizeService);'
)

text = text.replace(
    'document.getElementById("updatedAt").textContent = escapeHtml(data.updated_at || "-");',
    'document.getElementById("updatedAt").textContent = escapeHtml(data.updated_at || data.UpdatedAt || "-");'
)

p.write_text(text)
PY

echo "OK ✅ normalize helper eklendi"

echo
echo "3. local dosya kontrol..."
grep -n "function normalizeService" "$FILE"
grep -n "data.services || data.Services" "$FILE"
echo "OK ✅ patch kontrol bitti"

echo
echo "4. html syntax kaba kontrol..."
grep -n "updated_at || data.UpdatedAt" "$FILE"
echo "OK ✅ updatedAt uyumu tamam"

echo
echo "5. local header test..."
curl -k -I https://127.0.0.1/monitor
echo "OK ✅ local monitor header test"

echo
echo "=== STEP 356 TAMAM ==="
