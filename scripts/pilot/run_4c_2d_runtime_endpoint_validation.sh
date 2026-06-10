#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC_FILE="docs/pilot/faz4c/4c_2d_runtime_endpoint_validation.md"
REPORT_FILE="reports/pilot/faz4c/4c_2d_runtime_endpoint_validation_report.md"
PORT_REPORT="reports/pilot/faz4c/4c_2c_runtime_port_standardization_report.md"

echo "===== 4C-2D RUNTIME ENDPOINT VALIDATION ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

curl_status() {
  local url="$1"

  if ! command -v curl >/dev/null 2>&1; then
    echo "CURL_NOT_FOUND"
    return 0
  fi

  local code
  code="$(curl -k -sS -o /dev/null -w "%{http_code}" --max-time 4 "$url" 2>/dev/null || true)"

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

[ -f "$PORT_REPORT" ] || fail "4C-2C port standardization report bulunamadi: $PORT_REPORT"

grep -q "4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS" "$PORT_REPORT" || fail "4C-2C port standardization PASS degil"

API_GATEWAY_PORT="9010"
IDENTITY_API_PORT="9002"
POSTGRES_PRIMARY_PORT="5433"
POSTGRES_REPLICA_PORT="5434"
REDIS_PORT="6379"
NATS_CLIENT_PORT="4222"
NATS_MONITORING_PORT="8222"
PROMETHEUS_PORT="9090"
GRAFANA_PORT="3001"
NODE_EXPORTER_PORT="9100"
CADVISOR_PORT="8080"
LOKI_PORT="3100"
TEMPO_PORT="3200"
MISSION_CONTROL_PORT="9101"

API_GATEWAY_PORT_STATUS="$(port_listen "$API_GATEWAY_PORT")"
IDENTITY_PORT_STATUS="$(port_listen "$IDENTITY_API_PORT")"
POSTGRES_PRIMARY_PORT_STATUS="$(port_listen "$POSTGRES_PRIMARY_PORT")"
POSTGRES_REPLICA_PORT_STATUS="$(port_listen "$POSTGRES_REPLICA_PORT")"
REDIS_PORT_STATUS="$(port_listen "$REDIS_PORT")"
NATS_CLIENT_PORT_STATUS="$(port_listen "$NATS_CLIENT_PORT")"
NATS_MONITORING_PORT_STATUS="$(port_listen "$NATS_MONITORING_PORT")"
PROMETHEUS_PORT_STATUS="$(port_listen "$PROMETHEUS_PORT")"
GRAFANA_PORT_STATUS="$(port_listen "$GRAFANA_PORT")"
NODE_EXPORTER_PORT_STATUS="$(port_listen "$NODE_EXPORTER_PORT")"
CADVISOR_PORT_STATUS="$(port_listen "$CADVISOR_PORT")"
LOKI_PORT_STATUS="$(port_listen "$LOKI_PORT")"
TEMPO_PORT_STATUS="$(port_listen "$TEMPO_PORT")"
MISSION_CONTROL_PORT_STATUS="$(port_listen "$MISSION_CONTROL_PORT")"

API_GATEWAY_HEALTH_HTTP="$(curl_status "http://127.0.0.1:${API_GATEWAY_PORT}/health")"
IDENTITY_HEALTH_HTTP="$(curl_status "http://127.0.0.1:${IDENTITY_API_PORT}/health")"
PROMETHEUS_READY_HTTP="$(curl_status "http://127.0.0.1:${PROMETHEUS_PORT}/-/ready")"
GRAFANA_HEALTH_HTTP="$(curl_status "http://127.0.0.1:${GRAFANA_PORT}/api/health")"
NODE_EXPORTER_METRICS_HTTP="$(curl_status "http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics")"
CADVISOR_METRICS_HTTP="$(curl_status "http://127.0.0.1:${CADVISOR_PORT}/metrics")"
NATS_HEALTH_HTTP="$(curl_status "http://127.0.0.1:${NATS_MONITORING_PORT}/healthz")"
NATS_VARZ_HTTP="$(curl_status "http://127.0.0.1:${NATS_MONITORING_PORT}/varz")"
LOKI_READY_HTTP="$(curl_status "http://127.0.0.1:${LOKI_PORT}/ready")"
TEMPO_READY_HTTP="$(curl_status "http://127.0.0.1:${TEMPO_PORT}/ready")"
MISSION_CONTROL_HEALTH_HTTP="$(curl_status "http://127.0.0.1:${MISSION_CONTROL_PORT}/health")"

CRITICAL_BLOCKER_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

CRITICAL_ITEMS=""
WARNING_ITEMS=""
INFO_ITEMS=""

add_critical() {
  CRITICAL_BLOCKER_COUNT=$((CRITICAL_BLOCKER_COUNT + 1))
  CRITICAL_ITEMS="${CRITICAL_ITEMS}- $1"$'\n'
}

add_warning() {
  WARNING_COUNT=$((WARNING_COUNT + 1))
  WARNING_ITEMS="${WARNING_ITEMS}- $1"$'\n'
}

add_info() {
  INFO_COUNT=$((INFO_COUNT + 1))
  INFO_ITEMS="${INFO_ITEMS}- $1"$'\n'
}

if [ "$API_GATEWAY_PORT_STATUS" != "LISTEN" ]; then
  add_critical "API Gateway port $API_GATEWAY_PORT dinlemiyor."
fi

if [ "$API_GATEWAY_HEALTH_HTTP" != "200" ]; then
  add_critical "API Gateway /health 200 donmuyor. Sonuc: $API_GATEWAY_HEALTH_HTTP"
fi

if [ "$POSTGRES_PRIMARY_PORT_STATUS" != "LISTEN" ]; then
  add_critical "PostgreSQL primary port $POSTGRES_PRIMARY_PORT dinlemiyor."
fi

if [ "$REDIS_PORT_STATUS" != "LISTEN" ]; then
  add_warning "Redis port $REDIS_PORT dinlemiyor veya port tool yakalayamadi."
else
  add_info "Redis port $REDIS_PORT LISTEN."
fi

if [ "$NATS_CLIENT_PORT_STATUS" != "LISTEN" ]; then
  add_warning "NATS client port $NATS_CLIENT_PORT dinlemiyor veya port tool yakalayamadi."
else
  add_info "NATS client port $NATS_CLIENT_PORT LISTEN."
fi

if [ "$NATS_MONITORING_PORT_STATUS" != "LISTEN" ]; then
  add_warning "NATS monitoring port $NATS_MONITORING_PORT dinlemiyor."
else
  add_info "NATS monitoring port $NATS_MONITORING_PORT LISTEN."
fi

if [ "$IDENTITY_PORT_STATUS" != "LISTEN" ]; then
  add_warning "Identity runtime port $IDENTITY_API_PORT dinlemiyor. 4C-4 user/role oncesi netlestirilmeli."
else
  add_info "Identity runtime port $IDENTITY_API_PORT LISTEN."
fi

if [ "$IDENTITY_HEALTH_HTTP" != "200" ]; then
  add_warning "Identity /health 200 donmedi. Sonuc: $IDENTITY_HEALTH_HTTP. 4C-4 oncesi tekrar kontrol edilecek."
else
  add_info "Identity /health 200."
fi

if [ "$PROMETHEUS_READY_HTTP" != "200" ]; then
  add_warning "Prometheus /-/ready 200 donmedi. Sonuc: $PROMETHEUS_READY_HTTP"
else
  add_info "Prometheus ready 200."
fi

if [ "$GRAFANA_HEALTH_HTTP" != "200" ]; then
  add_warning "Grafana /api/health 200 donmedi. Sonuc: $GRAFANA_HEALTH_HTTP"
else
  add_info "Grafana health 200."
fi

if [ "$NODE_EXPORTER_METRICS_HTTP" != "200" ]; then
  add_warning "Node Exporter /metrics 200 donmedi. Sonuc: $NODE_EXPORTER_METRICS_HTTP"
else
  add_info "Node Exporter metrics 200."
fi

if [ "$CADVISOR_METRICS_HTTP" != "200" ]; then
  add_warning "cAdvisor /metrics 200 donmedi. Sonuc: $CADVISOR_METRICS_HTTP"
else
  add_info "cAdvisor metrics 200."
fi

if [ "$NATS_HEALTH_HTTP" = "200" ] || [ "$NATS_VARZ_HTTP" = "200" ]; then
  add_info "NATS monitoring endpoint cevap veriyor."
else
  add_warning "NATS monitoring endpoint 200 donmedi. healthz=$NATS_HEALTH_HTTP varz=$NATS_VARZ_HTTP"
fi

if [ "$LOKI_READY_HTTP" = "200" ]; then
  add_info "Loki ready 200."
else
  add_warning "Loki ready 200 donmedi. Sonuc: $LOKI_READY_HTTP"
fi

if [ "$TEMPO_READY_HTTP" = "200" ]; then
  add_info "Tempo ready 200."
else
  add_warning "Tempo ready 200 donmedi. Sonuc: $TEMPO_READY_HTTP"
fi

if [ "$MISSION_CONTROL_HEALTH_HTTP" = "200" ]; then
  add_info "Mission Control health 200."
else
  add_warning "Mission Control health 200 donmedi. Sonuc: $MISSION_CONTROL_HEALTH_HTTP"
fi

if [ -z "$CRITICAL_ITEMS" ]; then
  CRITICAL_ITEMS="- Kritik endpoint blocker yok"$'\n'
fi

if [ -z "$WARNING_ITEMS" ]; then
  WARNING_ITEMS="- Warning yok"$'\n'
fi

if [ -z "$INFO_ITEMS" ]; then
  INFO_ITEMS="- Info yok"$'\n'
fi

if [ "$CRITICAL_BLOCKER_COUNT" -eq 0 ]; then
  ENDPOINT_VALIDATION_STATUS="PASS"
  NEXT_READY="YES"
else
  ENDPOINT_VALIDATION_STATUS="BLOCKED"
  NEXT_READY="NO"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-2D Runtime Endpoint Validation

## Blok

4C-2D — Runtime Endpoint Validation

## Amaç

Bu adım FAZ 4C pilot öncesi gerçek endpoint ve port doğrulamasını yapar.

Bu adım servis değiştirmez.
Bu adım restart yapmaz.
Bu adım sadece doğrulama ve raporlama yapar.

---

## 1. Port validation

| Bileşen | Port | Durum |
|---|---:|---|
| API Gateway | $API_GATEWAY_PORT | $API_GATEWAY_PORT_STATUS |
| Identity API | $IDENTITY_API_PORT | $IDENTITY_PORT_STATUS |
| PostgreSQL Primary | $POSTGRES_PRIMARY_PORT | $POSTGRES_PRIMARY_PORT_STATUS |
| PostgreSQL Replica | $POSTGRES_REPLICA_PORT | $POSTGRES_REPLICA_PORT_STATUS |
| Redis | $REDIS_PORT | $REDIS_PORT_STATUS |
| NATS Client | $NATS_CLIENT_PORT | $NATS_CLIENT_PORT_STATUS |
| NATS Monitoring | $NATS_MONITORING_PORT | $NATS_MONITORING_PORT_STATUS |
| Prometheus | $PROMETHEUS_PORT | $PROMETHEUS_PORT_STATUS |
| Grafana | $GRAFANA_PORT | $GRAFANA_PORT_STATUS |
| Node Exporter | $NODE_EXPORTER_PORT | $NODE_EXPORTER_PORT_STATUS |
| cAdvisor | $CADVISOR_PORT | $CADVISOR_PORT_STATUS |
| Loki | $LOKI_PORT | $LOKI_PORT_STATUS |
| Tempo | $TEMPO_PORT | $TEMPO_PORT_STATUS |
| Mission Control | $MISSION_CONTROL_PORT | $MISSION_CONTROL_PORT_STATUS |

---

## 2. HTTP endpoint validation

| Endpoint | Sonuç |
|---|---|
| Gateway /health | $API_GATEWAY_HEALTH_HTTP |
| Identity /health | $IDENTITY_HEALTH_HTTP |
| Prometheus /-/ready | $PROMETHEUS_READY_HTTP |
| Grafana /api/health | $GRAFANA_HEALTH_HTTP |
| Node Exporter /metrics | $NODE_EXPORTER_METRICS_HTTP |
| cAdvisor /metrics | $CADVISOR_METRICS_HTTP |
| NATS /healthz | $NATS_HEALTH_HTTP |
| NATS /varz | $NATS_VARZ_HTTP |
| Loki /ready | $LOKI_READY_HTTP |
| Tempo /ready | $TEMPO_READY_HTTP |
| Mission Control /health | $MISSION_CONTROL_HEALTH_HTTP |

---

## 3. Critical listesi

$CRITICAL_ITEMS

---

## 4. Warning listesi

$WARNING_ITEMS

---

## 5. Info listesi

$INFO_ITEMS

---

## 6. Pilot kararı

4C-2D sonucuna göre kritik endpoint blocker sayısı:

4C_2D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT

Gateway ve PostgreSQL primary kritik kabul edilir.
Identity warning olarak izlenir; çünkü 4C-4 user/role assignment öncesi tekrar özel kontrol yapılacak.

---

## 7. Status

4C_2D_ENDPOINT_VALIDATION_STATUS=$ENDPOINT_VALIDATION_STATUS
4C_2D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_2D_WARNING_COUNT=$WARNING_COUNT
4C_2D_INFO_COUNT=$INFO_COUNT
4C_2D_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
4C_2D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
4C_2D_POSTGRES_PRIMARY_PORT_STATUS=$POSTGRES_PRIMARY_PORT_STATUS
4C_2D_NEXT_STEP_READY=$NEXT_READY
4C_2E_READY=$NEXT_READY
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-2D Runtime Endpoint Validation Report

Step: 4C-2D
Blok: Runtime Endpoint Validation
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2D_ENDPOINT_VALIDATION_STATUS=$ENDPOINT_VALIDATION_STATUS
4C_2D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_2D_WARNING_COUNT=$WARNING_COUNT
4C_2D_INFO_COUNT=$INFO_COUNT
4C_2D_GATEWAY_PORT_STATUS=$API_GATEWAY_PORT_STATUS
4C_2D_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP
4C_2D_IDENTITY_PORT_STATUS=$IDENTITY_PORT_STATUS
4C_2D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP
4C_2D_POSTGRES_PRIMARY_PORT_STATUS=$POSTGRES_PRIMARY_PORT_STATUS
4C_2D_REDIS_PORT_STATUS=$REDIS_PORT_STATUS
4C_2D_NATS_CLIENT_PORT_STATUS=$NATS_CLIENT_PORT_STATUS
4C_2D_PROMETHEUS_READY_HTTP=$PROMETHEUS_READY_HTTP
4C_2D_GRAFANA_HEALTH_HTTP=$GRAFANA_HEALTH_HTTP
4C_2D_NODE_EXPORTER_METRICS_HTTP=$NODE_EXPORTER_METRICS_HTTP
4C_2D_CADVISOR_METRICS_HTTP=$CADVISOR_METRICS_HTTP
4C_2D_NEXT_STEP_READY=$NEXT_READY
4C_2E_READY=$NEXT_READY

## Sonuc

Runtime endpoint validation tamamlandi.
Critical blocker sayisi: $CRITICAL_BLOCKER_COUNT
Warning sayisi: $WARNING_COUNT
Sonraki adim: 4C-2E Runtime Gap Decision / Fix Plan.
REPORT_EOF

echo "OK ✅ Endpoint validation dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Endpoint validation report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-2D VALIDATION OZETI ====="
echo "4C_2D_ENDPOINT_VALIDATION_STATUS=$ENDPOINT_VALIDATION_STATUS"
echo "4C_2D_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
echo "4C_2D_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2D_GATEWAY_HEALTH_HTTP=$API_GATEWAY_HEALTH_HTTP"
echo "4C_2D_IDENTITY_HEALTH_HTTP=$IDENTITY_HEALTH_HTTP"
echo "4C_2E_READY=$NEXT_READY"
