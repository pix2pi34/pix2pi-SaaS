package ocrprocessing

import (
	"strings"
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:         true,
		DefaultLanguage:        "tr",
		RequireTenantScope:     true,
		RequireFileHash:        true,
		RequireSourceText:      true,
		RequireConfidence:      true,
		RequireAuditHash:       true,
		MinConfidenceBps:       5000,
		ReviewConfidenceBps:    8500,
		MaxTextLength:          50000,
		AllowedSourceTypes:     []SourceType{SourceTypeImage, SourceTypePDF, SourceTypeScan},
		AllowedMimeTypes:       []string{"image/jpeg", "image/png", "application/pdf"},
		SupportedDocumentTypes: []DocumentType{DocumentTypeUnknown, DocumentTypeTaxCertificate, DocumentTypeBusinessCard, DocumentTypeInvoice, DocumentTypeReceipt},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validSource() OCRSource {
	return OCRSource{
		TenantID:   "tenant-accountant-001",
		DocumentID: "doc-ocr-001",
		SourceType: SourceTypeImage,
		MimeType:   "image/jpeg",
		FileName:   "vergi-levhasi.jpg",
		FileHash:   "sha256:ocr-source-001",
		SourceText: "Firma Ünvanı: Pilot Market A.Ş.\nVergi No: 1234567890\nVergi Dairesi: Kadıköy\nTelefon: 02160000000\nEmail: info@pilotmarket.test\nAdres: İstanbul",
		Language:   "tr",
		PageCount:  1,
		ImageCount: 1,
		UploadedBy: "acc-user-001",
		UploadedAt: validNow(),
	}
}

func validRequest() ProcessRequest {
	return ProcessRequest{
		TenantID:             "tenant-accountant-001",
		CorrelationID:        "corr-ocr-001",
		RequestID:            "req-ocr-001",
		IdempotencyKey:       "idem-ocr-001",
		ProcessID:            "ocr-process-001",
		ExpectedDocumentType: DocumentTypeTaxCertificate,
		Source:               validSource(),
		RequestedAt:          validNow(),
	}
}

func newRuntime(t *testing.T) *OCRLensProcessingRuntime {
	t.Helper()

	runtime, err := NewOCRLensProcessingRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestProcessTaxCertificateReady(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Process(validRequest())
	if err != nil {
		t.Fatalf("expected OCR ready, got error: %v", err)
	}
	if result.Status != OCRStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.Decision != OCRDecisionProcessed {
		t.Fatalf("expected PROCESSED, got %s", result.Decision)
	}
	if result.DocumentType != DocumentTypeTaxCertificate {
		t.Fatalf("expected TAX_CERTIFICATE, got %s", result.DocumentType)
	}
	if result.ConfidenceBps < 8500 {
		t.Fatalf("expected confidence >= 8500, got %d", result.ConfidenceBps)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestProcessBuildsBlocks(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Process(validRequest())
	if err != nil {
		t.Fatalf("expected OCR ready, got error: %v", err)
	}
	if len(result.Blocks) < 5 {
		t.Fatalf("expected at least 5 blocks, got %d", len(result.Blocks))
	}
	if result.Blocks[0].BlockID == "" {
		t.Fatal("expected block id")
	}
}

func TestProcessExtractsFieldCandidates(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Process(validRequest())
	if err != nil {
		t.Fatalf("expected OCR ready, got error: %v", err)
	}

	keys := map[string]bool{}
	for _, candidate := range result.FieldCandidates {
		keys[candidate.FieldKey] = true
	}

	for _, key := range []string{"company_name", "tax_no", "tax_office", "phone", "email", "address"} {
		if !keys[key] {
			t.Fatalf("expected candidate key %s", key)
		}
	}
}

func TestProcessDetectsUnknownDocumentType(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.ExpectedDocumentType = DocumentTypeUnknown
	req.Source.SourceText = "Telefon: 02160000000\nEmail: info@pilotmarket.test"

	result, err := runtime.Process(req)
	if err != nil {
		t.Fatalf("expected OCR ready, got error: %v", err)
	}
	if result.DocumentType != DocumentTypeBusinessCard {
		t.Fatalf("expected BUSINESS_CARD, got %s", result.DocumentType)
	}
}

func TestProcessReviewNeededForLowText(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Source.SourceText = "Vergi No"

	result, err := runtime.Process(req)
	if err != nil {
		t.Fatalf("expected OCR review, got error: %v", err)
	}
	if result.Status != OCRStatusReviewNeeded {
		t.Fatalf("expected REVIEW_NEEDED, got %s", result.Status)
	}
	if !result.ReviewRequired {
		t.Fatal("expected review required")
	}
}

func TestProcessRejectsTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Source.TenantID = "tenant-other"

	result, err := runtime.Process(req)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if result.Status != OCRStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestProcessRejectsMissingFileHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Source.FileHash = ""

	result, err := runtime.Process(req)
	if err == nil {
		t.Fatal("expected file hash error")
	}
	if !strings.Contains(result.ErrorMessage, "file_hash") {
		t.Fatalf("expected file_hash error, got %s", result.ErrorMessage)
	}
}

func TestProcessRejectsUnsupportedMimeType(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Source.MimeType = "application/octet-stream"

	result, err := runtime.Process(req)
	if err == nil {
		t.Fatal("expected unsupported mime type")
	}
	if !strings.Contains(result.ErrorMessage, "mime_type is not allowed") {
		t.Fatalf("expected mime type error, got %s", result.ErrorMessage)
	}
}

func TestProcessRejectsEmptySourceText(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Source.SourceText = ""

	result, err := runtime.Process(req)
	if err == nil {
		t.Fatal("expected source text error")
	}
	if !strings.Contains(result.ErrorMessage, "source_text") {
		t.Fatalf("expected source_text error, got %s", result.ErrorMessage)
	}
}

func TestProcessRejectsTooLongSourceText(t *testing.T) {
	cfg := validConfig()
	cfg.MaxTextLength = 10

	runtime, err := NewOCRLensProcessingRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.Process(validRequest())
	if err == nil {
		t.Fatal("expected max text length error")
	}
	if !strings.Contains(result.ErrorMessage, "max_text_length") {
		t.Fatalf("expected max_text_length error, got %s", result.ErrorMessage)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewOCRLensProcessingRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsInvalidConfidenceConfig(t *testing.T) {
	cfg := validConfig()
	cfg.ReviewConfidenceBps = 4000

	_, err := NewOCRLensProcessingRuntime(cfg)
	if err == nil {
		t.Fatal("expected invalid confidence config error")
	}
}
