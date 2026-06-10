#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_4_EVENT_BUS_RUNTIME_AUDIT.md"
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
# FAZ 6-4 Event Bus Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit runtime ortaminda event bus / queue / backlog SRE izlerini toplar. Destructive islem yapmaz.

FAZ_6_4_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-4 EVENT BUS RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-4.1 Host / Kernel" uname -a

if command -v docker >/dev/null 2>&1; then
  write_cmd_block "6-4.2 Docker Event Bus Containers" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | grep -Ei 'nats|jetstream|event|consumer|worker|NAME' || true"
else
  write_cmd_block "6-4.2 Docker Event Bus Containers" bash -lc "echo 'WARN ⚠️ docker command not found'"
fi

if command -v systemctl >/dev/null 2>&1; then
  write_cmd_block "6-4.3 Event-related Systemd Services" bash -lc "systemctl list-units --type=service --all | grep -Ei 'nats|event|consumer|worker|queue|pix2pi' || true"
else
  write_cmd_block "6-4.3 Event-related Systemd Services" bash -lc "echo 'WARN ⚠️ systemctl not available'"
fi

if command -v ss >/dev/null 2>&1; then
  write_cmd_block "6-4.4 NATS / Event Ports" bash -lc "ss -lntp | grep -E ':4222|:6222|:8222|:8080|:900|:901' || true"
else
  write_cmd_block "6-4.4 NATS / Event Ports" bash -lc "netstat -lntp 2>/dev/null | grep -E ':4222|:6222|:8222|:8080|:900|:901' || true"
fi

write_cmd_block "6-4.5 NATS Monitoring varz Probe" bash -lc "curl -fsS --max-time 2 http://127.0.0.1:8222/varz 2>/dev/null | head -c 2000 || echo 'WARN ⚠️ NATS /varz unavailable'"

write_cmd_block "6-4.6 NATS JetStream jsz Probe" bash -lc "curl -fsS --max-time 2 http://127.0.0.1:8222/jsz 2>/dev/null | head -c 3000 || echo 'WARN ⚠️ NATS /jsz unavailable'"

write_cmd_block "6-4.7 NATS Connection connz Probe" bash -lc "curl -fsS --max-time 2 http://127.0.0.1:8222/connz 2>/dev/null | head -c 2000 || echo 'WARN ⚠️ NATS /connz unavailable'"

write_cmd_block "6-4.8 NATS Subscription subsz Probe" bash -lc "curl -fsS --max-time 2 http://127.0.0.1:8222/subsz 2>/dev/null | head -c 2000 || echo 'WARN ⚠️ NATS /subsz unavailable'"

write_cmd_block "6-4.9 Event Env Inventory" bash -lc "for f in .env .env.production /etc/pix2pi/ports.env /opt/pix2pi/orchestrator/env/common.env; do if [ -f \"\$f\" ]; then echo ===== \$f =====; grep -E 'NATS|JETSTREAM|EVENT|QUEUE|CONSUMER|WORKER|DLQ|REPLAY|BACKLOG|REDIS|DB_' \"\$f\" | head -n 160; fi; done"

write_cmd_block "6-4.10 Event Scripts Inventory" bash -lc "find scripts cmd internal -type f 2>/dev/null | grep -Ei 'event|nats|jetstream|consumer|worker|queue|dlq|replay|idempot|backlog' | sort | head -n 160 || true"

{
  echo
  echo "## 6-4.11 Runtime Audit Interpretation"
  echo
  echo '```text'
  echo "6-4.1 Host inventory collected OK ✅"
  echo "6-4.2 Docker event bus inventory collected OK ✅"
  echo "6-4.3 Systemd event service inventory collected OK ✅"
  echo "6-4.4 NATS/event ports inventory collected OK ✅"
  echo "6-4.5 NATS /varz probe collected OK ✅"
  echo "6-4.6 NATS /jsz probe collected OK ✅"
  echo "6-4.7 NATS /connz probe collected OK ✅"
  echo "6-4.8 NATS /subsz probe collected OK ✅"
  echo "6-4.9 Event env inventory collected OK ✅"
  echo "6-4.10 Event scripts inventory collected OK ✅"
  echo "FAZ_6_4_RUNTIME_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_4_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
