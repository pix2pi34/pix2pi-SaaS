package masterparty

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresVendorRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping vendor repository integration test")
	}

	return dsn
}

func TestPostgresVendorRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresVendorRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	partyRepo := NewPostgresPartyRepository(pool)
	vendorRepo := NewPostgresVendorRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	party, err := partyRepo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "FAZ3 Vendor Repo Tedarikci " + unique,
		LegalName:   "FAZ3 Vendor Repo Tedarikci Ltd",
		TaxNo:       "VND" + unique,
		TaxOffice:   "Kadikoy",
		Phone:       "05000000000",
		Email:       "vendor_repo_" + unique + "@example.com",
		Source:      "integration_test",
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		t.Fatalf("create party: %v", err)
	}

	vendorCode := "VEND-" + unique

	vendor, err := vendorRepo.CreateVendor(ctx, "tenant_7", party.PartyID, vendorCode)
	if err != nil {
		cleanupPostgresVendorAndParty(t, pool, "tenant_7", "", party.PartyID)
		t.Fatalf("create vendor: %v", err)
	}

	defer cleanupPostgresVendorAndParty(t, pool, "tenant_7", vendor.VendorID, party.PartyID)

	if vendor.VendorID == "" {
		t.Fatal("expected vendor_id")
	}

	if vendor.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", vendor.TenantID)
	}

	if vendor.PartyID != party.PartyID {
		t.Fatalf("expected party_id %s, got %s", party.PartyID, vendor.PartyID)
	}

	if vendor.VendorCode != vendorCode {
		t.Fatalf("expected vendor_code %s, got %s", vendorCode, vendor.VendorCode)
	}

	got, err := vendorRepo.GetVendorByID(ctx, "tenant_7", vendor.VendorID)
	if err != nil {
		t.Fatalf("get vendor: %v", err)
	}

	if got.VendorID != vendor.VendorID {
		t.Fatalf("expected vendor_id %s, got %s", vendor.VendorID, got.VendorID)
	}

	list, err := vendorRepo.ListVendors(ctx, "tenant_7", ListVendorsFilter{
		Query:  unique,
		Status: PartyStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list vendors: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 vendor in list, got %d", len(list))
	}

	_, err = vendorRepo.GetVendorByID(ctx, "tenant_99", vendor.VendorID)
	if !errors.Is(err, ErrVendorNotFound) {
		t.Fatalf("expected ErrVendorNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresVendorRepositoryTenantRequired(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresVendorRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	vendorRepo := NewPostgresVendorRepository(pool)

	_, err = vendorRepo.CreateVendor(ctx, "", "party-id", "VEND-EMPTY-TENANT")
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func cleanupPostgresVendorAndParty(t *testing.T, pool *pgxpool.Pool, tenantID string, vendorID string, partyID string) {
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

	if vendorID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_vendors WHERE vendor_id = $1;", vendorID); err != nil {
			t.Logf("cleanup vendor delete failed: %v", err)
			return
		}
	}

	if partyID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_parties WHERE party_id = $1;", partyID); err != nil {
			t.Logf("cleanup party delete failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
