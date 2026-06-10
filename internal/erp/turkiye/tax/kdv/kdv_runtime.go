package kdv

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
	DocumentTypeSalesReturn     DocumentType = "SALES_RETURN"
	DocumentTypePurchaseReturn  DocumentType = "PURCHASE_RETURN"
	DocumentTypeEBelgeDocument  DocumentType = "E_BELGE_DOCUMENT"
	DocumentTypeCustom          DocumentType = "CUSTOM"
)

type TaxDirection string

const (
	DirectionOutput TaxDirection = "OUTPUT_KDV"
	DirectionInput  TaxDirection = "INPUT_KDV"
	DirectionReturn TaxDirection = "RETURN_KDV"
)

type KDVRateCode string

const (
	RateCodeKDV0   KDVRateCode = "KDV_0"
	RateCodeKDV1   KDVRateCode = "KDV_1"
	RateCodeKDV10  KDVRateCode = "KDV_10"
	RateCodeKDV20  KDVRateCode = "KDV_20"
	RateCodeCustom KDVRateCode = "CUSTOM"
)

const (
	TDHPOutputKDVAccountPrefix = "391"
	TDHPInputKDVAccountPrefix  = "191"
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
	CalculationZeroRated   CalculationStatus = "ZERO_RATED"
	CalculationRuleMissing CalculationStatus = "RULE_MISSING"
	CalculationExempt      CalculationStatus = "EXEMPT"
	CalculationInvalid     CalculationStatus = "INVALID"
)

type RuntimeConfig struct {
	RuntimeEnabled       bool           `json:"runtime_enabled"`
	ActiveRuleVersion    string         `json:"active_rule_version"`
	DefaultCurrencyCode  string         `json:"default_currency_code"`
	AuditRequired        bool           `json:"audit_required"`
	IdempotencyRequired  bool           `json:"idempotency_required"`
	MinRateBps           int            `json:"min_rate_bps"`
	MaxRateBps           int            `json:"max_rate_bps"`
	AllowedDocumentTypes []DocumentType `json:"allowed_document_types"`
	AllowedDirections    []TaxDirection `json:"allowed_directions"`
	AllowedRateCodes     []KDVRateCode  `json:"allowed_rate_codes"`
}

type KDVRule struct {
	RuleID               string       `json:"rule_id"`
	RuleVersion          string       `json:"rule_version"`
	RateCode             KDVRateCode  `json:"rate_code"`
	RateBps              int          `json:"rate_bps"`
	Direction            TaxDirection `json:"direction"`
	EffectiveFrom        time.Time    `json:"effective_from"`
	EffectiveTo          time.Time    `json:"effective_to"`
	OutputAccountCode    string       `json:"output_account_code"`
	InputAccountCode     string       `json:"input_account_code"`
	ReturnAccountCode    string       `json:"return_account_code"`
	DeclarationCode      string       `json:"declaration_code"`
	ExemptionAllowed     bool         `json:"exemption_allowed"`
	ReverseChargeAllowed bool         `json:"reverse_charge_allowed"`
	Active               bool         `json:"active"`
}

type KDVRequest struct {
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

	Direction TaxDirection `json:"direction"`
	RateCode  KDVRateCode  `json:"rate_code"`

	GrossAmountKurus   int64  `json:"gross_amount_kurus"`
	NetAmountKurus     int64  `json:"net_amount_kurus"`
	TaxBaseAmountKurus int64  `json:"tax_base_amount_kurus"`
	CurrencyCode       string `json:"currency_code"`

	ExemptionCode   string `json:"exemption_code"`
	ExemptionReason string `json:"exemption_reason"`
	ReverseCharge   bool   `json:"reverse_charge"`

	DocumentDate time.Time `json:"document_date"`
	RequestedAt  time.Time `json:"requested_at"`
}

type KDVResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	Direction TaxDirection `json:"direction"`
	RateCode  KDVRateCode  `json:"rate_code"`

	DecisionStatus    DecisionStatus    `json:"decision_status"`
	CalculationStatus CalculationStatus `json:"calculation_status"`

	RuleID          string `json:"rule_id"`
	RuleVersion     string `json:"rule_version"`
	AccountCode     string `json:"account_code"`
	DeclarationCode string `json:"declaration_code"`
	RateBps         int    `json:"rate_bps"`

	GrossAmountKurus   int64 `json:"gross_amount_kurus"`
	NetAmountKurus     int64 `json:"net_amount_kurus"`
	TaxBaseAmountKurus int64 `json:"tax_base_amount_kurus"`
	KDVAmountKurus     int64 `json:"kdv_amount_kurus"`
	TotalAmountKurus   int64 `json:"total_amount_kurus"`

	ReverseChargeApplied bool `json:"reverse_charge_applied"`
	ExemptionApplied     bool `json:"exemption_applied"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CalculatedAt        time.Time `json:"calculated_at"`
}

type KDVRuntime struct {
	config RuntimeConfig
	rules  map[string]KDVRule
}

func NewKDVRuntime(config RuntimeConfig, rules []KDVRule) (*KDVRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("kdv runtime is disabled")
	}
	if strings.TrimSpace(config.ActiveRuleVersion) == "" {
		return nil, errors.New("active_rule_version is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.MinRateBps < 0 {
		return nil, errors.New("min_rate_bps cannot be negative")
	}
	if config.MaxRateBps < config.MinRateBps {
		return nil, errors.New("max_rate_bps must be greater than or equal to min_rate_bps")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed_document_types are required")
	}
	if len(config.AllowedDirections) == 0 {
		return nil, errors.New("allowed_directions are required")
	}
	if len(config.AllowedRateCodes) == 0 {
		return nil, errors.New("allowed_rate_codes are required")
	}
	if len(rules) == 0 {
		return nil, errors.New("kdv rules are required")
	}

	ruleMap := make(map[string]KDVRule, len(rules))
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
			return nil, fmt.Errorf("rate_bps out of allowed range for rate code %s", rule.RateCode)
		}
		if rule.EffectiveFrom.IsZero() {
			return nil, errors.New("effective_from is required")
		}
		if strings.TrimSpace(rule.DeclarationCode) == "" {
			return nil, errors.New("declaration_code is required")
		}
		if accountCodeForRule(rule) == "" {
			return nil, fmt.Errorf("account code is required for direction %s", rule.Direction)
		}
		if err := validateTDHPAccountPrefix(rule); err != nil {
			return nil, err
		}
		ruleMap[ruleKey(rule.Direction, rule.RateCode)] = rule
	}

	if len(ruleMap) == 0 {
		return nil, errors.New("no active kdv rules found for active rule version")
	}

	return &KDVRuntime{config: config, rules: ruleMap}, nil
}

func (r *KDVRuntime) Execute(req KDVRequest) (KDVResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	rule, ok := r.rules[ruleKey(req.Direction, req.RateCode)]
	if !ok {
		result := rejected(req, "KDV_RULE_MISSING", "kdv rule is missing for direction and rate code")
		result.CalculationStatus = CalculationRuleMissing
		return result, errors.New("kdv rule is missing for direction and rate code")
	}

	if !isWithinEffectiveDate(req.DocumentDate, rule.EffectiveFrom, rule.EffectiveTo) {
		result := rejected(req, "KDV_RULE_NOT_EFFECTIVE", "kdv rule is not effective for document date")
		result.RuleID = rule.RuleID
		result.RuleVersion = rule.RuleVersion
		result.CalculationStatus = CalculationInvalid
		return result, errors.New("kdv rule is not effective for document date")
	}

	if strings.TrimSpace(req.ExemptionCode) != "" {
		if !rule.ExemptionAllowed {
			result := rejected(req, "KDV_EXEMPTION_NOT_ALLOWED", "kdv exemption is not allowed for this rule")
			result.RuleID = rule.RuleID
			result.RuleVersion = rule.RuleVersion
			result.CalculationStatus = CalculationInvalid
			return result, errors.New("kdv exemption is not allowed for this rule")
		}

		return KDVResult{
			TenantID:            req.TenantID,
			CorrelationID:       req.CorrelationID,
			RequestID:           req.RequestID,
			IdempotencyKey:      req.IdempotencyKey,
			DocumentType:        req.DocumentType,
			DocumentID:          req.DocumentID,
			DocumentNo:          req.DocumentNo,
			Direction:           req.Direction,
			RateCode:            req.RateCode,
			DecisionStatus:      DecisionNotApplied,
			CalculationStatus:   CalculationExempt,
			RuleID:              rule.RuleID,
			RuleVersion:         rule.RuleVersion,
			AccountCode:         accountCodeForRule(rule),
			DeclarationCode:     rule.DeclarationCode,
			RateBps:             rule.RateBps,
			GrossAmountKurus:    req.GrossAmountKurus,
			NetAmountKurus:      req.NetAmountKurus,
			TaxBaseAmountKurus:  req.TaxBaseAmountKurus,
			KDVAmountKurus:      0,
			TotalAmountKurus:    req.NetAmountKurus,
			ExemptionApplied:    true,
			AuditAction:         "KDV_EXEMPTION_APPLIED",
			AuditDecisionReason: "kdv exemption applied by exemption code",
			CalculatedAt:        time.Now().UTC(),
		}, nil
	}

	if req.ReverseCharge {
		if !rule.ReverseChargeAllowed {
			result := rejected(req, "KDV_REVERSE_CHARGE_NOT_ALLOWED", "reverse charge is not allowed for this kdv rule")
			result.RuleID = rule.RuleID
			result.RuleVersion = rule.RuleVersion
			result.CalculationStatus = CalculationInvalid
			return result, errors.New("reverse charge is not allowed for this kdv rule")
		}
	}

	kdvAmount := calculateBps(req.TaxBaseAmountKurus, rule.RateBps)
	totalAmount := req.NetAmountKurus + kdvAmount
	status := CalculationOK
	if rule.RateBps == 0 {
		status = CalculationZeroRated
	}

	return KDVResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		DocumentType:         req.DocumentType,
		DocumentID:           req.DocumentID,
		DocumentNo:           req.DocumentNo,
		Direction:            req.Direction,
		RateCode:             req.RateCode,
		DecisionStatus:       DecisionApplied,
		CalculationStatus:    status,
		RuleID:               rule.RuleID,
		RuleVersion:          rule.RuleVersion,
		AccountCode:          accountCodeForRule(rule),
		DeclarationCode:      rule.DeclarationCode,
		RateBps:              rule.RateBps,
		GrossAmountKurus:     req.GrossAmountKurus,
		NetAmountKurus:       req.NetAmountKurus,
		TaxBaseAmountKurus:   req.TaxBaseAmountKurus,
		KDVAmountKurus:       kdvAmount,
		TotalAmountKurus:     totalAmount,
		ReverseChargeApplied: req.ReverseCharge,
		AuditAction:          "KDV_APPLIED",
		AuditDecisionReason:  "kdv calculated with active rule version",
		CalculatedAt:         time.Now().UTC(),
	}, nil
}

func (r *KDVRuntime) validateRequest(req KDVRequest) error {
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
	if !r.directionAllowed(req.Direction) {
		return fmt.Errorf("tax direction is not allowed: %s", req.Direction)
	}
	if !r.rateCodeAllowed(req.RateCode) {
		return fmt.Errorf("kdv rate code is not allowed: %s", req.RateCode)
	}
	if req.GrossAmountKurus <= 0 {
		return errors.New("gross_amount_kurus must be positive")
	}
	if req.NetAmountKurus <= 0 {
		return errors.New("net_amount_kurus must be positive")
	}
	if req.TaxBaseAmountKurus <= 0 {
		return errors.New("tax_base_amount_kurus must be positive")
	}
	if req.TaxBaseAmountKurus > req.NetAmountKurus {
		return errors.New("tax_base_amount_kurus cannot exceed net_amount_kurus")
	}
	if req.NetAmountKurus > req.GrossAmountKurus {
		return errors.New("net_amount_kurus cannot exceed gross_amount_kurus")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("currency_code mismatch")
	}
	if strings.TrimSpace(req.ExemptionCode) != "" && strings.TrimSpace(req.ExemptionReason) == "" {
		return errors.New("exemption_reason is required when exemption_code is present")
	}
	if req.DocumentDate.IsZero() {
		return errors.New("document_date is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *KDVRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func (r *KDVRuntime) directionAllowed(d TaxDirection) bool {
	for _, allowed := range r.config.AllowedDirections {
		if allowed == d {
			return true
		}
	}
	return false
}

func (r *KDVRuntime) rateCodeAllowed(code KDVRateCode) bool {
	for _, allowed := range r.config.AllowedRateCodes {
		if allowed == code {
			return true
		}
	}
	return false
}

func ruleKey(direction TaxDirection, rateCode KDVRateCode) string {
	return string(direction) + "::" + string(rateCode)
}

func accountCodeForRule(rule KDVRule) string {
	switch rule.Direction {
	case DirectionOutput:
		return strings.TrimSpace(rule.OutputAccountCode)
	case DirectionInput:
		return strings.TrimSpace(rule.InputAccountCode)
	case DirectionReturn:
		return strings.TrimSpace(rule.ReturnAccountCode)
	default:
		return ""
	}
}

func validateTDHPAccountPrefix(rule KDVRule) error {
	accountCode := accountCodeForRule(rule)

	switch rule.Direction {
	case DirectionOutput:
		if !strings.HasPrefix(accountCode, TDHPOutputKDVAccountPrefix) {
			return fmt.Errorf("output kdv account code must start with %s", TDHPOutputKDVAccountPrefix)
		}
	case DirectionInput:
		if !strings.HasPrefix(accountCode, TDHPInputKDVAccountPrefix) {
			return fmt.Errorf("input kdv account code must start with %s", TDHPInputKDVAccountPrefix)
		}
	case DirectionReturn:
		if accountCode == "" {
			return errors.New("return kdv account code is required")
		}
	}

	return nil
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

func rejected(req KDVRequest, code string, message string) KDVResult {
	return KDVResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		DocumentType:        req.DocumentType,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		Direction:           req.Direction,
		RateCode:            req.RateCode,
		DecisionStatus:      DecisionRejected,
		CalculationStatus:   CalculationInvalid,
		GrossAmountKurus:    req.GrossAmountKurus,
		NetAmountKurus:      req.NetAmountKurus,
		TaxBaseAmountKurus:  req.TaxBaseAmountKurus,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "KDV_REJECTED",
		AuditDecisionReason: "kdv request rejected by runtime validation guard",
		CalculatedAt:        time.Now().UTC(),
	}
}
