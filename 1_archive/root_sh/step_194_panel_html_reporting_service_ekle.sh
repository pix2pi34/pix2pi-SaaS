#!/bin/bash
set -e

panel_dosya="/opt/pix2pi/nginx/panel_index.html"
yedek_dizin="$HOME/pix2pi/pix2pi-SaaS/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

echo "1) Kontrol basliyor..."
mkdir -p "$yedek_dizin"

if [ ! -f "$panel_dosya" ]; then
  echo "HATA ❌ panel dosyasi yok: $panel_dosya"
  exit 1
fi
echo "OK ✅ panel dosyasi bulundu"

echo
echo "2) Yedek aliniyor..."
cp "$panel_dosya" "$yedek_dizin/panel_index.html.$zaman.bak"
echo "OK ✅ yedek alindi"

echo
echo "3) reporting_service zaten var mi kontrol ediliyor..."
if grep -q "reporting_service" "$panel_dosya"; then
  echo "OK ✅ reporting_service zaten panel dosyasinda var"
else
  python3 <<'PYEOF'
from pathlib import Path

dosya = Path("/opt/pix2pi/nginx/panel_index.html")
icerik = dosya.read_text(encoding="utf-8")

eski = """                <div class="service-card">
                    <strong>accounting_service</strong>
                    <span class="status running">RUNNING</span>
                </div>"""

yeni = """                <div class="service-card">
                    <strong>accounting_service</strong>
                    <span class="status running">RUNNING</span>
                </div>
                <div class="service-card">
                    <strong>reporting_service</strong>
                    <span class="status running">RUNNING</span>
                </div>"""

if eski in icerik:
    icerik = icerik.replace(eski, yeni, 1)
else:
    eski2 = "accounting_service"
    if eski2 in icerik and "reporting_service" not in icerik:
        icerik = icerik.replace(eski2, "accounting_service", 1)
        ek = """
                <div class="service-card">
                    <strong>reporting_service</strong>
                    <span class="status running">RUNNING</span>
                </div>"""
        marker = "</div>\n        </section>"
        if marker in icerik:
            icerik = icerik.replace(marker, ek + "\n" + marker, 1)

dosya.write_text(icerik, encoding="utf-8")
PYEOF
  echo "OK ✅ reporting_service panel dosyasina eklendi"
fi

echo
echo "4) Son kontrol..."
grep -n "reporting_service\|accounting_service" "$panel_dosya" || true

echo
echo "5) Nginx reload..."
nginx -t
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "6) Bitti"
echo "Paneli yenile ve reporting_service kutusunu kontrol et"
