package platform

import (
	"encoding/json"
	"fmt"
	"log"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventbusservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/service"
	"github.com/nats-io/nats.go"
)

type DLQ struct {
	nc *nats.Conn
}

func NewDLQ(nc *nats.Conn) *DLQ {
	return &DLQ{nc: nc}
}

func buildTenantSafeDlqPayload(
	event eventdomain.EventMessage,
) ([]byte, error) {
	if err := eventbusservice.ValidateDlqEvent(event); err != nil {
		return nil, err
	}

	data, err := json.Marshal(event)
	if err != nil {
		return nil, err
	}

	return data, nil
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

func (d *DLQ) SendTenantSafe(
	event eventdomain.EventMessage,
) error {
	if d == nil || d.nc == nil {
		return fmt.Errorf("nats connection zorunlu")
	}

	data, err := buildTenantSafeDlqPayload(event)
	if err != nil {
		return err
	}

	err = d.nc.Publish("pix2pi.dlq", data)
	if err != nil {
		return err
	}

	log.Println("⚠ tenant-safe event DLQ'ya gonderildi")
	return nil
}
