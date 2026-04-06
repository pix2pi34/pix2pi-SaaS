package platform

import (
	"testing"

	"github.com/nats-io/nats.go"
)

func TestDLQ_Send(t *testing.T) {

	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		t.Skip("nats yok, test skip")
	}

	dlq := NewDLQ(nc)

	err = dlq.Send(map[string]string{
		"event": "sale.created",
	})

	if err != nil {
		t.Fatalf("dlq send hatasi: %v", err)
	}
}
