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

func postgresPartyRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping repository integration test")
	}

	return dsn
}

func TestPostgresPartyRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPartyRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPartyRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	party, err := repo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "FAZ3 Repository Test Market " + unique,
		LegalName:   "FAZ3 Repository Test Market Ltd",
		TaxNo:       "RPT" + unique,
		TaxOffice:   "Kadikoy",
		Phone:       "05000000000",
		Email:       "repo_" + unique + "@example.com",
		Source:      "integration_test",
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		t.Fatalf("create party: %v", err)
	}

	defer cleanupPostgresParty(t, pool, "tenant_7", party.PartyID)

	if party.PartyID == "" {
		t.Fatal("expected party_id")
	}

	if party.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", party.TenantID)
	}

	got, err := repo.GetPartyByID(ctx, "tenant_7", party.PartyID)
	if err != nil {
		t.Fatalf("get party: %v", err)
	}

	if got.PartyID != party.PartyID {
		t.Fatalf("expected party_id %s, got %s", party.PartyID, got.PartyID)
	}

	list, err := repo.ListParties(ctx, "tenant_7", ListPartiesFilter{
		Query:  unique,
		Status: PartyStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list parties: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 party in list, got %d", len(list))
	}

	_, err = repo.GetPartyByID(ctx, "tenant_99", party.PartyID)
	if !errors.Is(err, ErrPartyNotFound) {
		t.Fatalf("expected ErrPartyNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresPartyRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPartyRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPartyRepository(pool)

	_, err = repo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "Eksik Vergi No",
		TaxOffice:   "Kadikoy",
	})

	if !errors.Is(err, ErrTaxNoRequired) {
		t.Fatalf("expected ErrTaxNoRequired, got %v", err)
	}
}

func cleanupPostgresParty(t *testing.T, pool *pgxpool.Pool, tenantID string, partyID string) {
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

	if _, err := tx.Exec(ctx, "DELETE FROM erp_parties WHERE party_id = $1;", partyID); err != nil {
		t.Logf("cleanup delete failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
