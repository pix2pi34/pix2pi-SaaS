package exemption

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type DocumentType string

const (
	DocumentTypeSalesInvoice    DocumentType = "SALES_INVOICE"
	DocumentTypePurchaseInvoice DocumentType = "PURCHASE_INVOICE"
	DocumentTypeEBelgeDocument  DocumentType = "E_BELGE_DOCUMENT"
	DocumentTypeExpenseVoucher  DocumentType = "EXPENSE_VOUCHER"
	DocumentTypeJournalDocument DocumentType = "JOURNAL_DOCUMENT"
	DocumentTypeCustom          DocumentType = "CUSTOM"
)

type TaxType string

const (
	TaxTypeKDV    TaxType = "KDV"
	TaxTypeStopaj TaxType = "STOPAJ"
	TaxTypeOTV    TaxType = "OTV"
	TaxTypeDamga  TaxType = "DAMGA"
	TaxTypeCustom TaxType = "CUSTOM"
)

type ExemptionScope string

const (
	ScopeFullExemption    ExemptionScope = "FULL_EXEMPTION"
	ScopePartialExemption ExemptionScope = "PARTIAL_EXEMPTION"
	ScopeRateOverride     ExemptionScope = "RATE_OVERRIDE"
	ScopeZeroRate         ExemptionScope = "ZERO_RATE"
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
	CalculationNotEligible CalculationStatus = "NOT_ELIGIBLE"
	CalculationExpired     CalculationStatus = "EXPIRED"
	CalculationInvalid     CalculationStatus = "INVALID"
)

type RuntimeConfig struct {
	RuntimeEnabled       bool           `json:"runtime_enabled"`
	ActiveRuleVersion    string         `json:"active_rule_version"`
	DefaultCurrencyCode  string         `json:"default_currency_code"`
	AuditRequired        bool           `json:"audit_required"`
	IdempotencyRequired  bool           `json:"idempotency_required"`
	MinOverrideRateBps   int            `json:"min_override_rate_bps"`
	MaxOverrideRateBps   int            `json:"max_override_rate_bps"`
	AllowedDocumentTypes []DocumentType `json:"allowed_document_types"`
	AllowedTaxTypes      []TaxType      `json:"allowed_tax_types"`
}

type ExemptionRule struct {
	RuleID             string         `json:"rule_id"`
	RuleVersion        string         `json:"rule_version"`
	TaxType            TaxType        `json:"tax_type"`
	ExemptionCode      string         `json:"exemption_code"`
	ExemptionScope     ExemptionScope `json:"exemption_scope"`
	EffectiveFrom      time.Time      `json:"effective_from"`
	EffectiveTo        time.Time      `json:"effective_to"`
	MinBaseAmountKurus int64          `json:"min_base_amount_kurus"`
	ExemptRateBps      int            `json:"exempt_rate_bps"`
	OverrideRateBps    int            `json:"override_rate_bps"`
	AccountCode        string         `json:"account_code"`
	DeclarationCode    string         `json:"declaration_code"`
	LegalReference     string         `json:"legal_reference"`
	ReasonRequired     bool           `json:"reason_required"`
	Active             bool           `json:"active"`
}

type ExemptionRequest struct {
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

	TaxType         TaxType `json:"tax_type"`
	ExemptionCode   string  `json:"exemption_code"`
	ExemptionReason string  `json:"exemption_reason"`

	GrossAmountKurus       int64  `json:"gross_amount_kurus"`
	TaxBaseAmountKurus     int64  `json:"tax_base_amount_kurus"`
	OriginalTaxRateBps     int    `json:"original_tax_rate_bps"`
	OriginalTaxAmountKurus int64  `json:"original_tax_amount_kurus"`
	CurrencyCode           string `json:"currency_code"`

	DocumentDate time.Time `json:"document_date"`
	RequestedAt  time.Time `json:"requested_at"`
}

type ExemptionResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	TaxType       TaxType `json:"tax_type"`
	ExemptionCode string  `json:"exemption_code"`

	DecisionStatus    DecisionStatus    `json:"decision_status"`
	CalculationStatus CalculationStatus `json:"calculation_status"`

	RuleID          string         `json:"rule_id"`
	RuleVersion     string         `json:"rule_version"`
	ExemptionScope  ExemptionScope `json:"exemption_scope"`
	AccountCode     string         `json:"account_code"`
	DeclarationCode string         `json:"declaration_code"`
	LegalReference  string         `json:"legal_reference"`

	GrossAmountKurus        int64 `json:"gross_amount_kurus"`
	TaxBaseAmountKurus      int64 `json:"tax_base_amount_kurus"`
	OriginalTaxRateBps      int   `json:"original_tax_rate_bps"`
	EffectiveTaxRateBps     int   `json:"effective_tax_rate_bps"`
	OriginalTaxAmountKurus  int64 `json:"original_tax_amount_kurus"`
	EffectiveTaxAmountKurus int64 `json:"effective_tax_amount_kurus"`
	ExemptedTaxAmountKurus  int64 `json:"exempted_tax_amount_kurus"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CalculatedAt        time.Time `json:"calculated_at"`
}

type TaxExemptionRuntime struct {
	config RuntimeConfig
	rules  map[string]ExemptionRule
}

func NewTaxExemptionRuntime(config RuntimeConfig, rules []ExemptionRule) (*TaxExemptionRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("tax exemption runtime is disabled")
	}
	if strings.TrimSpace(config.ActiveRuleVersion) == "" {
		return nil, errors.New("active_rule_version is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.MinOverrideRateBps < 0 {
		return nil, errors.New("min_override_rate_bps cannot be negative")
	}
	if config.MaxOverrideRateBps < config.MinOverrideRateBps {
		return nil, errors.New("max_override_rate_bps must be greater than or equal to min_override_rate_bps")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed_document_types are required")
	}
	if len(config.AllowedTaxTypes) == 0 {
		return nil, errors.New("allowed_tax_types are required")
	}
	if len(rules) == 0 {
		return nil, errors.New("exemption rules are required")
	}

	ruleMap := make(map[string]ExemptionRule, len(rules))
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
		if strings.TrimSpace(rule.ExemptionCode) == "" {
			return nil, errors.New("exemption_code is required")
		}
		if rule.EffectiveFrom.IsZero() {
			return nil, errors.New("effective_from is required")
		}
		if rule.ExemptionScope == ScopeRateOverride && (rule.OverrideRateBps < config.MinOverrideRateBps || rule.OverrideRateBps > config.MaxOverrideRateBps) {
			return nil, fmt.Errorf("override_rate_bps out of allowed range for exemption code %s", rule.ExemptionCode)
		}
		if rule.ExemptionScope == ScopePartialExemption && (rule.ExemptRateBps <= 0 || rule.ExemptRateBps > 10000) {
			return nil, fmt.Errorf("exempt_rate_bps out of allowed range for exemption code %s", rule.ExemptionCode)
		}
		if strings.TrimSpace(rule.AccountCode) == "" {
			return nil, errors.New("account_code is required")
		}
		if strings.TrimSpace(rule.DeclarationCode) == "" {
			return nil, errors.New("declaration_code is required")
		}
		ruleMap[ruleKey(rule.TaxType, rule.ExemptionCode)] = rule
	}

	if len(ruleMap) == 0 {
		return nil, errors.New("no active exemption rules found for active rule version")
	}

	return &TaxExemptionRuntime{config: config, rules: ruleMap}, nil
}

func (r *TaxExemptionRuntime) Execute(req ExemptionRequest) (ExemptionResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	rule, ok := r.rules[ruleKey(req.TaxType, req.ExemptionCode)]
	if !ok {
		result := rejected(req, "EXEMPTION_RULE_MISSING", "exemption rule is missing for tax type and exemption code")
		result.CalculationStatus = CalculationRuleMissing
		return result, errors.New("exemption rule is missing for tax type and exemption code")
	}

	if !isWithinEffectiveDate(req.DocumentDate, rule.EffectiveFrom, rule.EffectiveTo) {
		result := rejected(req, "EXEMPTION_RULE_NOT_EFFECTIVE", "exemption rule is not effective for document date")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationExpired
		return result, errors.New("exemption rule is not effective for document date")
	}

	if req.TaxBaseAmountKurus < rule.MinBaseAmountKurus {
		return ExemptionResult{
			TenantID:                req.TenantID,
			CorrelationID:           req.CorrelationID,
			RequestID:               req.RequestID,
			IdempotencyKey:          req.IdempotencyKey,
			DocumentType:            req.DocumentType,
			DocumentID:              req.DocumentID,
			DocumentNo:              req.DocumentNo,
			TaxType:                 req.TaxType,
			ExemptionCode:           req.ExemptionCode,
			DecisionStatus:          DecisionNotApplied,
			CalculationStatus:       CalculationNotEligible,
			RuleID:                  rule.RuleID,
			RuleVersion:             rule.RuleVersion,
			ExemptionScope:          rule.ExemptionScope,
			AccountCode:             rule.AccountCode,
			DeclarationCode:         rule.DeclarationCode,
			LegalReference:          rule.LegalReference,
			GrossAmountKurus:        req.GrossAmountKurus,
			TaxBaseAmountKurus:      req.TaxBaseAmountKurus,
			OriginalTaxRateBps:      req.OriginalTaxRateBps,
			EffectiveTaxRateBps:     req.OriginalTaxRateBps,
			OriginalTaxAmountKurus:  req.OriginalTaxAmountKurus,
			EffectiveTaxAmountKurus: req.OriginalTaxAmountKurus,
			ExemptedTaxAmountKurus:  0,
			AuditAction:             "TAX_EXEMPTION_NOT_APPLIED_BELOW_MIN_BASE",
			AuditDecisionReason:     "tax base amount is below exemption rule minimum base",
			CalculatedAt:            time.Now().UTC(),
		}, nil
	}

	if rule.ReasonRequired && strings.TrimSpace(req.ExemptionReason) == "" {
		result := rejected(req, "EXEMPTION_REASON_REQUIRED", "exemption_reason is required")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("exemption_reason is required")
	}

	effectiveRate := req.OriginalTaxRateBps
	effectiveTaxAmount := req.OriginalTaxAmountKurus

	switch rule.ExemptionScope {
	case ScopeFullExemption, ScopeZeroRate:
		effectiveRate = 0
		effectiveTaxAmount = 0
	case ScopePartialExemption:
		exemptedAmount := calculateBps(req.OriginalTaxAmountKurus, rule.ExemptRateBps)
		effectiveTaxAmount = req.OriginalTaxAmountKurus - exemptedAmount
		if effectiveTaxAmount < 0 {
			effectiveTaxAmount = 0
		}
	case ScopeRateOverride:
		effectiveRate = rule.OverrideRateBps
		effectiveTaxAmount = calculateBps(req.TaxBaseAmountKurus, effectiveRate)
	default:
		result := rejected(req, "EXEMPTION_SCOPE_INVALID", "exemption scope is invalid")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("exemption scope is invalid")
	}

	if effectiveTaxAmount > req.OriginalTaxAmountKurus {
		result := rejected(req, "EFFECTIVE_TAX_EXCEEDS_ORIGINAL", "effective tax amount cannot exceed original tax amount")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("effective tax amount cannot exceed original tax amount")
	}

	exemptedTaxAmount := req.OriginalTaxAmountKurus - effectiveTaxAmount
	if exemptedTaxAmount < 0 {
		exemptedTaxAmount = 0
	}

	return ExemptionResult{
		TenantID:                req.TenantID,
		CorrelationID:           req.CorrelationID,
		RequestID:               req.RequestID,
		IdempotencyKey:          req.IdempotencyKey,
		DocumentType:            req.DocumentType,
		DocumentID:              req.DocumentID,
		DocumentNo:              req.DocumentNo,
		TaxType:                 req.TaxType,
		ExemptionCode:           req.ExemptionCode,
		DecisionStatus:          DecisionApplied,
		CalculationStatus:       CalculationOK,
		RuleID:                  rule.RuleID,
		RuleVersion:             rule.RuleVersion,
		ExemptionScope:          rule.ExemptionScope,
		AccountCode:             rule.AccountCode,
		DeclarationCode:         rule.DeclarationCode,
		LegalReference:          rule.LegalReference,
		GrossAmountKurus:        req.GrossAmountKurus,
		TaxBaseAmountKurus:      req.TaxBaseAmountKurus,
		OriginalTaxRateBps:      req.OriginalTaxRateBps,
		EffectiveTaxRateBps:     effectiveRate,
		OriginalTaxAmountKurus:  req.OriginalTaxAmountKurus,
		EffectiveTaxAmountKurus: effectiveTaxAmount,
		ExemptedTaxAmountKurus:  exemptedTaxAmount,
		AuditAction:             "TAX_EXEMPTION_APPLIED",
		AuditDecisionReason:     "tax exemption calculated with active rule version",
		CalculatedAt:            time.Now().UTC(),
	}, nil
}

func (r *TaxExemptionRuntime) validateRequest(req ExemptionRequest) error {
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
	if !r.taxTypeAllowed(req.TaxType) {
		return fmt.Errorf("tax_type is not allowed: %s", req.TaxType)
	}
	if strings.TrimSpace(req.ExemptionCode) == "" {
		return errors.New("exemption_code is required")
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
	if req.OriginalTaxRateBps < 0 {
		return errors.New("original_tax_rate_bps cannot be negative")
	}
	if req.OriginalTaxAmountKurus < 0 {
		return errors.New("original_tax_amount_kurus cannot be negative")
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

func (r *TaxExemptionRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func (r *TaxExemptionRuntime) taxTypeAllowed(t TaxType) bool {
	for _, allowed := range r.config.AllowedTaxTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func ruleKey(taxType TaxType, exemptionCode string) string {
	return string(taxType) + "::" + strings.ToUpper(strings.TrimSpace(exemptionCode))
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

func rejected(req ExemptionRequest, code string, message string) ExemptionResult {
	return ExemptionResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		DocumentType:           req.DocumentType,
		DocumentID:             req.DocumentID,
		DocumentNo:             req.DocumentNo,
		TaxType:                req.TaxType,
		ExemptionCode:          req.ExemptionCode,
		DecisionStatus:         DecisionRejected,
		CalculationStatus:      CalculationInvalid,
		GrossAmountKurus:       req.GrossAmountKurus,
		TaxBaseAmountKurus:     req.TaxBaseAmountKurus,
		OriginalTaxRateBps:     req.OriginalTaxRateBps,
		OriginalTaxAmountKurus: req.OriginalTaxAmountKurus,
		ErrorCode:              code,
		ErrorMessage:           message,
		AuditAction:            "TAX_EXEMPTION_REJECTED",
		AuditDecisionReason:    "tax exemption request rejected by runtime validation guard",
		CalculatedAt:           time.Now().UTC(),
	}
}
