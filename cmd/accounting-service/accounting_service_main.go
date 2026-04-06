package main

import (
	"database/sql"
	"encoding/json"
	"log"

	_ "github.com/lib/pq"
	"github.com/nats-io/nats.go"

	audit "github.com/divrigili/pix2pi-SaaS/internal/platform/audit"
	auditlog "github.com/divrigili/pix2pi-SaaS/internal/platform/auditlog"
	journal "github.com/divrigili/pix2pi-SaaS/internal/platform/journal"
)

type SaleEvent struct {
	Event    string `json:"event"`
	SaleID   string `json:"sale_id"`
	TenantID string `json:"tenant_id"`
	Amount   int    `json:"amount"`
}

func main() {
	connStr := "host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("db baglanti hatasi: %v", err)
	}
	defer db.Close()

	repo := journal.NewRepository(db)
	builder := journal.NewJournalBuilder()
	auditEngine := audit.NewAuditEngine()
	auditRepo := auditlog.NewRepository(db)

	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatalf("nats baglanti hatasi: %v", err)
	}
	defer nc.Close()

	log.Println("OK ✅ accounting basladi")

	_, err = nc.Subscribe("pix2pi.sale.created", func(m *nats.Msg) {
		var e SaleEvent

		err := json.Unmarshal(m.Data, &e)
		if err != nil {
			log.Printf("json parse hatasi: %v", err)

			_ = auditRepo.Write(auditlog.Record{
				TenantID:   "unknown",
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "sale.consume",
				EntityType: "sale_event",
				EntityID:   "unknown",
				Status:     "failed",
				Details: map[string]interface{}{
					"error": "json parse hatasi",
				},
			})
			return
		}

		entry := builder.BuildSaleJournal(journal.SaleEvent{
			Event:    e.Event,
			SaleID:   e.SaleID,
			TenantID: e.TenantID,
			Amount:   e.Amount,
		})

		err = auditEngine.Validate(entry)
		if err != nil {
			log.Printf("AUDIT RED ❌ %v", err)

			_ = auditRepo.Write(auditlog.Record{
				TenantID:   e.TenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "journal.validate",
				EntityType: "journal_entry",
				EntityID:   e.SaleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id": e.SaleID,
					"amount":  e.Amount,
					"error":   err.Error(),
				},
			})
			return
		}

		err = repo.Save(entry)
		if err != nil {
			log.Printf("journal save hatasi: %v", err)

			_ = auditRepo.Write(auditlog.Record{
				TenantID:   e.TenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "journal.write",
				EntityType: "journal_entry",
				EntityID:   e.SaleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id": e.SaleID,
					"amount":  e.Amount,
					"error":   err.Error(),
				},
			})
			return
		}

		log.Println("OK ✅ journal yazildi")

		_ = auditRepo.Write(auditlog.Record{
			TenantID:   e.TenantID,
			ActorType:  "system",
			ActorID:    "accounting-service",
			Action:     "journal.write",
			EntityType: "journal_entry",
			EntityID:   e.SaleID,
			Status:     "success",
			Details: map[string]interface{}{
				"sale_id": e.SaleID,
				"amount":  e.Amount,
				"event":   e.Event,
			},
		})
	})

	if err != nil {
		log.Fatalf("subscribe hatasi: %v", err)
	}

	select {}
}
