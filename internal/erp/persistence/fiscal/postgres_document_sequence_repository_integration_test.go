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

func postgresDocumentSequenceRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping document sequence repository integration test")
	}

	return dsn
}

func TestPostgresDocumentSequenceRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocumentSequenceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresDocumentSequenceRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	documentType := "invoice_repo_" + unique[len(unique)-6:]
	fiscalYear := 2060 + int(time.Now().UnixNano()%30)
	maxNo := int64(999999)
	isActive := true

	cleanupDocumentSequenceRepositoryFixtureByType(t, pool, "tenant_7", documentType)

	item, err := repo.CreateDocumentSequence(ctx, CreateDocumentSequenceInput{
		TenantID:       "tenant_7",
		DocumentModule: DocumentModuleSales,
		DocumentType:   documentType,
		FiscalYear:     &fiscalYear,
		Prefix:         "INV-",
		Suffix:         "",
		CurrentNo:      0,
		MinNo:          1,
		MaxNo:          &maxNo,
		Padding:        6,
		ResetPolicy:    ResetPolicyYearly,
		IsActive:       true,
		Description:    "FAZ3 document sequence repository test " + unique,
		CreatedBy:      "faz3_test",
	})
	if err != nil {
		t.Fatalf("create document sequence: %v", err)
	}

	defer cleanupDocumentSequenceRepositoryFixture(t, pool, "tenant_7", item.DocumentSequenceID)

	if item.DocumentSequenceID == "" {
		t.Fatal("expected document_sequence_id")
	}

	if item.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", item.TenantID)
	}

	if item.DocumentModule != DocumentModuleSales {
		t.Fatalf("expected sales module, got %s", item.DocumentModule)
	}

	if item.DocumentType != documentType {
		t.Fatalf("expected document_type %s, got %s", documentType, item.DocumentType)
	}

	if item.FiscalYear == nil || *item.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %v", fiscalYear, item.FiscalYear)
	}

	if item.MaxNo == nil || *item.MaxNo != maxNo {
		t.Fatalf("expected max_no %d, got %v", maxNo, item.MaxNo)
	}

	gotByID, err := repo.GetDocumentSequenceByID(ctx, "tenant_7", item.DocumentSequenceID)
	if err != nil {
		t.Fatalf("get document sequence by id: %v", err)
	}

	if gotByID.DocumentSequenceID != item.DocumentSequenceID {
		t.Fatalf("expected document_sequence_id %s, got %s", item.DocumentSequenceID, gotByID.DocumentSequenceID)
	}

	gotByKey, err := repo.GetDocumentSequenceByModuleTypeYear(ctx, "tenant_7", DocumentModuleSales, documentType, &fiscalYear)
	if err != nil {
		t.Fatalf("get document sequence by module/type/year: %v", err)
	}

	if gotByKey.DocumentType != documentType {
		t.Fatalf("expected document_type %s, got %s", documentType, gotByKey.DocumentType)
	}

	list, err := repo.ListDocumentSequences(ctx, "tenant_7", ListDocumentSequencesFilter{
		DocumentModule: DocumentModuleSales,
		DocumentType:   documentType,
		FiscalYear:     &fiscalYear,
		IsActive:       &isActive,
		Status:         SequenceStatusActive,
		Query:          unique,
		Limit:          10,
	})
	if err != nil {
		t.Fatalf("list document sequences: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 document sequence in list, got %d", len(list))
	}

	_, err = repo.GetDocumentSequenceByID(ctx, "tenant_99", item.DocumentSequenceID)
	if !errors.Is(err, ErrDocumentSequenceNotFound) {
		t.Fatalf("expected ErrDocumentSequenceNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresDocumentSequenceRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresDocumentSequenceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresDocumentSequenceRepository(pool)

	_, err = repo.CreateDocumentSequence(ctx, CreateDocumentSequenceInput{
		TenantID:       "tenant_7",
		DocumentModule: DocumentModule("wrong"),
		DocumentType:   "invoice",
		MinNo:          1,
		Padding:        6,
		ResetPolicy:    ResetPolicyYearly,
	})

	if !errors.Is(err, ErrDocumentModuleInvalid) {
		t.Fatalf("expected ErrDocumentModuleInvalid, got %v", err)
	}
}

func cleanupDocumentSequenceRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, documentSequenceID string) {
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

	if documentSequenceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_document_number_allocations WHERE document_sequence_id = $1;", documentSequenceID); err != nil {
			t.Logf("cleanup document allocations failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_document_sequences WHERE document_sequence_id = $1;", documentSequenceID); err != nil {
			t.Logf("cleanup document sequence failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}

func cleanupDocumentSequenceRepositoryFixtureByType(t *testing.T, pool *pgxpool.Pool, tenantID string, documentType string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup by type begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup by type set tenant failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_document_number_allocations
WHERE tenant_id = $1
  AND document_type = $2;
`, tenantID, documentType); err != nil {
		t.Logf("cleanup allocations by type failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_document_sequences
WHERE tenant_id = $1
  AND document_type = $2
  AND created_by = 'faz3_test';
`, tenantID, documentType); err != nil {
		t.Logf("cleanup sequence by type failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup by type commit failed: %v", err)
		return
	}
}
