package contactextraction

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode"

	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
)

type ContactExtractionStatus string

const (
	ContactExtractionStatusReady        ContactExtractionStatus = "READY"
	ContactExtractionStatusReviewNeeded ContactExtractionStatus = "REVIEW_NEEDED"
	ContactExtractionStatusRejected     ContactExtractionStatus = "REJECTED"
)

type ContactExtractionDecision string

const (
	ContactExtractionDecisionExtracted ContactExtractionDecision = "EXTRACTED"
	ContactExtractionDecisionReview    ContactExtractionDecision = "REVIEW"
	ContactExtractionDecisionRejected  ContactExtractionDecision = "REJECTED"
)

type ContactFieldKey string

const (
	ContactFieldCompanyName ContactFieldKey = "company_name"
	ContactFieldPhone       ContactFieldKey = "phone"
	ContactFieldEmail       ContactFieldKey = "email"
	ContactFieldAddress     ContactFieldKey = "address"
)

type RuntimeConfig struct {
	RuntimeEnabled              bool                         `json:"runtime_enabled"`
	RequireTenantScope          bool                         `json:"require_tenant_scope"`
	RequireOCRResultHash        bool                         `json:"require_ocr_result_hash"`
	RequireOCRReadyOrReview     bool                         `json:"require_ocr_ready_or_review"`
	RequirePhone                bool                         `json:"require_phone"`
	RequireEmail                bool                         `json:"require_email"`
	RequireAddress              bool                         `json:"require_address"`
	RequireCompanyNameCandidate bool                         `json:"require_company_name_candidate"`
	RequireConfidence           bool                         `json:"require_confidence"`
	RequireAuditHash            bool                         `json:"require_audit_hash"`
	MinConfidenceBps            int                          `json:"min_confidence_bps"`
	ReviewConfidenceBps         int                          `json:"review_confidence_bps"`
	SupportedDocumentTypes      []ocrprocessing.DocumentType `json:"supported_document_types"`
	SupportedFieldKeys          []ContactFieldKey            `json:"supported_field_keys"`
}

type ContactFieldExtractionRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExtractionID string `json:"extraction_id"`

	OCRResult ocrprocessing.ProcessResult `json:"ocr_result"`

	RequestedAt time.Time `json:"requested_at"`
}

type ExtractedContactField struct {
	FieldKey        ContactFieldKey `json:"field_key"`
	FieldLabel      string          `json:"field_label"`
	RawValue        string          `json:"raw_value"`
	NormalizedValue string          `json:"normalized_value"`
	ConfidenceBps   int             `json:"confidence_bps"`
	SourceBlockID   string          `json:"source_block_id"`
	Decision        string          `json:"decision"`
}

type ContactFieldExtractionResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExtractionID string `json:"extraction_id"`
	ProcessID    string `json:"process_id"`
	DocumentID   string `json:"document_id"`

	DocumentType ocrprocessing.DocumentType `json:"document_type"`

	Status   ContactExtractionStatus   `json:"status"`
	Decision ContactExtractionDecision `json:"decision"`

	CompanyName string `json:"company_name"`
	Phone       string `json:"phone"`
	Email       string `json:"email"`
	Address     string `json:"address"`

	Fields []ExtractedContactField `json:"fields"`

	MissingRequiredFields []ContactFieldKey `json:"missing_required_fields"`

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

type ContactFieldExtractionRuntime struct {
	config RuntimeConfig
}

func NewContactFieldExtractionRuntime(config RuntimeConfig) (*ContactFieldExtractionRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("contact field extraction runtime is disabled")
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

	return &ContactFieldExtractionRuntime{config: config}, nil
}

func (r *ContactFieldExtractionRuntime) Extract(req ContactFieldExtractionRequest) (ContactFieldExtractionResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	fields := r.collectContactFields(req.OCRResult.FieldCandidates)
	missing := r.missingRequiredFields(fields)
	confidence := r.calculateConfidence(req.OCRResult, fields, missing)

	status := ContactExtractionStatusReady
	decision := ContactExtractionDecisionExtracted
	reviewRequired := false
	reasonCode := "CONTACT_FIELDS_EXTRACTED"
	reason := "contact fields extracted from OCR result"

	if len(missing) > 0 {
		status = ContactExtractionStatusReviewNeeded
		decision = ContactExtractionDecisionReview
		reviewRequired = true
		reasonCode = "CONTACT_FIELDS_REVIEW_REQUIRED"
		reason = "required contact fields are missing"
	}

	if confidence < r.config.ReviewConfidenceBps {
		status = ContactExtractionStatusReviewNeeded
		decision = ContactExtractionDecisionReview
		reviewRequired = true
		reasonCode = "CONTACT_FIELDS_LOW_CONFIDENCE"
		reason = "contact field confidence requires manual review"
	}

	result := ContactFieldExtractionResult{
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
		CompanyName:           valueOf(fields, ContactFieldCompanyName),
		Phone:                 valueOf(fields, ContactFieldPhone),
		Email:                 valueOf(fields, ContactFieldEmail),
		Address:               valueOf(fields, ContactFieldAddress),
		Fields:                fields,
		MissingRequiredFields: missing,
		ConfidenceBps:         confidence,
		ReviewRequired:        reviewRequired,
		ReasonCode:            reasonCode,
		Reason:                reason,
		ResultHash:            buildResultHash(req, fields, missing, confidence),
		AuditAction:           "CONTACT_FIELD_EXTRACTION_COMPLETED",
		AuditDecisionReason:   reason,
		CreatedAt:             time.Now().UTC(),
	}

	if r.config.RequireAuditHash && strings.TrimSpace(result.ResultHash) == "" {
		err := errors.New("result_hash is required")
		return rejected(req, "RESULT_HASH_MISSING", err.Error()), err
	}

	return result, nil
}

func (r *ContactFieldExtractionRuntime) validateRequest(req ContactFieldExtractionRequest) error {
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

func (r *ContactFieldExtractionRuntime) collectContactFields(candidates []ocrprocessing.OCRFieldCandidate) []ExtractedContactField {
	bestByKey := map[ContactFieldKey]ExtractedContactField{}

	for _, candidate := range candidates {
		key := ContactFieldKey(candidate.FieldKey)
		if !hasFieldKey(r.config.SupportedFieldKeys, key) {
			continue
		}

		field := ExtractedContactField{
			FieldKey:        key,
			FieldLabel:      candidate.FieldLabel,
			RawValue:        candidate.RawValue,
			NormalizedValue: normalizeByKey(key, candidate.NormalizedValue),
			ConfidenceBps:   candidate.ConfidenceBps,
			SourceBlockID:   candidate.SourceBlockID,
			Decision:        "CANDIDATE_ACCEPTED",
		}

		if key == ContactFieldEmail && !validEmail(field.NormalizedValue) {
			field.Decision = "CANDIDATE_REVIEW_INVALID_EMAIL"
			field.ConfidenceBps = lowerConfidence(field.ConfidenceBps, 1500, r.config.MinConfidenceBps)
		}

		if key == ContactFieldPhone && !validPhone(field.NormalizedValue) {
			field.Decision = "CANDIDATE_REVIEW_INVALID_PHONE"
			field.ConfidenceBps = lowerConfidence(field.ConfidenceBps, 1500, r.config.MinConfidenceBps)
		}

		if existing, ok := bestByKey[key]; !ok || field.ConfidenceBps > existing.ConfidenceBps {
			bestByKey[key] = field
		}
	}

	fields := make([]ExtractedContactField, 0, len(bestByKey))
	for _, field := range bestByKey {
		fields = append(fields, field)
	}

	sort.SliceStable(fields, func(i int, j int) bool {
		return fields[i].FieldKey < fields[j].FieldKey
	})

	return fields
}

func (r *ContactFieldExtractionRuntime) missingRequiredFields(fields []ExtractedContactField) []ContactFieldKey {
	missing := make([]ContactFieldKey, 0)

	if r.config.RequireCompanyNameCandidate && valueOf(fields, ContactFieldCompanyName) == "" {
		missing = append(missing, ContactFieldCompanyName)
	}
	if r.config.RequirePhone && valueOf(fields, ContactFieldPhone) == "" {
		missing = append(missing, ContactFieldPhone)
	}
	if r.config.RequireEmail && valueOf(fields, ContactFieldEmail) == "" {
		missing = append(missing, ContactFieldEmail)
	}
	if r.config.RequireAddress && valueOf(fields, ContactFieldAddress) == "" {
		missing = append(missing, ContactFieldAddress)
	}

	return missing
}

func (r *ContactFieldExtractionRuntime) calculateConfidence(ocr ocrprocessing.ProcessResult, fields []ExtractedContactField, missing []ContactFieldKey) int {
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

	if valueOf(fields, ContactFieldEmail) != "" && validEmail(valueOf(fields, ContactFieldEmail)) {
		confidence += 250
	}
	if valueOf(fields, ContactFieldPhone) != "" && validPhone(valueOf(fields, ContactFieldPhone)) {
		confidence += 250
	}
	if valueOf(fields, ContactFieldAddress) != "" {
		confidence += 150
	}
	if valueOf(fields, ContactFieldCompanyName) != "" {
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

func normalizeByKey(key ContactFieldKey, value string) string {
	value = strings.TrimSpace(value)
	value = strings.Join(strings.Fields(value), " ")

	switch key {
	case ContactFieldPhone:
		return normalizePhone(value)
	case ContactFieldEmail:
		return strings.ToLower(value)
	case ContactFieldAddress:
		return normalizeText(value)
	case ContactFieldCompanyName:
		return normalizeText(value)
	default:
		return value
	}
}

func normalizePhone(value string) string {
	var b strings.Builder
	for _, r := range value {
		if unicode.IsDigit(r) || r == '+' {
			b.WriteRune(r)
		}
	}
	return b.String()
}

func normalizeText(value string) string {
	value = strings.TrimSpace(value)
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "\r", " ")
	return strings.Join(strings.Fields(value), " ")
}

func validEmail(value string) bool {
	value = strings.TrimSpace(strings.ToLower(value))
	if strings.Count(value, "@") != 1 {
		return false
	}
	parts := strings.Split(value, "@")
	return len(parts[0]) > 0 && strings.Contains(parts[1], ".") && !strings.Contains(value, " ")
}

func validPhone(value string) bool {
	digits := onlyDigits(value)
	return len(digits) >= 10 && len(digits) <= 13
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

func lowerConfidence(value int, penalty int, min int) int {
	value -= penalty
	if value < min {
		return min
	}
	return value
}

func valueOf(fields []ExtractedContactField, key ContactFieldKey) string {
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

func hasFieldKey(items []ContactFieldKey, value ContactFieldKey) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func buildResultHash(req ContactFieldExtractionRequest, fields []ExtractedContactField, missing []ContactFieldKey, confidence int) string {
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

	return "contact-field-extraction:" + strings.Join(parts, ":")
}

func rejected(req ContactFieldExtractionRequest, code string, message string) ContactFieldExtractionResult {
	return ContactFieldExtractionResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExtractionID:        req.ExtractionID,
		ProcessID:           req.OCRResult.ProcessID,
		DocumentID:          req.OCRResult.DocumentID,
		DocumentType:        req.OCRResult.DocumentType,
		Status:              ContactExtractionStatusRejected,
		Decision:            ContactExtractionDecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "CONTACT_FIELD_EXTRACTION_REJECTED",
		AuditDecisionReason: "contact field extraction rejected by runtime guard",
		CreatedAt:           time.Now().UTC(),
	}
}
