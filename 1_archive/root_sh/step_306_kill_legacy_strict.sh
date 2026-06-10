#!/bin/bash

echo "=== SYSTEMD PIDLER ==="
SYSTEMD_PIDS=$(systemctl status pix2pi-* | grep Main | awk '{print $3}')

echo "$SYSTEMD_PIDS"

echo
echo "=== LEGACY PROCESSLER ARANIYOR ==="

ps aux | grep '/tmp/go-build' | grep -v grep | while read line; do
  PID=$(echo $line | awk '{print $2}')
  
  if echo "$SYSTEMD_PIDS" | grep -q "$PID"; then
    echo "SKIP (systemd): $PID"
  else
    echo "KILL (legacy): $PID"
    kill -9 $PID || true
  fi
done

echo
echo "=== KONTROL ==="
ps aux | grep '/tmp/go-build' | grep -v grep || echo "OK temiz"

echo
echo "OK ✅ sadece systemd kaldi"
