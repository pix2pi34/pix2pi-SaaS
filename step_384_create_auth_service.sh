#!/bin/bash
set -euo pipefail

echo "=== STEP 384 / CREATE AUTH SERVICE ==="

SERVICE_FILE="/etc/systemd/system/pix2pi-auth.service"

echo
echo "1. service dosyasi yaziliyor..."

cat <<'EOS' > "$SERVICE_FILE"
[Unit]
Description=Pix2pi Auth Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do echo "auth running"; sleep 10; done'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOS

echo "OK ✅ service yazildi"

echo
echo "2. daemon reload..."
systemctl daemon-reexec
systemctl daemon-reload
echo "OK ✅ daemon reload"

echo
echo "3. service enable/start..."
systemctl enable pix2pi-auth
systemctl start pix2pi-auth
echo "OK ✅ service aktif"

echo
echo "4. status kontrol..."
systemctl status pix2pi-auth --no-pager | head -n 10

echo
echo "=== STEP 384 TAMAM ✅ ==="
