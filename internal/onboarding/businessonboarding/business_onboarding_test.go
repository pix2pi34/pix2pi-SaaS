package businessonboarding

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type memoryStore struct {
	tenants     []TenantRecord
	legals      []LegalEntityRecord
	branches    []BranchRecord
	memberships []MembershipRecord
	requests    []OnboardingRequestRecord
	auditEvents []AuditEvent
}

func (s *memoryStore) CreateTenant(_ context.Context, record TenantRecord) error {
	s.tenants = append(s.tenants, record)
	return nil
}

func (s *memoryStore) CreateLegalEntity(_ context.Context, record LegalEntityRecord) error {
	s.legals = append(s.legals, record)
	return nil
}

func (s *memoryStore) CreateBranch(_ context.Context, record BranchRecord) error {
	s.branches = append(s.branches, record)
	return nil
}

func (s *memoryStore) CreateMembership(_ context.Context, record MembershipRecord) error {
	s.memberships = append(s.memberships, record)
	return nil
}

func (s *memoryStore) SaveOnboardingRequest(_ context.Context, record OnboardingRequestRecord) error {
	s.requests = append(s.requests, record)
	return nil
}

func (s *memoryStore) RecordAuditEvent(_ context.Context, event AuditEvent) error {
	s.auditEvents = append(s.auditEvents, event)
	return nil
}

func testService() (*Service, *memoryStore) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	counter := 0
	store := &memoryStore{}
	service := NewService(store, func() time.Time { return now }, func(prefix string) string {
		counter++
		return prefix + "-id-" + string(rune('0'+counter))
	})
	return service, store
}

func validInput() Input {
	return Input{
		OwnerUserID:   "user-001",
		BusinessName:  "Örnek Market",
		TaxOrTCKN:     "1234567890",
		AddressLine:   "Atatürk Caddesi No:1",
		City:          "İstanbul",
		District:      "Fatih",
		SectorCode:    "market",
		BranchName:    "Merkez Şube",
		CurrencyCode:  "TRY",
		LanguageCode:  "tr-TR",
		FirstRoleCode: "owner",
		CorrelationID: "corr-319",
	}
}

func TestCompleteCreatesTenantLegalBranchMembershipAndRequest(t *testing.T) {
	service, store := testService()

	result, err := service.Complete(context.Background(), validInput())
	if err != nil {
		t.Fatalf("Complete error: %v", err)
	}

	if result.Status != "completed" {
		t.Fatalf("status mismatch: %s", result.Status)
	}
	if result.TenantSlug != "ornek-market" {
		t.Fatalf("slug mismatch: %s", result.TenantSlug)
	}
	if len(store.tenants) != 1 {
		t.Fatalf("tenant not created")
	}
	if len(store.legals) != 1 {
		t.Fatalf("legal entity not created")
	}
	if len(store.branches) != 1 {
		t.Fatalf("branch not created")
	}
	if len(store.memberships) != 1 {
		t.Fatalf("membership not created")
	}
	if store.memberships[0].RoleCode != "owner" {
		t.Fatalf("role mismatch: %s", store.memberships[0].RoleCode)
	}
	if len(store.requests) != 1 {
		t.Fatalf("onboarding request not saved")
	}
	if len(store.auditEvents) != 1 {
		t.Fatalf("audit event not recorded")
	}
}

func TestValidationRejectsMissingBusinessName(t *testing.T) {
	service, _ := testService()
	input := validInput()
	input.BusinessName = ""

	_, err := service.Complete(context.Background(), input)
	if !errors.Is(err, ErrBusinessNameRequired) {
		t.Fatalf("expected ErrBusinessNameRequired, got %v", err)
	}
}

func TestValidationRejectsInvalidTaxOrTCKN(t *testing.T) {
	service, _ := testService()
	input := validInput()
	input.TaxOrTCKN = "abc"

	_, err := service.Complete(context.Background(), input)
	if !errors.Is(err, ErrTaxOrTCKNInvalid) {
		t.Fatalf("expected ErrTaxOrTCKNInvalid, got %v", err)
	}
}

func TestValidationRejectsUnsupportedLanguageCurrencyAndRole(t *testing.T) {
	service, _ := testService()

	input := validInput()
	input.LanguageCode = "de"
	_, err := service.Complete(context.Background(), input)
	if !errors.Is(err, ErrLanguageUnsupported) {
		t.Fatalf("expected ErrLanguageUnsupported, got %v", err)
	}

	input = validInput()
	input.CurrencyCode = "GBP"
	_, err = service.Complete(context.Background(), input)
	if !errors.Is(err, ErrCurrencyUnsupported) {
		t.Fatalf("expected ErrCurrencyUnsupported, got %v", err)
	}

	input = validInput()
	input.FirstRoleCode = "unknown"
	_, err = service.Complete(context.Background(), input)
	if !errors.Is(err, ErrFirstRoleUnsupported) {
		t.Fatalf("expected ErrFirstRoleUnsupported, got %v", err)
	}
}

func TestBuildTenantSlug(t *testing.T) {
	got := BuildTenantSlug("Çağrı Şarküteri 2026")
	want := "cagri-sarkuteri-2026"
	if got != want {
		t.Fatalf("slug mismatch got=%s want=%s", got, want)
	}
}

func TestCompleteHTTP(t *testing.T) {
	service, _ := testService()

	body := bytes.NewBufferString(`{
		"owner_user_id":"user-001",
		"business_name":"Örnek Market",
		"tax_or_tckn":"1234567890",
		"address_line":"Atatürk Caddesi No:1",
		"city":"İstanbul",
		"district":"Fatih",
		"sector_code":"market",
		"branch_name":"Merkez Şube",
		"currency_code":"TRY",
		"language_code":"tr-TR",
		"first_role_code":"owner",
		"correlation_id":"corr-http"
	}`)
	req := httptest.NewRequest(http.MethodPost, "/api/onboarding/business", body)
	rec := httptest.NewRecorder()

	service.CompleteHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
}
