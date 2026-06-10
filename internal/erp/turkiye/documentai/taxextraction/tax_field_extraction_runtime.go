package taxextraction

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode"

	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
)

type TaxExtractionStatus string

const (
	TaxExtractionStatusReady        TaxExtractionStatus = "READY"
	TaxExtractionStatusReviewNeeded TaxExtractionStatus = "REVIEW_NEEDED"
	TaxExtractionStatusRejected     TaxExtractionStatus = "REJECTED"
)

type TaxExtractionDecision string

const (
	TaxExtractionDecisionExtracted TaxExtractionDecision = "EXTRACTED"
	TaxExtractionDecisionReview    TaxExtractionDecision = "REVIEW"
	TaxExtractionDecisionRejected  TaxExtractionDecision = "REJECTED"
)

type TaxFieldKey string

const (
	TaxFieldCompanyName TaxFieldKey = "company_name"
	TaxFieldTaxNo       TaxFieldKey = "tax_no"
	TaxFieldTaxOffice   TaxFieldKey = "tax_office"
	TaxFieldMersisNo    TaxFieldKey = "mersis_no"
)

type RuntimeConfig struct {
	RuntimeEnabled              bool                         `json:"runtime_enabled"`
	RequireTenantScope          bool                         `json:"require_tenant_scope"`
	RequireOCRResultHash        bool                         `json:"require_ocr_result_hash"`
	RequireOCRReadyOrReview     bool                         `json:"require_ocr_ready_or_review"`
	RequireTaxNo                bool                         `json:"require_tax_no"`
	RequireTaxOffice            bool                         `json:"require_tax_office"`
	RequireCompanyNameCandidate bool                         `json:"require_company_name_candidate"`
	RequireConfidence           bool                         `json:"require_confidence"`
	RequireAuditHash            bool                         `json:"require_audit_hash"`
	MinConfidenceBps            int                          `json:"min_confidence_bps"`
	ReviewConfidenceBps         int                          `json:"review_confidence_bps"`
	SupportedDocumentTypes      []ocrprocessing.DocumentType `json:"supported_document_types"`
	SupportedFieldKeys          []TaxFieldKey                `json:"supported_field_keys"`
}

type TaxFieldExtractionRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExtractionID string `json:"extraction_id"`

	OCRResult ocrprocessing.ProcessResult `json:"ocr_result"`

	RequestedAt time.Time `json:"requested_at"`
}

type ExtractedTaxField struct {
	FieldKey        TaxFieldKey `json:"field_key"`
	FieldLabel      string      `json:"field_label"`
	RawValue        string      `json:"raw_value"`
	NormalizedValue string      `json:"normalized_value"`
	ConfidenceBps   int         `json:"confidence_bps"`
	SourceBlockID   string      `json:"source_block_id"`
	Decision        string      `json:"decision"`
}

type TaxFieldExtractionResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExtractionID string `json:"extraction_id"`
	ProcessID    string `json:"process_id"`
	DocumentID   string `json:"document_id"`

	DocumentType ocrprocessing.DocumentType `json:"document_type"`

	Status   TaxExtractionStatus   `json:"status"`
	Decision TaxExtractionDecision `json:"decision"`

	CompanyName string `json:"company_name"`
	TaxNo       string `json:"tax_no"`
	TaxOffice   string `json:"tax_office"`
	MersisNo    string `json:"mersis_no"`

	Fields []ExtractedTaxField `json:"fields"`

	MissingRequiredFields []TaxFieldKey `json:"missing_required_fields"`

	ConfidenceBps  int  `json:"confidence_bps"`
	ReviewRequired bool `json:"review_required"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	ResultHash string `json:"result_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type TaxFieldExtractionRuntime struct {
	config RuntimeConfig
}

func NewTaxFieldExtractionRuntime(config RuntimeConfig) (*TaxFieldExtractionRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("tax field extraction runtime is disabled")
	}
	if config.MinConfidenceBps <= 0 {
		return nil, errors.New("min_confidence_bps must be positive")
	}
	if config.ReviewConfidenceBps <= 0 {
		return nil, errors.New("review_confidence_bps must be positive")
	}
	if config.ReviewConfidenceBps < config.MinConfidenceBps {
		return nil, errors.New("review_confidence_bps cannot be below min_confidence_bps")
	}
	if len(config.SupportedDocumentTypes) == 0 {
		return nil, errors.New("supported_document_types are required")
	}
	if len(config.SupportedFieldKeys) == 0 {
		return nil, errors.New("supported_field_keys are required")
	}

	return &TaxFieldExtractionRuntime{config: config}, nil
}

func (r *TaxFieldExtractionRuntime) Extract(req TaxFieldExtractionRequest) (TaxFieldExtractionResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	fields := r.collectTaxFields(req.OCRResult.FieldCandidates)
	missing := r.missingRequiredFields(fields)

	confidence := r.calculateConfidence(req.OCRResult, fields, missing)

	status := TaxExtractionStatusReady
	decision := TaxExtractionDecisionExtracted
	reviewRequired := false
	reasonCode := "TAX_FIELDS_EXTRACTED"
	reason := "tax fields extracted from OCR result"

	if len(missing) > 0 {
		status = TaxExtractionStatusReviewNeeded
		decision = TaxExtractionDecisionReview
		reviewRequired = true
		reasonCode = "TAX_FIELDS_REVIEW_REQUIRED"
		reason = "required tax fields are missing"
	}

	if confidence < r.config.ReviewConfidenceBps {
		status = TaxExtractionStatusReviewNeeded
		decision = TaxExtractionDecisionReview
		reviewRequired = true
		reasonCode = "TAX_FIELDS_LOW_CONFIDENCE"
		reason = "tax field confidence requires manual review"
	}

	result := TaxFieldExtractionResult{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		ExtractionID:          req.ExtractionID,
		ProcessID:             req.OCRResult.ProcessID,
		DocumentID:            req.OCRResult.DocumentID,
		DocumentType:          req.OCRResult.DocumentType,
		Status:                status,
		Decision:              decision,
		CompanyName:           valueOf(fields, TaxFieldCompanyName),
		TaxNo:                 valueOf(fields, TaxFieldTaxNo),
		TaxOffice:             valueOf(fields, TaxFieldTaxOffice),
		MersisNo:              valueOf(fields, TaxFieldMersisNo),
		Fields:                fields,
		MissingRequiredFields: missing,
		ConfidenceBps:         confidence,
		ReviewRequired:        reviewRequired,
		ReasonCode:            reasonCode,
		Reason:                reason,
		ResultHash:            buildResultHash(req, fields, missing, confidence),
		AuditAction:           "TAX_FIELD_EXTRACTION_COMPLETED",
		AuditDecisionReason:   reason,
		CreatedAt:             time.Now().UTC(),
	}

	if r.config.RequireAuditHash && strings.TrimSpace(result.ResultHash) == "" {
		err := errors.New("result_hash is required")
		return rejected(req, "RESULT_HASH_MISSING", err.Error()), err
	}

	return result, nil
}

func (r *TaxFieldExtractionRuntime) validateRequest(req TaxFieldExtractionRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.ExtractionID) == "" {
		return errors.New("extraction_id is required")
	}
	if r.config.RequireTenantScope && req.OCRResult.TenantID != req.TenantID {
		return errors.New("ocr_result tenant_id mismatch")
	}
	if strings.TrimSpace(req.OCRResult.ProcessID) == "" {
		return errors.New("ocr_result process_id is required")
	}
	if strings.TrimSpace(req.OCRResult.DocumentID) == "" {
		return errors.New("ocr_result document_id is required")
	}
	if r.config.RequireOCRResultHash && strings.TrimSpace(req.OCRResult.ResultHash) == "" {
		return errors.New("ocr_result result_hash is required")
	}
	if !hasDocumentType(r.config.SupportedDocumentTypes, req.OCRResult.DocumentType) {
		return errors.New("ocr_result document_type is not supported")
	}
	if r.config.RequireOCRReadyOrReview {
		if req.OCRResult.Status != ocrprocessing.OCRStatusReady && req.OCRResult.Status != ocrprocessing.OCRStatusReviewNeeded {
			return errors.New("ocr_result status must be READY or REVIEW_NEEDED")
		}
	}
	if strings.TrimSpace(req.OCRResult.NormalizedText) == "" {
		return errors.New("ocr_result normalized_text is required")
	}
	if r.config.RequireConfidence && req.OCRResult.ConfidenceBps <= 0 {
		return errors.New("ocr_result confidence_bps is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *TaxFieldExtractionRuntime) collectTaxFields(candidates []ocrprocessing.OCRFieldCandidate) []ExtractedTaxField {
	bestByKey := map[TaxFieldKey]ExtractedTaxField{}

	for _, candidate := range candidates {
		key := TaxFieldKey(candidate.FieldKey)
		if !hasFieldKey(r.config.SupportedFieldKeys, key) {
			continue
		}

		field := ExtractedTaxField{
			FieldKey:        key,
			FieldLabel:      candidate.FieldLabel,
			RawValue:        candidate.RawValue,
			NormalizedValue: normalizeByKey(key, candidate.NormalizedValue),
			ConfidenceBps:   candidate.ConfidenceBps,
			SourceBlockID:   candidate.SourceBlockID,
			Decision:        "CANDIDATE_ACCEPTED",
		}

		if key == TaxFieldTaxNo && !validTaxNo(field.NormalizedValue) {
			field.Decision = "CANDIDATE_REVIEW_INVALID_TAX_NO"
			field.ConfidenceBps -= 1500
			if field.ConfidenceBps < r.config.MinConfidenceBps {
				field.ConfidenceBps = r.config.MinConfidenceBps
			}
		}

		if existing, ok := bestByKey[key]; !ok || field.ConfidenceBps > existing.ConfidenceBps {
			bestByKey[key] = field
		}
	}

	fields := make([]ExtractedTaxField, 0, len(bestByKey))
	for _, field := range bestByKey {
		fields = append(fields, field)
	}

	sort.SliceStable(fields, func(i int, j int) bool {
		return fields[i].FieldKey < fields[j].FieldKey
	})

	return fields
}

func (r *TaxFieldExtractionRuntime) missingRequiredFields(fields []ExtractedTaxField) []TaxFieldKey {
	missing := make([]TaxFieldKey, 0)

	if r.config.RequireCompanyNameCandidate && valueOf(fields, TaxFieldCompanyName) == "" {
		missing = append(missing, TaxFieldCompanyName)
	}
	if r.config.RequireTaxNo && valueOf(fields, TaxFieldTaxNo) == "" {
		missing = append(missing, TaxFieldTaxNo)
	}
	if r.config.RequireTaxOffice && valueOf(fields, TaxFieldTaxOffice) == "" {
		missing = append(missing, TaxFieldTaxOffice)
	}

	return missing
}

func (r *TaxFieldExtractionRuntime) calculateConfidence(ocr ocrprocessing.ProcessResult, fields []ExtractedTaxField, missing []TaxFieldKey) int {
	if len(fields) == 0 {
		return r.config.MinConfidenceBps
	}

	total := ocr.ConfidenceBps
	count := 1

	for _, field := range fields {
		total += field.ConfidenceBps
		count++
	}

	confidence := total / count

	if len(missing) > 0 {
		confidence -= len(missing) * 1000
	}

	if valueOf(fields, TaxFieldTaxNo) != "" && validTaxNo(valueOf(fields, TaxFieldTaxNo)) {
		confidence += 250
	}
	if valueOf(fields, TaxFieldTaxOffice) != "" {
		confidence += 150
	}
	if valueOf(fields, TaxFieldCompanyName) != "" {
		confidence += 100
	}

	if confidence > 9900 {
		confidence = 9900
	}
	if confidence < r.config.MinConfidenceBps {
		confidence = r.config.MinConfidenceBps
	}

	return confidence
}

func normalizeByKey(key TaxFieldKey, value string) string {
	value = strings.TrimSpace(value)
	value = strings.Join(strings.Fields(value), " ")

	switch key {
	case TaxFieldTaxNo:
		return onlyDigits(value)
	case TaxFieldMersisNo:
		return onlyDigits(value)
	case TaxFieldTaxOffice:
		return normalizeTurkishText(value)
	case TaxFieldCompanyName:
		return normalizeTurkishText(value)
	default:
		return value
	}
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

func normalizeTurkishText(value string) string {
	value = strings.TrimSpace(value)
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "\r", " ")
	return strings.Join(strings.Fields(value), " ")
}

func validTaxNo(value string) bool {
	digits := onlyDigits(value)
	return len(digits) == 10 || len(digits) == 11
}

func valueOf(fields []ExtractedTaxField, key TaxFieldKey) string {
	for _, field := range fields {
		if field.FieldKey == key {
			return field.NormalizedValue
		}
	}
	return ""
}

func hasDocumentType(items []ocrprocessing.DocumentType, value ocrprocessing.DocumentType) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func hasFieldKey(items []TaxFieldKey, value TaxFieldKey) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func buildResultHash(req TaxFieldExtractionRequest, fields []ExtractedTaxField, missing []TaxFieldKey, confidence int) string {
	parts := []string{
		req.TenantID,
		req.ExtractionID,
		req.OCRResult.ProcessID,
		req.OCRResult.DocumentID,
		req.OCRResult.ResultHash,
		fmt.Sprintf("fields:%d", len(fields)),
		fmt.Sprintf("missing:%d", len(missing)),
		fmt.Sprintf("confidence:%d", confidence),
	}

	for _, field := range fields {
		parts = append(parts, string(field.FieldKey)+":"+field.NormalizedValue)
	}

	return "tax-field-extraction:" + strings.Join(parts, ":")
}

func rejected(req TaxFieldExtractionRequest, code string, message string) TaxFieldExtractionResult {
	return TaxFieldExtractionResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExtractionID:        req.ExtractionID,
		ProcessID:           req.OCRResult.ProcessID,
		DocumentID:          req.OCRResult.DocumentID,
		DocumentType:        req.OCRResult.DocumentType,
		Status:              TaxExtractionStatusRejected,
		Decision:            TaxExtractionDecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "TAX_FIELD_EXTRACTION_REJECTED",
		AuditDecisionReason: "tax field extraction rejected by runtime guard",
		CreatedAt:           time.Now().UTC(),
	}
}
