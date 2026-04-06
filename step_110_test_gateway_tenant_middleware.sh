#!/bin/bash
set -e

URL="https://api.pix2pi.com.tr/api/identity/health"

echo "=== TEST 1 tenant header yok ==="
curl -s -i "$URL"
echo
echo

echo "=== TEST 2 tenant-001 ile ilk istek ==="
curl -s -i -H "X-Tenant-ID: tenant-001" "$URL"
echo
echo

echo "=== TEST 3 tenant-001 rate limit ==="
for i in 1 2 3 4 5 6
do
  echo "--- tenant-001 istek $i ---"
  curl -s -o /tmp/pix2pi_tenant_001_body_$i.txt -w "%{http_code}" \
    -H "X-Tenant-ID: tenant-001" "$URL" > /tmp/pix2pi_tenant_001_code_$i.txt

  CODE=$(cat /tmp/pix2pi_tenant_001_code_$i.txt)
  BODY=$(cat /tmp/pix2pi_tenant_001_body_$i.txt)

  echo "HTTP CODE: $CODE"
  echo "BODY: $BODY"
  echo
done

echo "=== TEST 4 farkli tenant ayri limit ==="
curl -s -i -H "X-Tenant-ID: tenant-002" "$URL"
echo
echo

echo "OK ✅ tenant middleware test bitti"
