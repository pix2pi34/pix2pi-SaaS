#!/bin/bash
set -e

echo "=== STRICT SERVER HTTPS ==="
curl -I https://server.pix2pi.com.tr

echo
echo "=== STRICT PANEL HTTPS ==="
curl -I https://panel.pix2pi.com.tr

echo
echo "OK ✅ strict ssl test bitti"
