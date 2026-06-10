#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/internal/platform/auditlog

cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog.go
package auditlog

import (
	"database/sql"
	"encoding/json"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

type Record struct {
	TenantID   string
	ActorType  string
	ActorID    string
	Action     string
	EntityType string
	EntityID   string
	Status     string
	Details    interface{}
}

func (r *Repository) Write(rec Record) error {
	data, err := json.Marshal(rec.Details)
	if err != nil {
		return err
	}

	_, err = r.db.Exec(`
		INSERT INTO audit_logs (
			tenant_id,
			actor_type,
			actor_id,
			action,
			entity_type,
			entity_id,
			status,
			details
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
	`,
		rec.TenantID,
		rec.ActorType,
		rec.ActorID,
		rec.Action,
		rec.EntityType,
		rec.EntityID,
		rec.Status,
		data,
	)

	return err
}
GOEOF

cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog_test.go
package auditlog

import (
	"database/sql"
	"os"
	"testing"

	_ "github.com/lib/pq"
)

func TestAuditLogRepositoryIntegration(t *testing.T) {
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

	err = repo.Write(Record{
		TenantID:   "tenant-audit-test",
		ActorType:  "system",
		ActorID:    "accounting-service",
		Action:     "journal.write",
		EntityType: "journal_entry",
		EntityID:   "J-AUDIT-1",
		Status:     "success",
		Details: map[string]interface{}{
			"sale_id": "S-AUDIT-1",
			"amount":  1500,
		},
	})
	if err != nil {
		t.Fatalf("audit write hatasi: %v", err)
	}

	var count int
	err = db.QueryRow(`
		SELECT COUNT(*)
		FROM audit_logs
		WHERE tenant_id = 'tenant-audit-test'
		  AND action = 'journal.write'
		  AND entity_id = 'J-AUDIT-1'
	`).Scan(&count)
	if err != nil {
		t.Fatalf("audit read hatasi: %v", err)
	}

	if count < 1 {
		t.Fatalf("audit kaydi bulunamadi")
	}
}
GOEOF

cd $BASE
PIX2PI_DB_TEST=1 go test ./internal/platform/auditlog -v

echo "OK ✅ audit log engine hazir"
