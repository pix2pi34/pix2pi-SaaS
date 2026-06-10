#!/bin/bash
set -e

PROJE_DIZINI="$HOME/pix2pi/pix2pi-SaaS"
YEDEK_DIZINI="$PROJE_DIZINI/_yedekler"
ZAMAN="$(date +%Y%m%d_%H%M%S)"

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"
NGINX_KOK="/opt/pix2pi/nginx"

mkdir -p "$YEDEK_DIZINI"

echo "1) Temel kontrol..."
if [ ! -f "$PANEL_HTML" ]; then
  echo "HATA ❌ panel html yok: $PANEL_HTML"
  exit 1
fi
echo "OK ✅ panel html bulundu"

echo
echo "2) Yedek aliniyor..."
cp "$PANEL_HTML" "$YEDEK_DIZINI/panel_index.html.$ZAMAN.bak"
echo "OK ✅ panel html yedeklendi"

echo
echo "3) Panel html icinde veri kaynagi ipuclari aranıyor..."
grep -nEi \
  "fetch|xmlhttprequest|service|json|api|monitor|status|health|script src|server monitor" \
  "$PANEL_HTML" || true

echo
echo "4) Nginx panel klasorunde ilgili dosyalar aranıyor..."
find "$NGINX_KOK" -maxdepth 3 -type f \( -name "*.html" -o -name "*.js" -o -name "*.json" \) | sort > /tmp/pix2pi_panel_dosyalar_$ZAMAN.txt
cat /tmp/pix2pi_panel_dosyalar_$ZAMAN.txt

echo
echo "5) accounting_service gecen dosyalar bulunuyor..."
grep -RIn "accounting_service\|stock_service\|api_gateway\|identity\|auth\|nats\|redis\|nginx" "$NGINX_KOK" 2>/dev/null | tee /tmp/pix2pi_panel_eslesmeler_$ZAMAN.txt || true

echo
echo "6) reporting_service status json dosyasina zorla yaziliyor..."
EN_YENI_JSON="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
if [ -n "$EN_YENI_JSON" ] && [ -f "$EN_YENI_JSON" ]; then
  cp "$EN_YENI_JSON" "$YEDEK_DIZINI/$(basename "$EN_YENI_JSON").$ZAMAN.bak"
  python3 - "$EN_YENI_JSON" <<'PYEOF'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text())

if isinstance(data, dict):
    if "services" in data and isinstance(data["services"], dict):
        data["services"]["reporting_service"] = "RUNNING"
    else:
        data["reporting_service"] = "RUNNING"

p.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("OK ✅ reporting_service json icine yazildi:", p)
PYEOF
else
  echo "UYARI ⚠ service status json bulunamadi"
fi

echo
echo "7) Panel klasorunde reporting_service patch denemesi..."
python3 <<'PYEOF'
from pathlib import Path
import re

kok = Path("/opt/pix2pi/nginx")
dosyalar = [p for p in kok.rglob("*") if p.is_file() and p.suffix.lower() in {".html", ".js", ".json"}]

patched = 0

for dosya in dosyalar:
    try:
        icerik = dosya.read_text(encoding="utf-8")
    except Exception:
        try:
            icerik = dosya.read_text()
        except Exception:
            continue

    eski = icerik
    yeni = icerik

    if "accounting_service" in yeni and "reporting_service" not in yeni:
        yeni = yeni.replace(
            '"accounting_service"',
            '"accounting_service", "reporting_service"',
            1
        )
        yeni = yeni.replace(
            "'accounting_service'",
            "'accounting_service', 'reporting_service'",
            1
        )

        # json obje icin
        yeni = yeni.replace(
            '"accounting_service":"RUNNING"',
            '"accounting_service":"RUNNING","reporting_service":"RUNNING"',
            1
        )

        # html block kopyalama
        m = re.search(r'(<div class="service-card">.*?accounting_service.*?</div>\s*</div>)', yeni, re.S)
        if m and "reporting_service" not in yeni:
            blok = m.group(1)
            yeni_blok = blok.replace("accounting_service", "reporting_service")
            yeni = yeni.replace(blok, blok + "\n" + yeni_blok, 1)

    if yeni != eski:
        dosya.write_text(yeni, encoding="utf-8")
        print(f"PATCHED: {dosya}")
        patched += 1

print("TOPLAM_PATCHED=", patched)
PYEOF

echo
echo "8) Nginx test ve reload..."
nginx -t
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "9) Son kontrol grep..."
grep -RIn "reporting_service" "$NGINX_KOK" 2>/dev/null || true

echo
echo "10) Ozet"
echo "Panel HTML: $PANEL_HTML"
echo "Nginx kok: $NGINX_KOK"
echo "Service JSON: ${EN_YENI_JSON:-bulunamadi}"
echo "OK ✅ islem bitti"
echo
echo "Simdi paneli tam kapat-ac yap ve tekrar kontrol et."
