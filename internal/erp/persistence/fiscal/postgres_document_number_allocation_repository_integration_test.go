package fiscal

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresDocumentNumberAllocationRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping document number allocation repository integration test")
	}

	return dsn
}

func TestPostgresDocumentNumberAllocationRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocumentNumberAllocationRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresDocumentNumberAllocationRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	documentType := "allocation_repo_" + unique[len(unique)-6:]
	documentNo := "INV-" + unique
	fiscalYear := 2060 + int(time.Now().UnixNano()%30)
	fiscalPeriod := fmt.Sprintf("%d-13-%s", fiscalYear, unique[len(unique)-6:])

	sequenceID := createDocumentAllocationSequenceFixture(t, pool, "tenant_7", documentType, fiscalYear, unique)
	defer cleanupDocumentAllocationRepositoryFixture(t, pool, "tenant_7", sequenceID)

	item, err := repo.CreateDocumentNumberAllocation(ctx, CreateDocumentNumberAllocationInput{
		TenantID:           "tenant_7",
		DocumentSequenceID: sequenceID,
		DocumentModule:     DocumentModuleSales,
		DocumentType:       documentType,
		DocumentNo:         documentNo,
		AllocatedNo:        1,
		FiscalYear:         &fiscalYear,
		FiscalPeriod:       fiscalPeriod,
		AllocationStatus:   AllocationStatusAllocated,
		AllocatedBy:        "faz3_test",
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		t.Fatalf("create document number allocation: %v", err)
	}

	if item.DocumentNumberAllocationID == "" {
		t.Fatal("expected document_number_allocation_id")
	}

	if item.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", item.TenantID)
	}

	if item.DocumentSequenceID != sequenceID {
		t.Fatalf("expected document_sequence_id %s, got %s", sequenceID, item.DocumentSequenceID)
	}

	if item.DocumentNo != documentNo {
		t.Fatalf("expected document_no %s, got %s", documentNo, item.DocumentNo)
	}

	if item.AllocatedNo != 1 {
		t.Fatalf("expected allocated_no 1, got %d", item.AllocatedNo)
	}

	if item.FiscalYear == nil || *item.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %v", fiscalYear, item.FiscalYear)
	}

	gotByID, err := repo.GetDocumentNumberAllocationByID(ctx, "tenant_7", item.DocumentNumberAllocationID)
	if err != nil {
		t.Fatalf("get document number allocation by id: %v", err)
	}

	if gotByID.DocumentNumberAllocationID != item.DocumentNumberAllocationID {
		t.Fatalf("expected document_number_allocation_id %s, got %s", item.DocumentNumberAllocationID, gotByID.DocumentNumberAllocationID)
	}

	gotByNo, err := repo.GetDocumentNumberAllocationByNo(ctx, "tenant_7", DocumentModuleSales, documentType, documentNo)
	if err != nil {
		t.Fatalf("get document number allocation by no: %v", err)
	}

	if gotByNo.DocumentNo != documentNo {
		t.Fatalf("expected document_no %s, got %s", documentNo, gotByNo.DocumentNo)
	}

	list, err := repo.ListDocumentNumberAllocations(ctx, "tenant_7", ListDocumentNumberAllocationsFilter{
		DocumentSequenceID: sequenceID,
		DocumentModule:     DocumentModuleSales,
		DocumentType:       documentType,
		FiscalYear:         &fiscalYear,
		FiscalPeriod:       fiscalPeriod,
		AllocationStatus:   AllocationStatusAllocated,
		Query:              unique,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list document number allocations: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 document number allocation in list, got %d", len(list))
	}

	_, err = repo.GetDocumentNumberAllocationByID(ctx, "tenant_99", item.DocumentNumberAllocationID)
	if !errors.Is(err, ErrDocumentAllocationNotFound) {
		t.Fatalf("expected ErrDocumentAllocationNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresDocumentNumberAllocationRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocumentNumberAllocationRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresDocumentNumberAllocationRepository(pool)

	_, err = repo.CreateDocumentNumberAllocation(ctx, CreateDocumentNumberAllocationInput{
		TenantID:           "tenant_7",
		DocumentSequenceID: "sequence-id",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		AllocatedNo:        1,
	})

	if !errors.Is(err, ErrDocumentNoRequired) {
		t.Fatalf("expected ErrDocumentNoRequired, got %v", err)
	}
}

func createDocumentAllocationSequenceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, documentType string, fiscalYear int, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("fixture set tenant failed: %v", err)
	}

	var sequenceID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_document_sequences (
    tenant_id,
    document_module,
    document_type,
    fiscal_year,
    prefix,
    suffix,
    current_no,
    min_no,
    max_no,
    padding,
    reset_policy,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    'sales',
    $2,
    $3,
    'INV-',
    '',
    0,
    1,
    999999,
    6,
    'yearly',
    true,
    $4,
    'active',
    'faz3_test'
)
RETURNING document_sequence_id::text;
`, tenantID, documentType, fiscalYear, "Document allocation sequence fixture "+unique).Scan(&sequenceID); err != nil {
		t.Fatalf("fixture document sequence failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return sequenceID
}

func cleanupDocumentAllocationRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sequenceID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup set tenant failed: %v", err)
		return
	}

	if sequenceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_document_number_allocations WHERE document_sequence_id = $1;", sequenceID); err != nil {
			t.Logf("cleanup document allocations failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_document_sequences WHERE document_sequence_id = $1;", sequenceID); err != nil {
			t.Logf("cleanup document sequence failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
