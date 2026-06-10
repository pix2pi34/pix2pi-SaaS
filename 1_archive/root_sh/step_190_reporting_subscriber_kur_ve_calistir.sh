#!/bin/bash
set -e

PROJE_DIZINI="$HOME/pix2pi/pix2pi-SaaS"
HEDEF_KLASOR="$PROJE_DIZINI/cmd/reporting-service"
HEDEF_DOSYA="$HEDEF_KLASOR/reporting_service_main.go"
YEDEK_KLASOR="$PROJE_DIZINI/_yedekler"
TARIH="$(date +%Y%m%d_%H%M%S)"
YEDEK_DOSYA="$YEDEK_KLASOR/reporting_service_main.go.$TARIH.bak"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$HEDEF_KLASOR"
mkdir -p "$YEDEK_KLASOR"
echo "OK ✅ klasorler hazir"

if [ -f "$HEDEF_DOSYA" ]; then
  cp "$HEDEF_DOSYA" "$YEDEK_DOSYA"
  echo "OK ✅ yedek alindi: $YEDEK_DOSYA"
else
  echo "OK ✅ onceki dosya yok, yeni dosya yazilacak"
fi

echo
echo "2) Reporting subscriber dosyasi yaziliyor..."

cat <<'GOEOF' > "$HEDEF_DOSYA"
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"

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

	olasiSubjectler := []string{
		"events.>",
		"sale.>",
		"sales.>",
		"stock.>",
		"accounting.>",
		"payment.>",
		"erp.>",
		"pix2pi.>",
	}

	basariliAbonelik := 0

	for _, subject := range olasiSubjectler {
		durableAd := strings.NewReplacer(".", "_", ">", "all").Replace("reporting_" + subject)

		_, err := js.Subscribe(subject, func(msg *nats.Msg) {
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
			nats.Durable(durableAd),
			nats.ManualAck(),
		)

		if err != nil {
			log.Printf("SKIP | subject=%s | err=%v", subject, err)
			continue
		}

		fmt.Printf("OK ✅ subscribed: %s\n", subject)
		basariliAbonelik++
	}

	if basariliAbonelik == 0 {
		log.Fatal("HATA: hicbir JetStream subject'ine baglanilamadi")
	}

	fmt.Println("OK ✅ Reporting subscriber started")

	select {}
}
GOEOF

echo "OK ✅ dosya yazildi: $HEDEF_DOSYA"

echo
echo "3) Go derleme testi yapiliyor..."
cd "$PROJE_DIZINI"
go build -o /tmp/reporting_service_test_bin ./cmd/reporting-service
echo "OK ✅ go build basarili"

echo
echo "4) Reporting subscriber calistiriliyor..."
echo "Not: Cikmak icin CTRL+C"
echo "Beklenen cikti:"
echo "- En az 1 adet: OK ✅ subscribed: ..."
echo "- Sonra: OK ✅ Reporting subscriber started"
echo

go run ./cmd/reporting-service/reporting_service_main.go
