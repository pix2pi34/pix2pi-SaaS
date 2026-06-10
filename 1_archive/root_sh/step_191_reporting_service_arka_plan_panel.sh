#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
hedef_klasor="$proje_dizini/cmd/reporting-service"
hedef_dosya="$hedef_klasor/reporting_service_main.go"

yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

binary_dosya="/usr/local/bin/pix2pi_reporting_service_bin"
start_script="/usr/local/bin/pix2pi_reporting_service_start.sh"
stop_script="/usr/local/bin/pix2pi_reporting_service_stop.sh"
status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
log_dosya="/tmp/pix2pi_reporting_service.log"
pid_dosya="/tmp/pix2pi_reporting_service.pid"

snapshot_script="/usr/local/bin/pix2pi_service_snapshot.sh"
snapshot_yedek="$yedek_klasor/pix2pi_service_snapshot.sh.$zaman.bak"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$hedef_klasor"
mkdir -p "$yedek_klasor"
echo "OK ✅ klasorler hazir"

echo
echo "2) Yedekler aliniyor..."
if [ -f "$hedef_dosya" ]; then
  cp "$hedef_dosya" "$yedek_klasor/reporting_service_main.go.$zaman.bak"
  echo "OK ✅ reporting_service_main.go yedegi alindi"
else
  echo "OK ✅ onceki reporting_service_main.go yok"
fi

if [ -f "$snapshot_script" ]; then
  cp "$snapshot_script" "$snapshot_yedek"
  echo "OK ✅ pix2pi_service_snapshot.sh yedegi alindi"
else
  echo "OK ✅ snapshot script bulunamadi, patch adimi kontrollu gececek"
fi

echo
echo "3) Reporting service kodu yaziliyor..."
cat <<'GOEOF' > "$hedef_dosya"
package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/nats-io/nats.go"
)

type Event struct {
	Type string                 `json:"type"`
	Data map[string]interface{} `json:"data"`
}

func main() {
	nc, err := nats.Connect("nats://localhost:4222")
	if err != nil {
		log.Fatalf("NATS baglanti hatasi: %v", err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		log.Fatalf("JetStream erisim hatasi: %v", err)
	}

	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
		var e Event

		if err := json.Unmarshal(msg.Data, &e); err != nil {
			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
			if ackErr := msg.Ack(); ackErr != nil {
				log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
			}
			return
		}

		fmt.Printf("REPORT EVENT | subject=%s | type=%s\n", msg.Subject, e.Type)

		if ackErr := msg.Ack(); ackErr != nil {
			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
		}
	},
		nats.Durable("reporting_service"),
		nats.ManualAck(),
	)
	if err != nil {
		log.Fatalf("Subscribe hatasi: %v", err)
	}

	fmt.Println("OK ✅ Reporting subscriber started")

	select {}
}
GOEOF
echo "OK ✅ reporting service kodu yazildi"

echo
echo "4) Binary build yapiliyor..."
cd "$proje_dizini"
go build -o "$binary_dosya" ./cmd/reporting-service
chmod +x "$binary_dosya"
echo "OK ✅ binary hazir: $binary_dosya"

echo
echo "5) Start / stop / status scriptleri yaziliyor..."
cat <<STARTEOF > "$start_script"
#!/bin/bash
set -e

binary_dosya="$binary_dosya"
log_dosya="$log_dosya"
pid_dosya="$pid_dosya"

if [ -f "\$pid_dosya" ]; then
  eski_pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$eski_pid" ] && kill -0 "\$eski_pid" 2>/dev/null; then
    echo "OK ✅ reporting_service zaten calisiyor | pid=\$eski_pid"
    exit 0
  fi
fi

nohup "\$binary_dosya" >> "\$log_dosya" 2>&1 &
yeni_pid=\$!
echo "\$yeni_pid" > "\$pid_dosya"
sleep 2

if kill -0 "\$yeni_pid" 2>/dev/null; then
  echo "OK ✅ reporting_service arka planda calisiyor | pid=\$yeni_pid"
else
  echo "HATA ❌ reporting_service baslamadi"
  exit 1
fi
STARTEOF

cat <<STOPEOF > "$stop_script"
#!/bin/bash
set -e

pid_dosya="$pid_dosya"

if [ ! -f "\$pid_dosya" ]; then
  echo "OK ✅ pid dosyasi yok, servis zaten kapali"
  exit 0
fi

pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
if [ -z "\$pid" ]; then
  rm -f "\$pid_dosya"
  echo "OK ✅ bos pid dosyasi temizlendi"
  exit 0
fi

if kill -0 "\$pid" 2>/dev/null; then
  kill "\$pid"
  sleep 1
  echo "OK ✅ reporting_service durduruldu | pid=\$pid"
else
  echo "OK ✅ process zaten calismiyordu | pid=\$pid"
fi

rm -f "\$pid_dosya"
STOPEOF

cat <<STATUSEOF > "$status_script"
#!/bin/bash
set -e

pid_dosya="$pid_dosya"
log_dosya="$log_dosya"

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

chmod +x "$start_script" "$stop_script" "$status_script"
echo "OK ✅ start / stop / status scriptleri hazir"

echo
echo "6) Eski reporting_service varsa kapatiliyor..."
"$stop_script" || true
echo "OK ✅ eski process temizligi tamam"

echo
echo "7) Yeni reporting_service arka planda baslatiliyor..."
"$start_script"

echo
echo "8) Calisma kontrolu yapiliyor..."
"$status_script"
sleep 2

if grep -q "Reporting subscriber started" "$log_dosya" 2>/dev/null; then
  echo "OK ✅ log icinde baslama mesaji bulundu"
else
  echo "UYARI ⚠ log icinde baslama mesaji henuz gorunmedi"
fi

echo
echo "9) Snapshot script reporting_service ile patch ediliyor..."
if [ -f "$snapshot_script" ]; then
  if grep -q "REPORTING_SERVICE_PATCH_V1" "$snapshot_script"; then
    echo "OK ✅ snapshot script daha once patch edilmis"
  else
    cat <<'PATCHEOF' >> "$snapshot_script"

# REPORTING_SERVICE_PATCH_V1
reporting_pid_file="/tmp/pix2pi_reporting_service.pid"
reporting_log_file="/tmp/pix2pi_reporting_service.log"

reporting_status="STOPPED"
if [ -f "$reporting_pid_file" ]; then
  reporting_pid="$(cat "$reporting_pid_file" 2>/dev/null || true)"
  if [ -n "$reporting_pid" ] && kill -0 "$reporting_pid" 2>/dev/null; then
    reporting_status="RUNNING"
  fi
fi

en_yeni_json="$(ls -1t /tmp/pix2pi*service*.json /tmp/*snapshot*.json 2>/dev/null | head -n 1 || true)"
if [ -n "$en_yeni_json" ] && [ -f "$en_yeni_json" ]; then
  python3 - "$en_yeni_json" "$reporting_status" <<'PYEOF'
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
    if "services" in data and isinstance(data["services"], dict):
        data["services"]["reporting_service"] = reporting_status
    else:
        data["reporting_service"] = reporting_status

    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
PYEOF
fi
# REPORTING_SERVICE_PATCH_V1_END
PATCHEOF
    echo "OK ✅ snapshot script patch edildi"
  fi

  echo
  echo "10) Snapshot script bir kez calistiriliyor..."
  "$snapshot_script" || true
  echo "OK ✅ snapshot tetiklendi"
else
  echo "UYARI ⚠ snapshot script bulunamadi, panel entegrasyonu bu adimda atlandi"
fi

echo
echo "11) Son durum kontrolu..."
"$status_script" || true

echo
echo "12) Son 20 log satiri..."
tail -n 20 "$log_dosya" || true

echo
echo "OK ✅ reporting_service arka planda kuruldu"
echo "OK ✅ panel snapshot entegrasyonu denendi"
echo
echo "KULLANIM:"
echo "  Baslat : $start_script"
echo "  Durdur : $stop_script"
echo "  Durum  : $status_script"
echo
echo "Panelde 10-15 saniye sonra reporting_service gorunmesi beklenir."
