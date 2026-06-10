package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"os"

	_ "github.com/lib/pq"
	"github.com/nats-io/nats.go"

	snapshot "github.com/divrigili/pix2pi-SaaS/internal/platform/snapshot"
)

type SaleEvent struct {
	Event    string `json:"event"`
	SaleID   string `json:"sale_id"`
	TenantID string `json:"tenant_id"`
	Amount   int    `json:"amount"`
}

func main() {
	connStr := os.Getenv("DB_WRITE_DSN")
	if connStr == "" {
		connStr = os.Getenv("DB_DSN")
	}
	if connStr == "" {
		log.Fatal("security: DB_WRITE_DSN or DB_DSN environment variable is required")
	}

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("db baglanti hatasi: %v", err)
	}
	defer db.Close()

	snapshotRepo := snapshot.NewRepository(db)

	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatalf("nats baglanti hatasi: %v", err)
	}
	defer nc.Close()

	log.Println("OK ✅ stock service basladi")

	_, err = nc.Subscribe("pix2pi.sale.created", func(m *nats.Msg) {
		var e SaleEvent

		err := json.Unmarshal(m.Data, &e)
		if err != nil {
			log.Printf("json parse hatasi: %v", err)
			return
		}

		log.Printf("OK ✅ stok guncelleniyor | sale=%s | tenant=%s | amount=%d", e.SaleID, e.TenantID, e.Amount)

		err = snapshotRepo.UpsertStockSaleSnapshot(e.TenantID, e.SaleID, e.Amount)
		if err != nil {
			log.Printf("snapshot yazma hatasi: %v", err)
			return
		}

		log.Println("OK ✅ snapshot kaydedildi")
	})
	if err != nil {
		log.Fatalf("subscribe hatasi: %v", err)
	}

	select {}
}
