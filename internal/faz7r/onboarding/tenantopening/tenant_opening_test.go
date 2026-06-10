package tenantopening

import (
	"context"
	"errors"
	"testing"
	"time"
)

func serviceForTest() (*Service, *MemoryRepository) {
	repo := NewMemoryRepository()
	service := NewService(repo)
	service.SetClock(func() time.Time {
		return time.Date(2026, 5, 11, 15, 0, 0, 0, time.UTC)
	})
	return service, repo
}

func validBusinessInput() BusinessOnboardingInput {
	return BusinessOnboardingInput{
		TenantID:          "tenant-pilot-001",
		RequestedByUserID: "user-owner-001",
		BusinessName:      "Pix2pi Pilot Market",
		TaxIdentity:       "1234567890",
		AddressLine:       "Merkez Mah. Ticaret Cad. No:1",
		City:              "İstanbul",
		Country:           "TR",
		Sector:            "perakende",
		BranchName:        "Merkez Şube",
		DefaultCurrency:   "TRY",
		DefaultLanguage:   "tr-TR",
		InitialRole:       "owner",
		CorrelationID:     "corr-319",
	}
}

func validOpeningInput() TenantOpeningInput {
	return TenantOpeningInput{
		TenantID:        "tenant-pilot-001",
		TenantSlug:      "pix2pi-pilot-market",
		TenantDomain:    "panel.pix2pi.com.tr",
		Environment:     "pilot",
		DefaultLanguage: "tr-TR",
		DefaultCurrency: "TRY",
		DefaultTimezone: "Europe/Istanbul",
		DefaultPlan:     "pilot-free-controlled",
		BranchName:      "Merkez Şube",
		City:            "İstanbul",
		Country:         "TR",
		RegisterCode:    "KASA-001",
		RegisterName:    "Merkez Kasa",
		OwnerUserID:     "user-owner-001",
		OpenedByUserID:  "platform-admin-001",
		CorrelationID:   "corr-347",
	}
}

func Test319CompleteBusinessOnboardingWritesAllFields(t *testing.T) {
	ctx := context.Background()
	service, repo := serviceForTest()

	result, err := service.CompleteBusinessOnboarding(ctx, validBusinessInput())
	if err != nil {
		t.Fatalf("CompleteBusinessOnboarding failed: %v", err)
	}

	if !result.Completed {
		t.Fatalf("expected onboarding completed")
	}

	record := repo.Business["tenant-pilot-001"]
	if record.BusinessName != "Pix2pi Pilot Market" {
		t.Fatalf("business name not persisted")
	}
	if record.TaxIdentity != "1234567890" {
		t.Fatalf("tax identity not persisted")
	}
	if record.AddressLine == "" || record.Sector == "" || record.BranchName == "" {
		t.Fatalf("319 required business fields not persisted")
	}
	if record.DefaultCurrency != "TRY" || record.DefaultLanguage != "tr-TR" || record.InitialRole != "owner" {
		t.Fatalf("319 default values not persisted")
	}
	if len(repo.AuditEvents) == 0 {
		t.Fatalf("audit event not recorded")
	}
}

func Test319RejectsMissingRequiredBusinessData(t *testing.T) {
	ctx := context.Background()
	service, _ := serviceForTest()

	input := validBusinessInput()
	input.BusinessName = ""

	_, err := service.CompleteBusinessOnboarding(ctx, input)
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func Test319RejectsInvalidTaxIdentity(t *testing.T) {
	ctx := context.Background()
	service, _ := serviceForTest()

	input := validBusinessInput()
	input.TaxIdentity = "abc"

	_, err := service.CompleteBusinessOnboarding(ctx, input)
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func Test347OpenPilotTenantCreatesConfigBranchRegisterAndOwner(t *testing.T) {
	ctx := context.Background()
	service, repo := serviceForTest()

	result, err := service.OpenPilotTenant(ctx, validOpeningInput())
	if err != nil {
		t.Fatalf("OpenPilotTenant failed: %v", err)
	}

	if result.Status != "opened" {
		t.Fatalf("unexpected tenant status: %s", result.Status)
	}
	if result.DefaultLanguage != "tr-TR" {
		t.Fatalf("pilot tenant default language must be tr-TR")
	}
	if result.DefaultPlan != "pilot-free-controlled" {
		t.Fatalf("default plan not set")
	}
	if result.BranchID == "" || result.RegisterID == "" {
		t.Fatalf("branch/register not created")
	}

	config := repo.Configs["tenant-pilot-001"]
	if config.TenantSlug != "pix2pi-pilot-market" {
		t.Fatalf("tenant config not persisted")
	}

	if _, ok := repo.Branches[result.BranchID]; !ok {
		t.Fatalf("branch not persisted")
	}
	if _, ok := repo.Registers[result.RegisterID]; !ok {
		t.Fatalf("register not persisted")
	}
	if _, ok := repo.Roles["tenant-pilot-001:user-owner-001:owner"]; !ok {
		t.Fatalf("owner role not assigned")
	}
}

func Test347RequiresDefaultLanguageTrTR(t *testing.T) {
	ctx := context.Background()
	service, _ := serviceForTest()

	input := validOpeningInput()
	input.DefaultLanguage = "en"

	_, err := service.OpenPilotTenant(ctx, input)
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func Test319And347EndToEndFlow(t *testing.T) {
	ctx := context.Background()
	service, repo := serviceForTest()

	onboarding, err := service.CompleteBusinessOnboarding(ctx, validBusinessInput())
	if err != nil {
		t.Fatalf("onboarding failed: %v", err)
	}
	if onboarding.NextStep != "/pilot-tenant-opening/" {
		t.Fatalf("unexpected onboarding next step")
	}

	opening, err := service.OpenPilotTenant(ctx, validOpeningInput())
	if err != nil {
		t.Fatalf("opening failed: %v", err)
	}
	if opening.NextStep != "/user-invite/" {
		t.Fatalf("unexpected opening next step")
	}

	if len(repo.Business) != 1 || len(repo.Configs) != 1 || len(repo.Branches) != 1 || len(repo.Registers) != 1 || len(repo.Roles) != 1 {
		t.Fatalf("end-to-end repository state incomplete")
	}
	if len(repo.AuditEvents) < 2 {
		t.Fatalf("expected onboarding and opening audit events")
	}
}
