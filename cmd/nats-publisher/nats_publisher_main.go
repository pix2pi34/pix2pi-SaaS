package main

import (
	"log"

	"github.com/nats-io/nats.go"
)

func main() {
	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatalf("nats baglanti hatasi: %v", err)
	}
	defer nc.Close()

	subject := "pix2pi.sale.created"
	payload := []byte(`{"event":"sale.created","sale_id":"S-1001","tenant_id":"tenant-001","amount":1250}`)

	err = nc.Publish(subject, payload)
	if err != nil {
		log.Fatalf("event publish hatasi: %v", err)
	}

	err = nc.Flush()
	if err != nil {
		log.Fatalf("flush hatasi: %v", err)
	}

	log.Println("OK ✅ event publish edildi:", subject)
}
