package taxextraction

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
		RequireTaxNo:                true,
		RequireTaxOffice:            true,
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
		SupportedFieldKeys: []TaxFieldKey{
			TaxFieldCompanyName,
			TaxFieldTaxNo,
			TaxFieldTaxOffice,
			TaxFieldMersisNo,
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
		DocumentType:   ocrprocessing.DocumentTypeTaxCertificate,
		Status:         ocrprocessing.OCRStatusReady,
		Decision:       ocrprocessing.OCRDecisionProcessed,
		RawText:        "Firma Ünvanı: Pilot Market A.Ş.\nVergi No: 1234567890\nVergi Dairesi: Kadıköy\nMersis No: 1234567890123456",
		NormalizedText: "Firma Ünvanı: Pilot Market A.Ş.\nVergi No: 1234567890\nVergi Dairesi: Kadıköy\nMersis No: 1234567890123456",
		Blocks: []ocrprocessing.OCRBlock{
			{BlockID: "block-001", PageNo: 1, LineNo: 1, Text: "Firma Ünvanı: Pilot Market A.Ş.", NormalizedText: "Firma Ünvanı: Pilot Market A.Ş.", ConfidenceBps: 9300},
			{BlockID: "block-002", PageNo: 1, LineNo: 2, Text: "Vergi No: 1234567890", NormalizedText: "Vergi No: 1234567890", ConfidenceBps: 9300},
			{BlockID: "block-003", PageNo: 1, LineNo: 3, Text: "Vergi Dairesi: Kadıköy", NormalizedText: "Vergi Dairesi: Kadıköy", ConfidenceBps: 9300},
			{BlockID: "block-004", PageNo: 1, LineNo: 4, Text: "Mersis No: 1234567890123456", NormalizedText: "Mersis No: 1234567890123456", ConfidenceBps: 9300},
		},
		FieldCandidates: []ocrprocessing.OCRFieldCandidate{
			{FieldKey: "company_name", FieldLabel: "Firma Ünvanı", RawValue: "Pilot Market A.Ş.", NormalizedValue: "Pilot Market A.Ş.", ConfidenceBps: 9300, SourceBlockID: "block-001"},
			{FieldKey: "tax_no", FieldLabel: "Vergi No", RawValue: "1234567890", NormalizedValue: "1234567890", ConfidenceBps: 9300, SourceBlockID: "block-002"},
			{FieldKey: "tax_office", FieldLabel: "Vergi Dairesi", RawValue: "Kadıköy", NormalizedValue: "Kadıköy", ConfidenceBps: 9300, SourceBlockID: "block-003"},
			{FieldKey: "mersis_no", FieldLabel: "Mersis No", RawValue: "1234567890123456", NormalizedValue: "1234567890123456", ConfidenceBps: 9300, SourceBlockID: "block-004"},
		},
		ConfidenceBps:  9450,
		ReviewRequired: false,
		ReasonCode:     "OCR_PROCESSED",
		ResultHash:     "ocr-lens-processing:tenant-accountant-001:ocr-process-001",
		CreatedAt:      validNow(),
	}
}

func validRequest() TaxFieldExtractionRequest {
	return TaxFieldExtractionRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-tax-extraction-001",
		RequestID:      "req-tax-extraction-001",
		IdempotencyKey: "idem-tax-extraction-001",
		ExtractionID:   "tax-extraction-001",
		OCRResult:      validOCRResult(),
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *TaxFieldExtractionRuntime {
	t.Helper()

	runtime, err := NewTaxFieldExtractionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestExtractTaxFieldsReady(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Extract(validRequest())
	if err != nil {
		t.Fatalf("expected tax extraction ready, got error: %v", err)
	}
	if result.Status != TaxExtractionStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.Decision != TaxExtractionDecisionExtracted {
		t.Fatalf("expected EXTRACTED, got %s", result.Decision)
	}
	if result.TaxNo != "1234567890" {
		t.Fatalf("expected tax no 1234567890, got %s", result.TaxNo)
	}
	if result.TaxOffice != "Kadıköy" {
		t.Fatalf("expected tax office Kadıköy, got %s", result.TaxOffice)
	}
	if result.CompanyName != "Pilot Market A.Ş." {
		t.Fatalf("expected company name, got %s", result.CompanyName)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestExtractNormalizesTaxNo(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates[1].RawValue = "VKN: 123 456 7890"
	req.OCRResult.FieldCandidates[1].NormalizedValue = "VKN: 123 456 7890"

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected tax extraction ready, got error: %v", err)
	}
	if result.TaxNo != "1234567890" {
		t.Fatalf("expected normalized tax no 1234567890, got %s", result.TaxNo)
	}
}

func TestExtractMersisNo(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Extract(validRequest())
	if err != nil {
		t.Fatalf("expected tax extraction ready, got error: %v", err)
	}
	if result.MersisNo != "1234567890123456" {
		t.Fatalf("expected mersis no, got %s", result.MersisNo)
	}
}

func TestExtractReviewWhenTaxOfficeMissing(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates = req.OCRResult.FieldCandidates[:2]

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected review result without validation error, got error: %v", err)
	}
	if result.Status != TaxExtractionStatusReviewNeeded {
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
	if result.Status != TaxExtractionStatusReviewNeeded {
		t.Fatalf("expected REVIEW_NEEDED, got %s", result.Status)
	}
	if result.ReasonCode != "TAX_FIELDS_LOW_CONFIDENCE" {
		t.Fatalf("expected TAX_FIELDS_LOW_CONFIDENCE, got %s", result.ReasonCode)
	}
}

func TestExtractReviewInvalidTaxNo(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.OCRResult.FieldCandidates[1].RawValue = "123"
	req.OCRResult.FieldCandidates[1].NormalizedValue = "123"

	result, err := runtime.Extract(req)
	if err != nil {
		t.Fatalf("expected tax extraction result, got error: %v", err)
	}

	foundInvalid := false
	for _, field := range result.Fields {
		if field.FieldKey == TaxFieldTaxNo && field.Decision == "CANDIDATE_REVIEW_INVALID_TAX_NO" {
			foundInvalid = true
		}
	}
	if !foundInvalid {
		t.Fatal("expected invalid tax no review candidate")
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
	if result.Status != TaxExtractionStatusRejected {
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

	_, err := NewTaxFieldExtractionRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingFieldKeysConfig(t *testing.T) {
	cfg := validConfig()
	cfg.SupportedFieldKeys = nil

	_, err := NewTaxFieldExtractionRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing field keys config error")
	}
}
