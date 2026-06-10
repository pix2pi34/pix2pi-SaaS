#!/bin/bash
set -e

echo "=== STEP 371 / EARLY WARNING COLLECTOR ==="

BASE_DIR="/opt/pix2pi/runtime"
BIN_DIR="/opt/pix2pi/bin"
SCRIPT_PATH="$BIN_DIR/pix2pi_early_warning.sh"
JSON_PATH="$BASE_DIR/watchdog_alerts.json"
LOG_PATH="$BASE_DIR/watchdog_alerts.log"

echo
echo "1. klasorler hazirlaniyor..."
mkdir -p "$BASE_DIR" "$BIN_DIR"
echo "OK ✅ klasorler hazir"

echo
echo "2. collector script yaziliyor..."
cat <<'EOS' > "$SCRIPT_PATH"
#!/bin/bash
set -euo pipefail

STATUS_URL="http://127.0.0.1:8090/status"
BASE_DIR="/opt/pix2pi/runtime"
JSON_PATH="$BASE_DIR/watchdog_alerts.json"
LOG_PATH="$BASE_DIR/watchdog_alerts.log"
TMP_JSON="$(mktemp)"

mkdir -p "$BASE_DIR"

RAW="$(curl -fsS "$STATUS_URL")"

echo "$RAW" > "$TMP_JSON"

UPDATED_AT="$(jq -r '.updated_at // ""' "$TMP_JSON")"
GLOBAL_STATUS="$(jq -r '.global_status // "UNKNOWN"' "$TMP_JSON")"

RUNNING_COUNT="$(jq '[.services[] | select(.status=="RUNNING")] | length' "$TMP_JSON")"
STOPPED_COUNT="$(jq '[.services[] | select(.status=="STOPPED")] | length' "$TMP_JSON")"
DEGRADED_COUNT="$(jq '[.services[] | select(.status=="DEGRADED")] | length' "$TMP_JSON")"
PLANNED_COUNT="$(jq '[.services[] | select(.status=="PLANNED")] | length' "$TMP_JSON")"

STOPPED_NAMES="$(jq -r '[.services[] | select(.status=="STOPPED") | .name] | join(", ")' "$TMP_JSON")"
DEGRADED_NAMES="$(jq -r '[.services[] | select(.status=="DEGRADED") | .name] | join(", ")' "$TMP_JSON")"

if [ "$GLOBAL_STATUS" = "CRITICAL" ] || [ "$STOPPED_COUNT" -gt 0 ]; then
  SEVERITY="critical"
elif [ "$GLOBAL_STATUS" = "DEGRADED" ] || [ "$DEGRADED_COUNT" -gt 0 ]; then
  SEVERITY="warning"
else
  SEVERITY="ok"
fi

jq -n \
  --arg updated_at "$UPDATED_AT" \
  --arg global_status "$GLOBAL_STATUS" \
  --arg severity "$SEVERITY" \
  --arg stopped_names "$STOPPED_NAMES" \
  --arg degraded_names "$DEGRADED_NAMES" \
  --argjson running_count "$RUNNING_COUNT" \
  --argjson stopped_count "$STOPPED_COUNT" \
  --argjson degraded_count "$DEGRADED_COUNT" \
  --argjson planned_count "$PLANNED_COUNT" \
  '{
    updated_at: $updated_at,
    global_status: $global_status,
    severity: $severity,
    counts: {
      running: $running_count,
      stopped: $stopped_count,
      degraded: $degraded_count,
      planned: $planned_count
    },
    stopped_names: $stopped_names,
    degraded_names: $degraded_names
  }' > "$JSON_PATH"

printf "[%s] severity=%s global_status=%s running=%s stopped=%s degraded=%s planned=%s stopped_names=%s degraded_names=%s\n" \
  "$(date '+%Y-%m-%d %H:%M:%S')" \
  "$SEVERITY" \
  "$GLOBAL_STATUS" \
  "$RUNNING_COUNT" \
  "$STOPPED_COUNT" \
  "$DEGRADED_COUNT" \
  "$PLANNED_COUNT" \
  "$STOPPED_NAMES" \
  "$DEGRADED_NAMES" >> "$LOG_PATH"

rm -f "$TMP_JSON"
echo "OK ✅ early warning guncellendi"
EOS

chmod +x "$SCRIPT_PATH"
echo "OK ✅ script yazildi: $SCRIPT_PATH"

echo
echo "3. ilk test calistiriliyor..."
"$SCRIPT_PATH"

echo
echo "4. json kontrol..."
cat "$JSON_PATH"
echo
echo "OK ✅ json kontrol bitti"

echo
echo "5. log kontrol..."
tail -n 3 "$LOG_PATH" || true
echo "OK ✅ log kontrol bitti"

echo
echo "=== STEP 371 TAMAM ✅ ==="
