#!/bin/bash
set -e

nginx -t
systemctl reload nginx

echo "OK ✅ nginx rate limit aktif"
