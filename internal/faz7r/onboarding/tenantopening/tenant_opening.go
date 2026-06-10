package tenantopening

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"
)

var (
	ErrValidation      = errors.New("validation failed")
	ErrUnsupported     = errors.New("unsupported value")
	ErrRepositoryWrite = errors.New("repository write failed")
)

var (
	taxIdentityPattern = regexp.MustCompile(`^[0-9]{10,11}$`)
	slugPattern        = regexp.MustCompile(`^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$`)
)

type BusinessOnboardingInput struct {
	TenantID          string
	RequestedByUserID string
	BusinessName      string
	TaxIdentity       string
	AddressLine       string
	City              string
	Country           string
	Sector            string
	BranchName        string
	DefaultCurrency   string
	DefaultLanguage   string
	InitialRole       string
	CorrelationID     string
}

type TenantOpeningInput struct {
	TenantID        string
	TenantSlug      string
	TenantDomain    string
	Environment     string
	DefaultLanguage string
	DefaultCurrency string
	DefaultTimezone string
	DefaultPlan     string
	BranchName      string
	City            string
	Country         string
	RegisterCode    string
	RegisterName    string
	OwnerUserID     string
	OpenedByUserID  string
	CorrelationID   string
}

type BusinessOnboardingRecord struct {
	TenantID          string
	RequestedByUserID string
	BusinessName      string
	TaxIdentity       string
	AddressLine       string
	City              string
	Country           string
	Sector            string
	BranchName        string
	DefaultCurrency   string
	DefaultLanguage   string
	InitialRole       string
	Completed         bool
	CompletedAt       time.Time
	CorrelationID     string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type TenantConfigRecord struct {
	TenantID        string
	TenantSlug      string
	TenantDomain    string
	Environment     string
	Status          string
	DefaultLanguage string
	DefaultCurrency string
	DefaultTimezone string
	DefaultPlan     string
	OpenedByUserID  string
	OpenedAt        time.Time
	CorrelationID   string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type BranchRecord struct {
	BranchID        string
	TenantID        string
	BranchName      string
	City            string
	Country         string
	DefaultCurrency string
	DefaultLanguage string
	Active          bool
	CreatedAt       time.Time
}

type RegisterRecord struct {
	RegisterID   string
	TenantID     string
	BranchID     string
	RegisterCode string
	RegisterName string
	Active       bool
	CreatedAt    time.Time
}

type UserRoleAssignment struct {
	TenantID         string
	UserID           string
	RoleCode         string
	AssignedByUserID string
	AssignedAt       time.Time
}

type AuditEvent struct {
	EventID       string
	TenantID      string
	UserID        string
	EventType     string
	CorrelationID string
	Metadata      map[string]string
	CreatedAt     time.Time
}

type OnboardingResult struct {
	TenantID        string
	Completed       bool
	DefaultLanguage string
	DefaultCurrency string
	InitialRole     string
	NextStep        string
}

type TenantOpeningResult struct {
	TenantID        string
	TenantSlug      string
	Status          string
	DefaultLanguage string
	DefaultPlan     string
	BranchID        string
	RegisterID      string
	OwnerUserID     string
	NextStep        string
}

type Repository interface {
	SaveBusinessOnboarding(ctx context.Context, record BusinessOnboardingRecord) error
	SaveTenantConfig(ctx context.Context, record TenantConfigRecord) error
	SaveBranch(ctx context.Context, record BranchRecord) error
	SaveRegister(ctx context.Context, record RegisterRecord) error
	AssignUserRole(ctx context.Context, record UserRoleAssignment) error
	RecordAudit(ctx context.Context, event AuditEvent) error
}

type Service struct {
	repo Repository
	now  func() time.Time
}

func NewService(repo Repository) *Service {
	return &Service{
		repo: repo,
		now:  time.Now,
	}
}

func (s *Service) SetClock(now func() time.Time) {
	s.now = now
}

func (s *Service) CompleteBusinessOnboarding(ctx context.Context, input BusinessOnboardingInput) (OnboardingResult, error) {
	input = normalizeBusinessInput(input)

	if err := ValidateBusinessOnboardingInput(input); err != nil {
		return OnboardingResult{}, err
	}

	now := s.now().UTC()
	record := BusinessOnboardingRecord{
		TenantID:          input.TenantID,
		RequestedByUserID: input.RequestedByUserID,
		BusinessName:      input.BusinessName,
		TaxIdentity:       input.TaxIdentity,
		AddressLine:       input.AddressLine,
		City:              input.City,
		Country:           input.Country,
		Sector:            input.Sector,
		BranchName:        input.BranchName,
		DefaultCurrency:   input.DefaultCurrency,
		DefaultLanguage:   input.DefaultLanguage,
		InitialRole:       input.InitialRole,
		Completed:         true,
		CompletedAt:       now,
		CorrelationID:     input.CorrelationID,
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	if err := s.repo.SaveBusinessOnboarding(ctx, record); err != nil {
		return OnboardingResult{}, fmt.Errorf("%w: business onboarding: %v", ErrRepositoryWrite, err)
	}

	if err := s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      input.TenantID,
		UserID:        input.RequestedByUserID,
		EventType:     "business_onboarding_completed",
		CorrelationID: input.CorrelationID,
		Metadata: map[string]string{
			"business_name":    input.BusinessName,
			"sector":           input.Sector,
			"default_currency": input.DefaultCurrency,
			"default_language": input.DefaultLanguage,
			"initial_role":     input.InitialRole,
		},
		CreatedAt: now,
	}); err != nil {
		return OnboardingResult{}, fmt.Errorf("%w: audit: %v", ErrRepositoryWrite, err)
	}

	return OnboardingResult{
		TenantID:        input.TenantID,
		Completed:       true,
		DefaultLanguage: input.DefaultLanguage,
		DefaultCurrency: input.DefaultCurrency,
		InitialRole:     input.InitialRole,
		NextStep:        "/pilot-tenant-opening/",
	}, nil
}

func (s *Service) OpenPilotTenant(ctx context.Context, input TenantOpeningInput) (TenantOpeningResult, error) {
	input = normalizeTenantOpeningInput(input)

	if err := ValidateTenantOpeningInput(input); err != nil {
		return TenantOpeningResult{}, err
	}

	now := s.now().UTC()
	branchID := input.TenantID + "-branch-main"
	registerID := input.TenantID + "-register-main"

	config := TenantConfigRecord{
		TenantID:        input.TenantID,
		TenantSlug:      input.TenantSlug,
		TenantDomain:    input.TenantDomain,
		Environment:     input.Environment,
		Status:          "opened",
		DefaultLanguage: input.DefaultLanguage,
		DefaultCurrency: input.DefaultCurrency,
		DefaultTimezone: input.DefaultTimezone,
		DefaultPlan:     input.DefaultPlan,
		OpenedByUserID:  input.OpenedByUserID,
		OpenedAt:        now,
		CorrelationID:   input.CorrelationID,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	branch := BranchRecord{
		BranchID:        branchID,
		TenantID:        input.TenantID,
		BranchName:      input.BranchName,
		City:            input.City,
		Country:         input.Country,
		DefaultCurrency: input.DefaultCurrency,
		DefaultLanguage: input.DefaultLanguage,
		Active:          true,
		CreatedAt:       now,
	}

	register := RegisterRecord{
		RegisterID:   registerID,
		TenantID:     input.TenantID,
		BranchID:     branchID,
		RegisterCode: input.RegisterCode,
		RegisterName: input.RegisterName,
		Active:       true,
		CreatedAt:    now,
	}

	role := UserRoleAssignment{
		TenantID:         input.TenantID,
		UserID:           input.OwnerUserID,
		RoleCode:         "owner",
		AssignedByUserID: input.OpenedByUserID,
		AssignedAt:       now,
	}

	if err := s.repo.SaveTenantConfig(ctx, config); err != nil {
		return TenantOpeningResult{}, fmt.Errorf("%w: tenant config: %v", ErrRepositoryWrite, err)
	}
	if err := s.repo.SaveBranch(ctx, branch); err != nil {
		return TenantOpeningResult{}, fmt.Errorf("%w: branch: %v", ErrRepositoryWrite, err)
	}
	if err := s.repo.SaveRegister(ctx, register); err != nil {
		return TenantOpeningResult{}, fmt.Errorf("%w: register: %v", ErrRepositoryWrite, err)
	}
	if err := s.repo.AssignUserRole(ctx, role); err != nil {
		return TenantOpeningResult{}, fmt.Errorf("%w: user role: %v", ErrRepositoryWrite, err)
	}

	if err := s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      input.TenantID,
		UserID:        input.OpenedByUserID,
		EventType:     "pilot_tenant_opened",
		CorrelationID: input.CorrelationID,
		Metadata: map[string]string{
			"tenant_slug":      input.TenantSlug,
			"default_language": input.DefaultLanguage,
			"default_plan":     input.DefaultPlan,
			"branch_id":        branchID,
			"register_id":      registerID,
			"owner_user_id":    input.OwnerUserID,
		},
		CreatedAt: now,
	}); err != nil {
		return TenantOpeningResult{}, fmt.Errorf("%w: audit: %v", ErrRepositoryWrite, err)
	}

	return TenantOpeningResult{
		TenantID:        input.TenantID,
		TenantSlug:      input.TenantSlug,
		Status:          "opened",
		DefaultLanguage: input.DefaultLanguage,
		DefaultPlan:     input.DefaultPlan,
		BranchID:        branchID,
		RegisterID:      registerID,
		OwnerUserID:     input.OwnerUserID,
		NextStep:        "/user-invite/",
	}, nil
}

func ValidateBusinessOnboardingInput(input BusinessOnboardingInput) error {
	required := map[string]string{
		"tenant_id":            input.TenantID,
		"requested_by_user_id": input.RequestedByUserID,
		"business_name":        input.BusinessName,
		"tax_identity":         input.TaxIdentity,
		"address_line":         input.AddressLine,
		"city":                 input.City,
		"country":              input.Country,
		"sector":               input.Sector,
		"branch_name":          input.BranchName,
		"default_currency":     input.DefaultCurrency,
		"default_language":     input.DefaultLanguage,
		"initial_role":         input.InitialRole,
		"correlation_id":       input.CorrelationID,
	}

	for name, value := range required {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf("%w: %s required", ErrValidation, name)
		}
	}

	if !taxIdentityPattern.MatchString(input.TaxIdentity) {
		return fmt.Errorf("%w: tax identity must be 10 or 11 digits", ErrValidation)
	}
	if !allowedCurrency(input.DefaultCurrency) {
		return fmt.Errorf("%w: currency", ErrUnsupported)
	}
	if !allowedLanguage(input.DefaultLanguage) {
		return fmt.Errorf("%w: language", ErrUnsupported)
	}
	if !allowedRole(input.InitialRole) {
		return fmt.Errorf("%w: role", ErrUnsupported)
	}
	return nil
}

func ValidateTenantOpeningInput(input TenantOpeningInput) error {
	required := map[string]string{
		"tenant_id":         input.TenantID,
		"tenant_slug":       input.TenantSlug,
		"tenant_domain":     input.TenantDomain,
		"environment":       input.Environment,
		"default_language":  input.DefaultLanguage,
		"default_currency":  input.DefaultCurrency,
		"default_timezone":  input.DefaultTimezone,
		"default_plan":      input.DefaultPlan,
		"branch_name":       input.BranchName,
		"city":              input.City,
		"country":           input.Country,
		"register_code":     input.RegisterCode,
		"register_name":     input.RegisterName,
		"owner_user_id":     input.OwnerUserID,
		"opened_by_user_id": input.OpenedByUserID,
		"correlation_id":    input.CorrelationID,
	}

	for name, value := range required {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf("%w: %s required", ErrValidation, name)
		}
	}

	if !slugPattern.MatchString(input.TenantSlug) {
		return fmt.Errorf("%w: tenant slug", ErrValidation)
	}
	if input.DefaultLanguage != "tr-TR" {
		return fmt.Errorf("%w: pilot tenant default language must be tr-TR", ErrValidation)
	}
	if !allowedCurrency(input.DefaultCurrency) {
		return fmt.Errorf("%w: currency", ErrUnsupported)
	}
	if input.Environment != "pilot" && input.Environment != "controlled" {
		return fmt.Errorf("%w: environment", ErrUnsupported)
	}
	return nil
}

func normalizeBusinessInput(input BusinessOnboardingInput) BusinessOnboardingInput {
	input.BusinessName = strings.TrimSpace(input.BusinessName)
	input.TaxIdentity = strings.TrimSpace(input.TaxIdentity)
	input.AddressLine = strings.TrimSpace(input.AddressLine)
	input.City = strings.TrimSpace(input.City)
	input.Country = defaultString(strings.TrimSpace(input.Country), "TR")
	input.Sector = strings.TrimSpace(input.Sector)
	input.BranchName = strings.TrimSpace(input.BranchName)
	input.DefaultCurrency = defaultString(strings.TrimSpace(input.DefaultCurrency), "TRY")
	input.DefaultLanguage = defaultString(strings.TrimSpace(input.DefaultLanguage), "tr-TR")
	input.InitialRole = defaultString(strings.TrimSpace(input.InitialRole), "owner")
	return input
}

func normalizeTenantOpeningInput(input TenantOpeningInput) TenantOpeningInput {
	input.TenantSlug = strings.ToLower(strings.TrimSpace(input.TenantSlug))
	input.TenantDomain = strings.TrimSpace(input.TenantDomain)
	input.Environment = defaultString(strings.TrimSpace(input.Environment), "pilot")
	input.DefaultLanguage = defaultString(strings.TrimSpace(input.DefaultLanguage), "tr-TR")
	input.DefaultCurrency = defaultString(strings.TrimSpace(input.DefaultCurrency), "TRY")
	input.DefaultTimezone = defaultString(strings.TrimSpace(input.DefaultTimezone), "Europe/Istanbul")
	input.DefaultPlan = defaultString(strings.TrimSpace(input.DefaultPlan), "pilot-free-controlled")
	input.BranchName = defaultString(strings.TrimSpace(input.BranchName), "Merkez Şube")
	input.City = strings.TrimSpace(input.City)
	input.Country = defaultString(strings.TrimSpace(input.Country), "TR")
	input.RegisterCode = defaultString(strings.TrimSpace(input.RegisterCode), "KASA-001")
	input.RegisterName = defaultString(strings.TrimSpace(input.RegisterName), "Merkez Kasa")
	return input
}

func allowedCurrency(v string) bool {
	switch v {
	case "TRY", "USD", "EUR":
		return true
	default:
		return false
	}
}

func allowedLanguage(v string) bool {
	switch v {
	case "tr-TR", "ota", "ar", "fa", "en":
		return true
	default:
		return false
	}
}

func allowedRole(v string) bool {
	switch v {
	case "owner", "manager", "cashier", "accountant":
		return true
	default:
		return false
	}
}

func defaultString(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}

func newID(prefix string) string {
	return fmt.Sprintf("%s_%d", prefix, time.Now().UTC().UnixNano())
}

type PostgresRepository struct {
	db *sql.DB
}

func NewPostgresRepository(db *sql.DB) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (r *PostgresRepository) SaveBusinessOnboarding(ctx context.Context, record BusinessOnboardingRecord) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.business_onboardings (
  tenant_id, requested_by_user_id, business_name, tax_identity, address_line, city, country,
  sector, branch_name, default_currency, default_language, initial_role, completed,
  completed_at, correlation_id, created_at, updated_at
) VALUES (
  $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17
)
ON CONFLICT (tenant_id) DO UPDATE SET
  requested_by_user_id = EXCLUDED.requested_by_user_id,
  business_name = EXCLUDED.business_name,
  tax_identity = EXCLUDED.tax_identity,
  address_line = EXCLUDED.address_line,
  city = EXCLUDED.city,
  country = EXCLUDED.country,
  sector = EXCLUDED.sector,
  branch_name = EXCLUDED.branch_name,
  default_currency = EXCLUDED.default_currency,
  default_language = EXCLUDED.default_language,
  initial_role = EXCLUDED.initial_role,
  completed = EXCLUDED.completed,
  completed_at = EXCLUDED.completed_at,
  correlation_id = EXCLUDED.correlation_id,
  updated_at = EXCLUDED.updated_at
`, record.TenantID, record.RequestedByUserID, record.BusinessName, record.TaxIdentity, record.AddressLine,
		record.City, record.Country, record.Sector, record.BranchName, record.DefaultCurrency, record.DefaultLanguage,
		record.InitialRole, record.Completed, record.CompletedAt, record.CorrelationID, record.CreatedAt, record.UpdatedAt)
	return err
}

func (r *PostgresRepository) SaveTenantConfig(ctx context.Context, record TenantConfigRecord) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.tenant_configs (
  tenant_id, tenant_slug, tenant_domain, environment, status, default_language,
  default_currency, default_timezone, default_plan, opened_by_user_id, opened_at,
  correlation_id, created_at, updated_at
) VALUES (
  $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14
)
ON CONFLICT (tenant_id) DO UPDATE SET
  tenant_slug = EXCLUDED.tenant_slug,
  tenant_domain = EXCLUDED.tenant_domain,
  environment = EXCLUDED.environment,
  status = EXCLUDED.status,
  default_language = EXCLUDED.default_language,
  default_currency = EXCLUDED.default_currency,
  default_timezone = EXCLUDED.default_timezone,
  default_plan = EXCLUDED.default_plan,
  opened_by_user_id = EXCLUDED.opened_by_user_id,
  opened_at = EXCLUDED.opened_at,
  correlation_id = EXCLUDED.correlation_id,
  updated_at = EXCLUDED.updated_at
`, record.TenantID, record.TenantSlug, record.TenantDomain, record.Environment, record.Status, record.DefaultLanguage,
		record.DefaultCurrency, record.DefaultTimezone, record.DefaultPlan, record.OpenedByUserID, record.OpenedAt,
		record.CorrelationID, record.CreatedAt, record.UpdatedAt)
	return err
}

func (r *PostgresRepository) SaveBranch(ctx context.Context, record BranchRecord) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.tenant_branches (
  branch_id, tenant_id, branch_name, city, country, default_currency, default_language, active, created_at
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
ON CONFLICT (branch_id) DO UPDATE SET
  branch_name = EXCLUDED.branch_name,
  city = EXCLUDED.city,
  country = EXCLUDED.country,
  default_currency = EXCLUDED.default_currency,
  default_language = EXCLUDED.default_language,
  active = EXCLUDED.active
`, record.BranchID, record.TenantID, record.BranchName, record.City, record.Country, record.DefaultCurrency, record.DefaultLanguage, record.Active, record.CreatedAt)
	return err
}

func (r *PostgresRepository) SaveRegister(ctx context.Context, record RegisterRecord) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.tenant_registers (
  register_id, tenant_id, branch_id, register_code, register_name, active, created_at
) VALUES ($1,$2,$3,$4,$5,$6,$7)
ON CONFLICT (register_id) DO UPDATE SET
  register_code = EXCLUDED.register_code,
  register_name = EXCLUDED.register_name,
  active = EXCLUDED.active
`, record.RegisterID, record.TenantID, record.BranchID, record.RegisterCode, record.RegisterName, record.Active, record.CreatedAt)
	return err
}

func (r *PostgresRepository) AssignUserRole(ctx context.Context, record UserRoleAssignment) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.tenant_user_roles (
  tenant_id, user_id, role_code, assigned_by_user_id, assigned_at
) VALUES ($1,$2,$3,$4,$5)
ON CONFLICT (tenant_id, user_id, role_code) DO UPDATE SET
  assigned_by_user_id = EXCLUDED.assigned_by_user_id,
  assigned_at = EXCLUDED.assigned_at
`, record.TenantID, record.UserID, record.RoleCode, record.AssignedByUserID, record.AssignedAt)
	return err
}

func (r *PostgresRepository) RecordAudit(ctx context.Context, event AuditEvent) error {
	_, err := r.db.ExecContext(ctx, `
INSERT INTO tenant_onboarding.tenant_opening_audit_events (
  event_id, tenant_id, user_id, event_type, correlation_id, metadata, created_at
) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7)
`, event.EventID, event.TenantID, event.UserID, event.EventType, event.CorrelationID, metadataJSON(event.Metadata), event.CreatedAt)
	return err
}

func metadataJSON(m map[string]string) string {
	if len(m) == 0 {
		return "{}"
	}
	parts := make([]string, 0, len(m))
	for k, v := range m {
		parts = append(parts, fmt.Sprintf("%q:%q", k, v))
	}
	return "{" + strings.Join(parts, ",") + "}"
}
