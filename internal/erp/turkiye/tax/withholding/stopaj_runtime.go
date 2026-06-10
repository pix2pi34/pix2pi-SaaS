package withholding

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type DocumentType string

const (
	DocumentTypePurchaseInvoice DocumentType = "PURCHASE_INVOICE"
	DocumentTypeExpenseVoucher  DocumentType = "EXPENSE_VOUCHER"
	DocumentTypeSelfEmployment  DocumentType = "SELF_EMPLOYMENT_RECEIPT"
	DocumentTypeRentAccrual     DocumentType = "RENT_ACCRUAL"
	DocumentTypeCustom          DocumentType = "CUSTOM"
)

type WithholdingSubject string

const (
	SubjectRent                WithholdingSubject = "RENT"
	SubjectProfessionalService WithholdingSubject = "PROFESSIONAL_SERVICE"
	SubjectSelfEmployment      WithholdingSubject = "SELF_EMPLOYMENT"
	SubjectFreelance           WithholdingSubject = "FREELANCE"
	SubjectConstruction        WithholdingSubject = "CONSTRUCTION"
	SubjectDividend            WithholdingSubject = "DIVIDEND"
	SubjectCustom              WithholdingSubject = "CUSTOM"
)

type DecisionStatus string

const (
	DecisionApplied    DecisionStatus = "APPLIED"
	DecisionNotApplied DecisionStatus = "NOT_APPLIED"
	DecisionRejected   DecisionStatus = "REJECTED"
)

type CalculationStatus string

const (
	CalculationOK          CalculationStatus = "OK"
	CalculationRuleMissing CalculationStatus = "RULE_MISSING"
	CalculationExempt      CalculationStatus = "EXEMPT"
	CalculationInvalid     CalculationStatus = "INVALID"
)

type RuntimeConfig struct {
	RuntimeEnabled       bool                 `json:"runtime_enabled"`
	ActiveRuleVersion    string               `json:"active_rule_version"`
	DefaultCurrencyCode  string               `json:"default_currency_code"`
	MaxRateBps           int                  `json:"max_rate_bps"`
	MinRateBps           int                  `json:"min_rate_bps"`
	AuditRequired        bool                 `json:"audit_required"`
	IdempotencyRequired  bool                 `json:"idempotency_required"`
	AllowedDocumentTypes []DocumentType       `json:"allowed_document_types"`
	AllowedSubjects      []WithholdingSubject `json:"allowed_subjects"`
}

type WithholdingRule struct {
	RuleID             string             `json:"rule_id"`
	RuleVersion        string             `json:"rule_version"`
	Subject            WithholdingSubject `json:"subject"`
	RateBps            int                `json:"rate_bps"`
	EffectiveFrom      time.Time          `json:"effective_from"`
	EffectiveTo        time.Time          `json:"effective_to"`
	MinBaseAmountKurus int64              `json:"min_base_amount_kurus"`
	AccountCode        string             `json:"account_code"`
	DeclarationCode    string             `json:"declaration_code"`
	Active             bool               `json:"active"`
	ExemptionAllowed   bool               `json:"exemption_allowed"`
}

type WithholdingRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	PartyID    string `json:"party_id"`
	PartyTitle string `json:"party_title"`
	PartyTaxNo string `json:"party_tax_no"`

	Subject WithholdingSubject `json:"subject"`

	GrossAmountKurus   int64  `json:"gross_amount_kurus"`
	TaxBaseAmountKurus int64  `json:"tax_base_amount_kurus"`
	CurrencyCode       string `json:"currency_code"`

	ExemptionCode   string `json:"exemption_code"`
	ExemptionReason string `json:"exemption_reason"`

	DocumentDate time.Time `json:"document_date"`
	RequestedAt  time.Time `json:"requested_at"`
}

type WithholdingResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	Subject WithholdingSubject `json:"subject"`

	DecisionStatus    DecisionStatus    `json:"decision_status"`
	CalculationStatus CalculationStatus `json:"calculation_status"`

	RuleID          string `json:"rule_id"`
	RuleVersion     string `json:"rule_version"`
	AccountCode     string `json:"account_code"`
	DeclarationCode string `json:"declaration_code"`
	RateBps         int    `json:"rate_bps"`

	GrossAmountKurus       int64 `json:"gross_amount_kurus"`
	TaxBaseAmountKurus     int64 `json:"tax_base_amount_kurus"`
	WithholdingAmountKurus int64 `json:"withholding_amount_kurus"`
	NetPayableAmountKurus  int64 `json:"net_payable_amount_kurus"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CalculatedAt        time.Time `json:"calculated_at"`
}

type StopajRuntime struct {
	config RuntimeConfig
	rules  map[WithholdingSubject]WithholdingRule
}

func NewStopajRuntime(config RuntimeConfig, rules []WithholdingRule) (*StopajRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("stopaj runtime is disabled")
	}
	if strings.TrimSpace(config.ActiveRuleVersion) == "" {
		return nil, errors.New("active_rule_version is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.MaxRateBps <= 0 {
		return nil, errors.New("max_rate_bps must be positive")
	}
	if config.MinRateBps < 0 {
		return nil, errors.New("min_rate_bps cannot be negative")
	}
	if config.MinRateBps > config.MaxRateBps {
		return nil, errors.New("min_rate_bps cannot be greater than max_rate_bps")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed_document_types are required")
	}
	if len(config.AllowedSubjects) == 0 {
		return nil, errors.New("allowed_subjects are required")
	}
	if len(rules) == 0 {
		return nil, errors.New("withholding rules are required")
	}

	ruleMap := make(map[WithholdingSubject]WithholdingRule, len(rules))
	for _, rule := range rules {
		if strings.TrimSpace(rule.RuleID) == "" {
			return nil, errors.New("rule_id is required")
		}
		if strings.TrimSpace(rule.RuleVersion) == "" {
			return nil, errors.New("rule_version is required")
		}
		if rule.RuleVersion != config.ActiveRuleVersion {
			continue
		}
		if !rule.Active {
			continue
		}
		if rule.RateBps < config.MinRateBps || rule.RateBps > config.MaxRateBps {
			return nil, fmt.Errorf("rate_bps out of allowed range for subject %s", rule.Subject)
		}
		if rule.EffectiveFrom.IsZero() {
			return nil, errors.New("effective_from is required")
		}
		if strings.TrimSpace(rule.AccountCode) == "" {
			return nil, errors.New("account_code is required")
		}
		if strings.TrimSpace(rule.DeclarationCode) == "" {
			return nil, errors.New("declaration_code is required")
		}
		ruleMap[rule.Subject] = rule
	}

	if len(ruleMap) == 0 {
		return nil, errors.New("no active withholding rules found for active rule version")
	}

	return &StopajRuntime{config: config, rules: ruleMap}, nil
}

func (r *StopajRuntime) Execute(req WithholdingRequest) (WithholdingResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	rule, ok := r.rules[req.Subject]
	if !ok {
		result := rejected(req, "WITHHOLDING_RULE_MISSING", "withholding rule is missing for subject")
		result.CalculationStatus = CalculationRuleMissing
		return result, errors.New("withholding rule is missing for subject")
	}

	if !isWithinEffectiveDate(req.DocumentDate, rule.EffectiveFrom, rule.EffectiveTo) {
		result := rejected(req, "WITHHOLDING_RULE_NOT_EFFECTIVE", "withholding rule is not effective for document date")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("withholding rule is not effective for document date")
	}

	if req.TaxBaseAmountKurus < rule.MinBaseAmountKurus {
		return WithholdingResult{
			TenantID:              req.TenantID,
			CorrelationID:         req.CorrelationID,
			RequestID:             req.RequestID,
			IdempotencyKey:        req.IdempotencyKey,
			DocumentType:          req.DocumentType,
			DocumentID:            req.DocumentID,
			DocumentNo:            req.DocumentNo,
			Subject:               req.Subject,
			DecisionStatus:        DecisionNotApplied,
			CalculationStatus:     CalculationExempt,
			RuleID:                rule.RuleID,
			RuleVersion:           rule.RuleVersion,
			AccountCode:           rule.AccountCode,
			DeclarationCode:       rule.DeclarationCode,
			RateBps:               rule.RateBps,
			GrossAmountKurus:      req.GrossAmountKurus,
			TaxBaseAmountKurus:    req.TaxBaseAmountKurus,
			NetPayableAmountKurus: req.GrossAmountKurus,
			AuditAction:           "STOPAJ_NOT_APPLIED_BELOW_MIN_BASE",
			AuditDecisionReason:   "tax base amount is below withholding rule minimum base",
			CalculatedAt:          time.Now().UTC(),
		}, nil
	}

	if strings.TrimSpace(req.ExemptionCode) != "" {
		if !rule.ExemptionAllowed {
			result := rejected(req, "EXEMPTION_NOT_ALLOWED", "exemption is not allowed for this withholding rule")
			result.RuleID = rule.RuleID
			result.RuleVersion = rule.RuleVersion
			result.CalculationStatus = CalculationInvalid
			return result, errors.New("exemption is not allowed for this withholding rule")
		}

		return WithholdingResult{
			TenantID:              req.TenantID,
			CorrelationID:         req.CorrelationID,
			RequestID:             req.RequestID,
			IdempotencyKey:        req.IdempotencyKey,
			DocumentType:          req.DocumentType,
			DocumentID:            req.DocumentID,
			DocumentNo:            req.DocumentNo,
			Subject:               req.Subject,
			DecisionStatus:        DecisionNotApplied,
			CalculationStatus:     CalculationExempt,
			RuleID:                rule.RuleID,
			RuleVersion:           rule.RuleVersion,
			AccountCode:           rule.AccountCode,
			DeclarationCode:       rule.DeclarationCode,
			RateBps:               rule.RateBps,
			GrossAmountKurus:      req.GrossAmountKurus,
			TaxBaseAmountKurus:    req.TaxBaseAmountKurus,
			NetPayableAmountKurus: req.GrossAmountKurus,
			AuditAction:           "STOPAJ_EXEMPTION_APPLIED",
			AuditDecisionReason:   "withholding exemption applied by exemption code",
			CalculatedAt:          time.Now().UTC(),
		}, nil
	}

	withholdingAmount := calculateBps(req.TaxBaseAmountKurus, rule.RateBps)
	netPayable := req.GrossAmountKurus - withholdingAmount
	if netPayable < 0 {
		result := rejected(req, "NET_PAYABLE_NEGATIVE", "net payable amount cannot be negative")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("net payable amount cannot be negative")
	}

	return WithholdingResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		DocumentType:           req.DocumentType,
		DocumentID:             req.DocumentID,
		DocumentNo:             req.DocumentNo,
		Subject:                req.Subject,
		DecisionStatus:         DecisionApplied,
		CalculationStatus:      CalculationOK,
		RuleID:                 rule.RuleID,
		RuleVersion:            rule.RuleVersion,
		AccountCode:            rule.AccountCode,
		DeclarationCode:        rule.DeclarationCode,
		RateBps:                rule.RateBps,
		GrossAmountKurus:       req.GrossAmountKurus,
		TaxBaseAmountKurus:     req.TaxBaseAmountKurus,
		WithholdingAmountKurus: withholdingAmount,
		NetPayableAmountKurus:  netPayable,
		AuditAction:            "STOPAJ_APPLIED",
		AuditDecisionReason:    "withholding calculated with active rule version",
		CalculatedAt:           time.Now().UTC(),
	}, nil
}

func (r *StopajRuntime) validateRequest(req WithholdingRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if !r.documentTypeAllowed(req.DocumentType) {
		return fmt.Errorf("document_type is not allowed: %s", req.DocumentType)
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if strings.TrimSpace(req.PartyID) == "" {
		return errors.New("party_id is required")
	}
	if strings.TrimSpace(req.PartyTitle) == "" {
		return errors.New("party_title is required")
	}
	if strings.TrimSpace(req.PartyTaxNo) == "" {
		return errors.New("party_tax_no is required")
	}
	if !r.subjectAllowed(req.Subject) {
		return fmt.Errorf("withholding subject is not allowed: %s", req.Subject)
	}
	if req.GrossAmountKurus <= 0 {
		return errors.New("gross_amount_kurus must be positive")
	}
	if req.TaxBaseAmountKurus <= 0 {
		return errors.New("tax_base_amount_kurus must be positive")
	}
	if req.TaxBaseAmountKurus > req.GrossAmountKurus {
		return errors.New("tax_base_amount_kurus cannot exceed gross_amount_kurus")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("currency_code mismatch")
	}
	if req.DocumentDate.IsZero() {
		return errors.New("document_date is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *StopajRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func (r *StopajRuntime) subjectAllowed(s WithholdingSubject) bool {
	for _, allowed := range r.config.AllowedSubjects {
		if allowed == s {
			return true
		}
	}
	return false
}

func calculateBps(amountKurus int64, rateBps int) int64 {
	return (amountKurus*int64(rateBps) + 5000) / 10000
}

func isWithinEffectiveDate(documentDate time.Time, effectiveFrom time.Time, effectiveTo time.Time) bool {
	if documentDate.Before(effectiveFrom) {
		return false
	}
	if !effectiveTo.IsZero() && documentDate.After(effectiveTo) {
		return false
	}
	return true
}

func rejected(req WithholdingRequest, code string, message string) WithholdingResult {
	return WithholdingResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		DocumentType:        req.DocumentType,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		Subject:             req.Subject,
		DecisionStatus:      DecisionRejected,
		CalculationStatus:   CalculationInvalid,
		GrossAmountKurus:    req.GrossAmountKurus,
		TaxBaseAmountKurus:  req.TaxBaseAmountKurus,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "STOPAJ_REJECTED",
		AuditDecisionReason: "withholding request rejected by runtime validation guard",
		CalculatedAt:        time.Now().UTC(),
	}
}
