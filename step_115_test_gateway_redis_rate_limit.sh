#!/bin/bash
set -e

URL="https://api.pix2pi.com.tr/api/identity/health"

echo "=== TEST 1 tenant header yok ==="
curl -s -i "$URL"
echo
echo

echo "=== TEST 2 tenant-redis-001 ilk istek ==="
curl -s -i -H "X-Tenant-ID: tenant-redis-001" "$URL"
echo
echo

echo "=== TEST 3 tenant-redis-001 rate limit ==="
for i in 1 2 3 4 5 6
do
  echo "--- tenant-redis-001 istek $i ---"
  curl -s -o /tmp/pix2pi_redis_tenant_body_$i.txt -w "%{http_code}" \
    -H "X-Tenant-ID: tenant-redis-001" "$URL" > /tmp/pix2pi_redis_tenant_code_$i.txt

  CODE=$(cat /tmp/pix2pi_redis_tenant_code_$i.txt)
  BODY=$(cat /tmp/pix2pi_redis_tenant_body_$i.txt)

  echo "HTTP CODE: $CODE"
  echo "BODY: $BODY"
  echo
done

echo "=== TEST 4 farkli tenant ayri limit ==="
curl -s -i -H "X-Tenant-ID: tenant-redis-002" "$URL"
echo
echo

echo "=== TEST 5 redis key kontrolu ==="
redis-cli GET tenant:tenant-redis-001:gateway:rate_limit || true
echo
redis-cli TTL tenant:tenant-redis-001:gateway:rate_limit || true
echo
redis-cli GET tenant:tenant-redis-002:gateway:rate_limit || true
echo
redis-cli TTL tenant:tenant-redis-002:gateway:rate_limit || true
echo

echo "OK ✅ redis tenant rate limit test bitti"
