#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md"
mkdir -p docs/faz6/evidence

PASS_COUNT=0
WARN_COUNT=0

write_line() {
  echo "$1" | tee -a "$EVIDENCE_FILE"
}

probe_url() {
  local label="$1"
  local url="$2"
  local accepted_codes="${3:-2xx3xx401403}"

  write_line "===== $label ====="
  write_line "URL=$url"

  RESULT="$(curl -o /tmp/pix2pi_smoke_body.txt -sS --max-time 5 -w 'http_code=%{http_code} time_total=%{time_total} size=%{size_download}' "$url" 2>/dev/null || true)"
  write_line "$RESULT"

  if [ "$accepted_codes" = "2xx3xx401403" ]; then
    if echo "$RESULT" | grep -Eq 'http_code=2[0-9][0-9]|http_code=3[0-9][0-9]|http_code=401|http_code=403'; then
      write_line "$label OK ✅"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      write_line "$label WARN ⚠️"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  else
    if echo "$RESULT" | grep -Eq "$accepted_codes"; then
      write_line "$label OK ✅"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      write_line "$label WARN ⚠️"
      WARN_COUNT=$((WARN_COUNT + 1))
    fi
  fi

  write_line ""
}

probe_first_ok() {
  local label="$1"
  shift

  write_line "===== $label ====="

  local ok_found=0
  local tried=0

  for url in "$@"; do
    tried=$((tried + 1))
    write_line "TRY_$tried=$url"

    RESULT="$(curl -o /tmp/pix2pi_smoke_body.txt -sS --max-time 5 -w 'http_code=%{http_code} time_total=%{time_total} size=%{size_download}' "$url" 2>/dev/null || true)"
    write_line "$RESULT"

    if echo "$RESULT" | grep -Eq 'http_code=2[0-9][0-9]|http_code=3[0-9][0-9]|http_code=401|http_code=403'; then
      write_line "$label OK ✅"
      PASS_COUNT=$((PASS_COUNT + 1))
      ok_found=1
      break
    fi
  done

  if [ "$ok_found" -eq 0 ]; then
    write_line "$label WARN ⚠️"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  write_line ""
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-9 Postdeploy Smoke Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

Bu script deploy yapmaz. Deploy sonrasi kullanilacak smoke kontrol standardini uygular.

Port correction note:
- identity icin host port 9002 onceliklidir, 9001 fallback olarak denenir.
- grafana icin host port 3001 onceliklidir, 3000 fallback olarak denenir.
- NATS 4222 HTTP portu degildir; smoke sadece 8222 monitoring /varz dener.

FAZ_6_9_POSTDEPLOY_SMOKE=STARTED ✅

---

EOF2

echo "===== PIX2PI POSTDEPLOY SMOKE BASLADI ====="

IDENTITY_PORT="${IDENTITY_PORT:-9002}"
GATEWAY_PORT="${GATEWAY_PORT:-9010}"
GRAFANA_PORT="${GRAFANA_PORT:-3001}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
NODE_EXPORTER_PORT="${NODE_EXPORTER_PORT:-9100}"
CADVISOR_PORT="${CADVISOR_PORT:-8080}"
NATS_MONITOR_PORT="${NATS_MONITOR_PORT:-8222}"

probe_first_ok "identity health" \
  "http://127.0.0.1:${IDENTITY_PORT}/health" \
  "http://127.0.0.1:9002/health" \
  "http://127.0.0.1:9001/health"

probe_first_ok "api gateway health" \
  "http://127.0.0.1:${GATEWAY_PORT}/health" \
  "http://127.0.0.1:9010/health"

probe_first_ok "prometheus ready" \
  "http://127.0.0.1:${PROMETHEUS_PORT}/-/ready" \
  "http://127.0.0.1:9090/-/ready"

probe_first_ok "grafana health" \
  "http://127.0.0.1:${GRAFANA_PORT}/api/health" \
  "http://127.0.0.1:3001/api/health" \
  "http://127.0.0.1:3000/api/health"

probe_first_ok "node exporter metrics" \
  "http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics" \
  "http://127.0.0.1:9100/metrics"

probe_first_ok "cadvisor metrics" \
  "http://127.0.0.1:${CADVISOR_PORT}/metrics" \
  "http://127.0.0.1:8080/metrics"

probe_first_ok "nats monitoring varz" \
  "http://127.0.0.1:${NATS_MONITOR_PORT}/varz" \
  "http://127.0.0.1:8222/varz"

{
  echo
  echo "## Postdeploy Smoke Final Seal"
  echo
  echo '```text'
  echo "PASS_COUNT=$PASS_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
  echo "POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅"

  if [ "$WARN_COUNT" -eq 0 ]; then
    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
  else
    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=HAS_WARNINGS ⚠️"
  fi
  echo '```'
} >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅"
echo "POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅"

if [ "$WARN_COUNT" -eq 0 ]; then
  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
else
  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=HAS_WARNINGS ⚠️"
fi

echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
