package contactextraction

import (
	"strings"
	"testing"
	"time"

	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:              true,
		RequireTenantScope:          true,
		RequireOCRResultHash:        true,
		RequireOCRReadyOrReview:     true,
		RequirePhone:                true,
		RequireEmail:                true,
		RequireAddress:              true,
		RequireCompanyNameCandidate: true,
		RequireConfidence:           true,
		RequireAuditHash:            true,
		MinConfidenceBps:            5000,
		ReviewConfidenceBps:         8500,
		SupportedDocumentTypes: []ocrprocessing.DocumentType{
			ocrprocessing.DocumentTypeTaxCertificate,
			ocrprocessing.DocumentTypeInvoice,
			ocrprocessing.DocumentTypeBusinessCard,
			ocrprocessing.DocumentTypeUnknown,
		},
		SupportedFieldKeys: []ContactFieldKey{
			ContactFieldCompanyName,
			ContactFieldPhone,
			ContactFieldEmail,
			ContactFieldAddress,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validOCRResult() ocrprocessing.ProcessResult {
	return ocrprocessing.ProcessResult{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-ocr-001",
		RequestID:      "req-ocr-001",
		IdempotencyKey: "idem-ocr-001",
		ProcessID:      "ocr-process-001",
		DocumentID:     "doc-ocr-001",
		SourceType:     ocrprocessing.SourceTypeImage,
		DocumentType:   ocrprocessing.DocumentTypeBusinessCard,
		Status:         ocrprocessing.OCRStatusReady,
		Decision:       ocrprocessing.OCRDecisionProcessed,
		RawText:        "Firma Ünvanı: Pilot Market A.Ş.\nTelefon: 0216 000 00 00\nEmail: INFO@PILOTMARKET.TEST\nAdres: İstanbul Kadıköy",
		NormalizedText: "Firma Ünvanı: Pilot Market A.Ş.\nTelefon: 0216 000 00 00\nEmail: INFO@PILOTMARKET.TEST\nAdres: İstanbul Kadıköy",
		Blocks: []ocrprocessing.OCRBlock{
			{BlockID: "block-001", PageNo: 1, LineNo: 1, Text: "Firma Ünvanı: Pilot Market A.Ş.", NormalizedText: "Firma Ünvanı: Pilot Market A.Ş.", ConfidenceBps: 9300},
			{BlockID: "block-002", PageNo: 1, LineNo: 2, Text: "Telefon: 0216 000 00 00", NormalizedText: "Telefon: 0216 000 00 00", ConfidenceBps: 9300},
			{BlockID: "block-003", PageNo: 1, LineNo: 3, Text: "Email: INFO@PILOTMARKET.TEST", NormalizedText: "Email: INFO@PILOTMARKET.TEST", ConfidenceBps: 9300},
			{BlockID: "block-004", PageNo: 1, LineNo: 4, Text: "Adres: İstanbul Kadıköy", NormalizedText: "Adres: İstanbul Kadıköy", ConfidenceBps: 9300},
		},
		FieldCandidates: []ocrprocessing.OCRFieldCandidate{
			{FieldKey: "company_name", FieldLabel: "Firma Ünvanı", RawValue: "Pilot Market A.Ş.", NormalizedValue: "Pilot Market A.Ş.", ConfidenceBps: 9300, SourceBlockID: "block-001"},
			{FieldKey: "phone", FieldLabel: "Telefon", RawValue: "0216 000 00 00", NormalizedValue: "0216 000 00 00", ConfidenceBps: 9300, SourceBlockID: "block-002"},
			{FieldKey: "email", FieldLabel: "Email", RawValue: "INFO@PILOTMARKET.TEST", NormalizedValue: "INFO@PILOTMARKET.TEST", ConfidenceBps: 9300, SourceBlockID: "block-003"},
			{FieldKey: "address", FieldLabel: "Adres", RawValue: "İstanbul Kadıköy", NormalizedValue: "İstanbul Kadıköy", ConfidenceBps: 9300, SourceBlockID: "block-004"},
		},
		ConfidenceBps:  9450,
		ReviewRequired: false,
		ReasonCode:     "OCR_PROCESSED",
		ResultHash:     "ocr-lens-processing:tenant-accountant-001:ocr-process-001",
		CreatedAt:      validNow(),
	}
}

func validRequest() ContactFieldExtractionRequest {
	return ContactFieldExtractionRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-contact-extraction-001",
		RequestID:      "req-contact-extraction-001",
		IdempotencyKey: "idem-contact-extraction-001",
		ExtractionID:   "contact-extraction-001",
		OCRResult:      validOCRResult(),
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *ContactFieldExtractionRuntime {
	t.Helper()

	runtime, err := NewContactFieldExtractionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestExtractContactFieldsReady(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Extract(validRequest())
	if err != nil {
		t.Fatalf("expected contact extraction ready, got error: %v", err)
	}
	if result.Status != ContactExtractionStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.Decision != ContactExtractionDecisionExtracted {
		t.Fatalf("expected EXTRACTED, got %s", result.Decision)
	}
	if result.Phone != "02160000000" {
		t.Fatalf("expected normalized phone, got %s", result.Phone)
	}
	if result.Email != "info@pilotmarket.test" {
		t.Fatalf("expected normalized email, got %s", result.Email)
	}
	if result.Address != "İstanbul Kadıköy" {
		t.Fatalf("expected address, got %s", result.Address)
	}
	if result.CompanyName != "Pilot Market A.Ş." {
		t.Fatalf("expected company name, got %s", result.CompanyName)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestExtractPhoneNormalization(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates[1].RawValue = "+90 (216) 000-00-00"
	req.OCRResult.FieldCandidates[1].NormalizedValue = "+90 (216) 000-00-00"

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected contact extraction ready, got error: %v", err)
	}
	if result.Phone != "+902160000000" {
		t.Fatalf("expected +902160000000, got %s", result.Phone)
	}
}

func TestExtractEmailNormalization(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Extract(validRequest())
	if err != nil {
		t.Fatalf("expected contact extraction ready, got error: %v", err)
	}
	if result.Email != "info@pilotmarket.test" {
		t.Fatalf("expected lowercase email, got %s", result.Email)
	}
}

func TestExtractReviewWhenAddressMissing(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates = req.OCRResult.FieldCandidates[:3]

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected review result without validation error, got error: %v", err)
	}
	if result.Status != ContactExtractionStatusReviewNeeded {
		t.Fatalf("expected REVIEW_NEEDED, got %s", result.Status)
	}
	if !result.ReviewRequired {
		t.Fatal("expected review required")
	}
	if len(result.MissingRequiredFields) == 0 {
		t.Fatal("expected missing required fields")
	}
}

func TestExtractReviewWhenLowConfidence(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.ConfidenceBps = 6000
	for i := range req.OCRResult.FieldCandidates {
		req.OCRResult.FieldCandidates[i].ConfidenceBps = 6000
	}

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected review result without validation error, got error: %v", err)
	}
	if result.Status != ContactExtractionStatusReviewNeeded {
		t.Fatalf("expected REVIEW_NEEDED, got %s", result.Status)
	}
	if result.ReasonCode != "CONTACT_FIELDS_LOW_CONFIDENCE" {
		t.Fatalf("expected CONTACT_FIELDS_LOW_CONFIDENCE, got %s", result.ReasonCode)
	}
}

func TestExtractReviewInvalidEmail(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates[2].RawValue = "not-an-email"
	req.OCRResult.FieldCandidates[2].NormalizedValue = "not-an-email"

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected contact extraction result, got error: %v", err)
	}

	foundInvalid := false
	for _, field := range result.Fields {
		if field.FieldKey == ContactFieldEmail && field.Decision == "CANDIDATE_REVIEW_INVALID_EMAIL" {
			foundInvalid = true
		}
	}
	if !foundInvalid {
		t.Fatal("expected invalid email review candidate")
	}
}

func TestExtractReviewInvalidPhone(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates[1].RawValue = "123"
	req.OCRResult.FieldCandidates[1].NormalizedValue = "123"

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected contact extraction result, got error: %v", err)
	}

	foundInvalid := false
	for _, field := range result.Fields {
		if field.FieldKey == ContactFieldPhone && field.Decision == "CANDIDATE_REVIEW_INVALID_PHONE" {
			foundInvalid = true
		}
	}
	if !foundInvalid {
		t.Fatal("expected invalid phone review candidate")
	}
}

func TestExtractRejectsTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.TenantID = "tenant-other"

	result, err := runtime.Extract(req)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if result.Status != ContactExtractionStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestExtractRejectsMissingOCRHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.ResultHash = ""

	result, err := runtime.Extract(req)
	if err == nil {
		t.Fatal("expected missing OCR hash error")
	}
	if !strings.Contains(result.ErrorMessage, "result_hash") {
		t.Fatalf("expected result_hash error, got %s", result.ErrorMessage)
	}
}

func TestExtractRejectsUnsupportedDocumentType(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.DocumentType = ocrprocessing.DocumentTypeReceipt

	result, err := runtime.Extract(req)
	if err == nil {
		t.Fatal("expected unsupported document type error")
	}
	if !strings.Contains(result.ErrorMessage, "document_type") {
		t.Fatalf("expected document_type error, got %s", result.ErrorMessage)
	}
}

func TestExtractRejectsBadOCRStatus(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.Status = ocrprocessing.OCRStatusRejected

	result, err := runtime.Extract(req)
	if err == nil {
		t.Fatal("expected bad OCR status error")
	}
	if !strings.Contains(result.ErrorMessage, "READY or REVIEW_NEEDED") {
		t.Fatalf("expected OCR status error, got %s", result.ErrorMessage)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewContactFieldExtractionRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingFieldKeysConfig(t *testing.T) {
	cfg := validConfig()
	cfg.SupportedFieldKeys = nil

	_, err := NewContactFieldExtractionRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing field keys config error")
	}
}
