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

func postgresAddressRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping address repository integration test")
	}

	return dsn
}

func TestPostgresAddressRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAddressRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	partyRepo := NewPostgresPartyRepository(pool)
	addressRepo := NewPostgresAddressRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	party, err := partyRepo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "FAZ3 Address Repo Market " + unique,
		LegalName:   "FAZ3 Address Repo Market Ltd",
		TaxNo:       "ADR" + unique,
		TaxOffice:   "Kadikoy",
		Phone:       "05000000000",
		Email:       "address_party_" + unique + "@example.com",
		Source:      "integration_test",
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		t.Fatalf("create party: %v", err)
	}

	address, err := addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:          "tenant_7",
		PartyID:           party.PartyID,
		AddressType:       AddressTypeInvoice,
		CountryCode:       "TR",
		City:              "Istanbul",
		District:          "Kadikoy",
		Neighborhood:      "Caferaga",
		AddressLine1:      "FAZ3 Test Sokak No: " + unique,
		AddressLine2:      "Kat 1",
		PostalCode:        "34710",
		IsPrimary:         true,
		IsInvoiceAddress:  true,
		IsDeliveryAddress: false,
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupPostgresAddressAndParty(t, pool, "tenant_7", "", party.PartyID)
		t.Fatalf("create address: %v", err)
	}

	defer cleanupPostgresAddressAndParty(t, pool, "tenant_7", address.AddressID, party.PartyID)

	if address.AddressID == "" {
		t.Fatal("expected address_id")
	}

	if address.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", address.TenantID)
	}

	if address.PartyID != party.PartyID {
		t.Fatalf("expected party_id %s, got %s", party.PartyID, address.PartyID)
	}

	if address.AddressType != AddressTypeInvoice {
		t.Fatalf("expected invoice address, got %s", address.AddressType)
	}

	if !address.IsPrimary {
		t.Fatal("expected primary address")
	}

	if !address.IsInvoiceAddress {
		t.Fatal("expected invoice address flag")
	}

	got, err := addressRepo.GetAddressByID(ctx, "tenant_7", address.AddressID)
	if err != nil {
		t.Fatalf("get address: %v", err)
	}

	if got.AddressID != address.AddressID {
		t.Fatalf("expected address_id %s, got %s", address.AddressID, got.AddressID)
	}

	list, err := addressRepo.ListAddresses(ctx, "tenant_7", ListAddressesFilter{
		PartyID:     party.PartyID,
		AddressType: AddressTypeInvoice,
		Query:       unique,
		Status:      PartyStatusActive,
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("list addresses: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 address in list, got %d", len(list))
	}

	_, err = addressRepo.GetAddressByID(ctx, "tenant_99", address.AddressID)
	if !errors.Is(err, ErrAddressNotFound) {
		t.Fatalf("expected ErrAddressNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresAddressRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAddressRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	addressRepo := NewPostgresAddressRepository(pool)

	_, err = addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:     "",
		PartyID:      "party-id",
		AddressType:  AddressTypeInvoice,
		City:         "Istanbul",
		AddressLine1: "Adres",
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	_, err = addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:     "tenant_7",
		PartyID:      "",
		AddressType:  AddressTypeInvoice,
		City:         "Istanbul",
		AddressLine1: "Adres",
	})

	if !errors.Is(err, ErrPartyIDRequired) {
		t.Fatalf("expected ErrPartyIDRequired, got %v", err)
	}

	_, err = addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:     "tenant_7",
		PartyID:      "party-id",
		AddressType:  AddressType("wrong"),
		City:         "Istanbul",
		AddressLine1: "Adres",
	})

	if !errors.Is(err, ErrAddressTypeInvalid) {
		t.Fatalf("expected ErrAddressTypeInvalid, got %v", err)
	}

	_, err = addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:     "tenant_7",
		PartyID:      "party-id",
		AddressType:  AddressTypeInvoice,
		AddressLine1: "Adres",
	})

	if !errors.Is(err, ErrAddressCityRequired) {
		t.Fatalf("expected ErrAddressCityRequired, got %v", err)
	}

	_, err = addressRepo.CreateAddress(ctx, CreateAddressInput{
		TenantID:    "tenant_7",
		PartyID:     "party-id",
		AddressType: AddressTypeInvoice,
		City:        "Istanbul",
	})

	if !errors.Is(err, ErrAddressLine1Required) {
		t.Fatalf("expected ErrAddressLine1Required, got %v", err)
	}
}

func cleanupPostgresAddressAndParty(t *testing.T, pool *pgxpool.Pool, tenantID string, addressID string, partyID string) {
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

	if addressID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_addresses WHERE address_id = $1;", addressID); err != nil {
			t.Logf("cleanup address delete failed: %v", err)
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
