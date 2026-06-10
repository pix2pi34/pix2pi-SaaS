package ocrprocessing

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode"
)

type SourceType string

const (
	SourceTypeImage SourceType = "IMAGE"
	SourceTypePDF   SourceType = "PDF"
	SourceTypeScan  SourceType = "SCAN"
)

type DocumentType string

const (
	DocumentTypeUnknown        DocumentType = "UNKNOWN"
	DocumentTypeTaxCertificate DocumentType = "TAX_CERTIFICATE"
	DocumentTypeBusinessCard   DocumentType = "BUSINESS_CARD"
	DocumentTypeInvoice        DocumentType = "INVOICE"
	DocumentTypeReceipt        DocumentType = "RECEIPT"
)

type OCRStatus string

const (
	OCRStatusReady        OCRStatus = "READY"
	OCRStatusReviewNeeded OCRStatus = "REVIEW_NEEDED"
	OCRStatusRejected     OCRStatus = "REJECTED"
)

type OCRDecision string

const (
	OCRDecisionProcessed OCRDecision = "PROCESSED"
	OCRDecisionReview    OCRDecision = "REVIEW"
	OCRDecisionRejected  OCRDecision = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled         bool           `json:"runtime_enabled"`
	DefaultLanguage        string         `json:"default_language"`
	RequireTenantScope     bool           `json:"require_tenant_scope"`
	RequireFileHash        bool           `json:"require_file_hash"`
	RequireSourceText      bool           `json:"require_source_text"`
	RequireConfidence      bool           `json:"require_confidence"`
	RequireAuditHash       bool           `json:"require_audit_hash"`
	MinConfidenceBps       int            `json:"min_confidence_bps"`
	ReviewConfidenceBps    int            `json:"review_confidence_bps"`
	MaxTextLength          int            `json:"max_text_length"`
	AllowedSourceTypes     []SourceType   `json:"allowed_source_types"`
	AllowedMimeTypes       []string       `json:"allowed_mime_types"`
	SupportedDocumentTypes []DocumentType `json:"supported_document_types"`
}

type OCRSource struct {
	TenantID   string     `json:"tenant_id"`
	DocumentID string     `json:"document_id"`
	SourceType SourceType `json:"source_type"`
	MimeType   string     `json:"mime_type"`
	FileName   string     `json:"file_name"`
	FileHash   string     `json:"file_hash"`
	SourceText string     `json:"source_text"`
	Language   string     `json:"language"`
	PageCount  int        `json:"page_count"`
	ImageCount int        `json:"image_count"`
	UploadedBy string     `json:"uploaded_by"`
	UploadedAt time.Time  `json:"uploaded_at"`
}

type OCRBlock struct {
	BlockID        string `json:"block_id"`
	PageNo         int    `json:"page_no"`
	LineNo         int    `json:"line_no"`
	Text           string `json:"text"`
	NormalizedText string `json:"normalized_text"`
	ConfidenceBps  int    `json:"confidence_bps"`
}

type OCRFieldCandidate struct {
	FieldKey        string `json:"field_key"`
	FieldLabel      string `json:"field_label"`
	RawValue        string `json:"raw_value"`
	NormalizedValue string `json:"normalized_value"`
	ConfidenceBps   int    `json:"confidence_bps"`
	SourceBlockID   string `json:"source_block_id"`
}

type ProcessRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ProcessID string `json:"process_id"`

	ExpectedDocumentType DocumentType `json:"expected_document_type"`
	Source               OCRSource    `json:"source"`

	RequestedAt time.Time `json:"requested_at"`
}

type ProcessResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ProcessID    string       `json:"process_id"`
	DocumentID   string       `json:"document_id"`
	SourceType   SourceType   `json:"source_type"`
	DocumentType DocumentType `json:"document_type"`

	Status   OCRStatus   `json:"status"`
	Decision OCRDecision `json:"decision"`

	RawText        string `json:"raw_text"`
	NormalizedText string `json:"normalized_text"`

	Blocks          []OCRBlock          `json:"blocks"`
	FieldCandidates []OCRFieldCandidate `json:"field_candidates"`

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

type OCRLensProcessingRuntime struct {
	config RuntimeConfig
}

func NewOCRLensProcessingRuntime(config RuntimeConfig) (*OCRLensProcessingRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("ocr lens processing runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultLanguage) == "" {
		return nil, errors.New("default_language is required")
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
	if config.MaxTextLength <= 0 {
		return nil, errors.New("max_text_length must be positive")
	}
	if len(config.AllowedSourceTypes) == 0 {
		return nil, errors.New("allowed_source_types are required")
	}
	if len(config.AllowedMimeTypes) == 0 {
		return nil, errors.New("allowed_mime_types are required")
	}
	if len(config.SupportedDocumentTypes) == 0 {
		return nil, errors.New("supported_document_types are required")
	}

	return &OCRLensProcessingRuntime{config: config}, nil
}

func (r *OCRLensProcessingRuntime) Process(req ProcessRequest) (ProcessResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	normalizedText := normalizeOCRText(req.Source.SourceText)
	blocks := buildBlocks(normalizedText, r.estimateBlockConfidence(req.Source))
	documentType := r.detectDocumentType(req.ExpectedDocumentType, normalizedText)
	candidates := r.extractCandidates(blocks)

	confidence := r.calculateConfidence(req.Source, normalizedText, blocks, candidates, documentType)
	status := OCRStatusReady
	decision := OCRDecisionProcessed
	reviewRequired := false
	reasonCode := "OCR_PROCESSED"
	reason := "OCR lens processing completed"

	if confidence < r.config.ReviewConfidenceBps {
		status = OCRStatusReviewNeeded
		decision = OCRDecisionReview
		reviewRequired = true
		reasonCode = "OCR_REVIEW_REQUIRED"
		reason = "OCR confidence requires manual review"
	}

	result := ProcessResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ProcessID:           req.ProcessID,
		DocumentID:          req.Source.DocumentID,
		SourceType:          req.Source.SourceType,
		DocumentType:        documentType,
		Status:              status,
		Decision:            decision,
		RawText:             req.Source.SourceText,
		NormalizedText:      normalizedText,
		Blocks:              blocks,
		FieldCandidates:     candidates,
		ConfidenceBps:       confidence,
		ReviewRequired:      reviewRequired,
		ReasonCode:          reasonCode,
		Reason:              reason,
		ResultHash:          buildResultHash(req, normalizedText, blocks, candidates, confidence),
		AuditAction:         "OCR_LENS_PROCESSING_COMPLETED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}

	if r.config.RequireAuditHash && strings.TrimSpace(result.ResultHash) == "" {
		err := errors.New("result_hash is required")
		return rejected(req, "RESULT_HASH_MISSING", err.Error()), err
	}

	return result, nil
}

func (r *OCRLensProcessingRuntime) validateRequest(req ProcessRequest) error {
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
	if strings.TrimSpace(req.ProcessID) == "" {
		return errors.New("process_id is required")
	}
	if !hasDocumentType(r.config.SupportedDocumentTypes, req.ExpectedDocumentType) {
		return errors.New("expected_document_type is not supported")
	}
	if err := r.validateSource(req.TenantID, req.Source); err != nil {
		return err
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *OCRLensProcessingRuntime) validateSource(expectedTenantID string, source OCRSource) error {
	if r.config.RequireTenantScope && source.TenantID != expectedTenantID {
		return errors.New("source tenant_id mismatch")
	}
	if strings.TrimSpace(source.DocumentID) == "" {
		return errors.New("source document_id is required")
	}
	if !hasSourceType(r.config.AllowedSourceTypes, source.SourceType) {
		return errors.New("source_type is not allowed")
	}
	if strings.TrimSpace(source.MimeType) == "" {
		return errors.New("mime_type is required")
	}
	if !hasString(r.config.AllowedMimeTypes, source.MimeType) {
		return errors.New("mime_type is not allowed")
	}
	if strings.TrimSpace(source.FileName) == "" {
		return errors.New("file_name is required")
	}
	if r.config.RequireFileHash && strings.TrimSpace(source.FileHash) == "" {
		return errors.New("file_hash is required")
	}
	if r.config.RequireSourceText && strings.TrimSpace(source.SourceText) == "" {
		return errors.New("source_text is required")
	}
	if len(source.SourceText) > r.config.MaxTextLength {
		return errors.New("source_text exceeds max_text_length")
	}
	if strings.TrimSpace(source.Language) == "" {
		return errors.New("language is required")
	}
	if source.PageCount <= 0 {
		return errors.New("page_count must be positive")
	}
	if source.ImageCount <= 0 {
		return errors.New("image_count must be positive")
	}
	if strings.TrimSpace(source.UploadedBy) == "" {
		return errors.New("uploaded_by is required")
	}
	if source.UploadedAt.IsZero() {
		return errors.New("uploaded_at is required")
	}
	return nil
}

func (r *OCRLensProcessingRuntime) detectDocumentType(expected DocumentType, normalizedText string) DocumentType {
	if expected != DocumentTypeUnknown {
		return expected
	}

	lower := strings.ToLower(normalizedText)
	switch {
	case strings.Contains(lower, "vergi dairesi") || strings.Contains(lower, "vergi no") || strings.Contains(lower, "vkn"):
		return DocumentTypeTaxCertificate
	case strings.Contains(lower, "e-fatura") || strings.Contains(lower, "fatura no"):
		return DocumentTypeInvoice
	case strings.Contains(lower, "fis no") || strings.Contains(lower, "tutar"):
		return DocumentTypeReceipt
	case strings.Contains(lower, "telefon") || strings.Contains(lower, "email") || strings.Contains(lower, "e-posta"):
		return DocumentTypeBusinessCard
	default:
		return DocumentTypeUnknown
	}
}

func (r *OCRLensProcessingRuntime) estimateBlockConfidence(source OCRSource) int {
	confidence := 9300

	if source.SourceType == SourceTypeScan {
		confidence -= 300
	}
	if source.SourceType == SourceTypeImage {
		confidence -= 150
	}
	if source.PageCount > 3 {
		confidence -= 100
	}
	if source.ImageCount > 5 {
		confidence -= 100
	}
	if len(strings.TrimSpace(source.SourceText)) < 30 {
		confidence -= 1200
	}

	if confidence < r.config.MinConfidenceBps {
		return r.config.MinConfidenceBps
	}
	return confidence
}

func (r *OCRLensProcessingRuntime) calculateConfidence(source OCRSource, normalizedText string, blocks []OCRBlock, candidates []OCRFieldCandidate, docType DocumentType) int {
	if len(blocks) == 0 || strings.TrimSpace(normalizedText) == "" {
		return r.config.MinConfidenceBps
	}

	total := 0
	for _, block := range blocks {
		total += block.ConfidenceBps
	}

	confidence := total / len(blocks)

	if len(candidates) >= 3 {
		confidence += 250
	}
	if docType != DocumentTypeUnknown {
		confidence += 150
	}
	if source.Language != r.config.DefaultLanguage {
		confidence -= 200
	}
	if confidence > 9900 {
		confidence = 9900
	}
	if confidence < r.config.MinConfidenceBps {
		confidence = r.config.MinConfidenceBps
	}

	return confidence
}

func buildBlocks(normalizedText string, confidence int) []OCRBlock {
	lines := strings.Split(normalizedText, "\n")
	blocks := make([]OCRBlock, 0, len(lines))

	lineNo := 1
	for _, line := range lines {
		clean := strings.TrimSpace(line)
		if clean == "" {
			continue
		}

		blocks = append(blocks, OCRBlock{
			BlockID:        fmt.Sprintf("block-%03d", lineNo),
			PageNo:         1,
			LineNo:         lineNo,
			Text:           clean,
			NormalizedText: clean,
			ConfidenceBps:  confidence,
		})
		lineNo++
	}

	return blocks
}

func (r *OCRLensProcessingRuntime) extractCandidates(blocks []OCRBlock) []OCRFieldCandidate {
	candidates := make([]OCRFieldCandidate, 0)

	for _, block := range blocks {
		line := block.NormalizedText
		lower := strings.ToLower(line)

		switch {
		case strings.Contains(lower, "vergi no"):
			candidates = append(candidates, candidateFromLine("tax_no", "Vergi No", line, block))
		case strings.Contains(lower, "vkn"):
			candidates = append(candidates, candidateFromLine("tax_no", "VKN", line, block))
		case strings.Contains(lower, "vergi dairesi"):
			candidates = append(candidates, candidateFromLine("tax_office", "Vergi Dairesi", line, block))
		case strings.Contains(lower, "mersis"):
			candidates = append(candidates, candidateFromLine("mersis_no", "Mersis No", line, block))
		case strings.Contains(lower, "telefon"):
			candidates = append(candidates, candidateFromLine("phone", "Telefon", line, block))
		case strings.Contains(lower, "email") || strings.Contains(lower, "e-posta"):
			candidates = append(candidates, candidateFromLine("email", "Email", line, block))
		case strings.Contains(lower, "adres"):
			candidates = append(candidates, candidateFromLine("address", "Adres", line, block))
		case strings.Contains(lower, "firma") || strings.Contains(lower, "unvan"):
			candidates = append(candidates, candidateFromLine("company_name", "Firma Ünvanı", line, block))
		}
	}

	sort.SliceStable(candidates, func(i int, j int) bool {
		if candidates[i].FieldKey == candidates[j].FieldKey {
			return candidates[i].SourceBlockID < candidates[j].SourceBlockID
		}
		return candidates[i].FieldKey < candidates[j].FieldKey
	})

	return candidates
}

func candidateFromLine(key string, label string, line string, block OCRBlock) OCRFieldCandidate {
	value := valueAfterSeparator(line)
	return OCRFieldCandidate{
		FieldKey:        key,
		FieldLabel:      label,
		RawValue:        value,
		NormalizedValue: normalizeFieldValue(value),
		ConfidenceBps:   block.ConfidenceBps,
		SourceBlockID:   block.BlockID,
	}
}

func valueAfterSeparator(line string) string {
	for _, sep := range []string{":", "=", "-"} {
		if strings.Contains(line, sep) {
			parts := strings.SplitN(line, sep, 2)
			return strings.TrimSpace(parts[1])
		}
	}
	return strings.TrimSpace(line)
}

func normalizeOCRText(text string) string {
	text = strings.ReplaceAll(text, "\r\n", "\n")
	text = strings.ReplaceAll(text, "\r", "\n")
	lines := strings.Split(text, "\n")
	normalizedLines := make([]string, 0, len(lines))

	for _, line := range lines {
		clean := strings.TrimSpace(line)
		clean = strings.Join(strings.Fields(clean), " ")
		if clean != "" {
			normalizedLines = append(normalizedLines, clean)
		}
	}

	return strings.Join(normalizedLines, "\n")
}

func normalizeFieldValue(value string) string {
	value = strings.TrimSpace(value)
	value = strings.Join(strings.Fields(value), " ")
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return -1
		}
		return r
	}, value)
}

func hasSourceType(items []SourceType, value SourceType) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func hasDocumentType(items []DocumentType, value DocumentType) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func hasString(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func buildResultHash(req ProcessRequest, normalizedText string, blocks []OCRBlock, candidates []OCRFieldCandidate, confidence int) string {
	parts := []string{
		req.TenantID,
		req.ProcessID,
		req.Source.DocumentID,
		string(req.Source.SourceType),
		req.Source.FileHash,
		fmt.Sprintf("text:%d", len(normalizedText)),
		fmt.Sprintf("blocks:%d", len(blocks)),
		fmt.Sprintf("candidates:%d", len(candidates)),
		fmt.Sprintf("confidence:%d", confidence),
	}
	return "ocr-lens-processing:" + strings.Join(parts, ":")
}

func rejected(req ProcessRequest, code string, message string) ProcessResult {
	return ProcessResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ProcessID:           req.ProcessID,
		DocumentID:          req.Source.DocumentID,
		SourceType:          req.Source.SourceType,
		DocumentType:        req.ExpectedDocumentType,
		Status:              OCRStatusRejected,
		Decision:            OCRDecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "OCR_LENS_PROCESSING_REJECTED",
		AuditDecisionReason: "OCR lens processing rejected by runtime guard",
		CreatedAt:           time.Now().UTC(),
	}
}
