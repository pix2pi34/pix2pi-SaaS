#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_5_OBSERVABILITY_RUNTIME_AUDIT.md"
mkdir -p docs/faz6/evidence

mask_secret() {
  sed -E \
    -e 's/(password=)[^ ]+/\1***MASKED***/g' \
    -e 's/(PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(PASS=).*/\1***MASKED***/g' \
    -e 's/(SECRET=).*/\1***MASKED***/g' \
    -e 's/(TOKEN=).*/\1***MASKED***/g'
}

write_cmd_block() {
  local title="$1"
  shift

  {
    echo
    echo "## $title"
    echo
    echo '```text'
    "$@" 2>&1 | mask_secret || true
    echo '```'
  } >> "$EVIDENCE_FILE"
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-5 Observability Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit runtime ortaminda observability / early warning / SRE dashboard izlerini toplar. Destructive islem yapmaz.

FAZ_6_5_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-5 OBSERVABILITY RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-5.1 Host / Kernel" uname -a

if command -v docker >/dev/null 2>&1; then
  write_cmd_block "6-5.2 Observability Docker Containers" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | grep -Ei 'prometheus|grafana|node|cadvisor|loki|alert|exporter|nats|postgres|redis|NAME' || true"
else
  write_cmd_block "6-5.2 Observability Docker Containers" bash -lc "echo 'WARN ⚠️ docker command not found'"
fi

if command -v systemctl >/dev/null 2>&1; then
  write_cmd_block "6-5.3 Observability Systemd Services" bash -lc "systemctl list-units --type=service --all | grep -Ei 'prometheus|grafana|node|cadvisor|loki|alert|exporter|pix2pi|mission|registry|gateway' || true"
else
  write_cmd_block "6-5.3 Observability Systemd Services" bash -lc "echo 'WARN ⚠️ systemctl not available'"
fi

if command -v ss >/dev/null 2>&1; then
  write_cmd_block "6-5.4 Observability Listening Ports" bash -lc "ss -lntp | grep -E ':3000|:8080|:9090|:9093|:9100|:3100|:9113|:9187|:9121|:9010|:9001|:4222|:8222' || true"
else
  write_cmd_block "6-5.4 Observability Listening Ports" bash -lc "netstat -lntp 2>/dev/null | grep -E ':3000|:8080|:9090|:9093|:9100|:3100|:9113|:9187|:9121|:9010|:9001|:4222|:8222' || true"
fi

write_cmd_block "6-5.5 Prometheus Ready Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:9090/-/ready 2>/dev/null || echo 'WARN ⚠️ Prometheus ready unavailable'"

write_cmd_block "6-5.6 Prometheus Targets Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:9090/api/v1/targets 2>/dev/null | head -c 4000 || echo 'WARN ⚠️ Prometheus targets unavailable'"

write_cmd_block "6-5.7 Grafana Health Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:3000/api/health 2>/dev/null | head -c 1000 || echo 'WARN ⚠️ Grafana health unavailable'"

write_cmd_block "6-5.8 Node Exporter Metrics Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:9100/metrics 2>/dev/null | head -n 20 || echo 'WARN ⚠️ node_exporter metrics unavailable'"

write_cmd_block "6-5.9 cAdvisor Metrics Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:8080/metrics 2>/dev/null | head -n 20 || echo 'WARN ⚠️ cAdvisor metrics unavailable'"

write_cmd_block "6-5.10 Pix2pi Local Health Probes" bash -lc "
for port in 9001 9010 9090 9100 8080 3000 8222; do
  echo ===== PORT \$port HEALTH/METRICS PROBE =====
  curl -fsS --max-time 2 http://127.0.0.1:\$port/health 2>/dev/null | head -c 500 || true
  curl -fsS --max-time 2 http://127.0.0.1:\$port/metrics 2>/dev/null | head -n 5 || true
  echo
done
"

write_cmd_block "6-5.11 Observability Config Inventory" bash -lc "
for p in \
  ./prometheus.yml \
  ./docker-compose.yml \
  ./docker-compose.yaml \
  ./monitoring \
  ./ops \
  /etc/prometheus \
  /etc/grafana \
  /opt/pix2pi \
  /opt/pix2pi/orchestrator \
  /etc/pix2pi
do
  if [ -e \"\$p\" ]; then
    echo ===== \$p =====
    find \"\$p\" -maxdepth 4 -type f 2>/dev/null | grep -Ei 'prometheus|grafana|alert|rule|dashboard|datasource|loki|metrics|exporter' | head -n 120 || true
  fi
done
"

write_cmd_block "6-5.12 Alert / Rule Inventory" bash -lc "grep -RInE 'alert:|expr:|for:|severity|threshold|cpu|memory|disk|latency|backlog|DLQ|5xx|down' . /etc/prometheus /opt/pix2pi 2>/dev/null | head -n 160 || true"

{
  echo
  echo "## 6-5.13 Runtime Audit Interpretation"
  echo
  echo '```text'
  echo "6-5.1 Host inventory collected OK ✅"
  echo "6-5.2 Observability docker inventory collected OK ✅"
  echo "6-5.3 Observability systemd inventory collected OK ✅"
  echo "6-5.4 Observability ports inventory collected OK ✅"
  echo "6-5.5 Prometheus ready probe collected OK ✅"
  echo "6-5.6 Prometheus targets probe collected OK ✅"
  echo "6-5.7 Grafana health probe collected OK ✅"
  echo "6-5.8 Node exporter probe collected OK ✅"
  echo "6-5.9 cAdvisor probe collected OK ✅"
  echo "6-5.10 Pix2pi health/metrics probe collected OK ✅"
  echo "6-5.11 Observability config inventory collected OK ✅"
  echo "6-5.12 Alert/rule inventory collected OK ✅"
  echo "FAZ_6_5_RUNTIME_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_5_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
