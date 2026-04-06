#!/bin/bash
set -e

echo "=== SERVER DNS ==="
dig server.pix2pi.com.tr +short

echo
echo "=== SERVER HTTPS ==="
curl -k -I https://server.pix2pi.com.tr

echo
echo "OK ✅ server ssl test bitti"
