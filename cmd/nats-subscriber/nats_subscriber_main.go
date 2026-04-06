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

	_, err = nc.Subscribe(subject, func(msg *nats.Msg) {
		log.Printf("OK ✅ event alindi | subject=%s | data=%s\n", msg.Subject, string(msg.Data))
	})
	if err != nil {
		log.Fatalf("subscribe hatasi: %v", err)
	}

	log.Println("subscriber dinlemede:", subject)

	select {}
}
