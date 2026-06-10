#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$HOME/pix2pi/pix2pi-SaaS}"
BASE_URL="${BASE_URL:-http://127.0.0.1:9010}"
SERVICE_NAME="${SERVICE_NAME:-pix2pi-api-gateway.service}"
LIST_LIMIT="${LIST_LIMIT:-3}"
FILTER_USERNAME="${FILTER_USERNAME:-ste}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "HATA ❌ $1"
  exit 1
}

echo "===== STEP 54B / QUERY DEPLOY VERIFY ====="

echo
echo "===== 1) SERVICE ACTIVE ====="
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
  systemctl --no-pager --full status "$SERVICE_NAME" | head -n 20 || true
  fail "service active degil: $SERVICE_NAME"
fi
systemctl --no-pager --full status "$SERVICE_NAME" | head -n 12 || true
echo "OK ✅ service active"

echo
echo "===== 2) COUNT ====="
COUNT_JSON="$(curl -fsS "$BASE_URL/api/query/users")" || fail "count endpoint fail"
printf '%s' "$COUNT_JSON" | tee "$TMP_DIR/count.json"
echo
python3 - "$TMP_DIR/count.json" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
if data.get("status") != "ok":
    raise SystemExit("count status ok degil")
uc = data.get("user_count")
if not isinstance(uc, int):
    raise SystemExit("user_count int degil")
print(f"OK ✅ count ok -> user_count={uc}")
PY

echo
echo "===== 3) LIST ====="
LIST_JSON="$(curl -fsS "$BASE_URL/api/query/users/list?limit=${LIST_LIMIT}")" || fail "list endpoint fail"
printf '%s' "$LIST_JSON" | tee "$TMP_DIR/list.json"
echo
FIRST_USER_ID="$(
python3 - "$TMP_DIR/list.json" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

if data.get("status") != "ok":
    raise SystemExit("list status ok degil")

users = data.get("users")
if not isinstance(users, list):
    raise SystemExit("users list degil")

if len(users) == 0:
    raise SystemExit("users bos geldi")

first = users[0]
uid = first.get("user_id")
if not uid:
    raise SystemExit("ilk user_id bos")

print(uid)
PY
)"
echo "OK ✅ list ok -> first_user_id=$FIRST_USER_ID"

echo
echo "===== 4) DETAIL ====="
DETAIL_JSON="$(curl -fsS "$BASE_URL/api/query/users/${FIRST_USER_ID}")" || fail "detail endpoint fail"
printf '%s' "$DETAIL_JSON" | tee "$TMP_DIR/detail.json"
echo
python3 - "$TMP_DIR/detail.json" "$FIRST_USER_ID" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

if data.get("status") != "ok":
    raise SystemExit("detail status ok degil")

user = data.get("user")
if not isinstance(user, dict):
    raise SystemExit("detail user objesi yok")

uid = user.get("user_id")
if uid != sys.argv[2]:
    raise SystemExit(f"detail user_id uyusmuyor: {uid} != {sys.argv[2]}")

print(f"OK ✅ detail ok -> user_id={uid}")
PY

echo
echo "===== 5) FILTER ====="
FILTER_JSON="$(curl -fsS --get --data-urlencode "username=${FILTER_USERNAME}" "$BASE_URL/api/query/users/list?limit=10")" || fail "filter endpoint fail"
printf '%s' "$FILTER_JSON" | tee "$TMP_DIR/filter.json"
echo
python3 - "$TMP_DIR/filter.json" "$FILTER_USERNAME" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

if data.get("status") != "ok":
    raise SystemExit("filter status ok degil")

users = data.get("users")
if not isinstance(users, list):
    raise SystemExit("filter users list degil")

prefix = sys.argv[2].lower()
for u in users:
    username = str(u.get("username", "")).lower()
    if not username.startswith(prefix):
        raise SystemExit(f"filter sonucu prefix bozuyor: {username}")

print(f"OK ✅ filter ok -> prefix={sys.argv[2]}")
PY

echo
echo "===== 6) LAST 20 GATEWAY LOG ====="
journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true

echo
echo "OK ✅ step_54b deploy verify gecti"
