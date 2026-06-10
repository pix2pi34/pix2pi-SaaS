package docnumber

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresDocNumberProviderStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping docnumber postgres provider store integration test")
	}

	return dsn
}

func TestPostgresDocumentNumberProviderStoreFindAndPersist(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocNumberProviderStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2070 + int(time.Now().UnixNano()%20)
	documentType := "runtime_docnumber_" + unique[len(unique)-6:]
	sequenceID := createRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", documentType, fiscalYear, unique)
	defer cleanupRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", sequenceID)

	store := NewPostgresDocumentNumberProviderStore(pool)

	req := AllocateDocumentNumberRequest{
		TenantID:       "tenant_7",
		RequestID:      "req-" + unique,
		ActorID:        "faz3_test",
		DocumentModule: DocumentModuleSales,
		DocumentType:   documentType,
		FiscalYear:     &fiscalYear,
		FiscalPeriod:   fmt.Sprintf("%d-12", fiscalYear),
	}

	sequence, err := store.FindDocumentSequence(ctx, req)
	if err != nil {
		t.Fatalf("find document sequence: %v", err)
	}

	if sequence.DocumentSequenceID != sequenceID {
		t.Fatalf("expected sequence_id %s, got %s", sequenceID, sequence.DocumentSequenceID)
	}

	allocation, err := BuildDocumentNumberAllocation(req, sequence)
	if err != nil {
		t.Fatalf("build allocation: %v", err)
	}

	persisted, err := store.PersistDocumentNumberAllocation(ctx, allocation)
	if err != nil {
		t.Fatalf("persist allocation: %v", err)
	}

	if persisted.DocumentNo != "INV-000001" {
		t.Fatalf("expected document no INV-000001, got %s", persisted.DocumentNo)
	}

	if persisted.AllocatedNo != 1 {
		t.Fatalf("expected allocated no 1, got %d", persisted.AllocatedNo)
	}

	if persisted.AllocationStatus != AllocationStatusAllocated {
		t.Fatalf("expected allocation status allocated, got %s", persisted.AllocationStatus)
	}

	currentNo := getRuntimeDocNumberCurrentNo(t, pool, "tenant_7", sequenceID)
	if currentNo != 1 {
		t.Fatalf("expected sequence current_no 1, got %d", currentNo)
	}
}

func TestPostgresDocumentNumberProviderStoreAllocatorIntegration(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocNumberProviderStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2070 + int(time.Now().UnixNano()%20)
	documentType := "runtime_allocator_" + unique[len(unique)-6:]
	sequenceID := createRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", documentType, fiscalYear, unique)
	defer cleanupRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", sequenceID)

	store := NewPostgresDocumentNumberProviderStore(pool)
	allocator := NewDefaultDocumentNumberAllocator(store, store)

	result, err := allocator.AllocateDocumentNumber(ctx, AllocateDocumentNumberRequest{
		TenantID:       "tenant_7",
		RequestID:      "req-" + unique,
		ActorID:        "faz3_test",
		DocumentModule: DocumentModuleSales,
		DocumentType:   documentType,
		FiscalYear:     &fiscalYear,
		FiscalPeriod:   fmt.Sprintf("%d-12", fiscalYear),
	})
	if err != nil {
		t.Fatalf("allocate document number: %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.DocumentNo != "INV-000001" {
		t.Fatalf("expected document no INV-000001, got %s", result.DocumentNo)
	}

	if result.AllocatedNo != 1 {
		t.Fatalf("expected allocated no 1, got %d", result.AllocatedNo)
	}
}

func TestPostgresDocumentNumberProviderStoreTenantIsolationNotFound(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocNumberProviderStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2070 + int(time.Now().UnixNano()%20)
	documentType := "runtime_rls_" + unique[len(unique)-6:]
	sequenceID := createRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", documentType, fiscalYear, unique)
	defer cleanupRuntimeDocNumberSequenceFixture(t, pool, "tenant_7", sequenceID)

	store := NewPostgresDocumentNumberProviderStore(pool)

	_, err = store.FindDocumentSequence(ctx, AllocateDocumentNumberRequest{
		TenantID:       "tenant_99",
		RequestID:      "req-" + unique,
		ActorID:        "faz3_test",
		DocumentModule: DocumentModuleSales,
		DocumentType:   documentType,
		FiscalYear:     &fiscalYear,
	})
	if !errors.Is(err, ErrSequenceNotFound) {
		t.Fatalf("expected ErrSequenceNotFound for cross tenant read, got %v", err)
	}
}

func TestPostgresDocumentNumberProviderStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocNumberProviderStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresDocumentNumberProviderStore(pool)

	_, err = store.FindDocumentSequence(ctx, AllocateDocumentNumberRequest{
		RequestID:      "req-1",
		ActorID:        "faz3_test",
		DocumentModule: DocumentModuleSales,
		DocumentType:   "invoice",
	})
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	_, err = store.PersistDocumentNumberAllocation(ctx, DocumentNumberAllocation{
		TenantID:           "tenant_7",
		DocumentSequenceID: "seq-1",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		DocumentNo:         "",
		AllocatedNo:        1,
	})
	if !errors.Is(err, ErrAllocatedNoInvalid) {
		t.Fatalf("expected ErrAllocatedNoInvalid, got %v", err)
	}
}

func createRuntimeDocNumberSequenceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, documentType string, fiscalYear int, unique string) string {
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
    'faz3_docnumber_runtime_test'
)
RETURNING document_sequence_id::text;
`, tenantID, documentType, fiscalYear, "Runtime docnumber fixture "+unique).Scan(&sequenceID); err != nil {
		t.Fatalf("fixture document sequence failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return sequenceID
}

func cleanupRuntimeDocNumberSequenceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, sequenceID string) {
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
			t.Logf("cleanup allocations failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_document_sequences WHERE document_sequence_id = $1;", sequenceID); err != nil {
			t.Logf("cleanup sequence failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}

func getRuntimeDocNumberCurrentNo(t *testing.T, pool *pgxpool.Pool, tenantID string, sequenceID string) int64 {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("current_no begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("current_no set tenant failed: %v", err)
	}

	var currentNo int64
	if err := tx.QueryRow(ctx, `
SELECT current_no
FROM erp_document_sequences
WHERE tenant_id = $1
  AND document_sequence_id = $2;
`, tenantID, sequenceID).Scan(&currentNo); err != nil {
		t.Fatalf("current_no query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("current_no commit failed: %v", err)
	}

	return currentNo
}
