#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/internal/platform/snapshot

cat <<'GOEOF' > $BASE/internal/platform/snapshot/snapshot.go
package snapshot

import (
	"database/sql"
	"encoding/json"
	"time"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

type StockState struct {
	Event       string    `json:"event"`
	SaleID      string    `json:"sale_id"`
	TenantID    string    `json:"tenant_id"`
	Amount      int       `json:"amount"`
	LastUpdated time.Time `json:"last_updated"`
}

func (r *Repository) UpsertStockSaleSnapshot(tenantID string, saleID string, amount int) error {
	state := StockState{
		Event:       "sale.created",
		SaleID:      saleID,
		TenantID:    tenantID,
		Amount:      amount,
		LastUpdated: time.Now().UTC(),
	}

	data, err := json.Marshal(state)
	if err != nil {
		return err
	}

	_, err = r.db.Exec(`
		INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
		VALUES ($1, $2, $3, 1, $4, NOW())
		ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
		DO UPDATE SET
			version = snapshots.version + 1,
			state = EXCLUDED.state,
			updated_at = NOW()
	`,
		tenantID,
		"stock",
		saleID,
		data,
	)

	return err
}

func (r *Repository) GetSnapshot(tenantID string, aggregateType string, aggregateID string) (string, int, error) {
	var state string
	var version int

	err := r.db.QueryRow(`
		SELECT state::text, version
		FROM snapshots
		WHERE tenant_id = $1 AND aggregate_type = $2 AND aggregate_id = $3
	`,
		tenantID,
		aggregateType,
		aggregateID,
	).Scan(&state, &version)

	return state, version, err
}
GOEOF

cat <<'GOEOF' > $BASE/internal/platform/snapshot/snapshot_test.go
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
GOEOF

cd $BASE
PIX2PI_DB_TEST=1 go test ./internal/platform/snapshot -v

echo "OK ✅ snapshot engine hazir"
