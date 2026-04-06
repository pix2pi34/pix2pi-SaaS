#!/bin/bash
set -euo pipefail

echo "=== STEP 385 / SYSTEMD HEALTH PATCH ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"
MAP="/opt/pix2pi/runtime/service_map.json"

echo
echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅"

echo
echo "2. patch ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

collect_systemd_status() {
  local MAP="/opt/pix2pi/runtime/service_map.json"
  local stopped=""

  if [ ! -f "$MAP" ]; then
    return
  fi

  services=$(jq -r 'keys[]' "$MAP")

  for svc in $services; do
    type=$(jq -r ".\"$svc\".type" "$MAP")
    name=$(jq -r ".\"$svc\".name" "$MAP")

    if [ "$type" = "systemd" ]; then
      state=$(systemctl is-active "$name" 2>/dev/null || echo "unknown")

      if [ "$state" != "active" ]; then
        stopped="${stopped},${svc}"
      fi
    fi
  done

  echo "${stopped#,}"
}

# override stopped_names
SYSTEMD_STOPPED="$(collect_systemd_status)"

if [ -n "$SYSTEMD_STOPPED" ]; then
  STOPPED_NAMES="$SYSTEMD_STOPPED"
fi

EOS

echo "OK ✅ patch eklendi"

echo
echo "3. test..."
/opt/pix2pi/bin/pix2pi_early_warning.sh
echo "OK ✅ test"

echo
echo "=== STEP 385 TAMAM ✅ ==="
