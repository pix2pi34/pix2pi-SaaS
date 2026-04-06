#!/bin/bash
set -e

nginx -t
systemctl reload nginx

echo "OK ✅ redirect fix sonrasi nginx reload bitti"
