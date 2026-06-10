#!/bin/bash
set -e

mkdir -p ~/pix2pi/nginx-backups

cp /etc/nginx/nginx.conf ~/pix2pi/nginx-backups/nginx.conf.before_rate_limit.bak

echo "OK ✅ nginx config yedegi alindi"
