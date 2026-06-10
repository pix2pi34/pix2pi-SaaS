package businessonboarding

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"
	"unicode"
)

var (
	ErrOwnerUserRequired    = errors.New("owner user id required")
	ErrBusinessNameRequired = errors.New("business name required")
	ErrTaxOrTCKNInvalid     = errors.New("tax or tckn invalid")
	ErrAddressRequired      = errors.New("address required")
	ErrCityRequired         = errors.New("city required")
	ErrDistrictRequired     = errors.New("district required")
	ErrSectorRequired       = errors.New("sector required")
	ErrBranchRequired       = errors.New("branch required")
	ErrCurrencyUnsupported  = errors.New("currency unsupported")
	ErrLanguageUnsupported  = errors.New("language unsupported")
	ErrFirstRoleUnsupported = errors.New("first role unsupported")
	ErrMethodNotAllowed     = errors.New("method not allowed")
)

type Input struct {
	OwnerUserID   string `json:"owner_user_id"`
	BusinessName  string `json:"business_name"`
	TaxOrTCKN     string `json:"tax_or_tckn"`
	AddressLine   string `json:"address_line"`
	City          string `json:"city"`
	District      string `json:"district"`
	SectorCode    string `json:"sector_code"`
	BranchName    string `json:"branch_name"`
	CurrencyCode  string `json:"currency_code"`
	LanguageCode  string `json:"language_code"`
	FirstRoleCode string `json:"first_role_code"`
	CorrelationID string `json:"correlation_id"`
}

type Result struct {
	TenantID      string    `json:"tenant_id"`
	TenantSlug    string    `json:"tenant_slug"`
	LegalEntityID string    `json:"legal_entity_id"`
	BranchID      string    `json:"branch_id"`
	OwnerUserID   string    `json:"owner_user_id"`
	BusinessName  string    `json:"business_name"`
	CurrencyCode  string    `json:"currency_code"`
	LanguageCode  string    `json:"language_code"`
	FirstRoleCode string    `json:"first_role_code"`
	Status        string    `json:"status"`
	CompletedAt   time.Time `json:"completed_at"`
	CorrelationID string    `json:"correlation_id"`
}

type TenantRecord struct {
	ID              string
	Slug            string
	Name            string
	Status          string
	DefaultLanguage string
	DefaultCurrency string
	CreatedAt       time.Time
}

type LegalEntityRecord struct {
	ID          string
	TenantID    string
	LegalName   string
	TaxOrTCKN   string
	AddressLine string
	City        string
	District    string
	CreatedAt   time.Time
}

type BranchRecord struct {
	ID            string
	TenantID      string
	LegalEntityID string
	BranchName    string
	Status        string
	CreatedAt     time.Time
}

type MembershipRecord struct {
	ID        string
	TenantID  string
	UserID    string
	RoleCode  string
	Status    string
	CreatedAt time.Time
}

type OnboardingRequestRecord struct {
	ID            string
	TenantID      string
	OwnerUserID   string
	TenantSlug    string
	BusinessName  string
	TaxOrTCKN     string
	AddressLine   string
	City          string
	District      string
	SectorCode    string
	BranchName    string
	CurrencyCode  string
	LanguageCode  string
	FirstRoleCode string
	Status        string
	CompletedAt   time.Time
	CorrelationID string
	CreatedAt     time.Time
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
	CreateTenant(ctx context.Context, record TenantRecord) error
	CreateLegalEntity(ctx context.Context, record LegalEntityRecord) error
	CreateBranch(ctx context.Context, record BranchRecord) error
	CreateMembership(ctx context.Context, record MembershipRecord) error
	SaveOnboardingRequest(ctx context.Context, record OnboardingRequestRecord) error
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

func (s *Service) Complete(ctx context.Context, input Input) (Result, error) {
	input = normalizeInput(input)

	if err := validate(input); err != nil {
		s.record(ctx, "", input.OwnerUserID, "business_onboarding", "rejected", err.Error(), input.CorrelationID)
		return Result{}, err
	}

	now := s.now().UTC()
	tenantID := s.idgen("tenant")
	legalEntityID := s.idgen("legal")
	branchID := s.idgen("branch")
	membershipID := s.idgen("membership")
	requestID := s.idgen("onboarding")
	tenantSlug := BuildTenantSlug(input.BusinessName)

	tenant := TenantRecord{
		ID:              tenantID,
		Slug:            tenantSlug,
		Name:            input.BusinessName,
		Status:          "active",
		DefaultLanguage: input.LanguageCode,
		DefaultCurrency: input.CurrencyCode,
		CreatedAt:       now,
	}

	legal := LegalEntityRecord{
		ID:          legalEntityID,
		TenantID:    tenantID,
		LegalName:   input.BusinessName,
		TaxOrTCKN:   input.TaxOrTCKN,
		AddressLine: input.AddressLine,
		City:        input.City,
		District:    input.District,
		CreatedAt:   now,
	}

	branch := BranchRecord{
		ID:            branchID,
		TenantID:      tenantID,
		LegalEntityID: legalEntityID,
		BranchName:    input.BranchName,
		Status:        "active",
		CreatedAt:     now,
	}

	membership := MembershipRecord{
		ID:        membershipID,
		TenantID:  tenantID,
		UserID:    input.OwnerUserID,
		RoleCode:  input.FirstRoleCode,
		Status:    "active",
		CreatedAt: now,
	}

	request := OnboardingRequestRecord{
		ID:            requestID,
		TenantID:      tenantID,
		OwnerUserID:   input.OwnerUserID,
		TenantSlug:    tenantSlug,
		BusinessName:  input.BusinessName,
		TaxOrTCKN:     input.TaxOrTCKN,
		AddressLine:   input.AddressLine,
		City:          input.City,
		District:      input.District,
		SectorCode:    input.SectorCode,
		BranchName:    input.BranchName,
		CurrencyCode:  input.CurrencyCode,
		LanguageCode:  input.LanguageCode,
		FirstRoleCode: input.FirstRoleCode,
		Status:        "completed",
		CompletedAt:   now,
		CorrelationID: input.CorrelationID,
		CreatedAt:     now,
	}

	if err := s.store.CreateTenant(ctx, tenant); err != nil {
		return Result{}, err
	}
	if err := s.store.CreateLegalEntity(ctx, legal); err != nil {
		return Result{}, err
	}
	if err := s.store.CreateBranch(ctx, branch); err != nil {
		return Result{}, err
	}
	if err := s.store.CreateMembership(ctx, membership); err != nil {
		return Result{}, err
	}
	if err := s.store.SaveOnboardingRequest(ctx, request); err != nil {
		return Result{}, err
	}

	s.record(ctx, tenantID, input.OwnerUserID, "business_onboarding", "accepted", "completed", input.CorrelationID)

	return Result{
		TenantID:      tenantID,
		TenantSlug:    tenantSlug,
		LegalEntityID: legalEntityID,
		BranchID:      branchID,
		OwnerUserID:   input.OwnerUserID,
		BusinessName:  input.BusinessName,
		CurrencyCode:  input.CurrencyCode,
		LanguageCode:  input.LanguageCode,
		FirstRoleCode: input.FirstRoleCode,
		Status:        "completed",
		CompletedAt:   now,
		CorrelationID: input.CorrelationID,
	}, nil
}

func (s *Service) CompleteHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": ErrMethodNotAllowed.Error()})
		return
	}

	var input Input
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": ErrBusinessNameRequired.Error()})
		return
	}

	result, err := s.Complete(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func validate(input Input) error {
	if input.OwnerUserID == "" {
		return ErrOwnerUserRequired
	}
	if input.BusinessName == "" {
		return ErrBusinessNameRequired
	}
	if !validTaxOrTCKN(input.TaxOrTCKN) {
		return ErrTaxOrTCKNInvalid
	}
	if input.AddressLine == "" {
		return ErrAddressRequired
	}
	if input.City == "" {
		return ErrCityRequired
	}
	if input.District == "" {
		return ErrDistrictRequired
	}
	if input.SectorCode == "" {
		return ErrSectorRequired
	}
	if input.BranchName == "" {
		return ErrBranchRequired
	}
	if !supportedCurrency(input.CurrencyCode) {
		return ErrCurrencyUnsupported
	}
	if !supportedLanguage(input.LanguageCode) {
		return ErrLanguageUnsupported
	}
	if !supportedRole(input.FirstRoleCode) {
		return ErrFirstRoleUnsupported
	}
	return nil
}

func normalizeInput(input Input) Input {
	input.OwnerUserID = strings.TrimSpace(input.OwnerUserID)
	input.BusinessName = strings.TrimSpace(input.BusinessName)
	input.TaxOrTCKN = onlyDigits(input.TaxOrTCKN)
	input.AddressLine = strings.TrimSpace(input.AddressLine)
	input.City = strings.TrimSpace(input.City)
	input.District = strings.TrimSpace(input.District)
	input.SectorCode = strings.TrimSpace(strings.ToLower(input.SectorCode))
	input.BranchName = strings.TrimSpace(input.BranchName)
	input.CurrencyCode = strings.TrimSpace(strings.ToUpper(input.CurrencyCode))
	input.LanguageCode = strings.TrimSpace(input.LanguageCode)
	input.FirstRoleCode = strings.TrimSpace(strings.ToLower(input.FirstRoleCode))
	input.CorrelationID = strings.TrimSpace(input.CorrelationID)
	if input.CorrelationID == "" {
		input.CorrelationID = "business-onboarding-correlation-missing"
	}
	return input
}

func BuildTenantSlug(name string) string {
	name = strings.ToLower(strings.TrimSpace(name))
	replacer := strings.NewReplacer(
		"ç", "c",
		"ğ", "g",
		"ı", "i",
		"ö", "o",
		"ş", "s",
		"ü", "u",
	)
	name = replacer.Replace(name)

	var b strings.Builder
	lastDash := false
	for _, r := range name {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
			lastDash = false
			continue
		}
		if !lastDash {
			b.WriteRune('-')
			lastDash = true
		}
	}

	slug := strings.Trim(b.String(), "-")
	if slug == "" {
		return "isletme"
	}
	return slug
}

func validTaxOrTCKN(value string) bool {
	if len(value) != 10 && len(value) != 11 {
		return false
	}
	matched, _ := regexp.MatchString(`^[0-9]+$`, value)
	return matched
}

func supportedCurrency(value string) bool {
	return value == "TRY" || value == "USD" || value == "EUR"
}

func supportedLanguage(value string) bool {
	return value == "tr-TR" || value == "ota" || value == "ar" || value == "fa" || value == "en"
}

func supportedRole(value string) bool {
	return value == "owner" || value == "manager" || value == "cashier" || value == "accountant"
}

func onlyDigits(value string) string {
	var b strings.Builder
	for _, r := range value {
		if unicode.IsDigit(r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func (s *Service) record(ctx context.Context, tenantID string, ownerUserID string, eventType string, result string, reasonCode string, correlationID string) {
	if correlationID == "" {
		correlationID = "business-onboarding-correlation-missing"
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
	case errors.Is(err, ErrOwnerUserRequired),
		errors.Is(err, ErrBusinessNameRequired),
		errors.Is(err, ErrTaxOrTCKNInvalid),
		errors.Is(err, ErrAddressRequired),
		errors.Is(err, ErrCityRequired),
		errors.Is(err, ErrDistrictRequired),
		errors.Is(err, ErrSectorRequired),
		errors.Is(err, ErrBranchRequired),
		errors.Is(err, ErrCurrencyUnsupported),
		errors.Is(err, ErrLanguageUnsupported),
		errors.Is(err, ErrFirstRoleUnsupported):
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
