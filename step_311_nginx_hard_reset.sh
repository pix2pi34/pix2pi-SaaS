#!/bin/bash
set -e

echo "=== NGINX HARD RESET ==="

echo "1. nginx stop"
systemctl stop nginx || true

echo "2. tum nginx processleri olduruluyor"
pkill -9 nginx || true

sleep 1

echo "3. port kontrol (once)"
ss -tulnp | grep nginx || echo "OK ✅ hic nginx kalmadi"

echo "4. nginx tekrar baslatiliyor"
systemctl start nginx

sleep 1

echo "5. port kontrol (sonra)"
ss -tulnp | grep nginx || true

echo "OK ✅ nginx temiz reset tamam"
