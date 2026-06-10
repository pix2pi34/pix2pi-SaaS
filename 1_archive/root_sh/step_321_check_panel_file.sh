#!/bin/bash
set -e

echo "==== PANEL DOSYA KONTROL ===="
ls -lah /opt/pix2pi/nginx/panel_index.html

echo
echo "==== ILK 40 SATIR ===="
sed -n '1,40p' /opt/pix2pi/nginx/panel_index.html

echo
echo "OK ✅ panel dosya kontrolu bitti"
