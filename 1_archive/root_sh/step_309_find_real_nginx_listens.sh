#!/bin/bash
set -e

echo "=== AKTIF NGINX INCLUDE AGACI ==="
nginx -T 2>/tmp/pix2pi_nginx_full_dump.txt || true
echo "OK ✅ nginx -T dump alindi: /tmp/pix2pi_nginx_full_dump.txt"
echo

echo "=== PORT ARAMA (DOGRU REGEX) ==="
grep -nE "8001|8002|8007|8099|8082|8085" /tmp/pix2pi_nginx_full_dump.txt || true
echo

echo "=== SERVER / LISTEN / INCLUDE ODAKLI ==="
grep -nE "listen .*8001|listen .*8002|listen .*8007|listen .*8099|proxy_pass .*8001|proxy_pass .*8002|proxy_pass .*8007|proxy_pass .*8099|include " /tmp/pix2pi_nginx_full_dump.txt || true
echo

echo "OK ✅ gercek nginx listen taramasi bitti"
