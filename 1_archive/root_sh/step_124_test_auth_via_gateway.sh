#!/bin/bash
set -e

curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health

echo
echo "OK ✅ auth gateway test bitti"
