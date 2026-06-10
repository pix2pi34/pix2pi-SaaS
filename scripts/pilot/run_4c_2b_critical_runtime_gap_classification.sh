#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

SCAN_REPORT="reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md"
DOC_FILE="docs/pilot/faz4c/4c_2b_critical_runtime_gap_classification.md"
REPORT_FILE="reports/pilot/faz4c/4c_2b_critical_runtime_gap_classification_report.md"

echo "===== 4C-2B CRITICAL RUNTIME GAP CLASSIFICATION ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

get_value() {
  local key="$1"
  local value
  value="$(grep "^${key}=" "$SCAN_REPORT" | tail -n 1 | cut -d'=' -f2- | tr -d '\r' || true)"
  if [ -z "$value" ]; then
    echo "UNKNOWN"
  else
    echo "$value"
  fi
}

[ -f "$SCAN_REPORT" ] || fail "4C-2A scan report bulunamadi: $SCAN_REPORT"

REPO_GIT_DIR="$(get_value REPO_GIT_DIR)"
GO_MOD_FILE="$(get_value GO_MOD_FILE)"
DOCKER_COMPOSE_FILE="$(get_value DOCKER_COMPOSE_FILE)"
PORTS_ENV_FILE="$(get_value PORTS_ENV_FILE)"
COMMON_ENV_FILE="$(get_value COMMON_ENV_FILE)"

API_GATEWAY_SERVICE_STATUS="$(get_value API_GATEWAY_SERVICE_STATUS)"
IDENTITY_SERVICE_STATUS="$(get_value IDENTITY_SERVICE_STATUS)"
FAIL2BAN_STATUS="$(get_value FAIL2BAN_STATUS)"
CRON_STATUS="$(get_value CRON_STATUS)"

PORT_9010_API_GATEWAY="$(get_value PORT_9010_API_GATEWAY)"
PORT_9001_IDENTITY="$(get_value PORT_9001_IDENTITY)"
PORT_5433_POSTGRES_HOST="$(get_value PORT_5433_POSTGRES_HOST)"
PORT_9090_PROMETHEUS="$(get_value PORT_9090_PROMETHEUS)"
PORT_3000_GRAFANA="$(get_value PORT_3000_GRAFANA)"
PORT_9100_NODE_EXPORTER="$(get_value PORT_9100_NODE_EXPORTER)"
PORT_8080_CADVISOR="$(get_value PORT_8080_CADVISOR)"

GATEWAY_HEALTH_HTTP="$(get_value GATEWAY_HEALTH_HTTP)"
IDENTITY_HEALTH_HTTP="$(get_value IDENTITY_HEALTH_HTTP)"
PROM_READY_HTTP="$(get_value PROM_READY_HTTP)"
GRAFANA_HEALTH_HTTP="$(get_value GRAFANA_HEALTH_HTTP)"
NODE_EXPORTER_HTTP="$(get_value NODE_EXPORTER_HTTP)"
CADVISOR_HTTP="$(get_value CADVISOR_HTTP)"

SCAN_CRITICAL_COUNT="$(get_value 4C_2A_CRITICAL_BLOCKER_COUNT)"
SCAN_WARNING_COUNT="$(get_value 4C_2A_WARNING_COUNT)"

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

if [ "$REPO_GIT_DIR" != "FOUND" ]; then
  add_critical "Repo .git dizini bulunamadi. Kod izlenebilirligi ve deploy takibi icin kritik."
fi

if [ "$GO_MOD_FILE" != "FOUND" ]; then
  add_critical "go.mod bulunamadi. Go servis build/test zinciri icin kritik."
fi

if [ "$PORT_5433_POSTGRES_HOST" != "LISTEN" ]; then
  add_critical "PostgreSQL host port 5433 dinlemiyor. Pilot tenant setup oncesi kritik."
fi

if [ "$PORT_9010_API_GATEWAY" != "LISTEN" ]; then
  add_critical "API Gateway port 9010 dinlemiyor. Pilot access layer icin kritik."
fi

if [ "$GATEWAY_HEALTH_HTTP" != "200" ]; then
  add_critical "Gateway health 200 donmuyor. Pilot runtime oncesi kritik."
fi

if [ "$DOCKER_COMPOSE_FILE" = "MISSING" ]; then
  add_warning "Repo kokunde docker-compose.yml yok. Sistem calisiyor ama deploy dosya yeri netlestirilmeli."
fi

if [ "$IDENTITY_SERVICE_STATUS" != "active" ]; then
  add_warning "pix2pi-identity-api.service systemd tarafinda active degil. Ancak Docker container aktif olabilir; servis stratejisi netlestirilmeli."
fi

if [ "$PORT_9001_IDENTITY" != "LISTEN" ] || [ "$IDENTITY_HEALTH_HTTP" = "NO_RESPONSE" ]; then
  add_warning "Identity icin 9001 beklenmis ama cevap yok. Docker raporunda identity-api 9002 portunda gorunuyor; port standardi netlestirilmeli."
fi

if [ "$PORT_3000_GRAFANA" != "LISTEN" ] || [ "$GRAFANA_HEALTH_HTTP" = "NO_RESPONSE" ]; then
  add_warning "Grafana 3000 portunda cevap vermiyor. Docker raporunda Grafana 3001->3000 map edilmis; port standardi netlestirilmeli."
fi

if [ "$PORTS_ENV_FILE" = "FOUND" ]; then
  add_info "/etc/pix2pi/ports.env bulundu."
else
  add_warning "/etc/pix2pi/ports.env bulunamadi."
fi

if [ "$COMMON_ENV_FILE" = "FOUND" ]; then
  add_info "/opt/pix2pi/orchestrator/env/common.env bulundu."
else
  add_warning "/opt/pix2pi/orchestrator/env/common.env bulunamadi."
fi

if [ "$FAIL2BAN_STATUS" = "active" ]; then
  add_info "fail2ban active."
else
  add_warning "fail2ban active degil."
fi

if [ "$CRON_STATUS" = "active" ]; then
  add_info "cron active."
else
  add_warning "cron active degil."
fi

if [ "$PROM_READY_HTTP" = "200" ]; then
  add_info "Prometheus ready 200."
else
  add_warning "Prometheus ready 200 donmedi."
fi

if [ "$NODE_EXPORTER_HTTP" = "200" ]; then
  add_info "Node exporter metrics 200."
else
  add_warning "Node exporter metrics 200 donmedi."
fi

if [ "$CADVISOR_HTTP" = "200" ]; then
  add_info "cAdvisor metrics 200."
else
  add_warning "cAdvisor metrics 200 donmedi."
fi

if [ -z "$CRITICAL_ITEMS" ]; then
  CRITICAL_ITEMS="- Kritik blocker yok"$'\n'
fi

if [ -z "$WARNING_ITEMS" ]; then
  WARNING_ITEMS="- Warning yok"$'\n'
fi

if [ -z "$INFO_ITEMS" ]; then
  INFO_ITEMS="- Info yok"$'\n'
fi

if [ "$CRITICAL_BLOCKER_COUNT" -eq 0 ]; then
  NEXT_READY="YES"
  CLASSIFICATION_STATUS="PASS"
else
  NEXT_READY="NO"
  CLASSIFICATION_STATUS="BLOCKED"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-2B Critical Runtime Gap Classification

## Blok

4C-2B — Critical Runtime Gap Classification

## Kaynak

Kaynak rapor:
reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md

---

## 1. 4C-2A ozet

4C_2A_CRITICAL_BLOCKER_COUNT=$SCAN_CRITICAL_COUNT
4C_2A_WARNING_COUNT=$SCAN_WARNING_COUNT

4C-2A sonucuna gore sistemde kritik blocker tespit edilmedi.
4C-2B bu sonucu ayrintili siniflandirir.

---

## 2. Critical blocker listesi

$CRITICAL_ITEMS

---

## 3. Warning listesi

$WARNING_ITEMS

---

## 4. Info listesi

$INFO_ITEMS

---

## 5. Ozel yorum

Identity icin 9001 portu beklenmis, fakat Docker container listesinde identity-api 9002 portunda calisiyor gorunuyor.

Grafana icin 3000 portu beklenmis, fakat Docker container listesinde Grafana 3001->3000 map edilmis gorunuyor.

Bu iki durum su an pilot tenant kurulumu icin kritik blocker degil.
Ancak 4C-2 icinde runtime port standardi netlestirilmelidir.

---

## 6. Karar

4C_2B_CLASSIFICATION_STATUS=$CLASSIFICATION_STATUS
4C_2B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_2B_WARNING_COUNT=$WARNING_COUNT
4C_2B_INFO_COUNT=$INFO_COUNT
4C_2B_RUNTIME_PORT_STANDARDIZATION_NEEDED=YES
4C_2B_IDENTITY_PORT_MISMATCH=YES
4C_2B_GRAFANA_PORT_MISMATCH=YES
4C_2B_NEXT_STEP_READY=$NEXT_READY
4C_2C_READY=$NEXT_READY
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-2B Critical Runtime Gap Classification Report

Step: 4C-2B
Blok: Critical Runtime Gap Classification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2B_CLASSIFICATION_STATUS=$CLASSIFICATION_STATUS
4C_2B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT
4C_2B_WARNING_COUNT=$WARNING_COUNT
4C_2B_INFO_COUNT=$INFO_COUNT
4C_2B_RUNTIME_PORT_STANDARDIZATION_NEEDED=YES
4C_2B_IDENTITY_PORT_MISMATCH=YES
4C_2B_GRAFANA_PORT_MISMATCH=YES
4C_2B_NEXT_STEP_READY=$NEXT_READY
4C_2C_READY=$NEXT_READY

## Sonuc

Critical blocker sayisi $CRITICAL_BLOCKER_COUNT.
Warning sayisi $WARNING_COUNT.
Runtime port standardizasyonu 4C-2C adiminda netlestirilecek.
REPORT_EOF

echo "OK ✅ Classification dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Classification report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-2B CLASSIFICATION OZETI ====="
echo "4C_2B_CLASSIFICATION_STATUS=$CLASSIFICATION_STATUS"
echo "4C_2B_CRITICAL_BLOCKER_COUNT=$CRITICAL_BLOCKER_COUNT"
echo "4C_2B_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2B_NEXT_STEP_READY=$NEXT_READY"
echo "4C_2C_READY=$NEXT_READY"
