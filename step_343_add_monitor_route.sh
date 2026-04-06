#!/bin/bash
set -e

CONF="/etc/nginx/sites-enabled/pix2pi_ssl"

cp "$CONF" "${CONF}.bak_$(date +%Y%m%d_%H%M%S)"

if ! grep -q 'location = /monitor' "$CONF"; then
  sed -i '/location \/containers\/ {/i \
    location = /monitor {\n\
        root /root/pix2pi/pix2pi-SaaS/web;\n\
        index monitor.html;\n\
        try_files /monitor.html =404;\n\
    }\n' "$CONF"
fi

nginx -t
systemctl reload nginx

echo "OK ✅ monitor route aktif"
