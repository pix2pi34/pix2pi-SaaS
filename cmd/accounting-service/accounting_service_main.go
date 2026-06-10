package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
	"github.com/nats-io/nats.go"

	eventsvc "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/service"
	ledgersvc "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service"
	journalsvc "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/service"
	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
	rulesvc "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/service"
	auditlog "github.com/divrigili/pix2pi-SaaS/internal/platform/auditlog"
)

type SaleEvent struct {
	Event         string `json:"event"`
	SaleID        string `json:"sale_id"`
	TenantID      string `json:"tenant_id"`
	Amount        int    `json:"amount"`
	PaymentMethod string `json:"payment_method"`
	Currency      string `json:"currency"`
	DocumentNo    string `json:"document_no"`
	ReferenceID   string `json:"reference_id"`
	TaxRate       int    `json:"tax_rate"`
}

func envOr(key string, fallback string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback
	}
	return v
}

func nonEmpty(v string, fallback string) string {
	v = strings.TrimSpace(v)
	if v == "" {
		return fallback
	}
	return v
}

func writeAudit(writeFn func(auditlog.Record) error, record auditlog.Record) {
	_ = writeFn(record)
}

func main() {
	connStr := envOr(
		"DB_WRITE_DSN",
		"host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable",
	)
	natsURL := envOr("NATS_URL", nats.DefaultURL)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("db baglanti hatasi: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("db ping hatasi: %v", err)
	}

	auditRepo := auditlog.NewRepository(db)
	intakeService := eventsvc.NewEventIntakeService()
	financialService := eventsvc.NewFinancialEventService()
	ruleService := rulesvc.NewAccountingRuleService()
	journalBuilder := journalsvc.NewJournalBuilderService()
	ledgerBuilder := ledgersvc.NewLedgerPostingService()

	nc, err := nats.Connect(natsURL, nats.Name("pix2pi-accounting-service"))
	if err != nil {
		log.Fatalf("nats baglanti hatasi: %v", err)
	}
	defer nc.Close()

	log.Println("OK ✅ accounting ERP core flow basladi")

	_, err = nc.Subscribe("pix2pi.sale.created", func(m *nats.Msg) {
		var e SaleEvent

		if err := json.Unmarshal(m.Data, &e); err != nil {
			log.Printf("ERROR ❌ sale event json parse hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   "unknown",
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "event.intake",
				EntityType: "sale_event",
				EntityID:   "unknown",
				Status:     "failed",
				Details: map[string]interface{}{
					"error": "json parse hatasi",
				},
			})
			return
		}

		saleID := nonEmpty(e.SaleID, "SALE-"+time.Now().Format("20060102150405"))
		tenantID := nonEmpty(e.TenantID, "tenant-001")
		eventName := nonEmpty(e.Event, "sale.completed")
		paymentMethod := nonEmpty(e.PaymentMethod, "cash")
		currency := nonEmpty(e.Currency, "TRY")
		documentNo := nonEmpty(e.DocumentNo, saleID)
		referenceID := nonEmpty(e.ReferenceID, saleID)

		intake, err := intakeService.Normalize(eventsvc.EventIntake{
			TenantID:      tenantID,
			EventID:       saleID,
			EventType:     eventName,
			SourceModule:  "pos",
			DocumentNo:    documentNo,
			ReferenceID:   referenceID,
			PaymentMethod: paymentMethod,
			TaxRate:       e.TaxRate,
			GrossAmount:   float64(e.Amount),
			Currency:      currency,
			OccurredAt:    time.Now(),
		})
		if err != nil {
			log.Printf("ERROR ❌ event intake hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   tenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "event.intake",
				EntityType: "financial_event",
				EntityID:   saleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id": saleID,
					"amount":  e.Amount,
					"error":   err.Error(),
				},
			})
			return
		}

		financialEvent, err := financialService.Build(intake.ToFinancialEventInput())
		if err != nil {
			log.Printf("ERROR ❌ financial event build hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   tenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "financial_event.build",
				EntityType: "financial_event",
				EntityID:   saleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id": saleID,
					"amount":  e.Amount,
					"error":   err.Error(),
				},
			})
			return
		}

		log.Printf(
			"OK ✅ financial event hazir | tenant=%s sale_id=%s gross=%.2f net=%.2f tax=%.2f",
			intake.TenantID,
			financialEvent.EventID,
			financialEvent.GrossAmount,
			financialEvent.NetAmount,
			financialEvent.TaxAmount,
		)

		rule, err := ruleService.FindRule(ruledomain.AccountingRuleQuery{
			EventType:     intake.EventType,
			PaymentMethod: intake.PaymentMethod,
			TaxRate:       intake.TaxRate,
		})
		if err != nil {
			log.Printf("ERROR ❌ accounting rule hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   tenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "rule.resolve",
				EntityType: "accounting_rule",
				EntityID:   saleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id":        saleID,
					"event_type":     intake.EventType,
					"payment_method": intake.PaymentMethod,
					"tax_rate":       intake.TaxRate,
					"error":          err.Error(),
				},
			})
			return
		}

		journalEntry, err := journalBuilder.Build(financialEvent, rule)
		if err != nil {
			log.Printf("ERROR ❌ journal build hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   tenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "journal.build",
				EntityType: "journal_entry",
				EntityID:   saleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id": saleID,
					"amount":  e.Amount,
					"rule_id": rule.RuleID,
					"error":   err.Error(),
				},
			})
			return
		}

		log.Printf(
			"OK ✅ journal build tamam | journal_id=%s line=%d rule=%s",
			journalEntry.JournalID,
			len(journalEntry.Lines),
			rule.RuleID,
		)

		postings, err := ledgerBuilder.BuildFromJournal(journalEntry)
		if err != nil {
			log.Printf("ERROR ❌ ledger build hatasi: %v", err)

			writeAudit(auditRepo.Write, auditlog.Record{
				TenantID:   tenantID,
				ActorType:  "system",
				ActorID:    "accounting-service",
				Action:     "ledger.build",
				EntityType: "ledger_posting",
				EntityID:   saleID,
				Status:     "failed",
				Details: map[string]interface{}{
					"sale_id":    saleID,
					"journal_id": journalEntry.JournalID,
					"rule_id":    rule.RuleID,
					"error":      err.Error(),
				},
			})
			return
		}

		log.Printf(
			"OK ✅ ledger build tamam | journal_id=%s posting=%d",
			journalEntry.JournalID,
			len(postings),
		)

		writeAudit(auditRepo.Write, auditlog.Record{
			TenantID:   tenantID,
			ActorType:  "system",
			ActorID:    "accounting-service",
			Action:     "ledger.build",
			EntityType: "ledger_posting",
			EntityID:   saleID,
			Status:     "success",
			Details: map[string]interface{}{
				"sale_id":       saleID,
				"tenant_id":     tenantID,
				"event":         intake.EventType,
				"rule_id":       rule.RuleID,
				"gross_amount":  financialEvent.GrossAmount,
				"net_amount":    financialEvent.NetAmount,
				"tax_amount":    financialEvent.TaxAmount,
				"journal_id":    journalEntry.JournalID,
				"posting_count": len(postings),
			},
		})
	})
	if err != nil {
		log.Fatalf("subscribe hatasi: %v", err)
	}

	log.Printf("OK ✅ pix2pi.sale.created dinleniyor | nats=%s", natsURL)

	select {}
}
