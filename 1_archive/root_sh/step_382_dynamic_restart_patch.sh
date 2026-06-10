#!/bin/bash
set -euo pipefail

echo "=== STEP 382 / DYNAMIC RESTART ENGINE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"
MAP="/opt/pix2pi/runtime/service_map.json"

echo
echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅"

echo
echo "2. patch uygulanıyor..."

cat <<'EOS' >> "$SCRIPT"

restart_service_dynamic() {
  local svc="$1"
  local MAP="/opt/pix2pi/runtime/service_map.json"

  if [ ! -f "$MAP" ]; then
    return 1
  fi

  local type name
  type="$(jq -r ".\"$svc\".type // empty" "$MAP")"
  name="$(jq -r ".\"$svc\".name // empty" "$MAP")"

  if [ -z "$type" ] || [ -z "$name" ]; then
    return 1
  fi

  case "$type" in
    systemd)
      systemctl restart "$name"
      ;;
    docker)
      docker restart "$name"
      ;;
    *)
      return 1
      ;;
  esac
}

# eski restart_auth override
restart_auth() {
  restart_service_dynamic "auth"
}
EOS

echo "OK ✅ patch eklendi"

echo
echo "3. test..."
/opt/pix2pi/bin/pix2pi_auto_heal.sh
echo "OK ✅ test"

echo
echo "=== STEP 382 TAMAM ✅ ==="
