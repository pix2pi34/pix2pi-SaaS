package pilottenantopening

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
	ownerMembership bool
	configs         []TenantConfigRecord
	plans           []PlanBindingRecord
	branches        []BranchRecord
	registers       []RegisterRecord
	runs            []OpeningRunRecord
	auditEvents     []AuditEvent
}

func (s *memoryStore) OwnerMembershipExists(_ context.Context, tenantID string, ownerUserID string) (bool, error) {
	return s.ownerMembership && tenantID == "tenant-001" && ownerUserID == "user-001", nil
}

func (s *memoryStore) CreateTenantConfig(_ context.Context, record TenantConfigRecord) error {
	s.configs = append(s.configs, record)
	return nil
}

func (s *memoryStore) CreatePlanBinding(_ context.Context, record PlanBindingRecord) error {
	s.plans = append(s.plans, record)
	return nil
}

func (s *memoryStore) CreateBranch(_ context.Context, record BranchRecord) error {
	s.branches = append(s.branches, record)
	return nil
}

func (s *memoryStore) CreateRegister(_ context.Context, record RegisterRecord) error {
	s.registers = append(s.registers, record)
	return nil
}

func (s *memoryStore) SaveOpeningRun(_ context.Context, record OpeningRunRecord) error {
	s.runs = append(s.runs, record)
	return nil
}

func (s *memoryStore) RecordAuditEvent(_ context.Context, event AuditEvent) error {
	s.auditEvents = append(s.auditEvents, event)
	return nil
}

func testService(ownerMembership bool) (*Service, *memoryStore) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	counter := 0
	store := &memoryStore{ownerMembership: ownerMembership}
	service := NewService(store, func() time.Time { return now }, func(prefix string) string {
		counter++
		return prefix + "-id-" + string(rune('0'+counter))
	})
	return service, store
}

func validInput() Input {
	return Input{
		TenantID:        "tenant-001",
		OwnerUserID:     "user-001",
		TenantSlug:      "ornek-market",
		DefaultLanguage: "tr-TR",
		DefaultCurrency: "TRY",
		DefaultPlanCode: "pilot-controlled",
		BranchName:      "Merkez Şube",
		RegisterName:    "Kasa 1",
		Timezone:        "Europe/Istanbul",
		CorrelationID:   "corr-347",
	}
}

func TestProvisionCreatesConfigPlanBranchRegisterAndRun(t *testing.T) {
	service, store := testService(true)

	result, err := service.Provision(context.Background(), validInput())
	if err != nil {
		t.Fatalf("Provision error: %v", err)
	}

	if result.OpeningStatus != "completed" {
		t.Fatalf("status mismatch: %s", result.OpeningStatus)
	}
	if result.DefaultLanguage != "tr-TR" {
		t.Fatalf("language mismatch: %s", result.DefaultLanguage)
	}
	if len(store.configs) != 1 {
		t.Fatalf("tenant config not created")
	}
	if len(store.plans) != 1 {
		t.Fatalf("plan binding not created")
	}
	if len(store.branches) != 1 {
		t.Fatalf("branch not created")
	}
	if len(store.registers) != 1 {
		t.Fatalf("register not created")
	}
	if len(store.runs) != 1 {
		t.Fatalf("opening run not saved")
	}
	if len(store.auditEvents) != 1 {
		t.Fatalf("audit event not recorded")
	}
}

func TestProvisionRejectsMissingTenantAndOwner(t *testing.T) {
	service, _ := testService(true)

	input := validInput()
	input.TenantID = ""
	_, err := service.Provision(context.Background(), input)
	if !errors.Is(err, ErrTenantIDRequired) {
		t.Fatalf("expected ErrTenantIDRequired, got %v", err)
	}

	input = validInput()
	input.OwnerUserID = ""
	_, err = service.Provision(context.Background(), input)
	if !errors.Is(err, ErrOwnerUserRequired) {
		t.Fatalf("expected ErrOwnerUserRequired, got %v", err)
	}
}

func TestProvisionRequiresTRDefaultLanguage(t *testing.T) {
	service, _ := testService(true)

	input := validInput()
	input.DefaultLanguage = "en"
	_, err := service.Provision(context.Background(), input)
	if !errors.Is(err, ErrDefaultLanguageInvalid) {
		t.Fatalf("expected ErrDefaultLanguageInvalid, got %v", err)
	}
}

func TestProvisionRejectsMissingPlanBranchRegister(t *testing.T) {
	service, _ := testService(true)

	input := validInput()
	input.DefaultPlanCode = ""
	_, err := service.Provision(context.Background(), input)
	if !errors.Is(err, ErrDefaultPlanRequired) {
		t.Fatalf("expected ErrDefaultPlanRequired, got %v", err)
	}

	input = validInput()
	input.BranchName = ""
	_, err = service.Provision(context.Background(), input)
	if !errors.Is(err, ErrBranchNameRequired) {
		t.Fatalf("expected ErrBranchNameRequired, got %v", err)
	}

	input = validInput()
	input.RegisterName = ""
	_, err = service.Provision(context.Background(), input)
	if !errors.Is(err, ErrRegisterNameRequired) {
		t.Fatalf("expected ErrRegisterNameRequired, got %v", err)
	}
}

func TestProvisionRequiresOwnerMembership(t *testing.T) {
	service, _ := testService(false)

	_, err := service.Provision(context.Background(), validInput())
	if !errors.Is(err, ErrOwnerMembershipMissing) {
		t.Fatalf("expected ErrOwnerMembershipMissing, got %v", err)
	}
}

func TestBuildRegisterCode(t *testing.T) {
	got := BuildRegisterCode("Kasa 1")
	if got != "kasa-1" {
		t.Fatalf("register code mismatch: %s", got)
	}
}

func TestProvisionHTTP(t *testing.T) {
	service, _ := testService(true)

	body := bytes.NewBufferString(`{
		"tenant_id":"tenant-001",
		"owner_user_id":"user-001",
		"tenant_slug":"ornek-market",
		"default_language":"tr-TR",
		"default_currency":"TRY",
		"default_plan_code":"pilot-controlled",
		"branch_name":"Merkez Şube",
		"register_name":"Kasa 1",
		"timezone":"Europe/Istanbul",
		"correlation_id":"corr-http"
	}`)
	req := httptest.NewRequest(http.MethodPost, "/api/pilot-tenant/opening", body)
	rec := httptest.NewRecorder()

	service.ProvisionHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rec.Code, rec.Body.String())
	}
}
