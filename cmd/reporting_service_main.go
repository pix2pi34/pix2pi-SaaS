package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/nats-io/nats.go"
)

type Event struct {
	Type string `json:"type"`
	Data map[string]interface{} `json:"data"`
}

func main() {

	nc, err := nats.Connect("nats://localhost:4222")
	if err != nil {
		log.Fatal(err)
	}

	js, err := nc.JetStream()
	if err != nil {
		log.Fatal(err)
	}

	_, err = js.Subscribe("events.>", func(msg *nats.Msg) {

		var e Event

		err := json.Unmarshal(msg.Data, &e)
		if err != nil {
			log.Println("event parse error:", err)
			return
		}

		fmt.Println("REPORT EVENT:", e.Type)

		msg.Ack()

	},
		nats.Durable("reporting_service"),
		nats.ManualAck(),
	)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Reporting subscriber started")

	select {}
}
