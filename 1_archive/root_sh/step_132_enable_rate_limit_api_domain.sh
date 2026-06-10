#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/pix2pi_api_gateway"

grep -q "pix2pi_limit_zone" $CONF || sed -i '/location \/ {/a \
        limit_req zone=pix2pi_limit_zone burst=40 nodelay;' $CONF

echo "OK ✅ api domain rate limit aktif"
