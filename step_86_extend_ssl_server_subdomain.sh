#!/bin/bash
set -e

certbot --nginx \
--cert-name pix2pi.com.tr \
--expand \
-d pix2pi.com.tr \
-d www.pix2pi.com.tr \
-d panel.pix2pi.com.tr \
-d api.pix2pi.com.tr \
-d auth.pix2pi.com.tr \
-d pos.pix2pi.com.tr \
-d server.pix2pi.com.tr \
--non-interactive \
--agree-tos \
-m admin@pix2pi.com.tr

echo "OK ✅ ssl server subdomain ile genislendi"
