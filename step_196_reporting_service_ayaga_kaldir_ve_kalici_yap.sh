#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_dizini="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

binary_dosya="/usr/local/bin/pix2pi_reporting_service_bin"
start_script="/usr/local/bin/pix2pi_reporting_service_start.sh"
stop_script="/usr/local/bin/pix2pi_reporting_service_stop.sh"
status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
ensure_script="/usr/local/bin/pix2pi_reporting_service_ensure.sh"
cron_dosya="/etc/cron.d/pix2pi_reporting_service"

log_dosya="/tmp/pix2pi_reporting_service.log"
pid_dosya="/tmp/pix2pi_reporting_service.pid"

echo "1) Klasor ve yedek hazirlaniyor..."
mkdir -p "$yedek_dizini"
echo "OK ✅ klasor hazir"

echo
echo "2) Mevcut dosyalar yedekleniyor..."
for f in "$start_script" "$stop_script" "$status_script" "$ensure_script" "$cron_dosya"; do
  if [ -f "$f" ]; then
    cp "$f" "$yedek_dizini/$(basename "$f").$zaman.bak"
    echo "OK ✅ yedek alindi: $f"
  fi
done

echo
echo "3) Binary kontrol ediliyor..."
if [ ! -f "$binary_dosya" ]; then
  echo "HATA ❌ binary yok: $binary_dosya"
  echo "Once reporting service build edilmis olmali"
  exit 1
fi
chmod +x "$binary_dosya"
echo "OK ✅ binary bulundu"

echo
echo "4) Start script yeniden yaziliyor..."
cat <<STARTEOF > "$start_script"
#!/bin/bash
set -e

binary_dosya="/usr/local/bin/pix2pi_reporting_service_bin"
log_dosya="/tmp/pix2pi_reporting_service.log"
pid_dosya="/tmp/pix2pi_reporting_service.pid"

if [ -f "\$pid_dosya" ]; then
  pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
    echo "OK ✅ reporting_service zaten calisiyor | pid=\$pid"
    exit 0
  fi
fi

nohup "\$binary_dosya" >> "\$log_dosya" 2>&1 &
yeni_pid=\$!
echo "\$yeni_pid" > "\$pid_dosya"
sleep 2

if kill -0 "\$yeni_pid" 2>/dev/null; then
  echo "OK ✅ reporting_service baslatildi | pid=\$yeni_pid"
else
  echo "HATA ❌ reporting_service baslatilamadi"
  exit 1
fi
STARTEOF

echo
echo "5) Stop script yeniden yaziliyor..."
cat <<STOPEOF > "$stop_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_reporting_service.pid"

if [ ! -f "\$pid_dosya" ]; then
  echo "OK ✅ reporting_service zaten kapali"
  exit 0
fi

pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
  kill "\$pid"
  sleep 1
  echo "OK ✅ reporting_service durduruldu | pid=\$pid"
else
  echo "OK ✅ process zaten calismiyordu"
fi

rm -f "\$pid_dosya"
STOPEOF

echo
echo "6) Status script yeniden yaziliyor..."
cat <<STATUSEOF > "$status_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_reporting_service.pid"
log_dosya="/tmp/pix2pi_reporting_service.log"

if [ -f "\$pid_dosya" ]; then
  pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
    echo "RUNNING pid=\$pid"
    echo "LOG: \$log_dosya"
    exit 0
  fi
fi

echo "STOPPED"
echo "LOG: \$log_dosya"
exit 1
STATUSEOF

echo
echo "7) Ensure script yaziliyor..."
cat <<ENSUREEOF > "$ensure_script"
#!/bin/bash
set -e

start_script="/usr/local/bin/pix2pi_reporting_service_start.sh"
status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"

if "\$status_script" >/dev/null 2>&1; then
  echo "OK ✅ reporting_service zaten ayakta"
  exit 0
fi

"\$start_script"
echo "OK ✅ reporting_service yeniden ayaga kaldirildi"
ENSUREEOF

chmod +x "$start_script" "$stop_script" "$status_script" "$ensure_script"
echo "OK ✅ start / stop / status / ensure scriptleri hazir"

echo
echo "8) Cron watchdog yaziliyor..."
cat <<CRONEOF > "$cron_dosya"
* * * * * root /usr/local/bin/pix2pi_reporting_service_ensure.sh >> /tmp/pix2pi_reporting_service_watchdog.log 2>&1
CRONEOF
chmod 644 "$cron_dosya"
systemctl restart cron
echo "OK ✅ cron watchdog aktif"

echo
echo "9) Eski process temizleniyor..."
"$stop_script" || true
echo "OK ✅ eski process temizligi tamam"

echo
echo "10) Reporting service baslatiliyor..."
"$start_script"

echo
echo "11) Son durum kontrolu..."
"$status_script"

echo
echo "12) Log kontrolu..."
sleep 2
tail -n 20 "$log_dosya" || true

echo
echo "13) Watchdog log kontrolu..."
sleep 1
tail -n 10 /tmp/pix2pi_reporting_service_watchdog.log 2>/dev/null || true

echo
echo "OK ✅ reporting_service arka planda aktif"
echo "OK ✅ duserse cron watchdog yeniden kaldiracak"
echo
echo "KULLANIM"
echo "Baslat : $start_script"
echo "Durdur : $stop_script"
echo "Durum  : $status_script"
echo "Ensure : $ensure_script"
