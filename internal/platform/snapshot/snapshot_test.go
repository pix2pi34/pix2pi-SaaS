package snapshot

import (
	"database/sql"
	"os"
	"strings"
	"testing"

	_ "github.com/lib/pq"
)

func TestSnapshotRepositoryIntegration(t *testing.T) {
	if os.Getenv("PIX2PI_DB_TEST") != "1" {
		t.Skip("db integration test skip")
	}

	connStr := "host=localhost port=5433 user=pix2pi password=pix2pi dbname=pix2pi sslmode=disable"

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		t.Fatalf("db baglanti hatasi: %v", err)
	}
	defer db.Close()

	_, err = db.Exec(`DELETE FROM snapshots WHERE tenant_id = 'tenant-test'`)
	if err != nil {
		t.Fatalf("snapshot cleanup hatasi: %v", err)
	}

	repo := NewRepository(db)

	err = repo.UpsertStockSaleSnapshot("tenant-test", "S-TEST-1", 1200)
	if err != nil {
		t.Fatalf("ilk upsert hatasi: %v", err)
	}

	state, version, err := repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
	if err != nil {
		t.Fatalf("snapshot read hatasi: %v", err)
	}

	if version != 1 {
		t.Fatalf("beklenen version 1, gelen %d", version)
	}

	if !strings.Contains(state, "S-TEST-1") {
		t.Fatalf("state icinde sale id yok: %s", state)
	}

	err = repo.UpsertStockSaleSnapshot("tenant-test", "S-TEST-1", 1500)
	if err != nil {
		t.Fatalf("ikinci upsert hatasi: %v", err)
	}

	state, version, err = repo.GetSnapshot("tenant-test", "stock", "S-TEST-1")
	if err != nil {
		t.Fatalf("snapshot read 2 hatasi: %v", err)
	}

	if version != 2 {
		t.Fatalf("beklenen version 2, gelen %d", version)
	}

	if !strings.Contains(state, "1500") {
		t.Fatalf("state icinde yeni amount yok: %s", state)
	}
}
