#!/bin/bash
set -e

apt update
apt install -y nginx

systemctl enable nginx
systemctl start nginx

nginx -v

echo "OK ✅ nginx kurulumu bitti"
