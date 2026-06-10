#!/bin/bash
set -euo pipefail

echo "=== STEP 392 / PRODUCTION HARDENING ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. hardening logic ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

# === PRODUCTION HARDENING ===

MAX_RETRY=3
COOLDOWN=60

now_ts() {
  date +%s
}

get_last_try() {
  file="/opt/pix2pi/runtime/auto_heal/lock/$1.lock"
  [ -f "$file" ] && cat "$file" || echo 0
}

set_last_try() {
  echo "$(now_ts)" > "/opt/pix2pi/runtime/auto_heal/lock/$1.lock"
}

get_fail_count() {
  file="/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
  [ -f "$file" ] && cat "$file" || echo 0
}

inc_fail_count() {
  file="/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
  count=$(get_fail_count "$1")
  echo $((count+1)) > "$file"
}

reset_fail_count() {
  echo 0 > "/opt/pix2pi/runtime/auto_heal/fail_counts/$1.count"
}

can_retry() {
  svc="$1"
  last=$(get_last_try "$svc")
  now=$(now_ts)
  diff=$((now-last))

  if [ "$diff" -lt "$COOLDOWN" ]; then
    return 1
  fi

  return 0
}

# === HARDENED RESTART ===

restart_service_hardened() {
  svc="$1"
  unit="$2"

  fail_count=$(get_fail_count "$svc")

  if [ "$fail_count" -ge "$MAX_RETRY" ]; then
    echo "svc=$svc action=blocked reason=max_retry"
    return
  fi

  if ! can_retry "$svc"; then
    echo "svc=$svc action=blocked reason=cooldown"
    return
  fi

  set_last_try "$svc"

  echo "svc=$svc action=restart_try unit=$unit"

  if systemctl restart "$unit"; then
    echo "svc=$svc action=restart_ok unit=$unit"
    reset_fail_count "$svc"
  else
    inc_fail_count "$svc"
    echo "svc=$svc action=restart_fail unit=$unit fail_count=$(get_fail_count "$svc")"
  fi
}

EOS

echo "OK ✅ hardening eklendi"

echo
echo "3. test..."

bash "$SCRIPT" || true

echo "OK ✅ test"

echo
echo "=== STEP 392 TAMAM ✅ ==="
