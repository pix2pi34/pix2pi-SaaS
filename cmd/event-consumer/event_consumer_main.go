package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/nats-io/nats.go"
)

type UserCreatedEvent struct {
	Event  string `json:"event"`
	UserID string `json:"user_id"`
}

var userCount = 0

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
		log.Println("📥 Event alındı:", string(msg.Data))

		var event map[string]interface{}
		_ = json.Unmarshal(msg.Data, &event)

		// 🔥 KRİTİK NOKTA
		if event["event"] == "user.created" {
			userCount++

			log.Println("🧠 USER CREATED işlendi")
			log.Println("👤 user_count:", userCount)
		}

		msg.Ack()
	}, nats.Durable("pix2pi-consumer-v2"), nats.ManualAck())

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("🚀 Event Consumer RUNNING...")
	select {}
}
