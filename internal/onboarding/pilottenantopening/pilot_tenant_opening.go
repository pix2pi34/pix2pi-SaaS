package pilottenantopening

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"
)

var (
	ErrTenantIDRequired        = errors.New("tenant id required")
	ErrOwnerUserRequired       = errors.New("owner user id required")
	ErrTenantSlugRequired      = errors.New("tenant slug required")
	ErrDefaultLanguageRequired = errors.New("default language required")
	ErrDefaultLanguageInvalid  = errors.New("default language must be tr-TR")
	ErrDefaultCurrencyRequired = errors.New("default currency required")
	ErrDefaultCurrencyInvalid  = errors.New("default currency unsupported")
	ErrDefaultPlanRequired     = errors.New("default plan required")
	ErrBranchNameRequired      = errors.New("branch name required")
	ErrRegisterNameRequired    = errors.New("register name required")
	ErrOwnerMembershipMissing  = errors.New("owner membership missing")
	ErrMethodNotAllowed        = errors.New("method not allowed")
)

type Input struct {
	TenantID        string `json:"tenant_id"`
	OwnerUserID     string `json:"owner_user_id"`
	TenantSlug      string `json:"tenant_slug"`
	DefaultLanguage string `json:"default_language"`
	DefaultCurrency string `json:"default_currency"`
	DefaultPlanCode string `json:"default_plan_code"`
	BranchName      string `json:"branch_name"`
	RegisterName    string `json:"register_name"`
	Timezone        string `json:"timezone"`
	CorrelationID   string `json:"correlation_id"`
}

type Result struct {
	TenantID        string    `json:"tenant_id"`
	OwnerUserID     string    `json:"owner_user_id"`
	TenantSlug      string    `json:"tenant_slug"`
	DefaultLanguage string    `json:"default_language"`
	DefaultCurrency string    `json:"default_currency"`
	DefaultPlanCode string    `json:"default_plan_code"`
	BranchID        string    `json:"branch_id"`
	RegisterID      string    `json:"register_id"`
	OpeningStatus   string    `json:"opening_status"`
	CompletedAt     time.Time `json:"completed_at"`
	CorrelationID   string    `json:"correlation_id"`
}

type TenantConfigRecord struct {
	ID              string
	TenantID        string
	TenantSlug      string
	DefaultLanguage string
	DefaultCurrency string
	Timezone        string
	OpeningMode     string
	CreatedAt       time.Time
}

type PlanBindingRecord struct {
	ID        string
	TenantID  string
	PlanCode  string
	Status    string
	StartedAt time.Time
	CreatedAt time.Time
}

type BranchRecord struct {
	ID            string
	TenantID      string
	LegalEntityID string
	BranchName    string
	Status        string
	CreatedAt     time.Time
}

type RegisterRecord struct {
	ID           string
	TenantID     string
	BranchID     string
	RegisterName string
	RegisterCode string
	Status       string
	CreatedAt    time.Time
}

type OpeningRunRecord struct {
	ID              string
	TenantID        string
	OwnerUserID     string
	TenantSlug      string
	DefaultLanguage string
	DefaultCurrency string
	DefaultPlanCode string
	BranchID        string
	RegisterID      string
	OpeningStatus   string
	CorrelationID   string
	CompletedAt     time.Time
	CreatedAt       time.Time
}

type AuditEvent struct {
	ID            string
	TenantID      string
	OwnerUserID   string
	EventType     string
	Result        string
	ReasonCode    string
	CorrelationID string
	OccurredAt    time.Time
}

type Store interface {
	OwnerMembershipExists(ctx context.Context, tenantID string, ownerUserID string) (bool, error)
	CreateTenantConfig(ctx context.Context, record TenantConfigRecord) error
	CreatePlanBinding(ctx context.Context, record PlanBindingRecord) error
	CreateBranch(ctx context.Context, record BranchRecord) error
	CreateRegister(ctx context.Context, record RegisterRecord) error
	SaveOpeningRun(ctx context.Context, record OpeningRunRecord) error
	RecordAuditEvent(ctx context.Context, event AuditEvent) error
}

type Service struct {
	store Store
	now   func() time.Time
	idgen func(prefix string) string
}

func NewService(store Store, now func() time.Time, idgen func(prefix string) string) *Service {
	if now == nil {
		now = time.Now
	}
	if idgen == nil {
		idgen = func(prefix string) string {
			return prefix + "-" + time.Now().UTC().Format("20060102150405")
		}
	}
	return &Service{store: store, now: now, idgen: idgen}
}

func (s *Service) Provision(ctx context.Context, input Input) (Result, error) {
	input = normalizeInput(input)

	if err := validate(input); err != nil {
		s.record(ctx, input.TenantID, input.OwnerUserID, "pilot_tenant_opening", "rejected", err.Error(), input.CorrelationID)
		return Result{}, err
	}

	ok, err := s.store.OwnerMembershipExists(ctx, input.TenantID, input.OwnerUserID)
	if err != nil {
		return Result{}, err
	}
	if !ok {
		s.record(ctx, input.TenantID, input.OwnerUserID, "pilot_tenant_opening", "rejected", ErrOwnerMembershipMissing.Error(), input.CorrelationID)
		return Result{}, ErrOwnerMembershipMissing
	}

	now := s.now().UTC()
	branchID := s.idgen("branch")
	registerID := s.idgen("register")

	config := TenantConfigRecord{
		ID:              s.idgen("tenant-config"),
		TenantID:        input.TenantID,
		TenantSlug:      input.TenantSlug,
		DefaultLanguage: input.DefaultLanguage,
		DefaultCurrency: input.DefaultCurrency,
		Timezone:        input.Timezone,
		OpeningMode:     "pilot-controlled",
		CreatedAt:       now,
	}

	plan := PlanBindingRecord{
		ID:        s.idgen("plan-binding"),
		TenantID:  input.TenantID,
		PlanCode:  input.DefaultPlanCode,
		Status:    "active",
		StartedAt: now,
		CreatedAt: now,
	}

	branch := BranchRecord{
		ID:            branchID,
		TenantID:      input.TenantID,
		LegalEntityID: "",
		BranchName:    input.BranchName,
		Status:        "active",
		CreatedAt:     now,
	}

	register := RegisterRecord{
		ID:           registerID,
		TenantID:     input.TenantID,
		BranchID:     branchID,
		RegisterName: input.RegisterName,
		RegisterCode: BuildRegisterCode(input.RegisterName),
		Status:       "active",
		CreatedAt:    now,
	}

	run := OpeningRunRecord{
		ID:              s.idgen("opening-run"),
		TenantID:        input.TenantID,
		OwnerUserID:     input.OwnerUserID,
		TenantSlug:      input.TenantSlug,
		DefaultLanguage: input.DefaultLanguage,
		DefaultCurrency: input.DefaultCurrency,
		DefaultPlanCode: input.DefaultPlanCode,
		BranchID:        branchID,
		RegisterID:      registerID,
		OpeningStatus:   "completed",
		CorrelationID:   input.CorrelationID,
		CompletedAt:     now,
		CreatedAt:       now,
	}

	if err := s.store.CreateTenantConfig(ctx, config); err != nil {
		return Result{}, err
	}
	if err := s.store.CreatePlanBinding(ctx, plan); err != nil {
		return Result{}, err
	}
	if err := s.store.CreateBranch(ctx, branch); err != nil {
		return Result{}, err
	}
	if err := s.store.CreateRegister(ctx, register); err != nil {
		return Result{}, err
	}
	if err := s.store.SaveOpeningRun(ctx, run); err != nil {
		return Result{}, err
	}

	s.record(ctx, input.TenantID, input.OwnerUserID, "pilot_tenant_opening", "accepted", "completed", input.CorrelationID)

	return Result{
		TenantID:        input.TenantID,
		OwnerUserID:     input.OwnerUserID,
		TenantSlug:      input.TenantSlug,
		DefaultLanguage: input.DefaultLanguage,
		DefaultCurrency: input.DefaultCurrency,
		DefaultPlanCode: input.DefaultPlanCode,
		BranchID:        branchID,
		RegisterID:      registerID,
		OpeningStatus:   "completed",
		CompletedAt:     now,
		CorrelationID:   input.CorrelationID,
	}, nil
}

func (s *Service) ProvisionHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": ErrMethodNotAllowed.Error()})
		return
	}

	var input Input
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": ErrTenantIDRequired.Error()})
		return
	}

	result, err := s.Provision(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func validate(input Input) error {
	if input.TenantID == "" {
		return ErrTenantIDRequired
	}
	if input.OwnerUserID == "" {
		return ErrOwnerUserRequired
	}
	if input.TenantSlug == "" {
		return ErrTenantSlugRequired
	}
	if input.DefaultLanguage == "" {
		return ErrDefaultLanguageRequired
	}
	if input.DefaultLanguage != "tr-TR" {
		return ErrDefaultLanguageInvalid
	}
	if input.DefaultCurrency == "" {
		return ErrDefaultCurrencyRequired
	}
	if input.DefaultCurrency != "TRY" && input.DefaultCurrency != "USD" && input.DefaultCurrency != "EUR" {
		return ErrDefaultCurrencyInvalid
	}
	if input.DefaultPlanCode == "" {
		return ErrDefaultPlanRequired
	}
	if input.BranchName == "" {
		return ErrBranchNameRequired
	}
	if input.RegisterName == "" {
		return ErrRegisterNameRequired
	}
	return nil
}

func normalizeInput(input Input) Input {
	input.TenantID = strings.TrimSpace(input.TenantID)
	input.OwnerUserID = strings.TrimSpace(input.OwnerUserID)
	input.TenantSlug = normalizeSlug(input.TenantSlug)
	input.DefaultLanguage = strings.TrimSpace(input.DefaultLanguage)
	input.DefaultCurrency = strings.ToUpper(strings.TrimSpace(input.DefaultCurrency))
	input.DefaultPlanCode = strings.TrimSpace(strings.ToLower(input.DefaultPlanCode))
	input.BranchName = strings.TrimSpace(input.BranchName)
	input.RegisterName = strings.TrimSpace(input.RegisterName)
	input.Timezone = strings.TrimSpace(input.Timezone)
	if input.Timezone == "" {
		input.Timezone = "Europe/Istanbul"
	}
	input.CorrelationID = strings.TrimSpace(input.CorrelationID)
	if input.CorrelationID == "" {
		input.CorrelationID = "pilot-tenant-opening-correlation-missing"
	}
	return input
}

func normalizeSlug(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	re := regexp.MustCompile(`[^a-z0-9-]+`)
	value = re.ReplaceAllString(value, "-")
	value = strings.Trim(value, "-")
	return value
}

func BuildRegisterCode(name string) string {
	name = strings.ToLower(strings.TrimSpace(name))
	re := regexp.MustCompile(`[^a-z0-9]+`)
	code := re.ReplaceAllString(name, "-")
	code = strings.Trim(code, "-")
	if code == "" {
		return "register-1"
	}
	return code
}

func (s *Service) record(ctx context.Context, tenantID string, ownerUserID string, eventType string, result string, reasonCode string, correlationID string) {
	if correlationID == "" {
		correlationID = "pilot-tenant-opening-correlation-missing"
	}
	_ = s.store.RecordAuditEvent(ctx, AuditEvent{
		ID:            s.idgen("audit"),
		TenantID:      tenantID,
		OwnerUserID:   ownerUserID,
		EventType:     eventType,
		Result:        result,
		ReasonCode:    reasonCode,
		CorrelationID: correlationID,
		OccurredAt:    s.now().UTC(),
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrTenantIDRequired),
		errors.Is(err, ErrOwnerUserRequired),
		errors.Is(err, ErrTenantSlugRequired),
		errors.Is(err, ErrDefaultLanguageRequired),
		errors.Is(err, ErrDefaultLanguageInvalid),
		errors.Is(err, ErrDefaultCurrencyRequired),
		errors.Is(err, ErrDefaultCurrencyInvalid),
		errors.Is(err, ErrDefaultPlanRequired),
		errors.Is(err, ErrBranchNameRequired),
		errors.Is(err, ErrRegisterNameRequired),
		errors.Is(err, ErrOwnerMembershipMissing):
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
	default:
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
}

func writeJSON(w http.ResponseWriter, status int, value interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
