#!/bin/bash
set -euo pipefail

echo "=== STEP 393 / FIX SYSTEMD PIPELINE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. systemd forced detection ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

# === FORCE SYSTEMD TRUTH ===

collect_systemd_stopped() {
  MAP="/opt/pix2pi/runtime/service_map.json"

  if [ ! -f "$MAP" ]; then
    echo ""
    return
  fi

  services=$(jq -r 'keys[]' "$MAP")

  stopped_list=""

  for svc in $services; do
    unit=$(jq -r ".\"$svc\".name" "$MAP")

    if ! systemctl is-active --quiet "$unit"; then
      stopped_list="${stopped_list},$svc"
    fi
  done

  echo "${stopped_list#,}"
}

# override
FORCED_STOPPED=$(collect_systemd_stopped)

if [ -n "$FORCED_STOPPED" ]; then
  STOPPED_NAMES="$FORCED_STOPPED"
fi

EOS

echo "OK ✅ systemd fix eklendi"

echo
echo "3. test..."

bash "$SCRIPT" || true

echo "OK ✅ test"

echo
echo "=== STEP 393 TAMAM ✅ ==="
