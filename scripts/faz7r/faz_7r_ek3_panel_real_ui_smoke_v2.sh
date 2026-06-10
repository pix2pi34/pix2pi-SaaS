#!/usr/bin/env bash
set +e
set -o pipefail

echo "===== FAZ 7-R / EK3 PANEL REAL UI SMOKE V2 START ====="

PASS_COUNT=0
FAIL_COUNT=0
ok(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }

BODY="/tmp/faz7r_ek3_panel_real_ui_body_v2.html"
HEADERS="/tmp/faz7r_ek3_panel_real_ui_headers_v2.txt"
HEALTH="/tmp/faz7r_ek3_panel_real_ui_health_v2.json"

CODE="$(curl -sS --max-time 12 -D "$HEADERS" -o "$BODY" -w "%{http_code}" -H "Host: panel.pix2pi.com.tr" "http://127.0.0.1/panel-real-ui/" 2>/tmp/faz7r_ek3_panel_v2.err)"
[ "$CODE" = "200" ] && ok "panel HTTP 200" || fail "panel HTTP code: $CODE"

HC="$(curl -sS --max-time 12 -o "$HEALTH" -w "%{http_code}" -H "Host: panel.pix2pi.com.tr" "http://127.0.0.1/panel-real-ui/health.json" 2>/tmp/faz7r_ek3_health_v2.err)"
[ "$HC" = "200" ] && ok "health HTTP 200" || fail "health HTTP code: $HC"

for marker in \
  "FAZ_7R_EK3_PANEL_REAL_UI_MARKER" \
  "PIX2PI_REAL_PANEL_REACT_APP" \
  "PANEL_ROUTE_BOUND_MARKER" \
  "I18N_TR_MARKER" \
  "I18N_OTA_ARAB_MARKER" \
  "HUSREV_EKALEM_RTL_MARKER" \
  "lang=\"ota-Arab\"" \
  "dir=\"rtl\""
do
  grep -Fq "$marker" "$BODY" && ok "body marker $marker" || fail "body marker eksik $marker"
done

grep -Fq "FAZ_7R_EK3_PANEL_REAL_UI_MARKER" "$HEADERS" && ok "header panel marker" || fail "header panel marker eksik"
grep -Fq "HUSREV_EKALEM_RTL_MARKER" "$HEADERS" && ok "header RTL marker" || fail "header RTL marker eksik"
grep -Fq "FAZ_7R_EK3_PANEL_REAL_UI_MARKER" "$HEALTH" && ok "health marker" || fail "health marker eksik"

echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_7R_EK3_PANEL_REAL_UI_SMOKE_V2_STATUS=PASS"
  exit 0
fi

echo "FAZ_7R_EK3_PANEL_REAL_UI_SMOKE_V2_STATUS=FAIL"
exit 1
