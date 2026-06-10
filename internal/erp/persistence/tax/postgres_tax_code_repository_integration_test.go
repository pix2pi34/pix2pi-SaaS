package tax

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresTaxCodeRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping tax code repository integration test")
	}

	return dsn
}

func TestPostgresTaxCodeRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxCodeRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxCodeRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxCodeValue := "KDV20-REPO-" + unique[len(unique)-6:]
	isPayable := true
	isWithholding := false
	isActive := true

	taxCode, err := repo.CreateTaxCode(ctx, CreateTaxCodeInput{
		TenantID:      "tenant_7",
		TaxCode:       taxCodeValue,
		TaxName:       "KDV 20 Repo Test " + unique,
		TaxType:       TaxTypeVAT,
		AccountCode:   "391.01.20",
		AccountName:   "Hesaplanan KDV",
		IsRecoverable: false,
		IsPayable:     true,
		IsWithholding: false,
		IsActive:      true,
		Description:   "FAZ3 tax code repository test " + unique,
		CreatedBy:     "faz3_test",
	})
	if err != nil {
		t.Fatalf("create tax code: %v", err)
	}

	defer cleanupTaxCodeFixture(t, pool, "tenant_7", taxCode.TaxCodeID)

	if taxCode.TaxCodeID == "" {
		t.Fatal("expected tax_code_id")
	}

	if taxCode.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", taxCode.TenantID)
	}

	if taxCode.TaxCode != taxCodeValue {
		t.Fatalf("expected tax_code %s, got %s", taxCodeValue, taxCode.TaxCode)
	}

	if taxCode.TaxType != TaxTypeVAT {
		t.Fatalf("expected vat tax type, got %s", taxCode.TaxType)
	}

	gotByID, err := repo.GetTaxCodeByID(ctx, "tenant_7", taxCode.TaxCodeID)
	if err != nil {
		t.Fatalf("get tax code by id: %v", err)
	}

	if gotByID.TaxCodeID != taxCode.TaxCodeID {
		t.Fatalf("expected tax_code_id %s, got %s", taxCode.TaxCodeID, gotByID.TaxCodeID)
	}

	gotByCode, err := repo.GetTaxCodeByCode(ctx, "tenant_7", taxCodeValue)
	if err != nil {
		t.Fatalf("get tax code by code: %v", err)
	}

	if gotByCode.TaxCode != taxCodeValue {
		t.Fatalf("expected tax_code %s, got %s", taxCodeValue, gotByCode.TaxCode)
	}

	list, err := repo.ListTaxCodes(ctx, "tenant_7", ListTaxCodesFilter{
		TaxType:       TaxTypeVAT,
		IsPayable:     &isPayable,
		IsWithholding: &isWithholding,
		IsActive:      &isActive,
		Query:         unique,
		Limit:         10,
	})
	if err != nil {
		t.Fatalf("list tax codes: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 tax code in list, got %d", len(list))
	}

	_, err = repo.GetTaxCodeByID(ctx, "tenant_99", taxCode.TaxCodeID)
	if !errors.Is(err, ErrTaxCodeNotFound) {
		t.Fatalf("expected ErrTaxCodeNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresTaxCodeRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxCodeRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxCodeRepository(pool)

	_, err = repo.CreateTaxCode(ctx, CreateTaxCodeInput{
		TenantID: "tenant_7",
		TaxName:  "KDV 20",
		TaxType:  TaxTypeVAT,
	})

	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func cleanupTaxCodeFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, taxCodeID string) {
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

	if taxCodeID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_transactions WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax transactions failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_rates WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax rates failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_codes WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax code failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
