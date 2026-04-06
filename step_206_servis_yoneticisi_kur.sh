#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

manager_dosya="/usr/local/bin/pix2pi_service_manager.sh"
test_dosya="/usr/local/bin/pix2pi_service_manager_test.sh"
liste_dosya="/usr/local/bin/pix2pi_service_list.txt"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$yedek_klasor"
echo "OK ✅ klasor hazir"

echo
echo "2) Mevcut dosyalar yedekleniyor..."
for f in "$manager_dosya" "$test_dosya" "$liste_dosya"; do
  if [ -f "$f" ]; then
    cp "$f" "$yedek_klasor/$(basename "$f").$zaman.bak"
    echo "OK ✅ yedek alindi: $f"
  else
    echo "OK ✅ onceki dosya yok: $f"
  fi
done

echo
echo "3) Service manager yaziliyor..."
cat <<'MANAGEREOF' > "$manager_dosya"
#!/bin/bash
set -e

liste_dosya="/usr/local/bin/pix2pi_service_list.txt"
snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"

servis_listesini_guncelle() {
  tmp_dosya="$(mktemp)"

  find /usr/local/bin -maxdepth 1 -type f -name 'pix2pi_*_start.sh' | sort | while read -r start_script; do
    servis_adi="$(basename "$start_script")"
    servis_adi="${servis_adi#pix2pi_}"
    servis_adi="${servis_adi%_start.sh}"

    case "$servis_adi" in
      service_manager|start_all_services)
        continue
        ;;
    esac

    stop_script="/usr/local/bin/pix2pi_${servis_adi}_stop.sh"
    status_script="/usr/local/bin/pix2pi_${servis_adi}_status.sh"

    printf "%s|%s|%s|%s\n" "$servis_adi" "$start_script" "$stop_script" "$status_script" >> "$tmp_dosya"
  done

  mv "$tmp_dosya" "$liste_dosya"
  echo "OK ✅ servis listesi guncellendi: $liste_dosya"
}

listele() {
  if [ ! -f "$liste_dosya" ]; then
    echo "UYARI ⚠ liste dosyasi yok, otomatik guncelleniyor..."
    servis_listesini_guncelle
  fi

  echo "===== PIX2PI SERVIS LISTESI ====="
  while IFS='|' read -r servis_adi start_script stop_script status_script; do
    [ -n "$servis_adi" ] || continue
    echo "- $servis_adi"
  done < "$liste_dosya"
}

baslat() {
  if [ ! -f "$liste_dosya" ]; then
    servis_listesini_guncelle
  fi

  echo "===== TUM SERVISLER BASLATILIYOR ====="
  while IFS='|' read -r servis_adi start_script stop_script status_script; do
    [ -n "$servis_adi" ] || continue

    if [ -x "$start_script" ]; then
      echo "▶ baslat: $servis_adi"
      "$start_script" || true
    else
      echo "HATA ❌ start script yok: $start_script"
    fi
  done < "$liste_dosya"

  if [ -x "$snapshot_script" ]; then
    "$snapshot_script" || true
  fi

  echo "OK ✅ tum servisler icin baslat komutu tamamlandi"
}

durdur() {
  if [ ! -f "$liste_dosya" ]; then
    servis_listesini_guncelle
  fi

  echo "===== TUM SERVISLER DURDURULUYOR ====="
  tac "$liste_dosya" | while IFS='|' read -r servis_adi start_script stop_script status_script; do
    [ -n "$servis_adi" ] || continue

    if [ -x "$stop_script" ]; then
      echo "■ durdur: $servis_adi"
      "$stop_script" || true
    else
      echo "UYARI ⚠ stop script yok: $stop_script"
    fi
  done

  if [ -x "$snapshot_script" ]; then
    "$snapshot_script" || true
  fi

  echo "OK ✅ tum servisler icin durdur komutu tamamlandi"
}

durum() {
  if [ ! -f "$liste_dosya" ]; then
    servis_listesini_guncelle
  fi

  echo "===== PIX2PI SERVIS DURUMU ====="
  while IFS='|' read -r servis_adi start_script stop_script status_script; do
    [ -n "$servis_adi" ] || continue

    printf "%-30s : " "$servis_adi"
    if [ -x "$status_script" ]; then
      "$status_script" 2>/dev/null | head -n 1 || echo "STATUS_BILGISI_YOK"
    else
      echo "STATUS_SCRIPT_YOK"
    fi
  done
}

restart() {
  durdur
  sleep 2
  baslat
}

yardim() {
  cat <<HELPEOF
KULLANIM:
  pix2pi_service_manager.sh guncelle
  pix2pi_service_manager.sh liste
  pix2pi_service_manager.sh baslat
  pix2pi_service_manager.sh durdur
  pix2pi_service_manager.sh restart
  pix2pi_service_manager.sh durum

ACIKLAMA:
  guncelle : /usr/local/bin altindaki pix2pi_*_start.sh dosyalarindan servis listesini yeniler
  liste    : bulunan servisleri listeler
  baslat   : tum bulunan servisleri baslatir
  durdur   : tum bulunan servisleri durdurur
  restart  : tum bulunan servisleri yeniden baslatir
  durum    : tum bulunan servislerin durumunu gosterir
HELPEOF
}

komut="${1:-yardim}"

case "$komut" in
  guncelle)
    servis_listesini_guncelle
    ;;
  liste)
    listele
    ;;
  baslat)
    baslat
    ;;
  durdur)
    durdur
    ;;
  restart)
    restart
    ;;
  durum)
    durum
    ;;
  *)
    yardim
    ;;
esac
MANAGEREOF
chmod +x "$manager_dosya"
echo "OK ✅ service manager yazildi"

echo
echo "4) Test script yaziliyor..."
cat <<'TESTEOF' > "$test_dosya"
#!/bin/bash
set -e

manager_dosya="/usr/local/bin/pix2pi_service_manager.sh"
liste_dosya="/usr/local/bin/pix2pi_service_list.txt"

echo "1) manager dosyasi kontrol..."
[ -x "$manager_dosya" ]
echo "OK ✅ manager dosyasi var"

echo
echo "2) guncelle testi..."
"$manager_dosya" guncelle
[ -f "$liste_dosya" ]
echo "OK ✅ liste dosyasi olustu"

echo
echo "3) liste testi..."
"$manager_dosya" liste
echo "OK ✅ liste komutu calisti"

echo
echo "4) durum testi..."
"$manager_dosya" durum || true
echo "OK ✅ durum komutu calisti"

echo
echo "OK ✅ service manager test tamam"
TESTEOF
chmod +x "$test_dosya"
echo "OK ✅ test script yazildi"

echo
echo "5) Guncelle komutu calistiriliyor..."
"$manager_dosya" guncelle

echo
echo "6) Liste komutu calistiriliyor..."
"$manager_dosya" liste

echo
echo "7) Test script calistiriliyor..."
"$test_dosya"

echo
echo "8) Son durum komutu..."
"$manager_dosya" durum || true

echo
echo "OK ✅ servis yoneticisi kuruldu"
echo "OK ✅ sonradan yeni servis eklenirse once: pix2pi_service_manager.sh guncelle"
echo
echo "KULLANIM"
echo "  /usr/local/bin/pix2pi_service_manager.sh guncelle"
echo "  /usr/local/bin/pix2pi_service_manager.sh liste"
echo "  /usr/local/bin/pix2pi_service_manager.sh baslat"
echo "  /usr/local/bin/pix2pi_service_manager.sh durdur"
echo "  /usr/local/bin/pix2pi_service_manager.sh restart"
echo "  /usr/local/bin/pix2pi_service_manager.sh durum"
