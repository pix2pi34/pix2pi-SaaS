package reviewqueue

import (
	"testing"
	"time"

	contactextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/contactextraction"
	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
	taxextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/taxextraction"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
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
		MaxOpenItemsPerTenant:     10,
		AllowedSourceTypes:        []ReviewSourceType{ReviewSourceOCR, ReviewSourceTax, ReviewSourceContact},
		AllowedStatuses:           []ReviewStatus{ReviewStatusOpen, ReviewStatusAssigned, ReviewStatusResolvedApproved, ReviewStatusResolvedRejected, ReviewStatusDismissed},
		AllowedActions:            []ReviewAction{ReviewActionRegister, ReviewActionAssign, ReviewActionResolveApprove, ReviewActionResolveReject, ReviewActionDismiss, ReviewActionListOpen},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func newRuntime(t *testing.T) *ConfidenceReviewQueueRuntime {
	t.Helper()

	runtime, err := NewConfidenceReviewQueueRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func validRegisterRequest(reviewID string) ReviewRegisterRequest {
	return ReviewRegisterRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-review-001",
		RequestID:      "req-review-001",
		IdempotencyKey: "idem-review-" + reviewID,
		ReviewID:       reviewID,
		SourceType:     ReviewSourceOCR,
		SourceID:       "ocr-process-001",
		DocumentID:     "doc-ocr-001",
		SourceHash:     "ocr-result-hash-001",
		ConfidenceBps:  8200,
		MissingFields:  []string{"tax_office"},
		ReasonCode:     "OCR_REVIEW_REQUIRED",
		Reason:         "OCR confidence requires manual review",
		RequestedAt:    validNow(),
	}
}

func validActionRequest(reviewID string, action ReviewAction) ReviewActionRequest {
	return ReviewActionRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-action-001",
		RequestID:      "req-action-001",
		IdempotencyKey: "idem-action-" + reviewID + "-" + string(action),
		ReviewID:       reviewID,
		Action:         action,
		ActorID:        "operator-001",
		AssigneeID:     "reviewer-001",
		ResolutionNote: "verified manually",
		RequestedAt:    validNow().Add(time.Hour),
	}
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
		Status:         ocrprocessing.OCRStatusReviewNeeded,
		Decision:       ocrprocessing.OCRDecisionReview,
		NormalizedText: "Vergi No",
		ConfidenceBps:  7600,
		ReviewRequired: true,
		ReasonCode:     "OCR_REVIEW_REQUIRED",
		Reason:         "OCR confidence requires manual review",
		ResultHash:     "ocr-lens-processing:hash",
	}
}

func validTaxResult() taxextraction.TaxFieldExtractionResult {
	return taxextraction.TaxFieldExtractionResult{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-tax-001",
		RequestID:      "req-tax-001",
		IdempotencyKey: "idem-tax-001",
		ExtractionID:   "tax-extraction-001",
		ProcessID:      "ocr-process-001",
		DocumentID:     "doc-ocr-001",
		DocumentType:   ocrprocessing.DocumentTypeTaxCertificate,
		Status:         taxextraction.TaxExtractionStatusReviewNeeded,
		Decision:       taxextraction.TaxExtractionDecisionReview,
		MissingRequiredFields: []taxextraction.TaxFieldKey{
			taxextraction.TaxFieldTaxOffice,
			taxextraction.TaxFieldCompanyName,
		},
		ConfidenceBps:  7200,
		ReviewRequired: true,
		ReasonCode:     "TAX_FIELDS_REVIEW_REQUIRED",
		Reason:         "required tax fields are missing",
		ResultHash:     "tax-field-extraction:hash",
	}
}

func validContactResult() contactextraction.ContactFieldExtractionResult {
	return contactextraction.ContactFieldExtractionResult{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-contact-001",
		RequestID:      "req-contact-001",
		IdempotencyKey: "idem-contact-001",
		ExtractionID:   "contact-extraction-001",
		ProcessID:      "ocr-process-001",
		DocumentID:     "doc-ocr-001",
		DocumentType:   ocrprocessing.DocumentTypeBusinessCard,
		Status:         contactextraction.ContactExtractionStatusReviewNeeded,
		Decision:       contactextraction.ContactExtractionDecisionReview,
		MissingRequiredFields: []contactextraction.ContactFieldKey{
			contactextraction.ContactFieldAddress,
		},
		ConfidenceBps:  8100,
		ReviewRequired: true,
		ReasonCode:     "CONTACT_FIELDS_REVIEW_REQUIRED",
		Reason:         "required contact fields are missing",
		ResultHash:     "contact-field-extraction:hash",
	}
}

func TestRegisterReviewItem(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.Register(validRegisterRequest("review-001"))
	if err != nil {
		t.Fatalf("expected register success, got error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected allowed")
	}
	if decision.Item.Status != ReviewStatusOpen {
		t.Fatalf("expected OPEN, got %s", decision.Item.Status)
	}
	if decision.Item.Priority != ReviewPriorityMedium {
		t.Fatalf("expected MEDIUM priority, got %s", decision.Item.Priority)
	}
	if decision.DecisionHash == "" {
		t.Fatal("expected decision hash")
	}
}

func TestRegisterOCRReview(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.RegisterOCRReview(OCRReviewRegisterRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-ocr-review-001",
		RequestID:      "req-ocr-review-001",
		IdempotencyKey: "idem-ocr-review-001",
		ReviewID:       "review-ocr-001",
		OCRResult:      validOCRResult(),
		RequestedAt:    validNow(),
	})
	if err != nil {
		t.Fatalf("expected OCR review register success, got error: %v", err)
	}
	if decision.Item.SourceType != ReviewSourceOCR {
		t.Fatalf("expected OCR source, got %s", decision.Item.SourceType)
	}
}

func TestRegisterTaxReviewCriticalPriority(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.RegisterTaxReview(TaxReviewRegisterRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-tax-review-001",
		RequestID:      "req-tax-review-001",
		IdempotencyKey: "idem-tax-review-001",
		ReviewID:       "review-tax-001",
		TaxResult:      validTaxResult(),
		RequestedAt:    validNow(),
	})
	if err != nil {
		t.Fatalf("expected tax review register success, got error: %v", err)
	}
	if decision.Item.Priority != ReviewPriorityCritical {
		t.Fatalf("expected CRITICAL priority, got %s", decision.Item.Priority)
	}
	if len(decision.Item.MissingFields) != 2 {
		t.Fatalf("expected 2 missing fields, got %d", len(decision.Item.MissingFields))
	}
}

func TestRegisterContactReview(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.RegisterContactReview(ContactReviewRegisterRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-contact-review-001",
		RequestID:      "req-contact-review-001",
		IdempotencyKey: "idem-contact-review-001",
		ReviewID:       "review-contact-001",
		ContactResult:  validContactResult(),
		RequestedAt:    validNow(),
	})
	if err != nil {
		t.Fatalf("expected contact review register success, got error: %v", err)
	}
	if decision.Item.SourceType != ReviewSourceContact {
		t.Fatalf("expected CONTACT source, got %s", decision.Item.SourceType)
	}
}

func TestAssignReviewItem(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-assign-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	decision, err := runtime.Assign(validActionRequest("review-assign-001", ReviewActionAssign))
	if err != nil {
		t.Fatalf("expected assign success, got error: %v", err)
	}
	if decision.Item.Status != ReviewStatusAssigned {
		t.Fatalf("expected ASSIGNED, got %s", decision.Item.Status)
	}
	if decision.Item.AssignedTo != "reviewer-001" {
		t.Fatalf("expected reviewer-001, got %s", decision.Item.AssignedTo)
	}
}

func TestResolveApproveReviewItem(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-approve-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	decision, err := runtime.ResolveApprove(validActionRequest("review-approve-001", ReviewActionResolveApprove))
	if err != nil {
		t.Fatalf("expected approve success, got error: %v", err)
	}
	if decision.Item.Status != ReviewStatusResolvedApproved {
		t.Fatalf("expected RESOLVED_APPROVED, got %s", decision.Item.Status)
	}
}

func TestResolveRejectReviewItem(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-reject-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	decision, err := runtime.ResolveReject(validActionRequest("review-reject-001", ReviewActionResolveReject))
	if err != nil {
		t.Fatalf("expected reject success, got error: %v", err)
	}
	if decision.Item.Status != ReviewStatusResolvedRejected {
		t.Fatalf("expected RESOLVED_REJECTED, got %s", decision.Item.Status)
	}
}

func TestDismissReviewItem(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-dismiss-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	decision, err := runtime.Dismiss(validActionRequest("review-dismiss-001", ReviewActionDismiss))
	if err != nil {
		t.Fatalf("expected dismiss success, got error: %v", err)
	}
	if decision.Item.Status != ReviewStatusDismissed {
		t.Fatalf("expected DISMISSED, got %s", decision.Item.Status)
	}
}

func TestListOpenTenantScoped(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-list-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	other := validRegisterRequest("review-list-002")
	other.TenantID = "tenant-other"
	if _, err := runtime.Register(other); err != nil {
		t.Fatalf("other tenant register failed: %v", err)
	}

	result, err := runtime.ListOpen(ReviewListRequest{
		TenantID:       "tenant-accountant-001",
		CorrelationID:  "corr-list-001",
		RequestID:      "req-list-001",
		IdempotencyKey: "idem-list-001",
		RequestedAt:    validNow(),
	})
	if err != nil {
		t.Fatalf("expected list success, got error: %v", err)
	}
	if result.OpenCount != 1 {
		t.Fatalf("expected open count 1, got %d", result.OpenCount)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestRejectsDuplicateReview(t *testing.T) {
	runtime := newRuntime(t)
	req := validRegisterRequest("review-duplicate-001")
	if _, err := runtime.Register(req); err != nil {
		t.Fatalf("register failed: %v", err)
	}

	decision, err := runtime.Register(req)
	if err == nil {
		t.Fatal("expected duplicate error")
	}
	if decision.ReasonCode != "DUPLICATE_REVIEW" {
		t.Fatalf("expected DUPLICATE_REVIEW, got %s", decision.ReasonCode)
	}
}

func TestRejectsMissingSourceHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRegisterRequest("review-missing-hash-001")
	req.SourceHash = ""

	decision, err := runtime.Register(req)
	if err == nil {
		t.Fatal("expected source hash error")
	}
	if decision.ReasonCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", decision.ReasonCode)
	}
}

func TestRejectsMissingAssignee(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-no-assignee-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}
	req := validActionRequest("review-no-assignee-001", ReviewActionAssign)
	req.AssigneeID = ""

	decision, err := runtime.Assign(req)
	if err == nil {
		t.Fatal("expected assignee error")
	}
	if decision.ReasonCode != "ASSIGNEE_REQUIRED" {
		t.Fatalf("expected ASSIGNEE_REQUIRED, got %s", decision.ReasonCode)
	}
}

func TestRejectsMissingResolutionNote(t *testing.T) {
	runtime := newRuntime(t)
	if _, err := runtime.Register(validRegisterRequest("review-no-note-001")); err != nil {
		t.Fatalf("register failed: %v", err)
	}
	req := validActionRequest("review-no-note-001", ReviewActionResolveApprove)
	req.ResolutionNote = ""

	decision, err := runtime.ResolveApprove(req)
	if err == nil {
		t.Fatal("expected resolution note error")
	}
	if decision.ReasonCode != "RESOLUTION_NOTE_REQUIRED" {
		t.Fatalf("expected RESOLUTION_NOTE_REQUIRED, got %s", decision.ReasonCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewConfidenceReviewQueueRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingSourceTypesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AllowedSourceTypes = nil

	_, err := NewConfidenceReviewQueueRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing source types config error")
	}
}
