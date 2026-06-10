package runtimetests

import (
	"strings"
	"testing"
	"time"

	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
	reviewqueue "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/reviewqueue"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:         true,
		RequireOCRFlow:         true,
		RequireTaxFlow:         true,
		RequireContactFlow:     true,
		RequireReviewQueueFlow: true,
		RequireAllHashes:       true,
		RequireReviewScenario:  true,
		MinHappyPathPassCount:  4,
		MinReviewPathPassCount: 7,
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validSource() ocrprocessing.OCRSource {
	return ocrprocessing.OCRSource{
		TenantID:   "tenant-accountant-001",
		DocumentID: "doc-ai-001",
		SourceType: ocrprocessing.SourceTypeImage,
		MimeType:   "image/jpeg",
		FileName:   "firma-karti.jpg",
		FileHash:   "sha256:document-ai-source-001",
		SourceText: strings.Join([]string{
			"Firma Ünvanı: Pilot Market A.Ş.",
			"Vergi No: 1234567890",
			"Vergi Dairesi: Kadıköy",
			"Mersis No: 1234567890123456",
			"Telefon: 0216 000 00 00",
			"Email: info@pilotmarket.test",
			"Adres: İstanbul Kadıköy",
		}, "\n"),
		Language:   "tr",
		PageCount:  1,
		ImageCount: 1,
		UploadedBy: "acc-user-001",
		UploadedAt: validNow(),
	}
}

func validRequest() DocumentAIRuntimeTestRequest {
	return DocumentAIRuntimeTestRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-document-ai-001",
		RequestID:      "req-document-ai-001",
		IdempotencyKey: "idem-document-ai-001",
		SuiteID:        "document-ai-suite-001",
		OCRProcessID:   "ocr-process-suite-001",
		DocumentID:     "doc-ai-001",
		Source:         validSource(),
		RequestedAt:    validNow(),
	}
}

func newSuite(t *testing.T) *DocumentAIRuntimeTestSuite {
	t.Helper()

	suite, err := NewDocumentAIRuntimeTestSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}
	return suite
}

func TestDocumentAIHappyPathPasses(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunHappyPath(validRequest())
	if err != nil {
		t.Fatalf("expected happy path pass, got error: %v", err)
	}
	if result.Status != SuiteStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if result.PassCount < 4 {
		t.Fatalf("expected pass count >= 4, got %d", result.PassCount)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.SuiteHash == "" {
		t.Fatal("expected suite hash")
	}
}

func TestDocumentAIHappyPathBuildsOCRResult(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunHappyPath(validRequest())
	if err != nil {
		t.Fatalf("expected happy path pass, got error: %v", err)
	}
	if result.OCRResult.Status != ocrprocessing.OCRStatusReady {
		t.Fatalf("expected OCR READY, got %s", result.OCRResult.Status)
	}
	if len(result.OCRResult.Blocks) < 7 {
		t.Fatalf("expected at least 7 OCR blocks, got %d", len(result.OCRResult.Blocks))
	}
	if result.OCRResult.ResultHash == "" {
		t.Fatal("expected OCR result hash")
	}
}

func TestDocumentAIHappyPathExtractsTaxFields(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunHappyPath(validRequest())
	if err != nil {
		t.Fatalf("expected happy path pass, got error: %v", err)
	}
	if result.TaxResult.TaxNo != "1234567890" {
		t.Fatalf("expected tax no 1234567890, got %s", result.TaxResult.TaxNo)
	}
	if result.TaxResult.TaxOffice != "Kadıköy" {
		t.Fatalf("expected tax office Kadıköy, got %s", result.TaxResult.TaxOffice)
	}
	if result.TaxResult.ResultHash == "" {
		t.Fatal("expected tax result hash")
	}
}

func TestDocumentAIHappyPathExtractsContactFields(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunHappyPath(validRequest())
	if err != nil {
		t.Fatalf("expected happy path pass, got error: %v", err)
	}
	if result.ContactResult.Phone != "02160000000" {
		t.Fatalf("expected phone 02160000000, got %s", result.ContactResult.Phone)
	}
	if result.ContactResult.Email != "info@pilotmarket.test" {
		t.Fatalf("expected email info@pilotmarket.test, got %s", result.ContactResult.Email)
	}
	if result.ContactResult.Address != "İstanbul Kadıköy" {
		t.Fatalf("expected address İstanbul Kadıköy, got %s", result.ContactResult.Address)
	}
	if result.ContactResult.ResultHash == "" {
		t.Fatal("expected contact result hash")
	}
}

func TestDocumentAIReviewRequiredPathPasses(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunReviewRequiredPath(validRequest())
	if err != nil {
		t.Fatalf("expected review path pass, got error: %v", err)
	}
	if result.Status != SuiteStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if result.PassCount < 7 {
		t.Fatalf("expected pass count >= 7, got %d", result.PassCount)
	}
	if len(result.ReviewItems) != 3 {
		t.Fatalf("expected 3 review decisions, got %d", len(result.ReviewItems))
	}
	if result.ReviewList.OpenCount != 3 {
		t.Fatalf("expected 3 open reviews, got %d", result.ReviewList.OpenCount)
	}
}

func TestDocumentAIReviewPathRegistersOCRReview(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunReviewRequiredPath(validRequest())
	if err != nil {
		t.Fatalf("expected review path pass, got error: %v", err)
	}

	found := false
	for _, decision := range result.ReviewItems {
		if decision.Item.SourceType == reviewqueue.ReviewSourceOCR {
			found = true
		}
	}
	if !found {
		t.Fatal("expected OCR review item")
	}
}

func TestDocumentAIReviewPathRegistersTaxReview(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunReviewRequiredPath(validRequest())
	if err != nil {
		t.Fatalf("expected review path pass, got error: %v", err)
	}

	found := false
	for _, decision := range result.ReviewItems {
		if decision.Item.SourceType == reviewqueue.ReviewSourceTax {
			found = true
			if len(decision.Item.MissingFields) == 0 {
				t.Fatal("expected tax review missing fields")
			}
		}
	}
	if !found {
		t.Fatal("expected tax review item")
	}
}

func TestDocumentAIReviewPathRegistersContactReview(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunReviewRequiredPath(validRequest())
	if err != nil {
		t.Fatalf("expected review path pass, got error: %v", err)
	}

	found := false
	for _, decision := range result.ReviewItems {
		if decision.Item.SourceType == reviewqueue.ReviewSourceContact {
			found = true
			if len(decision.Item.MissingFields) == 0 {
				t.Fatal("expected contact review missing fields")
			}
		}
	}
	if !found {
		t.Fatal("expected contact review item")
	}
}

func TestDocumentAIRejectsMissingTenant(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.TenantID = ""

	result, err := suite.RunHappyPath(req)
	if err == nil {
		t.Fatal("expected validation failure")
	}
	if result.Status != SuiteStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestDocumentAIRejectsMissingSourceText(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Source.SourceText = ""

	result, err := suite.RunHappyPath(req)
	if err == nil {
		t.Fatal("expected source_text validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestDocumentAIRejectsMissingFileHash(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Source.FileHash = ""

	result, err := suite.RunHappyPath(req)
	if err == nil {
		t.Fatal("expected file hash validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewDocumentAIRuntimeTestSuite(cfg)
	if err == nil {
		t.Fatal("expected disabled suite error")
	}
}

func TestRuntimeRejectsInvalidPassCountConfig(t *testing.T) {
	cfg := validConfig()
	cfg.MinHappyPathPassCount = 0

	_, err := NewDocumentAIRuntimeTestSuite(cfg)
	if err == nil {
		t.Fatal("expected invalid pass count config error")
	}
}
