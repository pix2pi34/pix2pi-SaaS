#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
POS_DOMAIN="${POS_DOMAIN:-pos.pix2pi.com.tr}"
POS_WEB_ROOT="${POS_WEB_ROOT:-/var/www/pix2pi/pos}"
ACTIVE_NGINX_ROUTE="/etc/nginx/conf.d/00_pix2pi_pos.conf"

cd "$REPO"

test -f "docs/faz7r/FAZ_7R_333_OFFLINE_READY_POS_HAZIRLIGI.md"
test -f "configs/faz7r/faz_7r_333_offline_ready_pos_hazirligi.v1.json"
test -f "web/pos/assets/offline/pos-offline-runtime.js"
test -f "web/pos/offline/index.html"
test -f "tests/faz7r/faz_7r_333_offline_ready_pos_hazirligi_smoke_test.json"

test -f "$POS_WEB_ROOT/assets/offline/pos-offline-runtime.js"
test -f "$POS_WEB_ROOT/offline/index.html"
test -f "$ACTIVE_NGINX_ROUTE"

python3 -m json.tool "configs/faz7r/faz_7r_333_offline_ready_pos_hazirligi.v1.json" >/dev/null
python3 -m json.tool "tests/faz7r/faz_7r_333_offline_ready_pos_hazirligi_smoke_test.json" >/dev/null

grep -Fq "server_name ${POS_DOMAIN};" "$ACTIVE_NGINX_ROUTE"
grep -Fq "root ${POS_WEB_ROOT};" "$ACTIVE_NGINX_ROUTE"

grep -Fq "PIX2PI_333_POS_OFFLINE_RUNTIME_START" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "tenantDeviceCashierHeaders" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "getNetworkStatus" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "generateIdempotencyKey" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "loadOfflineQueue" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "saveOfflineQueue" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "buildOfflineSaleDraft" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "enqueueOfflineSaleDraft" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "buildSyncPayload" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "validateOfflineQueue" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "evaluateConflictPreview" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "clearOfflineQueue" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "syncOfflineQueueDryRun" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "realOfflineReplayEnabled: false" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "readyForStep334: true" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "X-Tenant-ID" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "X-POS-Device-ID" "web/pos/assets/offline/pos-offline-runtime.js"
grep -Fq "X-POS-Cashier-Code" "web/pos/assets/offline/pos-offline-runtime.js"

grep -Fq "PIX2PI_333_OFFLINE_READY_POS_APP_SHELL_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_NETWORK_STATUS_INDICATOR_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_LOCAL_QUEUE_STORAGE_CONTRACT_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_OFFLINE_SALE_DRAFT_QUEUE_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_IDEMPOTENCY_KEY_GENERATION_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_SYNC_REPLAY_POLICY_PLACEHOLDER_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_CONFLICT_RESOLUTION_PREVIEW_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_QUEUE_RETENTION_CLEAR_GUARD_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_TENANT_DEVICE_CASHIER_OFFLINE_GUARD_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_SERVICE_WORKER_PWA_HANDOFF_PLACEHOLDER_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_OFFLINE_RUNTIME_HEALTH_CONTRACT_START" "web/pos/offline/index.html"
grep -Fq "PIX2PI_333_I18N_READY_MARKERS_START" "web/pos/offline/index.html"

cmp -s "web/pos/offline/index.html" "$POS_WEB_ROOT/offline/index.html"
cmp -s "web/pos/assets/offline/pos-offline-runtime.js" "$POS_WEB_ROOT/assets/offline/pos-offline-runtime.js"

nginx -t >/dev/null 2>&1
nginx -T 2>/dev/null | grep -Fq "server_name ${POS_DOMAIN};"

check_http_200_contains() {
  local path="$1"
  local marker="$2"
  local body_file
  body_file="$(mktemp)"
  local status

  status="$(curl --noproxy '*' --resolve "${POS_DOMAIN}:80:127.0.0.1" -sS -o "$body_file" -w "%{http_code}" "http://${POS_DOMAIN}${path}")"

  test "$status" = "200"
  grep -Fq "$marker" "$body_file"
  rm -f "$body_file"
}

check_http_200_contains "/offline/" "PIX2PI_333_OFFLINE_READY_POS_APP_SHELL_START"
check_http_200_contains "/assets/offline/pos-offline-runtime.js" "PIX2PI_333_POS_OFFLINE_RUNTIME_START"
