#!/bin/bash
set -e

PROJE_DIZINI="$HOME/pix2pi/pix2pi-SaaS"
YEDEK_DIZINI="$PROJE_DIZINI/_yedekler"
ZAMAN="$(date +%Y%m%d_%H%M%S)"

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
SNAPSHOT_SCRIPT="/usr/local/bin/pix2pi_service_snapshot.sh"

mkdir -p "$YEDEK_DIZINI"

echo "1) Temel dosya kontrolu..."
[ -f "$PANEL_HTML" ] || { echo "HATA ❌ panel html yok: $PANEL_HTML"; exit 1; }
[ -f "$SNAPSHOT_SCRIPT" ] || { echo "HATA ❌ snapshot script yok: $SNAPSHOT_SCRIPT"; exit 1; }
echo "OK ✅ panel html bulundu"
echo "OK ✅ snapshot script bulundu"

echo
echo "2) Yedek aliniyor..."
cp "$PANEL_HTML" "$YEDEK_DIZINI/panel_index.html.$ZAMAN.bak"
cp "$SNAPSHOT_SCRIPT" "$YEDEK_DIZINI/pix2pi_service_snapshot.sh.$ZAMAN.bak"
echo "OK ✅ yedekler alindi"

echo
echo "3) Panel veri kaynagi ipuclari..."
grep -nEi "fetch|json|status|monitor|health|server monitor|services|UNKNOWN|accounting_service|reporting_service" "$PANEL_HTML" || true

echo
echo "4) Nginx panel klasorunde ilgili dosyalar..."
find /opt/pix2pi/nginx -maxdepth 3 -type f \( -name "*.html" -o -name "*.js" -o -name "*.json" \) | sort

echo
echo "5) reporting_service / UNKNOWN gecen dosyalar..."
grep -RIn "reporting_service\|UNKNOWN\|accounting_service" /opt/pix2pi/nginx /usr/local/bin 2>/dev/null || true

echo
echo "6) En guncel service status json bulunuyor..."
EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
if [ -z "$EN_YENI_JSON" ]; then
  echo "HATA ❌ status json bulunamadi"
  exit 1
fi
cp "$EN_YENI_JSON" "$YEDEK_DIZINI/$(basename "$EN_YENI_JSON").$ZAMAN.bak"
echo "OK ✅ json bulundu: $EN_YENI_JSON"

echo
echo "7) Json icerigi (reporting/accounting farki)..."
python3 - "$EN_YENI_JSON" <<'PYEOF'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text())

print("JSON DOSYA:", p)

if isinstance(data, dict):
    print("\nUST SEVIYE ANAHTARLAR:")
    for k in data.keys():
        print("-", k)

    print("\nMUHTEMEL SERVIS ALANLARI:")
    if "services" in data and isinstance(data["services"], dict):
        for k, v in data["services"].items():
            if "service" in k or k in ["api_gateway", "identity", "auth", "nats", "redis", "nginx"]:
                print(f"services.{k} = {v}")

    for ad in ["reporting_service", "accounting_service", "stock_service", "api_gateway", "identity", "auth", "nats", "redis", "nginx"]:
        if ad in data:
            print(f"{ad} = {data[ad]}")
PYEOF

echo
echo "8) reporting_service status mapping snapshot scriptine ekleniyor..."
if grep -q "REPORTING_STATUS_FIX_V2" "$SNAPSHOT_SCRIPT"; then
  echo "OK ✅ patch zaten var"
else
  cat <<'PATCHEOF' >> "$SNAPSHOT_SCRIPT"

# REPORTING_STATUS_FIX_V2
reporting_status_value="UNKNOWN"
if /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
  reporting_status_value="RUNNING"
else
  reporting_status_value="STOPPED"
fi

en_yeni_json_fix="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
if [ -n "$en_yeni_json_fix" ] && [ -f "$en_yeni_json_fix" ]; then
  python3 - "$en_yeni_json_fix" "$reporting_status_value" <<'PYEOF'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
reporting_status = sys.argv[2]

try:
    data = json.loads(json_path.read_text())
except Exception:
    sys.exit(0)

if isinstance(data, dict):
    if "services" not in data or not isinstance(data.get("services"), dict):
        mevcut = {}
        for anahtar in ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "nats", "redis", "nginx", "reporting_service"]:
            if anahtar in data:
                mevcut[anahtar] = data[anahtar]
        data["services"] = mevcut

    data["services"]["reporting_service"] = reporting_status

    if "all_critical_services_up" in data:
        kritikler = ["api_gateway", "identity", "auth", "stock_service", "accounting_service", "reporting_service", "nats", "redis", "nginx"]
        hepsi = True
        for ad in kritikler:
            durum = str(data["services"].get(ad, "UNKNOWN")).upper()
            if durum not in ["RUNNING", "HEALTHY"]:
                hepsi = False
                break
        data["all_critical_services_up"] = hepsi

    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
PYEOF
fi
# REPORTING_STATUS_FIX_V2_END
PATCHEOF
  echo "OK ✅ snapshot script patch edildi"
fi

echo
echo "9) Snapshot yeniden tetikleniyor..."
"$SNAPSHOT_SCRIPT" || true
sleep 2
echo "OK ✅ snapshot tetiklendi"

echo
echo "10) Json tekrar kontrol ediliyor..."
python3 - "$EN_YENI_JSON" <<'PYEOF'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text())

print("JSON DOSYA:", p)
print("\nSERVISLER:")
if isinstance(data, dict):
    if "services" in data and isinstance(data["services"], dict):
        for k, v in data["services"].items():
            print(f"{k} = {v}")
    else:
        for k, v in data.items():
            if isinstance(v, (str, int, float, bool)):
                print(f"{k} = {v}")
PYEOF

echo
echo "11) Panelde reporting_service kontrolu..."
grep -RIn "reporting_service" /opt/pix2pi/nginx 2>/dev/null || true

echo
echo "12) Bitti"
echo "OK ✅ servis calisiyor mu: /usr/local/bin/pix2pi_reporting_service_status.sh"
echo "OK ✅ snapshot patch edildi"
echo "Simdi paneli tam kapat-ac ve tekrar bak"
