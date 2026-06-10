#!/bin/bash

echo "=== GO PROCESSLER ==="
ps aux | grep go | grep -v grep

echo
echo "=== PIX2PI PROCESSLER ==="
ps aux | grep pix2pi | grep -v grep

echo
echo "=== PORT KULLANIMI ==="
ss -tulnp | grep -E "8080|8007|8002|8082|8085" || true

echo
echo "=== SYSTEMD SERVISLER ==="
systemctl list-units --type=service | grep pix2pi || true

echo
echo "OK ✅ process snapshot alindi"
