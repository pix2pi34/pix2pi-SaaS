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

func postgresContactRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping contact repository integration test")
	}

	return dsn
}

func TestPostgresContactRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresContactRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	partyRepo := NewPostgresPartyRepository(pool)
	contactRepo := NewPostgresContactRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	party, err := partyRepo.CreateParty(ctx, CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "FAZ3 Contact Repo Market " + unique,
		LegalName:   "FAZ3 Contact Repo Market Ltd",
		TaxNo:       "CNT" + unique,
		TaxOffice:   "Kadikoy",
		Phone:       "05000000000",
		Email:       "contact_party_" + unique + "@example.com",
		Source:      "integration_test",
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		t.Fatalf("create party: %v", err)
	}

	contact, err := contactRepo.CreateContact(ctx, CreateContactInput{
		TenantID:    "tenant_7",
		PartyID:     party.PartyID,
		FullName:    "FAZ3 Contact Yetkili " + unique,
		Title:       "Satinalma Sorumlusu",
		Department:  "Operasyon",
		Phone:       "02120000000",
		MobilePhone: "05000000001",
		Email:       "contact_repo_" + unique + "@example.com",
		IsPrimary:   true,
		CreatedBy:   "faz3_test",
	})
	if err != nil {
		cleanupPostgresContactAndParty(t, pool, "tenant_7", "", party.PartyID)
		t.Fatalf("create contact: %v", err)
	}

	defer cleanupPostgresContactAndParty(t, pool, "tenant_7", contact.ContactID, party.PartyID)

	if contact.ContactID == "" {
		t.Fatal("expected contact_id")
	}

	if contact.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", contact.TenantID)
	}

	if contact.PartyID != party.PartyID {
		t.Fatalf("expected party_id %s, got %s", party.PartyID, contact.PartyID)
	}

	if !contact.IsPrimary {
		t.Fatal("expected primary contact")
	}

	got, err := contactRepo.GetContactByID(ctx, "tenant_7", contact.ContactID)
	if err != nil {
		t.Fatalf("get contact: %v", err)
	}

	if got.ContactID != contact.ContactID {
		t.Fatalf("expected contact_id %s, got %s", contact.ContactID, got.ContactID)
	}

	list, err := contactRepo.ListContacts(ctx, "tenant_7", ListContactsFilter{
		PartyID: party.PartyID,
		Query:   unique,
		Status:  PartyStatusActive,
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("list contacts: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 contact in list, got %d", len(list))
	}

	_, err = contactRepo.GetContactByID(ctx, "tenant_99", contact.ContactID)
	if !errors.Is(err, ErrContactNotFound) {
		t.Fatalf("expected ErrContactNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresContactRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresContactRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	contactRepo := NewPostgresContactRepository(pool)

	_, err = contactRepo.CreateContact(ctx, CreateContactInput{
		TenantID: "tenant_7",
		PartyID:  "party-id",
		Email:    "hatali-email",
	})

	if !errors.Is(err, ErrContactFullNameRequired) {
		t.Fatalf("expected ErrContactFullNameRequired, got %v", err)
	}

	_, err = contactRepo.CreateContact(ctx, CreateContactInput{
		TenantID: "tenant_7",
		PartyID:  "party-id",
		FullName: "Hatali Email",
		Email:    "hatali-email",
	})

	if !errors.Is(err, ErrEmailInvalid) {
		t.Fatalf("expected ErrEmailInvalid, got %v", err)
	}

	_, err = contactRepo.CreateContact(ctx, CreateContactInput{
		TenantID: "",
		PartyID:  "party-id",
		FullName: "Eksik Tenant",
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func cleanupPostgresContactAndParty(t *testing.T, pool *pgxpool.Pool, tenantID string, contactID string, partyID string) {
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

	if contactID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_contacts WHERE contact_id = $1;", contactID); err != nil {
			t.Logf("cleanup contact delete failed: %v", err)
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
