#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

manager_dosya="/usr/local/bin/pix2pi_service_manager.sh"

echo "1) Klasor hazirlaniyor..."
mkdir -p "$yedek_klasor"
echo "OK ✅ klasor hazir"

echo
echo "2) Manager dosyasi kontrol ediliyor..."
if [ ! -f "$manager_dosya" ]; then
  echo "HATA ❌ manager dosyasi yok: $manager_dosya"
  exit 1
fi
echo "OK ✅ manager dosyasi bulundu"

echo
echo "3) Yedek aliniyor..."
cp "$manager_dosya" "$yedek_klasor/pix2pi_service_manager.sh.$zaman.bak"
echo "OK ✅ yedek alindi"

echo
echo "4) panel-guncelle komutu ekleniyor..."
python3 <<'PYEOF'
from pathlib import Path

dosya = Path("/usr/local/bin/pix2pi_service_manager.sh")
icerik = dosya.read_text()

if "panel_guncelle()" in icerik:
    print("OK ✅ panel_guncelle zaten var")
    raise SystemExit

eklenecek_fonksiyon = r'''

panel_guncelle() {
  if [ ! -f "$liste_dosya" ]; then
    servis_listesini_guncelle
  fi

  echo "===== PANEL GUNCELLENIYOR ====="

  echo "1) Servis listesi yenileniyor..."
  servis_listesini_guncelle || true
  echo "OK ✅ servis listesi guncellendi"

  echo
  echo "2) Snapshot guncelleniyor..."
  if [ -x "$snapshot_script" ]; then
    "$snapshot_script" || true
    echo "OK ✅ snapshot guncellendi"
  else
    echo "UYARI ⚠ snapshot script yok"
  fi

  echo
  echo "3) Nginx test ediliyor..."
  if nginx -t; then
    echo "OK ✅ nginx test basarili"
  else
    echo "HATA ❌ nginx test basarisiz"
    exit 1
  fi

  echo
  echo "4) Nginx reload ediliyor..."
  systemctl reload nginx
  echo "OK ✅ nginx reload tamam"

  echo
  echo "5) Panel guncelleme tamamlandi"
}
'''

yardim_eski = """  pix2pi_service_manager.sh restart
  pix2pi_service_manager.sh durum"""

yardim_yeni = """  pix2pi_service_manager.sh restart
  pix2pi_service_manager.sh durum
  pix2pi_service_manager.sh panel-guncelle"""

icerik = icerik.replace(yardim_eski, yardim_yeni)

aciklama_eski = """  restart  : tum bulunan servisleri yeniden baslatir
  durum    : tum bulunan servislerin durumunu gosterir"""

aciklama_yeni = """  restart       : tum bulunan servisleri yeniden baslatir
  durum         : tum bulunan servislerin durumunu gosterir
  panel-guncelle: servis listesini yeniler, snapshot alir, nginx reload yapar"""

icerik = icerik.replace(aciklama_eski, aciklama_yeni)

hedef = """restart() {
  durdur
  sleep 2
  baslat
}

yardim() {"""

if hedef not in icerik:
    raise SystemExit("Fonksiyon ekleme noktasi bulunamadi")

icerik = icerik.replace(hedef, """restart() {
  durdur
  sleep 2
  baslat
}""" + eklenecek_fonksiyon + """

yardim() {""")

case_eski = """  restart)
    restart
    ;;
  durum)
    durum
    ;;
  *)
    yardim
    ;;"""

case_yeni = """  restart)
    restart
    ;;
  durum)
    durum
    ;;
  panel-guncelle)
    panel_guncelle
    ;;
  *)
    yardim
    ;;"""

icerik = icerik.replace(case_eski, case_yeni)

dosya.write_text(icerik)
print("OK ✅ panel_guncelle eklendi")
PYEOF

chmod +x "$manager_dosya"
echo "OK ✅ manager dosyasi guncellendi"

echo
echo "5) Hızlı test..."
"$manager_dosya" panel-guncelle

echo
echo "OK ✅ panel-guncelle komutu aktif"
echo
echo "KULLANIM"
echo "  /usr/local/bin/pix2pi_service_manager.sh panel-guncelle"
