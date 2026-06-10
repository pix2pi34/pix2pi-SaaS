#!/bin/bash
set -e

URL="https://api.pix2pi.com.tr/api/identity/health"

echo "Rate limit testi basliyor..."
echo "URL: $URL"
echo

for i in 1 2 3 4 5 6
do
  echo "=== istek $i ==="
  curl -s -o /tmp/pix2pi_rl_body_$i.txt -w "%{http_code}" "$URL" > /tmp/pix2pi_rl_code_$i.txt

  CODE=$(cat /tmp/pix2pi_rl_code_$i.txt)
  BODY=$(cat /tmp/pix2pi_rl_body_$i.txt)

  echo "HTTP CODE: $CODE"
  echo "BODY: $BODY"
  echo
done

echo "OK ✅ api gateway rate limit test bitti"
