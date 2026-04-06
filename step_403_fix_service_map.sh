#!/bin/bash
set -euo pipefail

echo "=== STEP 403 / FIX SERVICE MAP ==="

MAP="/opt/pix2pi/runtime/service_map.json"

echo "1. backup..."
cp "$MAP" "${MAP}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. gerçek servis map yaziliyor..."

cat <<'JSON' > "$MAP"
{
  "auth": {
    "type": "systemd",
    "name": "pix2pi-auth"
  },
  "api_gateway": {
    "type": "systemd",
    "name": "pix2pi-api-gateway"
  },
  "accounting": {
    "type": "systemd",
    "name": "pix2pi-accounting"
  },
  "identity": {
    "type": "systemd",
    "name": "pix2pi-identity"
  },
  "panel": {
    "type": "systemd",
    "name": "pix2pi-panel"
  },
  "query_read_model": {
    "type": "systemd",
    "name": "pix2pi-query-read-model"
  },
  "service_registry": {
    "type": "systemd",
    "name": "pix2pi-service-registry"
  }
}
JSON

echo "OK ✅ map yazildi"

echo
echo "3. test..."

cat "$MAP" | jq .

echo "OK ✅ json valid"

echo
echo "=== STEP 403 TAMAM ✅ ==="
