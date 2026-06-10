#!/bin/bash
set -u

PROJE_DIZINI="$HOME/pix2pi/pix2pi-SaaS"
RAPOR_DOSYASI="$PROJE_DIZINI/verify_done_report.txt"
DETAY_DOSYASI="$PROJE_DIZINI/verify_done_detail.txt"

TOPLAM=0
BASARILI=0
BASARISIZ=0
ATLANAN=0

: > "$RAPOR_DOSYASI"
: > "$DETAY_DOSYASI"

yaz() {
  echo "$1" | tee -a "$RAPOR_DOSYASI"
}

detay() {
  echo "$1" >> "$DETAY_DOSYASI"
}

calistir_test() {
  local dosya="$1"
  local ad
  ad="$(basename "$dosya")"

  TOPLAM=$((TOPLAM + 1))
  yaz ""
  yaz "=================================================="
  yaz "TEST: $ad"
  yaz "DOSYA: $dosya"
  yaz "--------------------------------------------------"

  chmod +x "$dosya" 2>/dev/null || true

  if bash "$dosya" >> "$DETAY_DOSYASI" 2>&1; then
    BASARILI=$((BASARILI + 1))
    yaz "SONUC: PASS ✅"
  else
    BASARISIZ=$((BASARISIZ + 1))
    yaz "SONUC: FAIL ❌"
    yaz "DETAY: verify_done_detail.txt icine yazildi"
  fi
}

atlanan_yaz() {
  local dosya="$1"
  ATLANAN=$((ATLANAN + 1))
  detay "ATLANDI: $dosya"
}

cd "$PROJE_DIZINI" || {
  echo "HATA: proje dizini bulunamadi: $PROJE_DIZINI"
  exit 1
}

yaz "Pix2pi dogrulama testi basladi"
yaz "Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
yaz "Proje: $PROJE_DIZINI"

yaz ""
yaz "1) Temel ortam kontrolleri"

if [ -d "$PROJE_DIZINI" ]; then
  yaz "OK ✅ proje dizini var"
else
  yaz "HATA ❌ proje dizini yok"
fi

if command -v docker >/dev/null 2>&1; then
  yaz "OK ✅ docker var"
else
  yaz "UYARI ⚠ docker yok"
fi

if command -v go >/dev/null 2>&1; then
  yaz "OK ✅ go var"
else
  yaz "UYARI ⚠ go yok"
fi

if command -v nginx >/dev/null 2>&1; then
  yaz "OK ✅ nginx var"
else
  yaz "UYARI ⚠ nginx yok"
fi

if command -v redis-cli >/dev/null 2>&1; then
  yaz "OK ✅ redis-cli var"
else
  yaz "UYARI ⚠ redis-cli yok"
fi

if command -v psql >/dev/null 2>&1; then
  yaz "OK ✅ psql var"
else
  yaz "UYARI ⚠ psql yok"
fi

yaz ""
yaz "2) Calistirilacak test scriptleri araniyor"

while IFS= read -r dosya; do
  ad="$(basename "$dosya")"

  case "$ad" in
    *install*|*backup*|*prepare*|*create*|*restart*|*reload*|*cleanup*|*fix*|*start*|*stop*)
      atlanan_yaz "$dosya"
      ;;
    *test*.sh|check_*files.sh|check_*runtime.sh|check_*env.sh|check_*login.sh|check_*health.sh|check_*source.sh|check_*names.sh|check_*ports.sh)
      calistir_test "$dosya"
      ;;
    *)
      atlanan_yaz "$dosya"
      ;;
  esac
done < <(find "$PROJE_DIZINI" -maxdepth 1 -type f -name "*.sh" | sort)

yaz ""
yaz "3) Ek dogrulama"

if docker ps >/dev/null 2>&1; then
  yaz ""
  yaz "Docker container durumu:"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | tee -a "$RAPOR_DOSYASI" >> "$DETAY_DOSYASI"
fi

if nginx -t >/dev/null 2>&1; then
  yaz "OK ✅ nginx config test basarili"
else
  yaz "FAIL ❌ nginx config test basarisiz"
fi

if [ -f "/etc/cron.d/pix2pi_service_status" ]; then
  yaz "OK ✅ service monitor cron dosyasi var"
else
  yaz "UYARI ⚠ service monitor cron dosyasi yok"
fi

if [ -f "/usr/local/bin/pix2pi_service_snapshot.sh" ]; then
  yaz "OK ✅ service snapshot scripti var"
else
  yaz "UYARI ⚠ service snapshot scripti yok"
fi

if curl -k -s --max-time 5 https://panel.pix2pi.com.tr >/dev/null 2>&1; then
  yaz "OK ✅ panel alan adi cevap veriyor"
else
  yaz "UYARI ⚠ panel alan adi dogrulanamadi"
fi

if curl -k -s --max-time 5 https://api.pix2pi.com.tr >/dev/null 2>&1; then
  yaz "OK ✅ api alan adi cevap veriyor"
else
  yaz "UYARI ⚠ api alan adi dogrulanamadi"
fi

yaz ""
yaz "4) Ozet"
yaz "Toplam test    : $TOPLAM"
yaz "Basarili       : $BASARILI"
yaz "Basarisiz      : $BASARISIZ"
yaz "Atlanan script : $ATLANAN"

if [ "$BASARISIZ" -eq 0 ]; then
  yaz "GENEL SONUC: PASS ✅"
else
  yaz "GENEL SONUC: FAIL ❌"
fi

yaz ""
yaz "Rapor dosyasi : $RAPOR_DOSYASI"
yaz "Detay dosyasi : $DETAY_DOSYASI"
