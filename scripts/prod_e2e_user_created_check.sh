#!/usr/bin/env bash
set -euo pipefail

IDENTITY_URL="http://127.0.0.1:9012/register"
COUNT_URL="http://127.0.0.1:9010/api/query/users"
LIST_URL="http://127.0.0.1:9010/api/query/users/list?limit=5"
API_SERVICE="pix2pi-api-gateway.service"
CONSUMER_SERVICE="pix2pi-user-created-consumer.service"

extract_user_count() {
  printf '%s' "$1" | grep -o '"user_count":[0-9]*' | head -n1 | cut -d: -f2
}

extract_user_id() {
  printf '%s' "$1" | grep -o '"id":"[^"]*"' | head -n1 | cut -d'"' -f4
}

echo "===== PROD E2E USER_CREATED CHECK ====="

systemctl is-active --quiet "$API_SERVICE"
echo "OK ✅ api gateway active"

systemctl is-active --quiet "$CONSUMER_SERVICE"
echo "OK ✅ user-created-consumer active"

pre_json="$(curl -fsS "$COUNT_URL")"
pre_count="$(extract_user_count "$pre_json")"

if [ -z "${pre_count:-}" ]; then
  echo "HATA ❌ pre_count parse edilemedi"
  exit 1
fi

echo "OK ✅ pre_count=$pre_count"

USERNAME="ops_$(date +%s)"
register_json="$(curl -fsS -X POST "$IDENTITY_URL" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\"}")"

user_id="$(extract_user_id "$register_json")"

if [ -z "${user_id:-}" ]; then
  echo "HATA ❌ register user_id parse edilemedi"
  exit 1
fi

echo "OK ✅ register username=$USERNAME"
echo "OK ✅ register user_id=$user_id"

expected_count=$((pre_count + 1))
post_json=""
post_count=""

for i in $(seq 1 20); do
  post_json="$(curl -fsS "$COUNT_URL" || true)"
  post_count="$(extract_user_count "$post_json" || true)"

  if [ -n "${post_count:-}" ] && [ "$post_count" = "$expected_count" ]; then
    break
  fi

  sleep 1
done

if [ -z "${post_count:-}" ]; then
  echo "HATA ❌ post_count parse edilemedi"
  exit 1
fi

if [ "$post_count" != "$expected_count" ]; then
  echo "HATA ❌ beklenen=$expected_count gelen=$post_count"
  exit 1
fi

echo "OK ✅ post_count=$post_count"

detail_json="$(curl -fsS "http://127.0.0.1:9010/api/query/users/$user_id")"
printf '%s' "$detail_json" | grep -q "\"user_id\":\"$user_id\""
printf '%s' "$detail_json" | grep -q "\"username\":\"$USERNAME\""
echo "OK ✅ detail dogrulandi"

list_json="$(curl -fsS "$LIST_URL")"
printf '%s' "$list_json" | grep -q "\"user_id\":\"$user_id\""
printf '%s' "$list_json" | grep -q "\"username\":\"$USERNAME\""
echo "OK ✅ list dogrulandi"

filter_json="$(curl -fsS "http://127.0.0.1:9010/api/query/users/list?limit=10&username=$USERNAME")"
printf '%s' "$filter_json" | grep -q "\"user_id\":\"$user_id\""
printf '%s' "$filter_json" | grep -q "\"username\":\"$USERNAME\""
echo "OK ✅ filter dogrulandi"

echo
echo "===== OZET ====="
echo "$pre_json"
echo "$post_json"
echo "$detail_json"
echo "$filter_json"

echo
echo "OK ✅ prod_e2e_user_created_check gecti"
