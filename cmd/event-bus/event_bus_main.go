package main

import (
	"fmt"
	"github.com/nats-io/nats.go"
)

func main() {

	nc, err := nats.Connect("nats://localhost:4222")
	if err != nil {
		panic(err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		panic(err)
	}

	msg := []byte(`{"event":"user.created","user_id":1}`)

	ack, err := js.Publish("pix2pi.user.created", msg)
	if err != nil {
		panic(err)
	}

	fmt.Println("OK ✅ event gönderildi", ack.Sequence)
}
