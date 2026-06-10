#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_dizini="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$yedek_dizini"

echo "1) Arama kok dizinleri hazirlaniyor..."
arama_dizinleri=(
  "$proje_dizini"
  "/var/www"
  "/usr/share/nginx/html"
  "/srv"
  "/opt"
  "/root"
)
echo "OK ✅ arama dizinleri hazir"

echo
echo "2) Panele ait aday dosyalar araniyor..."
aday_liste="/tmp/pix2pi_panel_adaylari_$zaman.txt"
: > "$aday_liste"

for dizin in "${arama_dizinleri[@]}"; do
  [ -d "$dizin" ] || continue

  grep -RIl \
    -e "Pix2pi Admin Panel" \
    -e "Servis Monitoru" \
    -e "Tum kritik servisler ayakta" \
    -e "Panel Health" \
    -e "accounting_service" \
    -e "stock_service" \
    -e "api_gateway" \
    "$dizin" 2>/dev/null | \
  grep -E '\.(html|js|json|go|ts|tsx|jsx|tmpl|tpl)$' >> "$aday_liste" || true
done

sort -u "$aday_liste" -o "$aday_liste"

if [ ! -s "$aday_liste" ]; then
  echo "HATA ❌ panele ait aday dosya bulunamadi"
  echo
  echo "3) Nginx root bilgisi cikariliyor..."
  nginx -T 2>/dev/null | grep -nE "root |server_name|listen " || true
  exit 1
fi

echo "OK ✅ aday dosyalar bulundu"
cat "$aday_liste"

echo
echo "3) Aday dosyalar yedekleniyor..."
while IFS= read -r dosya; do
  [ -n "$dosya" ] || continue
  cp "$dosya" "$yedek_dizini/$(basename "$dosya").$zaman.bak"
  echo "OK ✅ yedek alindi: $dosya"
done < "$aday_liste"

echo
echo "4) reporting_service ekleme patch islemi..."
python3 - "$aday_liste" <<'PYEOF'
import re
import sys
from pathlib import Path

liste_dosyasi = Path(sys.argv[1])
dosyalar = [Path(x.strip()) for x in liste_dosyasi.read_text().splitlines() if x.strip()]

def patch_text(text: str):
    degisti = False
    yeni = text

    # JS/TS/JSON listeye ekleme
    for eski, yeni_parca in [
        ('"accounting_service",', '"accounting_service",\n    "reporting_service",'),
        ("'accounting_service',", "'accounting_service',\n    'reporting_service',"),
        ('`accounting_service`,', '`accounting_service`,\n    `reporting_service`,'),
    ]:
        if eski in yeni and "reporting_service" not in yeni:
            yeni = yeni.replace(eski, yeni_parca, 1)
            degisti = True

    # Duz obje alanina ekleme
    if '"accounting_service"' in yeni and '"reporting_service"' not in yeni and ":" in yeni:
        yeni2 = yeni.replace(
            '"accounting_service":',
            '"reporting_service":"RUNNING",\n  "accounting_service":',
            1
        )
        if yeni2 != yeni:
            yeni = yeni2
            degisti = True

    # HTML kart kopyalama
    if "reporting_service" not in yeni and "accounting_service" in yeni:
        m = re.search(r'(<[^>]+>[^<]*accounting_service[^<]*</[^>]+>)', yeni, re.IGNORECASE)
        if m:
            blok = m.group(1)
            yeni_blok = blok.replace("accounting_service", "reporting_service")
            yeni = yeni.replace(blok, blok + "\n" + yeni_blok, 1)
            degisti = True

    # Daha genel string tabanli yedek patch
    if "reporting_service" not in yeni and "accounting_service" in yeni:
        yeni2 = yeni.replace("accounting_service", "accounting_service reporting_service", 1)
        if yeni2 != yeni:
            yeni = yeni2
            degisti = True

    return yeni, degisti

toplam = 0
for dosya in dosyalar:
    try:
        icerik = dosya.read_text(encoding="utf-8")
    except Exception:
        try:
            icerik = dosya.read_text()
        except Exception:
            print(f"SKIP: {dosya}")
            continue

    yeni_icerik, degisti = patch_text(icerik)
    if degisti:
        dosya.write_text(yeni_icerik, encoding="utf-8")
        print(f"PATCHED: {dosya}")
        toplam += 1
    else:
        print(f"SKIP: {dosya}")

print(f"TOPLAM_PATCHED={toplam}")
PYEOF

echo
echo "5) reporting_service geciyor mu kontrol..."
while IFS= read -r dosya; do
  [ -n "$dosya" ] || continue
  grep -n "reporting_service" "$dosya" 2>/dev/null || true
done < "$aday_liste"

echo
echo "6) Nginx html root ve panel dosya ipuclari..."
nginx -T 2>/dev/null | grep -nE "root |index |server_name|location " || true

echo
echo "7) Kisa sonuc..."
echo "Aday dosya listesi: $aday_liste"
echo "Yedekler: $yedek_dizini"
echo "OK ✅ islem bitti"
echo "Simdi paneli yenile ve sonucu kontrol et"
