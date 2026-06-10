package runtimetests

import (
	"errors"
	"fmt"
	"strings"
	"time"

	contactextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/contactextraction"
	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
	reviewqueue "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/reviewqueue"
	taxextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/taxextraction"
)

type SuiteStatus string

const (
	SuiteStatusPass SuiteStatus = "PASS"
	SuiteStatusFail SuiteStatus = "FAIL"
)

type RuntimeConfig struct {
	RuntimeEnabled         bool `json:"runtime_enabled"`
	RequireOCRFlow         bool `json:"require_ocr_flow"`
	RequireTaxFlow         bool `json:"require_tax_flow"`
	RequireContactFlow     bool `json:"require_contact_flow"`
	RequireReviewQueueFlow bool `json:"require_review_queue_flow"`
	RequireAllHashes       bool `json:"require_all_hashes"`
	RequireReviewScenario  bool `json:"require_review_scenario"`
	MinHappyPathPassCount  int  `json:"min_happy_path_pass_count"`
	MinReviewPathPassCount int  `json:"min_review_path_pass_count"`
}

type DocumentAIRuntimeTestRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID string `json:"suite_id"`

	OCRProcessID string `json:"ocr_process_id"`
	DocumentID   string `json:"document_id"`

	Source ocrprocessing.OCRSource `json:"source"`

	RequestedAt time.Time `json:"requested_at"`
}

type DocumentAIRuntimeTestResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID string `json:"suite_id"`

	Status SuiteStatus `json:"status"`

	OCRResult     ocrprocessing.ProcessResult                    `json:"ocr_result"`
	TaxResult     taxextraction.TaxFieldExtractionResult         `json:"tax_result"`
	ContactResult contactextraction.ContactFieldExtractionResult `json:"contact_result"`
	ReviewItems   []reviewqueue.ReviewDecision                   `json:"review_items"`
	ReviewList    reviewqueue.ReviewListResult                   `json:"review_list"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	SuiteHash string `json:"suite_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type DocumentAIRuntimeTestSuite struct {
	config         RuntimeConfig
	ocrRuntime     *ocrprocessing.OCRLensProcessingRuntime
	taxRuntime     *taxextraction.TaxFieldExtractionRuntime
	contactRuntime *contactextraction.ContactFieldExtractionRuntime
	reviewRuntime  *reviewqueue.ConfidenceReviewQueueRuntime
}

func NewDocumentAIRuntimeTestSuite(config RuntimeConfig) (*DocumentAIRuntimeTestSuite, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("document AI runtime test suite is disabled")
	}
	if config.MinHappyPathPassCount <= 0 {
		return nil, errors.New("min_happy_path_pass_count must be positive")
	}
	if config.MinReviewPathPassCount <= 0 {
		return nil, errors.New("min_review_path_pass_count must be positive")
	}

	ocrRuntime, err := ocrprocessing.NewOCRLensProcessingRuntime(defaultOCRConfig())
	if err != nil {
		return nil, err
	}

	taxRuntime, err := taxextraction.NewTaxFieldExtractionRuntime(defaultTaxConfig())
	if err != nil {
		return nil, err
	}

	contactRuntime, err := contactextraction.NewContactFieldExtractionRuntime(defaultContactConfig())
	if err != nil {
		return nil, err
	}

	reviewRuntime, err := reviewqueue.NewConfidenceReviewQueueRuntime(defaultReviewQueueConfig())
	if err != nil {
		return nil, err
	}

	return &DocumentAIRuntimeTestSuite{
		config:         config,
		ocrRuntime:     ocrRuntime,
		taxRuntime:     taxRuntime,
		contactRuntime: contactRuntime,
		reviewRuntime:  reviewRuntime,
	}, nil
}

func (s *DocumentAIRuntimeTestSuite) RunHappyPath(req DocumentAIRuntimeTestRequest) (DocumentAIRuntimeTestResult, error) {
	if err := s.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	passCount := 0
	failCount := 0

	ocrResult, err := s.runOCR(req, req.Source, ocrprocessing.DocumentTypeTaxCertificate)
	if err != nil || ocrResult.Status != ocrprocessing.OCRStatusReady {
		failCount++
		return s.failed(req, ocrResult, taxextraction.TaxFieldExtractionResult{}, contactextraction.ContactFieldExtractionResult{}, nil, reviewqueue.ReviewListResult{}, passCount, failCount, "OCR_FLOW_FAILED", err), err
	}
	passCount++

	taxResult, err := s.runTaxExtraction(req, ocrResult)
	if err != nil || taxResult.Status != taxextraction.TaxExtractionStatusReady {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactextraction.ContactFieldExtractionResult{}, nil, reviewqueue.ReviewListResult{}, passCount, failCount, "TAX_FLOW_FAILED", err), err
	}
	passCount++

	contactResult, err := s.runContactExtraction(req, ocrResult)
	if err != nil || contactResult.Status != contactextraction.ContactExtractionStatusReady {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, nil, reviewqueue.ReviewListResult{}, passCount, failCount, "CONTACT_FLOW_FAILED", err), err
	}
	passCount++

	if s.config.RequireAllHashes {
		if strings.TrimSpace(ocrResult.ResultHash) == "" || strings.TrimSpace(taxResult.ResultHash) == "" || strings.TrimSpace(contactResult.ResultHash) == "" {
			failCount++
			err := errors.New("required runtime hash is missing")
			return s.failed(req, ocrResult, taxResult, contactResult, nil, reviewqueue.ReviewListResult{}, passCount, failCount, "HASH_FLOW_FAILED", err), err
		}
		passCount++
	}

	result := DocumentAIRuntimeTestResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SuiteID:             req.SuiteID,
		Status:              SuiteStatusPass,
		OCRResult:           ocrResult,
		TaxResult:           taxResult,
		ContactResult:       contactResult,
		PassCount:           passCount,
		FailCount:           failCount,
		SuiteHash:           buildSuiteHash(req, ocrResult, taxResult, contactResult, nil, reviewqueue.ReviewListResult{}),
		AuditAction:         "DOCUMENT_AI_HAPPY_PATH_TESTS_PASS",
		AuditDecisionReason: "OCR, tax extraction and contact extraction happy path passed",
		CreatedAt:           time.Now().UTC(),
	}

	if result.PassCount < s.config.MinHappyPathPassCount {
		err := errors.New("happy path pass count is below minimum")
		return s.failed(req, ocrResult, taxResult, contactResult, nil, reviewqueue.ReviewListResult{}, passCount, failCount+1, "PASS_COUNT_BELOW_MINIMUM", err), err
	}

	return result, nil
}

func (s *DocumentAIRuntimeTestSuite) RunReviewRequiredPath(req DocumentAIRuntimeTestRequest) (DocumentAIRuntimeTestResult, error) {
	if err := s.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	reviewSource := req.Source
	reviewSource.SourceText = "Vergi No: 123\nTelefon: 123"
	reviewSource.FileName = "dusuk-guven-belge.jpg"
	reviewSource.FileHash = req.Source.FileHash + ":review"
	reviewSource.DocumentID = req.DocumentID + "-review"

	passCount := 0
	failCount := 0
	reviewDecisions := make([]reviewqueue.ReviewDecision, 0)

	ocrResult, err := s.runOCR(req, reviewSource, ocrprocessing.DocumentTypeTaxCertificate)
	if err != nil {
		failCount++
		return s.failed(req, ocrResult, taxextraction.TaxFieldExtractionResult{}, contactextraction.ContactFieldExtractionResult{}, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "OCR_REVIEW_FLOW_FAILED", err), err
	}
	if ocrResult.Status != ocrprocessing.OCRStatusReviewNeeded {
		failCount++
		err = errors.New("OCR review status was expected")
		return s.failed(req, ocrResult, taxextraction.TaxFieldExtractionResult{}, contactextraction.ContactFieldExtractionResult{}, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "OCR_REVIEW_STATUS_MISSING", err), err
	}
	passCount++

	taxResult, err := s.runTaxExtraction(req, ocrResult)
	if err != nil {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactextraction.ContactFieldExtractionResult{}, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "TAX_REVIEW_FLOW_FAILED", err), err
	}
	if taxResult.Status != taxextraction.TaxExtractionStatusReviewNeeded {
		failCount++
		err = errors.New("tax extraction review status was expected")
		return s.failed(req, ocrResult, taxResult, contactextraction.ContactFieldExtractionResult{}, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "TAX_REVIEW_STATUS_MISSING", err), err
	}
	passCount++

	contactResult, err := s.runContactExtraction(req, ocrResult)
	if err != nil {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "CONTACT_REVIEW_FLOW_FAILED", err), err
	}
	if contactResult.Status != contactextraction.ContactExtractionStatusReviewNeeded {
		failCount++
		err = errors.New("contact extraction review status was expected")
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "CONTACT_REVIEW_STATUS_MISSING", err), err
	}
	passCount++

	ocrReview, err := s.reviewRuntime.RegisterOCRReview(reviewqueue.OCRReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":ocr-review",
		ReviewID:       req.SuiteID + ":ocr-review",
		OCRResult:      ocrResult,
		RequestedAt:    req.RequestedAt,
	})
	if err != nil || !ocrReview.Allowed {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "OCR_REVIEW_REGISTER_FAILED", err), err
	}
	reviewDecisions = append(reviewDecisions, ocrReview)
	passCount++

	taxReview, err := s.reviewRuntime.RegisterTaxReview(reviewqueue.TaxReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":tax-review",
		ReviewID:       req.SuiteID + ":tax-review",
		TaxResult:      taxResult,
		RequestedAt:    req.RequestedAt,
	})
	if err != nil || !taxReview.Allowed {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "TAX_REVIEW_REGISTER_FAILED", err), err
	}
	reviewDecisions = append(reviewDecisions, taxReview)
	passCount++

	contactReview, err := s.reviewRuntime.RegisterContactReview(reviewqueue.ContactReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":contact-review",
		ReviewID:       req.SuiteID + ":contact-review",
		ContactResult:  contactResult,
		RequestedAt:    req.RequestedAt,
	})
	if err != nil || !contactReview.Allowed {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewqueue.ReviewListResult{}, passCount, failCount, "CONTACT_REVIEW_REGISTER_FAILED", err), err
	}
	reviewDecisions = append(reviewDecisions, contactReview)
	passCount++

	reviewList, err := s.reviewRuntime.ListOpen(reviewqueue.ReviewListRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":review-list",
		RequestedAt:    req.RequestedAt,
	})
	if err != nil {
		failCount++
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewList, passCount, failCount, "REVIEW_LIST_FAILED", err), err
	}
	if reviewList.OpenCount != 3 {
		failCount++
		err = errors.New("expected 3 open review items")
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewList, passCount, failCount, "REVIEW_OPEN_COUNT_MISMATCH", err), err
	}
	passCount++

	result := DocumentAIRuntimeTestResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SuiteID:             req.SuiteID,
		Status:              SuiteStatusPass,
		OCRResult:           ocrResult,
		TaxResult:           taxResult,
		ContactResult:       contactResult,
		ReviewItems:         reviewDecisions,
		ReviewList:          reviewList,
		PassCount:           passCount,
		FailCount:           failCount,
		SuiteHash:           buildSuiteHash(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewList),
		AuditAction:         "DOCUMENT_AI_REVIEW_PATH_TESTS_PASS",
		AuditDecisionReason: "OCR, tax extraction, contact extraction and review queue path passed",
		CreatedAt:           time.Now().UTC(),
	}

	if result.PassCount < s.config.MinReviewPathPassCount {
		err = errors.New("review path pass count is below minimum")
		return s.failed(req, ocrResult, taxResult, contactResult, reviewDecisions, reviewList, passCount, failCount+1, "PASS_COUNT_BELOW_MINIMUM", err), err
	}

	return result, nil
}

func (s *DocumentAIRuntimeTestSuite) runOCR(req DocumentAIRuntimeTestRequest, source ocrprocessing.OCRSource, expectedType ocrprocessing.DocumentType) (ocrprocessing.ProcessResult, error) {
	source.TenantID = req.TenantID
	if strings.TrimSpace(source.DocumentID) == "" {
		source.DocumentID = req.DocumentID
	}

	return s.ocrRuntime.Process(ocrprocessing.ProcessRequest{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey + ":ocr:" + source.DocumentID,
		ProcessID:            req.OCRProcessID + ":" + source.DocumentID,
		ExpectedDocumentType: expectedType,
		Source:               source,
		RequestedAt:          req.RequestedAt,
	})
}

func (s *DocumentAIRuntimeTestSuite) runTaxExtraction(req DocumentAIRuntimeTestRequest, ocrResult ocrprocessing.ProcessResult) (taxextraction.TaxFieldExtractionResult, error) {
	return s.taxRuntime.Extract(taxextraction.TaxFieldExtractionRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":tax:" + ocrResult.DocumentID,
		ExtractionID:   req.SuiteID + ":tax:" + ocrResult.DocumentID,
		OCRResult:      ocrResult,
		RequestedAt:    req.RequestedAt,
	})
}

func (s *DocumentAIRuntimeTestSuite) runContactExtraction(req DocumentAIRuntimeTestRequest, ocrResult ocrprocessing.ProcessResult) (contactextraction.ContactFieldExtractionResult, error) {
	return s.contactRuntime.Extract(contactextraction.ContactFieldExtractionRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":contact:" + ocrResult.DocumentID,
		ExtractionID:   req.SuiteID + ":contact:" + ocrResult.DocumentID,
		OCRResult:      ocrResult,
		RequestedAt:    req.RequestedAt,
	})
}

func (s *DocumentAIRuntimeTestSuite) validateRequest(req DocumentAIRuntimeTestRequest) error {
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
	if strings.TrimSpace(req.SuiteID) == "" {
		return errors.New("suite_id is required")
	}
	if strings.TrimSpace(req.OCRProcessID) == "" {
		return errors.New("ocr_process_id is required")
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.Source.FileHash) == "" {
		return errors.New("source file_hash is required")
	}
	if strings.TrimSpace(req.Source.SourceText) == "" {
		return errors.New("source_text is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (s *DocumentAIRuntimeTestSuite) failed(req DocumentAIRuntimeTestRequest, ocrResult ocrprocessing.ProcessResult, taxResult taxextraction.TaxFieldExtractionResult, contactResult contactextraction.ContactFieldExtractionResult, reviews []reviewqueue.ReviewDecision, reviewList reviewqueue.ReviewListResult, passCount int, failCount int, code string, err error) DocumentAIRuntimeTestResult {
	message := "document AI runtime test failed"
	if err != nil {
		message = err.Error()
	}

	return DocumentAIRuntimeTestResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SuiteID:             req.SuiteID,
		Status:              SuiteStatusFail,
		OCRResult:           ocrResult,
		TaxResult:           taxResult,
		ContactResult:       contactResult,
		ReviewItems:         reviews,
		ReviewList:          reviewList,
		PassCount:           passCount,
		FailCount:           failCount,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "DOCUMENT_AI_RUNTIME_TESTS_FAIL",
		AuditDecisionReason: message,
		CreatedAt:           time.Now().UTC(),
	}
}

func rejected(req DocumentAIRuntimeTestRequest, code string, message string) DocumentAIRuntimeTestResult {
	return DocumentAIRuntimeTestResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SuiteID:             req.SuiteID,
		Status:              SuiteStatusFail,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "DOCUMENT_AI_RUNTIME_TESTS_REJECTED",
		AuditDecisionReason: "document AI runtime test rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}

func buildSuiteHash(req DocumentAIRuntimeTestRequest, ocrResult ocrprocessing.ProcessResult, taxResult taxextraction.TaxFieldExtractionResult, contactResult contactextraction.ContactFieldExtractionResult, reviews []reviewqueue.ReviewDecision, reviewList reviewqueue.ReviewListResult) string {
	parts := []string{
		req.TenantID,
		req.SuiteID,
		ocrResult.ResultHash,
		taxResult.ResultHash,
		contactResult.ResultHash,
		fmt.Sprintf("reviews:%d", len(reviews)),
		reviewList.ResultHash,
	}

	for _, decision := range reviews {
		parts = append(parts, decision.DecisionHash)
	}

	return "document-ai-runtime-tests:" + strings.Join(parts, ":")
}

func defaultOCRConfig() ocrprocessing.RuntimeConfig {
	return ocrprocessing.RuntimeConfig{
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
		AllowedSourceTypes:     []ocrprocessing.SourceType{ocrprocessing.SourceTypeImage, ocrprocessing.SourceTypePDF, ocrprocessing.SourceTypeScan},
		AllowedMimeTypes:       []string{"image/jpeg", "image/png", "application/pdf"},
		SupportedDocumentTypes: []ocrprocessing.DocumentType{ocrprocessing.DocumentTypeUnknown, ocrprocessing.DocumentTypeTaxCertificate, ocrprocessing.DocumentTypeBusinessCard, ocrprocessing.DocumentTypeInvoice, ocrprocessing.DocumentTypeReceipt},
	}
}

func defaultTaxConfig() taxextraction.RuntimeConfig {
	return taxextraction.RuntimeConfig{
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
		SupportedFieldKeys: []taxextraction.TaxFieldKey{
			taxextraction.TaxFieldCompanyName,
			taxextraction.TaxFieldTaxNo,
			taxextraction.TaxFieldTaxOffice,
			taxextraction.TaxFieldMersisNo,
		},
	}
}

func defaultContactConfig() contactextraction.RuntimeConfig {
	return contactextraction.RuntimeConfig{
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
		SupportedFieldKeys: []contactextraction.ContactFieldKey{
			contactextraction.ContactFieldCompanyName,
			contactextraction.ContactFieldPhone,
			contactextraction.ContactFieldEmail,
			contactextraction.ContactFieldAddress,
		},
	}
}

func defaultReviewQueueConfig() reviewqueue.RuntimeConfig {
	return reviewqueue.RuntimeConfig{
		RuntimeEnabled:            true,
		RequireTenantScope:        true,
		RequireSourceHash:         true,
		RequireReviewReason:       true,
		RequireActorForAction:     true,
		RequireAssigneeForAssign:  true,
		RequireResolutionNote:     true,
		RequireDecisionHash:       true,
		MinConfidenceBps:          5000,
		MediumPriorityBelowBps:    8500,
		HighPriorityBelowBps:      7500,
		CriticalPriorityBelowBps:  6000,
		CriticalMissingFieldCount: 2,
		MaxOpenItemsPerTenant:     1000,
		AllowedSourceTypes:        []reviewqueue.ReviewSourceType{reviewqueue.ReviewSourceOCR, reviewqueue.ReviewSourceTax, reviewqueue.ReviewSourceContact},
		AllowedStatuses: []reviewqueue.ReviewStatus{
			reviewqueue.ReviewStatusOpen,
			reviewqueue.ReviewStatusAssigned,
			reviewqueue.ReviewStatusResolvedApproved,
			reviewqueue.ReviewStatusResolvedRejected,
			reviewqueue.ReviewStatusDismissed,
		},
		AllowedActions: []reviewqueue.ReviewAction{
			reviewqueue.ReviewActionRegister,
			reviewqueue.ReviewActionAssign,
			reviewqueue.ReviewActionResolveApprove,
			reviewqueue.ReviewActionResolveReject,
			reviewqueue.ReviewActionDismiss,
			reviewqueue.ReviewActionListOpen,
		},
	}
}
