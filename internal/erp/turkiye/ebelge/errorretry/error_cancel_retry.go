package errorretry

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type DocumentType string

const (
	DocumentTypeEFatura  DocumentType = "E_FATURA"
	DocumentTypeEArsiv   DocumentType = "E_ARSIV"
	DocumentTypeEAdisyon DocumentType = "E_ADISYON"
)

type ProviderOperation string

const (
	OperationSend        ProviderOperation = "SEND"
	OperationStatusCheck ProviderOperation = "STATUS_CHECK"
	OperationCancel      ProviderOperation = "CANCEL"
	OperationDownloadPDF ProviderOperation = "DOWNLOAD_PDF"
	OperationDownloadUBL ProviderOperation = "DOWNLOAD_UBL"
)

type ErrorClass string

const (
	ErrorClassRetryable    ErrorClass = "RETRYABLE"
	ErrorClassNonRetryable ErrorClass = "NON_RETRYABLE"
	ErrorClassDuplicate    ErrorClass = "DUPLICATE"
	ErrorClassManualReview ErrorClass = "MANUAL_REVIEW"
)

type RetryDecisionStatus string

const (
	DecisionRetryScheduled RetryDecisionStatus = "RETRY_SCHEDULED"
	DecisionDLQ            RetryDecisionStatus = "DLQ"
	DecisionNoRetry        RetryDecisionStatus = "NO_RETRY"
	DecisionDuplicate      RetryDecisionStatus = "DUPLICATE_IGNORED"
	DecisionManualReview   RetryDecisionStatus = "MANUAL_REVIEW"
)

type CancelDecisionStatus string

const (
	CancelDecisionAccepted CancelDecisionStatus = "CANCEL_ACCEPTED"
	CancelDecisionRejected CancelDecisionStatus = "CANCEL_REJECTED"
	CancelDecisionQueued   CancelDecisionStatus = "CANCEL_QUEUED"
)

type RuntimeConfig struct {
	MaxRetryCount        int            `json:"max_retry_count"`
	BaseRetryDelaySec    int            `json:"base_retry_delay_sec"`
	MaxRetryDelaySec     int            `json:"max_retry_delay_sec"`
	DLQEnabled           bool           `json:"dlq_enabled"`
	ManualReviewEnabled  bool           `json:"manual_review_enabled"`
	CancelReasonRequired bool           `json:"cancel_reason_required"`
	AllowedDocumentTypes []DocumentType `json:"allowed_document_types"`
	AllowedProviderCodes []string       `json:"allowed_provider_codes"`
	RetryableErrorCodes  []string       `json:"retryable_error_codes"`
	FatalErrorCodes      []string       `json:"fatal_error_codes"`
	ManualReviewCodes    []string       `json:"manual_review_codes"`
}

type ErrorEvent struct {
	TenantID            string            `json:"tenant_id"`
	CorrelationID       string            `json:"correlation_id"`
	RequestID           string            `json:"request_id"`
	IdempotencyKey      string            `json:"idempotency_key"`
	DocumentID          string            `json:"document_id"`
	DocumentNo          string            `json:"document_no"`
	DocumentType        DocumentType      `json:"document_type"`
	ProviderCode        string            `json:"provider_code"`
	ProviderDocumentID  string            `json:"provider_document_id"`
	Operation           ProviderOperation `json:"operation"`
	ProviderErrorCode   string            `json:"provider_error_code"`
	ProviderErrorText   string            `json:"provider_error_text"`
	ProviderPayloadHash string            `json:"provider_payload_hash"`
	RetryCount          int               `json:"retry_count"`
	OccurredAt          time.Time         `json:"occurred_at"`
	ReceivedAt          time.Time         `json:"received_at"`
}

type RetryDecision struct {
	TenantID             string              `json:"tenant_id"`
	CorrelationID        string              `json:"correlation_id"`
	RequestID            string              `json:"request_id"`
	DocumentID           string              `json:"document_id"`
	DocumentNo           string              `json:"document_no"`
	DocumentType         DocumentType        `json:"document_type"`
	ProviderCode         string              `json:"provider_code"`
	Operation            ProviderOperation   `json:"operation"`
	ErrorClass           ErrorClass          `json:"error_class"`
	DecisionStatus       RetryDecisionStatus `json:"decision_status"`
	RetryCount           int                 `json:"retry_count"`
	NextRetryCount       int                 `json:"next_retry_count"`
	RetryAfter           time.Time           `json:"retry_after"`
	DLQRequired          bool                `json:"dlq_required"`
	ManualReviewRequired bool                `json:"manual_review_required"`
	AuditAction          string              `json:"audit_action"`
	AuditDecisionReason  string              `json:"audit_decision_reason"`
	ErrorCode            string              `json:"error_code"`
	ErrorMessage         string              `json:"error_message"`
	DecidedAt            time.Time           `json:"decided_at"`
}

type CancelRequest struct {
	TenantID           string       `json:"tenant_id"`
	CorrelationID      string       `json:"correlation_id"`
	RequestID          string       `json:"request_id"`
	IdempotencyKey     string       `json:"idempotency_key"`
	DocumentID         string       `json:"document_id"`
	DocumentNo         string       `json:"document_no"`
	DocumentType       DocumentType `json:"document_type"`
	ProviderCode       string       `json:"provider_code"`
	ProviderDocumentID string       `json:"provider_document_id"`
	CancelReasonCode   string       `json:"cancel_reason_code"`
	CancelReasonText   string       `json:"cancel_reason_text"`
	RequestedBy        string       `json:"requested_by"`
	RequestedAt        time.Time    `json:"requested_at"`
}

type CancelDecision struct {
	TenantID            string               `json:"tenant_id"`
	CorrelationID       string               `json:"correlation_id"`
	RequestID           string               `json:"request_id"`
	DocumentID          string               `json:"document_id"`
	DocumentNo          string               `json:"document_no"`
	DocumentType        DocumentType         `json:"document_type"`
	ProviderCode        string               `json:"provider_code"`
	DecisionStatus      CancelDecisionStatus `json:"decision_status"`
	ProviderCancelID    string               `json:"provider_cancel_id"`
	AuditAction         string               `json:"audit_action"`
	AuditDecisionReason string               `json:"audit_decision_reason"`
	ErrorCode           string               `json:"error_code"`
	ErrorMessage        string               `json:"error_message"`
	DecidedAt           time.Time            `json:"decided_at"`
}

type ErrorCancelRetryRuntime struct {
	config RuntimeConfig
}

func NewErrorCancelRetryRuntime(config RuntimeConfig) (*ErrorCancelRetryRuntime, error) {
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max retry count cannot be negative")
	}
	if config.BaseRetryDelaySec <= 0 {
		return nil, errors.New("base retry delay seconds must be positive")
	}
	if config.MaxRetryDelaySec < config.BaseRetryDelaySec {
		return nil, errors.New("max retry delay seconds must be greater than or equal to base retry delay seconds")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed document types are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed provider codes are required")
	}

	return &ErrorCancelRetryRuntime{config: config}, nil
}

func (r *ErrorCancelRetryRuntime) HandleProviderError(event ErrorEvent) (RetryDecision, error) {
	if err := r.validateErrorEvent(event); err != nil {
		return rejectedRetryDecision(event, "VALIDATION_FAILED", err.Error()), err
	}

	class := r.classifyError(event.ProviderErrorCode)
	now := time.Now().UTC()

	switch class {
	case ErrorClassDuplicate:
		return RetryDecision{
			TenantID:            event.TenantID,
			CorrelationID:       event.CorrelationID,
			RequestID:           event.RequestID,
			DocumentID:          event.DocumentID,
			DocumentNo:          event.DocumentNo,
			DocumentType:        event.DocumentType,
			ProviderCode:        event.ProviderCode,
			Operation:           event.Operation,
			ErrorClass:          class,
			DecisionStatus:      DecisionDuplicate,
			RetryCount:          event.RetryCount,
			NextRetryCount:      event.RetryCount,
			AuditAction:         "PROVIDER_ERROR_DUPLICATE_IGNORED",
			AuditDecisionReason: "duplicate provider/idempotency error does not create a new retry",
			DecidedAt:           now,
		}, nil

	case ErrorClassManualReview:
		return RetryDecision{
			TenantID:             event.TenantID,
			CorrelationID:        event.CorrelationID,
			RequestID:            event.RequestID,
			DocumentID:           event.DocumentID,
			DocumentNo:           event.DocumentNo,
			DocumentType:         event.DocumentType,
			ProviderCode:         event.ProviderCode,
			Operation:            event.Operation,
			ErrorClass:           class,
			DecisionStatus:       DecisionManualReview,
			RetryCount:           event.RetryCount,
			NextRetryCount:       event.RetryCount,
			ManualReviewRequired: r.config.ManualReviewEnabled,
			AuditAction:          "PROVIDER_ERROR_MANUAL_REVIEW_REQUIRED",
			AuditDecisionReason:  "provider error requires manual review before retry or cancel",
			DecidedAt:            now,
		}, nil

	case ErrorClassNonRetryable:
		return RetryDecision{
			TenantID:            event.TenantID,
			CorrelationID:       event.CorrelationID,
			RequestID:           event.RequestID,
			DocumentID:          event.DocumentID,
			DocumentNo:          event.DocumentNo,
			DocumentType:        event.DocumentType,
			ProviderCode:        event.ProviderCode,
			Operation:           event.Operation,
			ErrorClass:          class,
			DecisionStatus:      DecisionNoRetry,
			RetryCount:          event.RetryCount,
			NextRetryCount:      event.RetryCount,
			AuditAction:         "PROVIDER_ERROR_NON_RETRYABLE",
			AuditDecisionReason: "provider error is classified as non-retryable",
			DecidedAt:           now,
		}, nil

	default:
		if event.RetryCount >= r.config.MaxRetryCount {
			return RetryDecision{
				TenantID:            event.TenantID,
				CorrelationID:       event.CorrelationID,
				RequestID:           event.RequestID,
				DocumentID:          event.DocumentID,
				DocumentNo:          event.DocumentNo,
				DocumentType:        event.DocumentType,
				ProviderCode:        event.ProviderCode,
				Operation:           event.Operation,
				ErrorClass:          ErrorClassRetryable,
				DecisionStatus:      DecisionDLQ,
				RetryCount:          event.RetryCount,
				NextRetryCount:      event.RetryCount,
				DLQRequired:         r.config.DLQEnabled,
				AuditAction:         "PROVIDER_ERROR_RETRY_EXHAUSTED_DLQ",
				AuditDecisionReason: "max retry count reached; event must be moved to DLQ",
				DecidedAt:           now,
			}, nil
		}

		nextRetry := event.RetryCount + 1
		retryAfter := event.ReceivedAt.Add(time.Duration(r.retryDelaySeconds(nextRetry)) * time.Second).UTC()

		return RetryDecision{
			TenantID:            event.TenantID,
			CorrelationID:       event.CorrelationID,
			RequestID:           event.RequestID,
			DocumentID:          event.DocumentID,
			DocumentNo:          event.DocumentNo,
			DocumentType:        event.DocumentType,
			ProviderCode:        event.ProviderCode,
			Operation:           event.Operation,
			ErrorClass:          ErrorClassRetryable,
			DecisionStatus:      DecisionRetryScheduled,
			RetryCount:          event.RetryCount,
			NextRetryCount:      nextRetry,
			RetryAfter:          retryAfter,
			AuditAction:         "PROVIDER_ERROR_RETRY_SCHEDULED",
			AuditDecisionReason: "retryable provider error scheduled with bounded backoff",
			DecidedAt:           now,
		}, nil
	}
}

func (r *ErrorCancelRetryRuntime) PrepareCancel(req CancelRequest) (CancelDecision, error) {
	if err := r.validateCancelRequest(req); err != nil {
		return rejectedCancelDecision(req, "VALIDATION_FAILED", err.Error()), err
	}

	return CancelDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		DocumentType:        req.DocumentType,
		ProviderCode:        req.ProviderCode,
		DecisionStatus:      CancelDecisionQueued,
		ProviderCancelID:    fmt.Sprintf("CANCEL-%s-%s", req.ProviderCode, req.DocumentID),
		AuditAction:         "CANCEL_REQUEST_QUEUED",
		AuditDecisionReason: "cancel request validated and queued for provider runtime",
		DecidedAt:           time.Now().UTC(),
	}, nil
}

func (r *ErrorCancelRetryRuntime) RegisterCancelAccepted(req CancelRequest) (CancelDecision, error) {
	if err := r.validateCancelRequest(req); err != nil {
		return rejectedCancelDecision(req, "VALIDATION_FAILED", err.Error()), err
	}

	return CancelDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		DocumentType:        req.DocumentType,
		ProviderCode:        req.ProviderCode,
		DecisionStatus:      CancelDecisionAccepted,
		ProviderCancelID:    fmt.Sprintf("CANCEL-ACCEPTED-%s-%s", req.ProviderCode, req.DocumentID),
		AuditAction:         "CANCEL_REQUEST_ACCEPTED",
		AuditDecisionReason: "provider cancel result accepted and document cancel lifecycle can continue",
		DecidedAt:           time.Now().UTC(),
	}, nil
}

func (r *ErrorCancelRetryRuntime) classifyError(code string) ErrorClass {
	normalized := strings.ToUpper(strings.TrimSpace(code))

	if normalized == "DUPLICATE_IDEMPOTENCY_KEY" || normalized == "DUPLICATE_PROVIDER_DOCUMENT" {
		return ErrorClassDuplicate
	}

	for _, manual := range r.config.ManualReviewCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(manual)) {
			return ErrorClassManualReview
		}
	}

	for _, fatal := range r.config.FatalErrorCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(fatal)) {
			return ErrorClassNonRetryable
		}
	}

	for _, retryable := range r.config.RetryableErrorCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(retryable)) {
			return ErrorClassRetryable
		}
	}

	return ErrorClassNonRetryable
}

func (r *ErrorCancelRetryRuntime) retryDelaySeconds(nextRetryCount int) int {
	delay := r.config.BaseRetryDelaySec

	for i := 1; i < nextRetryCount; i++ {
		delay = delay * 2
		if delay >= r.config.MaxRetryDelaySec {
			return r.config.MaxRetryDelaySec
		}
	}

	if delay > r.config.MaxRetryDelaySec {
		return r.config.MaxRetryDelaySec
	}

	return delay
}

func (r *ErrorCancelRetryRuntime) validateErrorEvent(event ErrorEvent) error {
	if strings.TrimSpace(event.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(event.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(event.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(event.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(event.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(event.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if !r.documentTypeAllowed(event.DocumentType) {
		return fmt.Errorf("document_type is not allowed: %s", event.DocumentType)
	}
	if !r.providerAllowed(event.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", event.ProviderCode)
	}
	if strings.TrimSpace(event.ProviderDocumentID) == "" {
		return errors.New("provider_document_id is required")
	}
	if strings.TrimSpace(string(event.Operation)) == "" {
		return errors.New("operation is required")
	}
	if strings.TrimSpace(event.ProviderErrorCode) == "" {
		return errors.New("provider_error_code is required")
	}
	if strings.TrimSpace(event.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if event.RetryCount < 0 {
		return errors.New("retry_count cannot be negative")
	}
	if event.OccurredAt.IsZero() {
		return errors.New("occurred_at is required")
	}
	if event.ReceivedAt.IsZero() {
		return errors.New("received_at is required")
	}
	return nil
}

func (r *ErrorCancelRetryRuntime) validateCancelRequest(req CancelRequest) error {
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
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if !r.documentTypeAllowed(req.DocumentType) {
		return fmt.Errorf("document_type is not allowed: %s", req.DocumentType)
	}
	if !r.providerAllowed(req.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", req.ProviderCode)
	}
	if strings.TrimSpace(req.ProviderDocumentID) == "" {
		return errors.New("provider_document_id is required")
	}
	if r.config.CancelReasonRequired && strings.TrimSpace(req.CancelReasonCode) == "" {
		return errors.New("cancel_reason_code is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ErrorCancelRetryRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func (r *ErrorCancelRetryRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}

func rejectedRetryDecision(event ErrorEvent, code string, message string) RetryDecision {
	return RetryDecision{
		TenantID:            event.TenantID,
		CorrelationID:       event.CorrelationID,
		RequestID:           event.RequestID,
		DocumentID:          event.DocumentID,
		DocumentNo:          event.DocumentNo,
		DocumentType:        event.DocumentType,
		ProviderCode:        event.ProviderCode,
		Operation:           event.Operation,
		DecisionStatus:      DecisionNoRetry,
		ErrorClass:          ErrorClassNonRetryable,
		AuditAction:         "PROVIDER_ERROR_REJECTED",
		AuditDecisionReason: "provider error event rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		DecidedAt:           time.Now().UTC(),
	}
}

func rejectedCancelDecision(req CancelRequest, code string, message string) CancelDecision {
	return CancelDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		DocumentType:        req.DocumentType,
		ProviderCode:        req.ProviderCode,
		DecisionStatus:      CancelDecisionRejected,
		AuditAction:         "CANCEL_REQUEST_REJECTED",
		AuditDecisionReason: "cancel request rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		DecidedAt:           time.Now().UTC(),
	}
}
