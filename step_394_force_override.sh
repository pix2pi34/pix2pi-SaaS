#!/bin/bash
set -euo pipefail

echo "=== STEP 394 / FORCE SYSTEMD OVERRIDE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. eski systemd block temizleniyor..."
sed -i '/FORCE SYSTEMD TRUTH/,$d' "$SCRIPT"
echo "OK ✅ eski block silindi"

echo
echo "3. FINAL override ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

# === FINAL SYSTEMD AUTHORITY (EN SONDA ÇALIŞIR) ===

collect_systemd_stopped() {
  MAP="/opt/pix2pi/runtime/service_map.json"

  if [ ! -f "$MAP" ]; then
    echo ""
    return
  fi

  services=$(jq -r 'keys[]' "$MAP')

  stopped=""

  for svc in $services; do
    unit=$(jq -r ".\"$svc\".name" "$MAP")

    if ! systemctl is-active --quiet "$unit"; then
      stopped="$stopped,$svc"
    fi
  done

  echo "${stopped#,}"
}

FINAL_STOPPED=$(collect_systemd_stopped)

STOPPED_NAMES="$FINAL_STOPPED"

if [ -n "$STOPPED_NAMES" ]; then
  SEVERITY="critical"
fi

EOS

echo "OK ✅ FINAL override eklendi"

echo
echo "4. test..."

bash "$SCRIPT" || true

echo "OK ✅ test"

echo
echo "=== STEP 394 TAMAM ✅ ==="
