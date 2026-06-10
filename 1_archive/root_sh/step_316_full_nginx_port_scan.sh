#!/bin/bash
set -e

echo "=== FULL NGINX PORT AV ==="

grep -R -nE "8001|8002|8007" /etc/nginx 2>/dev/null

echo
echo "=== INCLUDE ZINCIRI ==="
grep -R "include" /etc/nginx 2>/dev/null

echo
echo "OK 🔍 port kaynagi bulunmali"
