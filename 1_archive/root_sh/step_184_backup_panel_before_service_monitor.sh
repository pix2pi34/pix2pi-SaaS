#!/bin/bash
set -e

mkdir -p ~/pix2pi/pix2pi-SaaS/backups/panel

cp /opt/pix2pi/nginx/panel_index.html \
  ~/pix2pi/pix2pi-SaaS/backups/panel/panel_index.html.before_service_monitor.bak

echo "OK ✅ panel yedegi alindi"
