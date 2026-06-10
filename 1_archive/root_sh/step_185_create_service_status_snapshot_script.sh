#!/bin/bash
set -e

cat <<'BASH' > /usr/local/bin/pix2pi_service_snapshot.sh
#!/bin/bash
set -e

DOSYA="/opt/pix2pi/nginx/service_status.json"

durum_process() {
  local ad="$1"
  local desen="$2"

  if pgrep -f "$desen" >/dev/null 2>&1; then
    echo "\"$ad\":{\"durum\":\"RUNNING\"}"
  else
    echo "\"$ad\":{\"durum\":\"DOWN\"}"
  fi
}

durum_http_json() {
  local ad="$1"
  local url="$2"
  local expected="$3"

  if curl -s --max-time 3 "$url" | grep -q "$expected"; then
    echo "\"$ad\":{\"durum\":\"HEALTHY\"}"
  else
    echo "\"$ad\":{\"durum\":\"UNHEALTHY\"}"
  fi
}

durum_http_text() {
  local ad="$1"
  local url="$2"
  local expected="$3"

  if curl -s --max-time 3 "$url" | grep -q "$expected"; then
    echo "\"$ad\":{\"durum\":\"HEALTHY\"}"
  else
    echo "\"$ad\":{\"durum\":\"UNHEALTHY\"}"
  fi
}

durum_docker() {
  local ad="$1"
  local container="$2"

  if docker ps --format '{{.Names}}' | grep -qx "$container"; then
    echo "\"$ad\":{\"durum\":\"RUNNING\"}"
  else
    echo "\"$ad\":{\"durum\":\"DOWN\"}"
  fi
}

API_GATEWAY=$(durum_http_text "api_gateway" "http://127.0.0.1:9010/health" "Pix2pi API Gateway OK")
IDENTITY=$(durum_http_json "identity" "http://127.0.0.1:9001/health" "\"service\":\"identity\"")
AUTH=$(durum_http_json "auth" "http://127.0.0.1:9002/health" "\"service\":\"auth\"")
STOCK=$(durum_process "stock_service" "stock_service_main.go")
ACCOUNTING=$(durum_process "accounting_service" "accounting_service_main.go")
NATS=$(durum_docker "nats" "pix2pi_nats")
REDIS=$(durum_http_text "redis" "http://127.0.0.1:6379" "" || true)

if redis-cli ping >/dev/null 2>&1; then
  REDIS="\"redis\":{\"durum\":\"RUNNING\"}"
else
  REDIS="\"redis\":{\"durum\":\"DOWN\"}"
fi

if systemctl is-active --quiet nginx; then
  NGINX="\"nginx\":{\"durum\":\"RUNNING\"}"
else
  NGINX="\"nginx\":{\"durum\":\"DOWN\"}"
fi

cat <<JSON > "$DOSYA"
{
  "guncellendi":"$(date '+%Y-%m-%d %H:%M:%S')",
  $API_GATEWAY,
  $IDENTITY,
  $AUTH,
  $STOCK,
  $ACCOUNTING,
  $NATS,
  $REDIS,
  $NGINX
}
JSON

echo "OK ✅ service status json guncellendi"
BASH

chmod +x /usr/local/bin/pix2pi_service_snapshot.sh

/usr/local/bin/pix2pi_service_snapshot.sh

echo "OK ✅ service snapshot script hazir"
