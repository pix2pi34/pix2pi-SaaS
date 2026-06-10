package productcatalog

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresUnitRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping unit repository integration test")
	}

	return dsn
}

func TestPostgresUnitRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresUnitRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unitRepo := NewPostgresUnitRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	unitCode := "UNIT-" + unique

	unit, err := unitRepo.CreateUnit(ctx, CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         unitCode,
		UnitName:         "FAZ3 Unit Test " + unique,
		UnitType:         UnitTypeQuantity,
		DecimalPrecision: 0,
		IsBaseUnit:       true,
		CreatedBy:        "faz3_test",
	})
	if err != nil {
		t.Fatalf("create unit: %v", err)
	}

	defer cleanupPostgresUnit(t, pool, "tenant_7", unit.UnitID)

	if unit.UnitID == "" {
		t.Fatal("expected unit_id")
	}

	if unit.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", unit.TenantID)
	}

	if unit.UnitCode != unitCode {
		t.Fatalf("expected unit_code %s, got %s", unitCode, unit.UnitCode)
	}

	got, err := unitRepo.GetUnitByID(ctx, "tenant_7", unit.UnitID)
	if err != nil {
		t.Fatalf("get unit: %v", err)
	}

	if got.UnitID != unit.UnitID {
		t.Fatalf("expected unit_id %s, got %s", unit.UnitID, got.UnitID)
	}

	list, err := unitRepo.ListUnits(ctx, "tenant_7", ListUnitsFilter{
		Query:  unique,
		Status: CatalogStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list units: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 unit in list, got %d", len(list))
	}

	_, err = unitRepo.GetUnitByID(ctx, "tenant_99", unit.UnitID)
	if !errors.Is(err, ErrUnitNotFound) {
		t.Fatalf("expected ErrUnitNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresUnitRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresUnitRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unitRepo := NewPostgresUnitRepository(pool)

	_, err = unitRepo.CreateUnit(ctx, CreateUnitInput{
		TenantID: "tenant_7",
		UnitName: "Eksik Kod",
	})

	if !errors.Is(err, ErrUnitCodeRequired) {
		t.Fatalf("expected ErrUnitCodeRequired, got %v", err)
	}
}

func cleanupPostgresUnit(t *testing.T, pool *pgxpool.Pool, tenantID string, unitID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
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

	if unitID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_units WHERE unit_id = $1;", unitID); err != nil {
			t.Logf("cleanup unit delete failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
