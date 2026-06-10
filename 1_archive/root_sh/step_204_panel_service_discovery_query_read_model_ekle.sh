#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

panel_dosya="/opt/pix2pi/nginx/panel_index.html"
json_dosya="/opt/pix2pi/nginx/service_status.json"
snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"

service_discovery_status="/usr/local/bin/pix2pi_service_discovery_status.sh"
query_read_model_status="/usr/local/bin/pix2pi_query_read_model_status.sh"
reporting_status="/usr/local/bin/pix2pi_reporting_service_status.sh"

echo "1) Klasorler ve dosyalar kontrol ediliyor..."
mkdir -p "$yedek_klasor"

for f in "$panel_dosya" "$json_dosya" "$snapshot_script" "$service_discovery_status" "$query_read_model_status"; do
  if [ ! -f "$f" ]; then
    echo "HATA ❌ dosya bulunamadi: $f"
    exit 1
  fi
done
echo "OK ✅ gerekli dosyalar bulundu"

echo
echo "2) Yedekler aliniyor..."
cp "$panel_dosya" "$yedek_klasor/panel_index.html.$zaman.bak"
cp "$json_dosya" "$yedek_klasor/service_status.json.$zaman.bak"
cp "$snapshot_script" "$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"
echo "OK ✅ yedekler alindi"

echo
echo "3) Panel HTML yeniden yaziliyor..."
cat <<'HTML' > "$panel_dosya"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Pix2pi Admin Panel</title>
  <style>
    body{font-family:system-ui,Arial,sans-serif;max-width:980px;margin:40px auto;padding:0 16px;background:#f7f7f7;color:#111}
    .card{background:#fff;border:1px solid #ddd;border-radius:14px;padding:18px;margin:14px 0}
    h1,h2{margin-top:0}
    .ok{color:#0a7d32;font-weight:700}
    .warn{color:#b00020;font-weight:700}
    .muted{color:#666}
    a{color:#0a58ca;text-decoration:none}
    ul{padding-left:20px}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}
    .service{border:1px solid #e5e5e5;border-radius:12px;padding:12px;background:#fafafa}
    .service-name{font-weight:700;margin-bottom:6px}
  </style>
</head>
<body>
  <h1>Pix2pi Admin Panel</h1>

  <div class="card">
    <h2>Durum</h2>
    <div id="genelDurum">Yukleniyor...</div>
  </div>

  <div class="card">
    <h2>Servis Monitoru</h2>
    <div class="muted">Otomatik yenileme: 10 saniye</div>
    <p class="muted">Son guncelleme: <span id="guncellemeSaati">-</span></p>
    <div id="serviceGrid" class="grid"></div>
  </div>

  <div class="card">
    <h2>Hizli Baglantilar</h2>
    <ul>
      <li><a href="/health">Panel Health</a></li>
      <li><a href="/api/health">API Health</a></li>
      <li><a href="https://server.pix2pi.com.tr/containers/">Server Monitor</a></li>
    </ul>
  </div>

  <script>
    function durumClass(durum) {
      if (durum === "RUNNING" || durum === "HEALTHY") return "ok";
      return "warn";
    }

    function servisOku(data, key) {
      if (data && data.services && data.services[key]) {
        return data.services[key];
      }
      if (data && data[key]) {
        return data[key];
      }
      return { durum: "UNKNOWN" };
    }

    function normDurum(item) {
      if (!item) return "UNKNOWN";
      if (typeof item === "string") return item;
      if (item.durum) return item.durum;
      return "UNKNOWN";
    }

    async function yukle() {
      try {
        const res = await fetch("/service_status.json?_=" + Date.now());
        const data = await res.json();

        document.getElementById("guncellemeSaati").textContent =
          data.guncellendi || data.updated_at || "-";

        const grid = document.getElementById("serviceGrid");
        grid.innerHTML = "";

        const anahtarlar = [
          "api_gateway",
          "identity",
          "auth",
          "stock_service",
          "accounting_service",
          "reporting_service",
          "service_discovery",
          "query_read_model",
          "nats",
          "redis",
          "nginx"
        ];

        let saglikli = 0;

        anahtarlar.forEach(key => {
          const item = servisOku(data, key);
          const durum = normDurum(item);

          if (durum === "RUNNING" || durum === "HEALTHY") {
            saglikli++;
          }

          const div = document.createElement("div");
          div.className = "service";
          div.innerHTML = `
            <div class="service-name">${key}</div>
            <div class="${durumClass(durum)}">${durum}</div>
          `;
          grid.appendChild(div);
        });

        const genel = document.getElementById("genelDurum");
        if (saglikli === anahtarlar.length) {
          genel.innerHTML = '<span class="ok">Tum kritik servisler ayakta</span>';
        } else {
          genel.innerHTML = '<span class="warn">Bazi servisler ayakta degil</span>';
        }
      } catch (err) {
        document.getElementById("genelDurum").innerHTML =
          '<span class="warn">Servis durumu okunamadi</span>';
      }
    }

    yukle();
    setInterval(yukle, 10000);
  </script>
</body>
</html>
HTML
echo "OK ✅ panel html guncellendi"

echo
echo "4) Snapshot script patch ediliyor..."
if grep -q "QUERY_READ_AND_DISCOVERY_PATCH_V1" "$snapshot_script"; then
  echo "OK ✅ snapshot patch zaten var"
else
  cat <<'PATCHEOF' >> "$snapshot_script"

# QUERY_READ_AND_DISCOVERY_PATCH_V1
service_discovery_status_value="STOPPED"
query_read_model_status_value="STOPPED"
reporting_status_value="STOPPED"

if [ -x /usr/local/bin/pix2pi_service_discovery_status.sh ] && /usr/local/bin/pix2pi_service_discovery_status.sh >/dev/null 2>&1; then
  service_discovery_status_value="RUNNING"
fi

if [ -x /usr/local/bin/pix2pi_query_read_model_status.sh ] && /usr/local/bin/pix2pi_query_read_model_status.sh >/dev/null 2>&1; then
  query_read_model_status_value="RUNNING"
fi

if [ -x /usr/local/bin/pix2pi_reporting_service_status.sh ] && /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
  reporting_status_value="RUNNING"
fi

sabit_json_dosya="/opt/pix2pi/nginx/service_status.json"
if [ -f "$sabit_json_dosya" ]; then
  python3 - "$sabit_json_dosya" "$reporting_status_value" "$service_discovery_status_value" "$query_read_model_status_value" <<'PYEOF'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
reporting_status = sys.argv[2]
service_discovery_status = sys.argv[3]
query_read_model_status = sys.argv[4]

try:
    data = json.loads(json_path.read_text())
except Exception:
    sys.exit(0)

if "services" not in data or not isinstance(data.get("services"), dict):
    services = {}
    for ad in [
        "api_gateway","identity","auth","stock_service","accounting_service",
        "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
    ]:
        if ad in data and isinstance(data[ad], dict):
            services[ad] = data[ad]
    data["services"] = services

for ad in [
    "api_gateway","identity","auth","stock_service","accounting_service",
    "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
]:
    if ad not in data["services"] or not isinstance(data["services"][ad], dict):
        data["services"][ad] = {"durum": "UNKNOWN"}

data["services"]["reporting_service"]["durum"] = reporting_status
data["services"]["service_discovery"]["durum"] = service_discovery_status
data["services"]["query_read_model"]["durum"] = query_read_model_status

kritikler = [
    "api_gateway","identity","auth","stock_service","accounting_service",
    "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
]

hepsi = True
for ad in kritikler:
    durum = str(data["services"].get(ad, {}).get("durum", "UNKNOWN")).upper()
    if durum not in ["RUNNING", "HEALTHY"]:
        hepsi = False
        break

data["genel_durum"] = "Tum kritik servisler ayakta" if hepsi else "Bazi servisler ayakta degil"

json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
PYEOF
fi
# QUERY_READ_AND_DISCOVERY_PATCH_V1_END
PATCHEOF
  echo "OK ✅ snapshot patch eklendi"
fi

echo
echo "5) service_status.json dogrudan guncelleniyor..."
reporting_durum="STOPPED"
service_discovery_durum="STOPPED"
query_read_model_durum="STOPPED"

if "$reporting_status" >/dev/null 2>&1; then
  reporting_durum="RUNNING"
fi
if "$service_discovery_status" >/dev/null 2>&1; then
  service_discovery_durum="RUNNING"
fi
if "$query_read_model_status" >/dev/null 2>&1; then
  query_read_model_durum="RUNNING"
fi

python3 - "$json_dosya" "$reporting_durum" "$service_discovery_durum" "$query_read_model_durum" <<'PYEOF'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
reporting_status = sys.argv[2]
service_discovery_status = sys.argv[3]
query_read_model_status = sys.argv[4]

data = json.loads(json_path.read_text())

if "services" not in data or not isinstance(data.get("services"), dict):
    services = {}
    for ad in [
        "api_gateway","identity","auth","stock_service","accounting_service",
        "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
    ]:
        if ad in data and isinstance(data[ad], dict):
            services[ad] = data[ad]
    data["services"] = services

for ad in [
    "api_gateway","identity","auth","stock_service","accounting_service",
    "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
]:
    if ad not in data["services"] or not isinstance(data["services"][ad], dict):
        data["services"][ad] = {"durum": "UNKNOWN"}

data["services"]["reporting_service"]["durum"] = reporting_status
data["services"]["service_discovery"]["durum"] = service_discovery_status
data["services"]["query_read_model"]["durum"] = query_read_model_status

kritikler = [
    "api_gateway","identity","auth","stock_service","accounting_service",
    "reporting_service","service_discovery","query_read_model","nats","redis","nginx"
]

hepsi = True
for ad in kritikler:
    durum = str(data["services"].get(ad, {}).get("durum", "UNKNOWN")).upper()
    if durum not in ["RUNNING", "HEALTHY"]:
        hepsi = False
        break

data["genel_durum"] = "Tum kritik servisler ayakta" if hepsi else "Bazi servisler ayakta degil"

json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("OK ✅ json guncellendi")
PYEOF

echo
echo "6) Snapshot tetikleniyor..."
"$snapshot_script" || true
echo "OK ✅ snapshot tetiklendi"

echo
echo "7) Nginx test ve reload..."
nginx -t
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "8) Son kontrol..."
echo "--- SERVICE STATUS JSON ---"
cat "$json_dosya"
echo
echo "--- PANEL HTML grep ---"
grep -n "service_discovery\|query_read_model\|reporting_service" "$panel_dosya" || true

echo
echo "OK ✅ panel servisleri guncellendi"
echo "OK ✅ paneli yenile ve 10-15 saniye bekle"
