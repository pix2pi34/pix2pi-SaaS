#!/bin/bash
set -e

nginx -t
systemctl reload nginx

echo "OK ✅ nginx split config reload bitti"
