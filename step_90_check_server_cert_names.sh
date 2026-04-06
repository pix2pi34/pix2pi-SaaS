#!/bin/bash
set -e

openssl x509 -in /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem -text -noout | grep -A1 "Subject Alternative Name" || true

echo "OK ✅ sertifika alan adlari kontrol edildi"
