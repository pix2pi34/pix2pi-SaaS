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

func postgresTaxRateRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping tax rate repository integration test")
	}

	return dsn
}

func TestPostgresTaxRateRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxRateRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxRateRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxCodeValue := "KDV-RATE-" + unique[len(unique)-6:]
	taxCodeID := createTaxRateRepositoryTaxCodeFixture(t, pool, "tenant_7", taxCodeValue, unique)

	num := 7
	den := 10
	isDefault := true
	isActive := true

	taxRate, err := repo.CreateTaxRate(ctx, CreateTaxRateInput{
		TenantID:               "tenant_7",
		TaxCodeID:              taxCodeID,
		TaxCode:                taxCodeValue,
		RatePercent:            20,
		WithholdingNumerator:   &num,
		WithholdingDenominator: &den,
		ValidFrom:              time.Now().UTC(),
		IsDefault:              true,
		IsActive:               true,
		Description:            "FAZ3 tax rate repository test " + unique,
		CreatedBy:              "faz3_test",
	})
	if err != nil {
		cleanupTaxRateRepositoryFixture(t, pool, "tenant_7", taxCodeID)
		t.Fatalf("create tax rate: %v", err)
	}

	defer cleanupTaxRateRepositoryFixture(t, pool, "tenant_7", taxCodeID)

	if taxRate.TaxRateID == "" {
		t.Fatal("expected tax_rate_id")
	}

	if taxRate.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", taxRate.TenantID)
	}

	if taxRate.TaxCodeID != taxCodeID {
		t.Fatalf("expected tax_code_id %s, got %s", taxCodeID, taxRate.TaxCodeID)
	}

	if taxRate.TaxCode != taxCodeValue {
		t.Fatalf("expected tax_code %s, got %s", taxCodeValue, taxRate.TaxCode)
	}

	if taxRate.RatePercent != 20 {
		t.Fatalf("expected rate_percent 20, got %v", taxRate.RatePercent)
	}

	if taxRate.WithholdingNumerator == nil || *taxRate.WithholdingNumerator != 7 {
		t.Fatalf("expected withholding numerator 7, got %v", taxRate.WithholdingNumerator)
	}

	if taxRate.WithholdingDenominator == nil || *taxRate.WithholdingDenominator != 10 {
		t.Fatalf("expected withholding denominator 10, got %v", taxRate.WithholdingDenominator)
	}

	gotByID, err := repo.GetTaxRateByID(ctx, "tenant_7", taxRate.TaxRateID)
	if err != nil {
		t.Fatalf("get tax rate by id: %v", err)
	}

	if gotByID.TaxRateID != taxRate.TaxRateID {
		t.Fatalf("expected tax_rate_id %s, got %s", taxRate.TaxRateID, gotByID.TaxRateID)
	}

	list, err := repo.ListTaxRates(ctx, "tenant_7", ListTaxRatesFilter{
		TaxCode:   taxCodeValue,
		IsDefault: &isDefault,
		IsActive:  &isActive,
		Query:     unique,
		Limit:     10,
	})
	if err != nil {
		t.Fatalf("list tax rates: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 tax rate in list, got %d", len(list))
	}

	_, err = repo.GetTaxRateByID(ctx, "tenant_99", taxRate.TaxRateID)
	if !errors.Is(err, ErrTaxRateNotFound) {
		t.Fatalf("expected ErrTaxRateNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresTaxRateRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxRateRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxRateRepository(pool)

	_, err = repo.CreateTaxRate(ctx, CreateTaxRateInput{
		TenantID:    "tenant_7",
		TaxCode:     "KDV20",
		RatePercent: 20,
	})

	if !errors.Is(err, ErrTaxCodeIDRequired) {
		t.Fatalf("expected ErrTaxCodeIDRequired, got %v", err)
	}
}

func createTaxRateRepositoryTaxCodeFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, taxCodeValue string, unique string) string {
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

	var taxCodeID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_tax_codes (
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    account_code,
    account_name,
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    'vat',
    '391.01.20',
    'Hesaplanan KDV',
    false,
    true,
    false,
    true,
    $4,
    'active',
    'faz3_tax_rate_test'
)
RETURNING tax_code_id::text;
`, tenantID, taxCodeValue, "KDV Rate Fixture "+unique, "Tax rate fixture "+unique).Scan(&taxCodeID); err != nil {
		t.Fatalf("fixture tax code failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return taxCodeID
}

func cleanupTaxRateRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, taxCodeID string) {
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
