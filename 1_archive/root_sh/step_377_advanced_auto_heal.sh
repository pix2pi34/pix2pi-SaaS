#!/bin/bash
set -euo pipefail

echo "=== STEP 377 / ADVANCED AUTO HEAL ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"
BACKUP_DIR="/opt/pix2pi/runtime/auto_heal/backups"
mkdir -p "$BACKUP_DIR"

echo
echo "1. backup aliniyor..."
if [ -f "$SCRIPT" ]; then
  cp "$SCRIPT" "$BACKUP_DIR/pix2pi_auto_heal.sh.bak_$(date +%Y%m%d_%H%M%S)"
fi
echo "OK ✅ backup"

echo
echo "2. script yeniden yaziliyor..."

cat <<'EOS' > "$SCRIPT"
#!/bin/bash
set -euo pipefail

ALERT_JSON="/opt/pix2pi/runtime/watchdog_alerts.json"
BASE="/opt/pix2pi/runtime/auto_heal"
LOCK_DIR="$BASE/lock"
FAIL_DIR="$BASE/fail_counts"
ALERT_DIR="$BASE/alerts"
SCALE_DIR="$BASE/scale"
LOG_FILE="$BASE/logs/auto_heal.log"

MAX_RESTART_TRIES=3
COOLDOWN_SECONDS=180

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

epoch_now() {
  date +%s
}

log() {
  echo "[$(timestamp)] $1" >> "$LOG_FILE"
}

acquire_lock() {
  if mkdir "$LOCK_DIR/worker.lock" 2>/dev/null; then
    echo $$ > "$LOCK_DIR/worker.lock/pid"
    return 0
  fi
  return 1
}

release_lock() {
  rm -rf "$LOCK_DIR/worker.lock" 2>/dev/null || true
}

cleanup() {
  release_lock
}
trap cleanup EXIT

read_fail_count() {
  local svc="$1"
  local f="$FAIL_DIR/${svc}.count"
  if [ -f "$f" ]; then
    cat "$f"
  else
    echo 0
  fi
}

write_fail_count() {
  local svc="$1"
  local val="$2"
  echo "$val" > "$FAIL_DIR/${svc}.count"
}

reset_fail_count() {
  local svc="$1"
  echo 0 > "$FAIL_DIR/${svc}.count"
}

cooldown_file() {
  local svc="$1"
  echo "$FAIL_DIR/${svc}.cooldown_until"
}

is_in_cooldown() {
  local svc="$1"
  local f
  f="$(cooldown_file "$svc")"
  local now
  now="$(epoch_now)"

  if [ ! -f "$f" ]; then
    return 1
  fi

  local until_ts
  until_ts="$(cat "$f" 2>/dev/null || echo 0)"

  if [ "$until_ts" -gt "$now" ]; then
    return 0
  fi

  rm -f "$f"
  return 1
}

set_cooldown() {
  local svc="$1"
  local now
  now="$(epoch_now)"
  echo $((now + COOLDOWN_SECONDS)) > "$(cooldown_file "$svc")"
}

append_alert_event() {
  local kind="$1"
  local svc="$2"
  local detail="$3"
  printf '[%s] kind=%s service=%s detail=%s\n' "$(timestamp)" "$kind" "$svc" "$detail" >> "$BASE/logs/alert_engine.log"
}

write_scale_trigger() {
  local svc="$1"
  cat <<JSON > "$SCALE_DIR/${svc}.json"
{
  "service": "$svc",
  "reason": "auto_heal_failed_repeatedly",
  "created_at": "$(date --iso-8601=seconds)"
}
JSON
}

restart_auth() {
  if systemctl restart pix2pi-auth; then
    return 0
  fi
  return 1
}

handle_service() {
  local svc="$1"

  case "$svc" in
    auth)
      if is_in_cooldown "$svc"; then
        log "svc=$svc skip reason=cooldown"
        append_alert_event "cooldown" "$svc" "restart skipped due to cooldown"
        return 0
      fi

      log "svc=$svc action=restart_try"
      if restart_auth; then
        log "svc=$svc action=restart_ok"
        reset_fail_count "$svc"
        append_alert_event "auto_heal_ok" "$svc" "service restart success"
        return 0
      fi

      local count
      count="$(read_fail_count "$svc")"
      count=$((count + 1))
      write_fail_count "$svc" "$count"

      log "svc=$svc action=restart_fail fail_count=$count"
      append_alert_event "auto_heal_fail" "$svc" "restart failed count=$count"

      if [ "$count" -ge "$MAX_RESTART_TRIES" ]; then
        set_cooldown "$svc"
        append_alert_event "escalate" "$svc" "max restart exceeded, cooldown applied"
        write_scale_trigger "$svc"
        log "svc=$svc action=escalate cooldown=${COOLDOWN_SECONDS}s scale_trigger=1"
      fi
      ;;
    *)
      log "svc=$svc action=skip reason=policy"
      ;;
  esac
}

main() {
  mkdir -p "$LOCK_DIR" "$FAIL_DIR" "$ALERT_DIR" "$SCALE_DIR" "$BASE/logs"

  if ! acquire_lock; then
    log "worker_locked skip"
    exit 0
  fi

  if [ ! -f "$ALERT_JSON" ]; then
    log "alert_json_missing"
    exit 0
  fi

  local severity stopped
  severity="$(jq -r '.severity // "unknown"' "$ALERT_JSON")"
  stopped="$(jq -r '.stopped_names // ""' "$ALERT_JSON")"

  log "run_start severity=$severity stopped=$stopped"

  if [ "$severity" != "critical" ]; then
    log "skip reason=not_critical"
    exit 0
  fi

  if [ -z "$stopped" ]; then
    log "skip reason=no_stopped_services"
    exit 0
  fi

  IFS=',' read -ra ITEMS <<< "$stopped"
  for raw in "${ITEMS[@]}"; do
    svc="$(echo "$raw" | xargs)"
    [ -z "$svc" ] && continue
    handle_service "$svc"
  done

  log "run_end"
}

main "$@"
EOS

chmod 700 "$SCRIPT"
echo "OK ✅ script yazildi"

echo
echo "3. test calistiriliyor..."
"$SCRIPT"
echo "OK ✅ test calisti"

echo
echo "4. log kontrol..."
tail -n 20 /opt/pix2pi/runtime/auto_heal/logs/auto_heal.log || true

echo
echo "5. fail counter kontrol..."
find /opt/pix2pi/runtime/auto_heal/fail_counts -maxdepth 1 -type f | sort || true

echo
echo "=== STEP 377 TAMAM ✅ ==="
