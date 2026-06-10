#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_klasor="$proje_dizini/_yedekler"
snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
json_dosya="/opt/pix2pi/nginx/service_status.json"
zaman="$(date +%Y%m%d_%H%M%S)"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$yedek_klasor"
echo "OK ✅ klasor hazir"

echo
echo "2) Yedek aliniyor..."
if [ -f "$snapshot_script" ]; then
  cp "$snapshot_script" "$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"
  echo "OK ✅ snapshot yedegi alindi"
else
  echo "UYARI ⚠ snapshot script yok, yeni yazilacak"
fi

echo
echo "3) Snapshot script process bazli yeniden yaziliyor..."
cat <<'SCRIPTEOF' > "$snapshot_script"
#!/bin/bash
set -e

json_dosya="/opt/pix2pi/nginx/service_status.json"

durum_process() {
  pattern="$1"
  if pgrep -fa "$pattern" >/dev/null 2>&1; then
    echo "RUNNING"
  else
    echo "STOPPED"
  fi
}

durum_docker() {
  pattern="$1"
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -E "$pattern" >/dev/null 2>&1; then
    echo "RUNNING"
  else
    echo "STOPPED"
  fi
}

api_gateway="$(durum_process 'pix2pi_api_gateway|pix2pi-api-gateway|api_gateway_main.go')"
identity="$(durum_process 'pix2pi-identity|pix2pi_identity|identity_main.go')"
auth="$(durum_process 'pix2pi_auth|pix2pi-auth|auth_main.go')"
stock_service="$(durum_process 'pix2pi_stock_service|pix2pi-stock-service|stock_service_main.go|stok_servisi')"
accounting_service="$(durum_process 'pix2pi_accounting_service|pix2pi-accounting-service|accounting_service_main.go')"
reporting_service="$(durum_process 'pix2pi_reporting_service_bin|reporting_service_main.go')"
service_discovery="$(durum_process 'pix2pi_service_discovery_bin|service_discovery_main.go')"
query_read_model="$(durum_process 'pix2pi_query_read_model_bin|query_read_model_main.go')"

nats="$(durum_docker 'pix2pi_nats|pix2pi_nats_cli')"
redis="$(durum_docker 'pix2pi-redis|pix2pi_redis')"

if pgrep -fa 'nginx: master process|nginx: worker process' >/dev/null 2>&1; then
  nginx="RUNNING"
else
  nginx="STOPPED"
fi

kritikler=(
  "$api_gateway"
  "$identity"
  "$auth"
  "$stock_service"
  "$accounting_service"
  "$reporting_service"
  "$service_discovery"
  "$query_read_model"
  "$nats"
  "$redis"
  "$nginx"
)

genel_durum="Tum kritik servisler ayakta"
for durum in "${kritikler[@]}"; do
  if [ "$durum" != "RUNNING" ] && [ "$durum" != "HEALTHY" ]; then
    genel_durum="Bazi servisler ayakta degil"
    break
  fi
done

cat <<JSON > "$json_dosya"
{
  "guncellendi": "$(date '+%Y-%m-%d %H:%M:%S')",
  "services": {
    "api_gateway": { "durum": "$api_gateway" },
    "identity": { "durum": "$identity" },
    "auth": { "durum": "$auth" },
    "stock_service": { "durum": "$stock_service" },
    "accounting_service": { "durum": "$accounting_service" },
    "reporting_service": { "durum": "$reporting_service" },
    "service_discovery": { "durum": "$service_discovery" },
    "query_read_model": { "durum": "$query_read_model" },
    "nats": { "durum": "$nats" },
    "redis": { "durum": "$redis" },
    "nginx": { "durum": "$nginx" }
  },
  "genel_durum": "$genel_durum"
}
JSON

echo "OK ✅ service status json guncellendi"
SCRIPTEOF

chmod +x "$snapshot_script"
echo "OK ✅ snapshot script yazildi"

echo
echo "4) Snapshot calistiriliyor..."
"$snapshot_script"

echo
echo "5) Son json kontrolu..."
cat "$json_dosya"

echo
echo "OK ✅ process bazli snapshot geri geldi"
echo "Paneli yenile"
