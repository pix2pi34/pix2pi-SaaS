#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${SERVICE_NAME:-pix2pi-api-gateway.service}"
BASE_URL="${BASE_URL:-http://127.0.0.1:9010}"

echo "===== STEP 53B / QUERY POST RESTART CHECK ====="

echo
echo "===== 1) SERVICE RESTART ====="
systemctl restart "$SERVICE_NAME"
sleep 3
echo "OK ✅ service restart atildi"

echo
echo "===== 2) SERVICE STATUS ====="
systemctl --no-pager --full status "$SERVICE_NAME" | head -n 20
ACTIVE_STATE="$(systemctl is-active "$SERVICE_NAME")"
if [ "$ACTIVE_STATE" != "active" ]; then
  echo "HATA ❌ service active degil: $ACTIVE_STATE"
  exit 1
fi
echo "OK ✅ service active"

echo
echo "===== 3) COUNT ====="
COUNT_JSON="$(curl -fsS "$BASE_URL/api/query/users")"
echo "$COUNT_JSON"

USER_COUNT="$(echo "$COUNT_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
assert isinstance(d.get("user_count"), int), d
print(d["user_count"])
')"
echo "OK ✅ count ok -> user_count=$USER_COUNT"

echo
echo "===== 4) LIST ====="
LIST_JSON="$(curl -fsS "$BASE_URL/api/query/users/list?limit=3")"
echo "$LIST_JSON"

FIRST_USER_ID="$(echo "$LIST_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
users = d.get("users") or []
assert isinstance(users, list), d
assert len(users) >= 1, d
print(users[0]["user_id"])
')"

FIRST_USERNAME="$(echo "$LIST_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
users = d.get("users") or []
print(users[0]["username"])
')"

echo "OK ✅ list ok -> first_user_id=$FIRST_USER_ID"

echo
echo "===== 5) DETAIL ====="
DETAIL_JSON="$(curl -fsS "$BASE_URL/api/query/users/$FIRST_USER_ID")"
echo "$DETAIL_JSON"

echo "$DETAIL_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
u = d.get("user") or {}
assert u.get("user_id"), d
assert u.get("username"), d
'
echo "OK ✅ detail ok"

PREFIX="$(printf '%s' "$FIRST_USERNAME" | cut -c1-3 || true)"

if [ -n "${PREFIX:-}" ]; then
  echo
  echo "===== 6) FILTER ====="
  FILTER_JSON="$(curl -fsS "$BASE_URL/api/query/users/list?limit=10&username=$PREFIX")"
  echo "$FILTER_JSON"

  echo "$FILTER_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
assert isinstance(d.get("users"), list), d
'
  echo "OK ✅ filter ok -> prefix=$PREFIX"
fi

echo
echo "===== 7) LAST 20 GATEWAY LOG ====="
journalctl -u "$SERVICE_NAME" -n 20 --no-pager

echo
echo "OK ✅ step_53b query post restart check gecti"
