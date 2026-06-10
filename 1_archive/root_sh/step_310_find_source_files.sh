#!/bin/bash
set -e

echo "=== /etc/nginx ICINDE DOGRU ARAMA ==="
grep -R -nE "8001|8002|8007|8099|8082|8085" /etc/nginx || true
echo

echo "=== /usr/local/openresty /usr/local/kong /opt ICINDE ARAMA ==="
grep -R -nE "8001|8002|8007|8099|8082|8085" /usr/local/openresty /usr/local/kong /opt 2>/dev/null || true
echo

echo "OK ✅ kaynak dosya aramasi bitti"
