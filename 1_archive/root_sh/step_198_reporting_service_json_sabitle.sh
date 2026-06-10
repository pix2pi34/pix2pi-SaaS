#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_dizini="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

json_dosya="/opt/pix2pi/nginx/service_status.json"
snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"

echo "1) Klasor ve dosya kontrolleri..."
mkdir -p "$yedek_dizini"

if [ ! -f "$json_dosya" ]; then
  echo "HATA ❌ json dosyasi yok: $json_dosya"
  exit 1
fi

if [ ! -f "$snapshot_script" ]; then
  echo "HATA ❌ snapshot script yok: $snapshot_script"
  exit 1
fi

if [ ! -f "$status_script" ]; then
  echo "HATA ❌ reporting status script yok: $status_script"
  exit 1
fi

echo "OK ✅ gerekli dosyalar bulundu"

echo
echo "2) Yedek aliniyor..."
cp "$json_dosya" "$yedek_dizini/service_status.json.$zaman.bak"
cp "$snapshot_script" "$yedek_dizini/pix2pi_service_snapshot.sh.$zaman.bak"
echo "OK ✅ yedekler alindi"

echo
echo "3) reporting_service mevcut durum kontrolu..."
if "$status_script" >/dev/null 2>&1; then
  reporting_durum="RUNNING"
else
  reporting_durum="STOPPED"
fi
echo "OK ✅ reporting_service durum: $reporting_durum"

echo
echo "4) service_status.json dogrudan guncelleniyor..."
python3 - "$json_dosya" "$reporting_durum" <<'PYEOF'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
reporting_status = sys.argv[2]

data = json.loads(json_path.read_text())

if "services" not in data or not isinstance(data.get("services"), dict):
    eski = {}
    for ad in ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "reporting_service", "nats", "redis", "nginx"]:
        if ad in data and isinstance(data[ad], dict):
            eski[ad] = data[ad]
    data["services"] = eski

for ad in ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "nats", "redis", "nginx"]:
    if ad in data["services"] and isinstance(data["services"][ad], str):
        data["services"][ad] = {"durum": data["services"][ad]}

if "reporting_service" not in data["services"] or not isinstance(data["services"]["reporting_service"], dict):
    data["services"]["reporting_service"] = {}

data["services"]["reporting_service"]["durum"] = reporting_status

kritikler = ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "reporting_service", "nats", "redis", "nginx"]
hepsi_ayakta = True

for ad in kritikler:
    servis = data["services"].get(ad, {})
    durum = str(servis.get("durum", "UNKNOWN")).upper()
    if durum not in ["RUNNING", "HEALTHY"]:
        hepsi_ayakta = False
        break

data["genel_durum"] = "Tum kritik servisler ayakta" if hepsi_ayakta else "Bazi servisler ayakta degil"

json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("OK ✅ json guncellendi")
PYEOF

echo
echo "5) Snapshot script bu json dosyasina sabitleniyor..."
if grep -q "REPORTING_JSON_FIX_V3" "$snapshot_script"; then
  echo "OK ✅ patch zaten var"
else
  cat <<'PATCHEOF' >> "$snapshot_script"

# REPORTING_JSON_FIX_V3
sabit_json_dosya="/opt/pix2pi/nginx/service_status.json"
reporting_status_value="STOPPED"
if /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
  reporting_status_value="RUNNING"
fi

if [ -f "$sabit_json_dosya" ]; then
  python3 - "$sabit_json_dosya" "$reporting_status_value" <<'PYEOF'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
reporting_status = sys.argv[2]

try:
    data = json.loads(json_path.read_text())
except Exception:
    sys.exit(0)

if "services" not in data or not isinstance(data.get("services"), dict):
    data["services"] = {}

if "reporting_service" not in data["services"] or not isinstance(data["services"]["reporting_service"], dict):
    data["services"]["reporting_service"] = {}

data["services"]["reporting_service"]["durum"] = reporting_status

kritikler = ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "reporting_service", "nats", "redis", "nginx"]
hepsi = True

for ad in kritikler:
    servis = data["services"].get(ad, {})
    durum = str(servis.get("durum", "UNKNOWN")).upper()
    if durum not in ["RUNNING", "HEALTHY"]:
        hepsi = False
        break

data["genel_durum"] = "Tum kritik servisler ayakta" if hepsi else "Bazi servisler ayakta degil"

json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
PYEOF
fi
# REPORTING_JSON_FIX_V3_END
PATCHEOF
  echo "OK ✅ snapshot script patch edildi"
fi

echo
echo "6) Snapshot yeniden calistiriliyor..."
"$snapshot_script" || true
echo "OK ✅ snapshot tetiklendi"

echo
echo "7) Son json kontrolu..."
cat "$json_dosya"

echo
echo "8) Nginx reload..."
nginx -t
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "9) Son durum..."
"$status_script" || true

echo
echo "OK ✅ reporting_service panel json dosyasina sabitlendi"
echo "OK ✅ paneli tam yenile"
