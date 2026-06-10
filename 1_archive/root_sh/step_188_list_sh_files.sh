#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "===== 1) .sh DOSYALARI ====="
find . -type f -name "*.sh" | sort

echo
echo "===== 2) STEP DOSYALARI ====="
find . -type f -name "step_*.sh" | sort

echo
echo "===== 3) CALISTIRMA / OK / SERVICE IPUCLARI ====="
grep -RIn --include="*.sh" \
  -e "OK ✅" \
  -e "OK" \
  -e "go run" \
  -e "docker" \
  -e "nats" \
  -e "journal" \
  -e "ledger" \
  -e "trial" \
  -e "reconciliation" \
  -e "tax" \
  -e "payment" \
  . || true

echo
echo "===== 4) DOSYA ICERIK BASLIKLARI ====="
for f in $(find . -type f -name "*.sh" | sort); do
  echo
  echo "----- $f -----"
  sed -n '1,80p' "$f"
done

echo
echo "OK ✅ sh tarama bitti"
