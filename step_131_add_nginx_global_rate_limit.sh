#!/bin/bash
set -e

CONF="/etc/nginx/nginx.conf"

grep -q "pix2pi_limit_zone" $CONF || sed -i '/http {/a \
    limit_req_zone $binary_remote_addr zone=pix2pi_limit_zone:10m rate=20r/s;' $CONF

echo "OK ✅ nginx global rate limit zone eklendi"
