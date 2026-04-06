#!/bin/bash
set -e

echo "=== NGINX ERROR LOG LAST 50 ==="
tail -n 50 /var/log/nginx/error.log || true

echo
echo "OK ✅ nginx error log kontrol bitti"
