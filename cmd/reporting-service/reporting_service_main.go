package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/nats-io/nats.go"
)

type Event struct {
	Type string                 `json:"type"`
	Data map[string]interface{} `json:"data"`
}

type SaleProjection struct {
	OrderID  string  `json:"order_id"`
	Customer string  `json:"customer"`
	Amount   float64 `json:"amount"`
	Status   string  `json:"status"`
}

func stringValue(data map[string]interface{}, keys ...string) string {
	for _, key := range keys {
		if v, ok := data[key]; ok {
			if s, ok := v.(string); ok {
				return s
			}
		}
	}
	return ""
}

func floatValue(data map[string]interface{}, keys ...string) float64 {
	for _, key := range keys {
		if v, ok := data[key]; ok {
			switch t := v.(type) {
			case float64:
				return t
			case int:
				return float64(t)
			case int64:
				return float64(t)
			}
		}
	}
	return 0
}

func buildSaleProjection(e Event) (SaleProjection, bool) {
	switch e.Type {
	case "sale.created", "sale.updated", "sale.completed":
	default:
		return SaleProjection{}, false
	}

	orderID := stringValue(e.Data, "order_id", "orderId", "siparis_no")
	if orderID == "" {
		return SaleProjection{}, false
	}

	customer := stringValue(e.Data, "customer", "customer_name", "cari")
	amount := floatValue(e.Data, "amount", "total", "tutar")
	status := stringValue(e.Data, "status", "durum")
	if status == "" {
		status = "PAID"
	}

	return SaleProjection{
		OrderID:  orderID,
		Customer: customer,
		Amount:   amount,
		Status:   status,
	}, true
}

func pushToQueryReadModel(baseURL string, payload SaleProjection) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Post(baseURL+"/upsert/sale", "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("query_read_model status=%d", resp.StatusCode)
	}

	return nil
}

func main() {
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	queryReadModelURL := os.Getenv("QUERY_READ_MODEL_URL")
	if queryReadModelURL == "" {
		queryReadModelURL = "http://127.0.0.1:8091"
	}

	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("NATS baglanti hatasi: %v", err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		log.Fatalf("JetStream erisim hatasi: %v", err)
	}

	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
		var e Event

		if err := json.Unmarshal(msg.Data, &e); err != nil {
			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
			_ = msg.Ack()
			return
		}

		log.Printf("REPORT EVENT | subject=%s | type=%s", msg.Subject, e.Type)

		if sale, ok := buildSaleProjection(e); ok {
			if err := pushToQueryReadModel(queryReadModelURL, sale); err != nil {
				log.Printf("QUERY READ MODEL PUSH HATA | order_id=%s | err=%v", sale.OrderID, err)
			} else {
				log.Printf("OK ✅ query_read_model upsert | order_id=%s", sale.OrderID)
			}
		}

		if err := msg.Ack(); err != nil {
			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, err)
		}
	},
		nats.Durable("reporting_service"),
		nats.ManualAck(),
	)
	if err != nil {
		log.Fatalf("Subscribe hatasi: %v", err)
	}

	log.Println("OK ✅ Reporting subscriber started")

	select {}
}
