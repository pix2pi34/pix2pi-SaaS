#!/bin/bash
set -e

WORKDIR="/root/pix2pi/pix2pi-SaaS"
SRC_DIR="/root/pix2pi/pix2pi-SaaS/cmd/service-watchdog"
TARGET="$SRC_DIR/service_watchdog_main.go"
BIN="$WORKDIR/bin/service-watchdog"

echo "=== STEP 355E / FIND LAST BUILDABLE WATCHDOG BACKUP ==="

echo
echo "1. mevcut dosya yedegi aliniyor..."
cp "$TARGET" "${TARGET}.before_find_$(date +%Y%m%d_%H%M%S)" || true
echo "OK ✅ mevcut dosya yedeklendi"

echo
echo "2. aday backup listesi hazirlaniyor..."
ls -1t "$SRC_DIR"/service_watchdog_main.go.bak* > /tmp/watchdog_backup_list.txt
cat /tmp/watchdog_backup_list.txt
echo "OK ✅ backup listesi hazir"

echo
echo "3. derlenen ilk backup aranıyor..."

FOUND=""
while read -r CANDIDATE; do
  echo
  echo "TEST => $CANDIDATE"
  cp "$CANDIDATE" "$TARGET"

  if cd "$WORKDIR" && go build -o "$BIN.test" ./cmd/service-watchdog >/tmp/watchdog_build.log 2>&1; then
    FOUND="$CANDIDATE"
    echo "OK ✅ derlenen backup bulundu: $FOUND"
    break
  else
    echo "HATA ❌ bu backup derlenmedi"
    tail -n 5 /tmp/watchdog_build.log || true
  fi
done < /tmp/watchdog_backup_list.txt

echo
if [ -z "$FOUND" ]; then
  echo "KRITIK HATA ❌ hicbir backup derlenmedi"
  exit 1
fi

echo "4. saglam backup aktif ediliyor..."
cp "$FOUND" "$TARGET"
cd "$WORKDIR"
go build -o "$BIN" ./cmd/service-watchdog
echo "OK ✅ build tamam"

echo
echo "5. watchdog restart..."
pkill -f "/root/pix2pi/pix2pi-SaaS/bin/service-watchdog" || true
nohup "$BIN" >/tmp/pix2pi-watchdog.log 2>&1 &
sleep 2
echo "OK ✅ watchdog restart"

echo
echo "6. status test..."
curl -s http://127.0.0.1:8090/status | head -c 400
echo

echo
echo "7. secilen backup:"
echo "$FOUND"

echo
echo "OK ✅ step 355e tamam"
