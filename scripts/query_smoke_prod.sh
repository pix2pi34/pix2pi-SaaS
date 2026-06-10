#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:9010}"

echo "===== QUERY COUNT ====="
COUNT_JSON="$(curl -fsS "$BASE_URL/api/query/users")"
echo "$COUNT_JSON"

USER_COUNT="$(echo "$COUNT_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
assert isinstance(d.get("user_count"), int), d
print(d["user_count"])
')"

echo
echo "===== QUERY LIST ====="
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

echo
echo "===== QUERY DETAIL ====="
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

PREFIX="$(printf '%s' "$FIRST_USERNAME" | cut -c1-3 || true)"

if [ -n "${PREFIX:-}" ]; then
  echo
  echo "===== QUERY FILTER ====="
  FILTER_JSON="$(curl -fsS "$BASE_URL/api/query/users/list?limit=10&username=$PREFIX")"
  echo "$FILTER_JSON"

  echo "$FILTER_JSON" | python3 -c '
import sys, json
d = json.load(sys.stdin)
assert d.get("status") == "ok", d
assert isinstance(d.get("users"), list), d
'
fi

echo
echo "OK ✅ query_smoke_prod gecti"
echo "OK ✅ user_count=$USER_COUNT"
