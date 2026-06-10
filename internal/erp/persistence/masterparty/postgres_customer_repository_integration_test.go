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

func postgresCustomerRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping customer repository integration test")
	}

	return dsn
}

func TestPostgresCustomerRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCustomerRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	partyRepo := NewPostgresPartyRepository(pool)
	customerRepo := NewPostgresCustomerRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	party, err := partyRepo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "FAZ3 Customer Repo Market " + unique,
		LegalName:   "FAZ3 Customer Repo Market Ltd",
		TaxNo:       "CST" + unique,
		TaxOffice:   "Kadikoy",
		Phone:       "05000000000",
		Email:       "customer_repo_" + unique + "@example.com",
		Source:      "integration_test",
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		t.Fatalf("create party: %v", err)
	}

	customerCode := "CUST-" + unique

	customer, err := customerRepo.CreateCustomer(ctx, "tenant_7", party.PartyID, customerCode)
	if err != nil {
		cleanupPostgresCustomerAndParty(t, pool, "tenant_7", "", party.PartyID)
		t.Fatalf("create customer: %v", err)
	}

	defer cleanupPostgresCustomerAndParty(t, pool, "tenant_7", customer.CustomerID, party.PartyID)

	if customer.CustomerID == "" {
		t.Fatal("expected customer_id")
	}

	if customer.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", customer.TenantID)
	}

	if customer.PartyID != party.PartyID {
		t.Fatalf("expected party_id %s, got %s", party.PartyID, customer.PartyID)
	}

	if customer.CustomerCode != customerCode {
		t.Fatalf("expected customer_code %s, got %s", customerCode, customer.CustomerCode)
	}

	got, err := customerRepo.GetCustomerByID(ctx, "tenant_7", customer.CustomerID)
	if err != nil {
		t.Fatalf("get customer: %v", err)
	}

	if got.CustomerID != customer.CustomerID {
		t.Fatalf("expected customer_id %s, got %s", customer.CustomerID, got.CustomerID)
	}

	list, err := customerRepo.ListCustomers(ctx, "tenant_7", ListCustomersFilter{
		Query:  unique,
		Status: PartyStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list customers: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 customer in list, got %d", len(list))
	}

	_, err = customerRepo.GetCustomerByID(ctx, "tenant_99", customer.CustomerID)
	if !errors.Is(err, ErrCustomerNotFound) {
		t.Fatalf("expected ErrCustomerNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresCustomerRepositoryTenantRequired(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCustomerRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	customerRepo := NewPostgresCustomerRepository(pool)

	_, err = customerRepo.CreateCustomer(ctx, "", "party-id", "CUST-EMPTY-TENANT")
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func cleanupPostgresCustomerAndParty(t *testing.T, pool *pgxpool.Pool, tenantID string, customerID string, partyID string) {
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

	if customerID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_customers WHERE customer_id = $1;", customerID); err != nil {
			t.Logf("cleanup customer delete failed: %v", err)
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
