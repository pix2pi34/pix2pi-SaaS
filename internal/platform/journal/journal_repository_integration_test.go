package journal

import (
	"database/sql"
	"os"
	"testing"

	_ "github.com/lib/pq"
)

func TestRepositorySaveIntegration(t *testing.T) {
	if os.Getenv("PIX2PI_DB_TEST") != "1" {
		t.Skip("db integration test skip")
	}

	connStr := "host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		t.Fatalf("db baglanti hatasi: %v", err)
	}
	defer db.Close()

	repo := NewRepository(db)
	builder := NewJournalBuilder()

	entry := builder.BuildSaleJournal(SaleEvent{
		Event:    "sale.created",
		SaleID:   "S-5002",
		TenantID: "tenant-001",
		Amount:   2100,
	})

	err = repo.Save(entry)
	if err != nil {
		t.Fatalf("repo save hatasi: %v", err)
	}
}
