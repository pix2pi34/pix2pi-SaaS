#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md"
mkdir -p docs/faz6/evidence

PASS_COUNT=0
WARN_COUNT=0

write_line() {
  echo "$1" | tee -a "$EVIDENCE_FILE"
}

probe_url() {
  local label="$1"
  local url="$2"

  write_line "===== OPS PROBE: $label ====="
  write_line "URL=$url"

  RESULT="$(curl -o /tmp/pix2pi_ops_probe_body.txt -sS --max-time 5 -w 'http_code=%{http_code} time_total=%{time_total} size=%{size_download}' "$url" 2>/tmp/pix2pi_ops_probe_err.txt || true)"
  write_line "$RESULT"

  if echo "$RESULT" | grep -Eq 'http_code=2[0-9][0-9]|http_code=3[0-9][0-9]|http_code=401|http_code=403'; then
    write_line "$label STATUS=OK ✅"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    write_line "$label STATUS=WARN ⚠️"
    WARN_COUNT=$((WARN_COUNT + 1))
    cat /tmp/pix2pi_ops_probe_err.txt 2>/dev/null | tee -a "$EVIDENCE_FILE" || true
  fi

  write_line ""
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-11 Ops Console Probe Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

Bu script servisleri restart etmez, config degistirmez, incident acmaz.
Sadece ops console icin health/dependency evidence uretir.

FAZ_6_11_OPS_CONSOLE_PROBE=STARTED ✅

---

EOF2

echo "===== PIX2PI OPS CONSOLE PROBE BASLADI ====="

probe_url "identity-api health" "http://127.0.0.1:9002/health"
probe_url "api-gateway health" "http://127.0.0.1:9010/health"
probe_url "prometheus ready" "http://127.0.0.1:9090/-/ready"
probe_url "grafana health" "http://127.0.0.1:3001/api/health"
probe_url "node_exporter metrics" "http://127.0.0.1:9100/metrics"
probe_url "cadvisor metrics" "http://127.0.0.1:8080/metrics"
probe_url "nats varz" "http://127.0.0.1:8222/varz"
probe_url "public root" "https://pix2pi.com.tr/"
probe_url "public pilot page" "https://pix2pi.com.tr/faz4d/pilot-go-live/"

{
  echo
  echo "## Docker Runtime Snapshot"
  echo
  echo '~~~text'
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null | head -n 80 || true
  echo '~~~'

  echo
  echo "## Systemd Runtime Snapshot"
  echo
  echo '~~~text'
  systemctl list-units --type=service --all 2>/dev/null | grep -Ei 'pix2pi|gateway|identity|mission|registry|event|nginx|docker' || true
  echo '~~~'

  echo
  echo "## Ops Console Probe Final Seal"
  echo
  echo '~~~text'
  echo "PASS_COUNT=$PASS_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅"

  if [ "$WARN_COUNT" -eq 0 ]; then
    echo "FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅"
  else
    echo "FAZ_6_11_OPS_CONSOLE_WARN_STATUS=HAS_WARNINGS ⚠️"
  fi
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅"

if [ "$WARN_COUNT" -eq 0 ]; then
  echo "FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅"
else
  echo "FAZ_6_11_OPS_CONSOLE_WARN_STATUS=HAS_WARNINGS ⚠️"
fi

echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
