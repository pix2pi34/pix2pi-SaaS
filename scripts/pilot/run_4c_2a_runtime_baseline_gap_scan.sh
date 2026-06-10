#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

REPORT_FILE="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md"

mkdir -p "$(dirname "$REPORT_FILE")"

now="$(date '+%Y-%m-%d %H:%M:%S')"

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "YES"
  else
    echo "NO"
  fi
}

check_file() {
  local f="$1"
  if [ -f "$f" ]; then
    echo "FOUND"
  else
    echo "MISSING"
  fi
}

check_dir() {
  local d="$1"
  if [ -d "$d" ]; then
    echo "FOUND"
  else
    echo "MISSING"
  fi
}

systemd_status() {
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active "$svc" 2>/dev/null || true
  else
    echo "systemctl_not_found"
  fi
}

curl_status() {
  local url="$1"

  if ! command -v curl >/dev/null 2>&1; then
    echo "CURL_NOT_FOUND"
    return 0
  fi

  local code
  code="$(curl -k -sS -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || true)"

  if [ -z "$code" ] || [ "$code" = "000" ]; then
    echo "NO_RESPONSE"
  else
    echo "$code"
  fi
}

port_listen() {
  local port="$1"

  if command -v ss >/dev/null 2>&1; then
    if ss -lntp 2>/dev/null | grep -q ":$port "; then
      echo "LISTEN"
    else
      echo "NOT_LISTEN"
    fi
  elif command -v netstat >/dev/null 2>&1; then
    if netstat -lntp 2>/dev/null | grep -q ":$port "; then
      echo "LISTEN"
    else
      echo "NOT_LISTEN"
    fi
  else
    echo "PORT_TOOL_NOT_FOUND"
  fi
}

echo "===== 4C-2A RUNTIME BASELINE GAP SCAN ====="

GIT_AVAILABLE="$(check_cmd git)"
GO_AVAILABLE="$(check_cmd go)"
DOCKER_AVAILABLE="$(check_cmd docker)"
CURL_AVAILABLE="$(check_cmd curl)"
SS_AVAILABLE="$(check_cmd ss)"
SYSTEMCTL_AVAILABLE="$(check_cmd systemctl)"

REPO_GIT_DIR="$(check_dir .git)"
GO_MOD_FILE="$(check_file go.mod)"
DOCKER_COMPOSE_FILE="$(check_file docker-compose.yml)"
PORTS_ENV_FILE="$(check_file /etc/pix2pi/ports.env)"
COMMON_ENV_FILE="$(check_file /opt/pix2pi/orchestrator/env/common.env)"

API_GATEWAY_SERVICE_STATUS="$(systemd_status pix2pi-api-gateway.service)"
IDENTITY_SERVICE_STATUS="$(systemd_status pix2pi-identity-api.service)"
FAIL2BAN_STATUS="$(systemd_status fail2ban.service)"
CRON_STATUS="$(systemd_status cron.service)"

PORT_9010_STATUS="$(port_listen 9010)"
PORT_9001_STATUS="$(port_listen 9001)"
PORT_5433_STATUS="$(port_listen 5433)"
PORT_9090_STATUS="$(port_listen 9090)"
PORT_3000_STATUS="$(port_listen 3000)"
PORT_9100_STATUS="$(port_listen 9100)"
PORT_8080_STATUS="$(port_listen 8080)"

GATEWAY_HEALTH_HTTP="$(curl_status http://127.0.0.1:9010/health)"
IDENTITY_HEALTH_HTTP="$(curl_status http://127.0.0.1:9001/health)"
PROM_READY_HTTP="$(curl_status http://127.0.0.1:9090/-/ready)"
GRAFANA_HEALTH_HTTP="$(curl_status http://127.0.0.1:3000/api/health)"
NODE_EXPORTER_HTTP="$(curl_status http://127.0.0.1:9100/metrics)"
CADVISOR_HTTP="$(curl_status http://127.0.0.1:8080/metrics)"

DOCKER_PS_SUMMARY="DOCKER_NOT_AVAILABLE"
if command -v docker >/dev/null 2>&1; then
  DOCKER_PS_SUMMARY="$(docker ps --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' 2>/dev/null || true)"
  if [ -z "$DOCKER_PS_SUMMARY" ]; then
    DOCKER_PS_SUMMARY="NO_RUNNING_CONTAINERS_OR_DOCKER_ERROR"
  fi
fi

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0

if [ "$REPO_GIT_DIR" != "FOUND" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$GO_MOD_FILE" != "FOUND" ]; then
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
fi

if [ "$DOCKER_AVAILABLE" != "YES" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$PORT_5433_STATUS" != "LISTEN" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$PORT_9010_STATUS" != "LISTEN" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$GATEWAY_HEALTH_HTTP" = "NO_RESPONSE" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$IDENTITY_HEALTH_HTTP" = "NO_RESPONSE" ]; then
  WARNING_COUNT=$((WARNING_COUNT + 1))
fi

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-2A Runtime Baseline Gap Scan Report

Step: 4C-2A
Blok: Runtime Baseline Inventory / Gap Scan
Test tarihi: $now

## 1. Tool durumu

GIT_AVAILABLE=$GIT_AVAILABLE
GO_AVAILABLE=$GO_AVAILABLE
DOCKER_AVAILABLE=$DOCKER_AVAILABLE
CURL_AVAILABLE=$CURL_AVAILABLE
SS_AVAILABLE=$SS_AVAILABLE
SYSTEMCTL_AVAILABLE=$SYSTEMCTL_AVAILABLE

---

## 2. Repo / dosya durumu

REPO_GIT_DIR=$REPO_GIT_DIR
GO_MOD_FILE=$GO_MOD_FILE
DOCKER_COMPOSE_FILE=$DOCKER_COMPOSE_FILE
PORTS_ENV_FILE=$PORTS_ENV_FILE
COMMON_ENV_FILE=$COMMON_ENV_FILE

---

## 3. Systemd servis durumu

API_GATEWAY_SERVICE_STATUS=$API_GATEWAY_SERVICE_STATUS
IDENTITY_SERVICE_STATUS=$IDENTITY_SERVICE_STATUS
FAIL2BAN_STATUS=$FAIL2BAN_STATUS
CRON_STATUS=$CRON_STATUS

---

## 4. Port dinleme durumu

PORT_9010_API_GATEWAY=$PORT_9010_STATUS
PORT_9001_IDENTITY=$PORT_9001_STATUS
PORT_5433_POSTGRES_HOST=$PORT_5433_STATUS
PORT_9090_PROMETHEUS=$PORT_9090_STATUS
PORT_3000_GRAFANA=$PORT_3000_STATUS
PORT_9100_NODE_EXPORTER=$PORT_9100_STATUS
PORT_8080_CADVISOR=$PORT_8080_STATUS

---

## 5. Health endpoint durumu

GATEWAY_HEALTH_HTTP=$GATEWAY_HEALTH_HTTP
IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
PROM_READY_HTTP=$PROM_READY_HTTP
GRAFANA_HEALTH_HTTP=$GRAFANA_HEALTH_HTTP
NODE_EXPORTER_HTTP=$NODE_EXPORTER_HTTP
CADVISOR_HTTP=$CADVISOR_HTTP

---

## 6. Docker running containers

\`\`\`text
$DOCKER_PS_SUMMARY
\`\`\`

---

## 7. Gap özeti

4C_2A_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_2A_WARNING_COUNT=$WARNING_COUNT

Not:
Bu adim runtime fotoğrafı çeker.
Warning olması bu adımı fail yapmaz.
Critical blocker varsa 4C-2B içinde ayrıştırılır.

---

## 8. Status

4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS
4C_2A_REPORT_CREATED=YES
4C_2A_NEXT_STEP_READY=YES
4C_2B_READY=YES
REPORT_EOF

echo "OK ✅ Runtime baseline report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-2A SCAN OZETI ====="
echo "4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS ✅"
echo "4C_2A_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
echo "4C_2A_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2B_READY=YES ✅"
