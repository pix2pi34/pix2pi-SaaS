package platform

import (
	"encoding/json"
	"log"

	"github.com/nats-io/nats.go"
)

type DLQ struct {
	nc *nats.Conn
}

func NewDLQ(nc *nats.Conn) *DLQ {
	return &DLQ{nc: nc}
}

func (d *DLQ) Send(event interface{}) error {

	data, err := json.Marshal(event)
	if err != nil {
		return err
	}

	err = d.nc.Publish("pix2pi.dlq", data)
	if err != nil {
		return err
	}

	log.Println("⚠ event DLQ'ya gonderildi")

	return nil
}
