#!/bin/bash
set -e

echo "=== NGINX PROCESSLER ==="
ps -ef | grep nginx | grep -v grep || true
echo

echo "=== NGINX PID FILE ==="
cat /run/nginx.pid || true
echo

echo "=== 8002 / 8007 SAHIPLERI ==="
ss -ltnp | grep -E '8002|8007' || true
echo

echo "OK ✅ nginx process kontrolu bitti"
