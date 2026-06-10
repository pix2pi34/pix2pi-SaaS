#!/bin/bash
set -e

echo "=== PIX2PI ROOT ==="
curl -k -I https://pix2pi.com.tr

echo
echo "=== PANEL ROOT ==="
curl -k -I https://panel.pix2pi.com.tr

echo
echo "=== PIX2PI HTML HEAD ==="
curl -k https://pix2pi.com.tr | head -20

echo
echo "=== PANEL HTML HEAD ==="
curl -k https://panel.pix2pi.com.tr | head -20

echo
echo "=== SERVER HOST HEADER ==="
curl -k -I -H "Host: server.pix2pi.com.tr" https://127.0.0.1

echo
echo "OK ✅ split route test bitti"
