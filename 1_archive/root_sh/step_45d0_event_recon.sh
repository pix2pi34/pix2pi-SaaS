#!/bin/bash
set -euo pipefail

echo "=== STEP 45D-0 / EVENT RECON ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

OUT="$HOME/pix2pi/pix2pi-SaaS/step_45d0_event_recon.txt"

{
  echo "===== 1) NATS / EVENT DOSYALARI ====="
  grep -RIn --exclude-dir=.git --exclude='*.log' \
    -E 'nats|jetstream|publish|subscribe|subject|event' \
    cmd internal kernel pkg 2>/dev/null || true

  echo
  echo "===== 2) USER EVENT ARAMA ====="
  grep -RIn --exclude-dir=.git --exclude='*.log' \
    -E 'user_created|created_user|UserCreated|Register|register|signup|sign_up' \
    cmd internal kernel pkg 2>/dev/null || true

  echo
  echo "===== 3) NATS IMPORT ARAMA ====="
  grep -RIn --exclude-dir=.git --exclude='*.log' \
    -E 'github.com/nats-io/nats.go|nats\.Connect|jetstream' \
    cmd internal kernel pkg 2>/dev/null || true

  echo
  echo "===== 4) IDENTITY / USER DOSYALARI ====="
  find internal -type f | grep -E 'identity|user' | sort || true

  echo
  echo "===== 5) EVENTBUS DOSYALARI ====="
  find . -type f | grep -E 'eventbus|publisher|subscriber|consumer|nats' | sort || true

} > "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
echo
echo "===== RAPOR ON IZLEME ====="
sed -n '1,220p' "$OUT"

echo
echo "OK ✅ STEP 45D-0 tamam"
