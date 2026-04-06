#!/bin/bash
set -euo pipefail

echo "=== STEP 390 / REWRITE EARLY WARNING CLEAN ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo
echo "1. backup aliniyor..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. script bastan yaziliyor..."

cat <<'EOS' > "$SCRIPT"
#!/bin/bash
set -euo pipefail

STATUS_JSON="http://127.0.0.1:8090/status"
OUT_JSON="/opt/pix2pi/runtime/early_warning.json"
LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/early_warning.log"
SERVICE_MAP="/opt/pix2pi/runtime/service_map.json"

mkdir -p /opt/pix2pi/runtime
mkdir -p /opt/pix2pi/runtime/auto_heal/logs
mkdir -p /opt/pix2pi/runtime/auto_heal/fail_counts
mkdir -p /opt/pix2pi/runtime/auto_heal/scale
touch "$LOG_FILE"

log() {
  echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

collect_json_status() {
  curl -fsS "$STATUS_JSON" 2>/dev/null || echo '{}'
}

collect_systemd_status() {
  if [ ! -f "$SERVICE_MAP" ]; then
    echo ""
    return 0
  fi

  jq -r '
    to_entries[]
    | select(.value.type=="systemd")
    | "\(.key)|\(.value.name)"
  ' "$SERVICE_MAP" 2>/dev/null | while IFS='|' read -r logical_name unit_name; do
    if [ -n "$unit_name" ] && ! systemctl is-active --quiet "$unit_name"; then
      echo "$logical_name"
    fi
  done
}

AUTO_HEAL_TARGETS() {
  if [ ! -f "$SERVICE_MAP" ]; then
    return 0
  fi

  jq -r '
    to_entries[]
    | select(.value.type=="systemd")
    | "\(.key)|\(.value.name)"
  ' "$SERVICE_MAP" 2>/dev/null
}

try_restart_service() {
  local logical_name="$1"
  local unit_name="$2"
  local count_file="/opt/pix2pi/runtime/auto_heal/fail_counts/${logical_name}.count"
  local fail_count="0"

  if [ -f "$count_file" ]; then
    fail_count="$(cat "$count_file" 2>/dev/null || echo 0)"
  fi

  log "svc=${logical_name} action=restart_try unit=${unit_name}"

  if systemctl restart "$unit_name" 2>/dev/null; then
    echo "0" > "$count_file"
    log "svc=${logical_name} action=restart_ok unit=${unit_name}"
    return 0
  fi

  fail_count=$((fail_count + 1))
  echo "$fail_count" > "$count_file"
  log "svc=${logical_name} action=restart_fail unit=${unit_name} fail_count=${fail_count}"
  return 1
}

main() {
  local raw
  local running=0
  local stopped=0
  local degraded=0
  local planned=0
  local severity="ok"
  local global_status="UNKNOWN"
  local stopped_names=""
  local degraded_names=""
  local final_stopped=""

  raw="$(collect_json_status)"

  running="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="RUNNING")) | length' 2>/dev/null || echo 0)"
  stopped="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="STOPPED")) | length' 2>/dev/null || echo 0)"
  degraded="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="DEGRADED")) | length' 2>/dev/null || echo 0)"
  planned="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="PLANNED")) | length' 2>/dev/null || echo 0)"
  global_status="$(echo "$raw" | jq -r '.global_status // "UNKNOWN"' 2>/dev/null || echo "UNKNOWN")"

  stopped_names="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="STOPPED") | .name) | join(", ")' 2>/dev/null || echo "")"
  degraded_names="$(echo "$raw" | jq -r '.services // [] | map(select(.status=="DEGRADED") | .name) | join(", ")' 2>/dev/null || echo "")"

  final_stopped="$(collect_systemd_status | paste -sd', ' -)"
  if [ -n "$final_stopped" ]; then
    stopped_names="$final_stopped"
    severity="critical"
  else
    if [ "$degraded" -gt 0 ]; then
      severity="warning"
    elif [ "$stopped" -gt 0 ]; then
      severity="critical"
    else
      severity="ok"
    fi
  fi

  cat <<JSON > "$OUT_JSON"
{
  "updated_at": "$(date --iso-8601=seconds)",
  "global_status": "${global_status}",
  "severity": "${severity}",
  "counts": {
    "running": ${running},
    "stopped": ${stopped},
    "degraded": ${degraded},
    "planned": ${planned}
  },
  "stopped_names": "$(printf '%s' "$stopped_names" | sed 's/"/\\"/g')",
  "degraded_names": "$(printf '%s' "$degraded_names" | sed 's/"/\\"/g')"
}
JSON

  log "severity=${severity} global_status=${global_status} running=${running} stopped=${stopped} degraded=${degraded} planned=${planned} stopped_names=${stopped_names} degraded_names=${degraded_names}"

  if [ "$severity" = "critical" ]; then
    AUTO_HEAL_TARGETS | while IFS='|' read -r logical_name unit_name; do
      [ -z "$logical_name" ] && continue
      [ -z "$unit_name" ] && continue

      if printf '%s\n' "$stopped_names" | grep -qw "$logical_name"; then
        try_restart_service "$logical_name" "$unit_name" || true
      fi
    done
  fi
}

main
EOS

chmod +x "$SCRIPT"
echo "OK ✅ script yazildi"

echo
echo "3. syntax test..."
bash -n "$SCRIPT"
echo "OK ✅ syntax gecti"

echo
echo "4. calistirma testi..."
"$SCRIPT"
echo "OK ✅ script calisti"

echo
echo "5. json kontrol..."
cat /opt/pix2pi/runtime/early_warning.json | jq .
echo "OK ✅ json hazir"

echo
echo "=== STEP 390 TAMAM ✅ ==="
