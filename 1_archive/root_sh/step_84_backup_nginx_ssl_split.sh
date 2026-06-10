#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/nginx

cp /etc/nginx/sites-available/pix2pi_ssl \
  ~/pix2pi/pix2pi-SaaS/backups/nginx/pix2pi_ssl.before_split.bak

echo "OK ✅ nginx ssl config yedegi alindi"
