package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/nats-io/nats.go"
)

type Event struct {
	Event  string `json:"event"`
	UserID int    `json:"user_id"`
}

var processedEvents = map[string]bool{}

func main() {
	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatal(err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		log.Fatal(err)
	}

	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
		eventID := msg.Subject + string(msg.Data)

		if processedEvents[eventID] {
			fmt.Println("⚠️ duplicate event ignore edildi")
			_ = msg.Ack()
			return
		}

		processedEvents[eventID] = true

		var e Event
		if err := json.Unmarshal(msg.Data, &e); err != nil {
			fmt.Println("HATA ❌ json parse")
			return
		}

		fmt.Printf("Event işlendi: %+v subject=%s\n", e, msg.Subject)
		_ = msg.Ack()

	}, nats.Durable("pix2pi-consumer-v2"), nats.ManualAck())

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Consumer dinliyor...")
	select {}
}
