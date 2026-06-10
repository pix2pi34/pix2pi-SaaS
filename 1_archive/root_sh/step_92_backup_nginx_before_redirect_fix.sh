#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/nginx

cp /etc/nginx/sites-available/pix2pi_ssl \
  ~/pix2pi/pix2pi-SaaS/backups/nginx/pix2pi_ssl.before_redirect_fix.bak

echo "OK ✅ redirect fix oncesi nginx yedegi alindi"
