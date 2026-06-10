package liveintegrationtests

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type TestMode string

const (
	TestModeSimulation TestMode = "SIMULATION"
	TestModeSandbox    TestMode = "SANDBOX"
	TestModeProduction TestMode = "PRODUCTION"
)

type DocumentKind string

const (
	DocumentKindEFatura  DocumentKind = "E_FATURA"
	DocumentKindEArsiv   DocumentKind = "E_ARSIV"
	DocumentKindEAdisyon DocumentKind = "E_ADISYON"
)

type LiveOperation string

const (
	OperationSendDocument       LiveOperation = "SEND_DOCUMENT"
	OperationCheckStatus        LiveOperation = "CHECK_STATUS"
	OperationCancelDocument     LiveOperation = "CANCEL_DOCUMENT"
	OperationDownloadUBL        LiveOperation = "DOWNLOAD_UBL"
	OperationDownloadPDF        LiveOperation = "DOWNLOAD_PDF"
	OperationHandleCallback     LiveOperation = "HANDLE_CALLBACK"
	OperationPollStatus         LiveOperation = "POLL_STATUS"
	OperationRetryFailed        LiveOperation = "RETRY_FAILED"
	OperationDLQRoute           LiveOperation = "DLQ_ROUTE"
	OperationManualReview       LiveOperation = "MANUAL_REVIEW"
	OperationLiveSmokeReadiness LiveOperation = "LIVE_SMOKE_READINESS"
)

type DecisionStatus string

const (
	DecisionPassed       DecisionStatus = "PASSED"
	DecisionReady        DecisionStatus = "READY"
	DecisionDenied       DecisionStatus = "DENIED"
	DecisionSkipped      DecisionStatus = "SKIPPED"
	DecisionReviewNeeded DecisionStatus = "REVIEW_NEEDED"
)

type ProviderStatus string

const (
	ProviderStatusDraft     ProviderStatus = "DRAFT"
	ProviderStatusQueued    ProviderStatus = "QUEUED"
	ProviderStatusSent      ProviderStatus = "SENT"
	ProviderStatusAccepted  ProviderStatus = "ACCEPTED"
	ProviderStatusRejected  ProviderStatus = "REJECTED"
	ProviderStatusCancelled ProviderStatus = "CANCELLED"
	ProviderStatusRetryable ProviderStatus = "RETRYABLE"
	ProviderStatusDLQ       ProviderStatus = "DLQ"
)

type RuntimeConfig struct {
	RuntimeEnabled            bool            `json:"runtime_enabled"`
	Mode                      TestMode        `json:"mode"`
	RealProviderGateOpen      bool            `json:"real_provider_gate_open"`
	ProductionApproved        bool            `json:"production_approved"`
	ProviderCode              string          `json:"provider_code"`
	EndpointBaseURL           string          `json:"endpoint_base_url"`
	CredentialRef             string          `json:"credential_ref"`
	RawSecretPolicy           string          `json:"raw_secret_policy"`
	TenantRequired            bool            `json:"tenant_required"`
	IdempotencyRequired       bool            `json:"idempotency_required"`
	SignatureRequired         bool            `json:"signature_required"`
	CallbackRequired          bool            `json:"callback_required"`
	PollRequired              bool            `json:"poll_required"`
	RetryRequired             bool            `json:"retry_required"`
	DLQRequired               bool            `json:"dlq_required"`
	ManualReviewRequired      bool            `json:"manual_review_required"`
	LiveSmokeAllowedInSandbox bool            `json:"live_smoke_allowed_in_sandbox"`
	SupportedDocuments        []DocumentKind  `json:"supported_documents"`
	RequiredOperations        []LiveOperation `json:"required_operations"`
}

type LiveIntegrationRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentKind DocumentKind `json:"document_kind"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	ProviderCode        string `json:"provider_code"`
	ProviderDocumentID  string `json:"provider_document_id"`
	ProviderPayloadHash string `json:"provider_payload_hash"`

	UBLHash string `json:"ubl_hash"`
	PDFHash string `json:"pdf_hash"`

	CallbackSignature   string `json:"callback_signature"`
	CallbackPayloadHash string `json:"callback_payload_hash"`

	CancelReason string `json:"cancel_reason"`
	ErrorCode    string `json:"error_code"`
	RetryCount   int    `json:"retry_count"`

	Operation   LiveOperation `json:"operation"`
	RequestedBy string        `json:"requested_by"`
	RequestedAt time.Time     `json:"requested_at"`
}

type LiveIntegrationResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentKind DocumentKind `json:"document_kind"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`

	ProviderCode       string `json:"provider_code"`
	ProviderDocumentID string `json:"provider_document_id"`

	Operation LiveOperation `json:"operation"`

	DecisionStatus DecisionStatus `json:"decision_status"`
	ProviderStatus ProviderStatus `json:"provider_status"`

	ProviderCallAllowed bool `json:"provider_call_allowed"`
	LiveGateOpen        bool `json:"live_gate_open"`
	SimulationOnly      bool `json:"simulation_only"`
	CallbackVerified    bool `json:"callback_verified"`
	PollReady           bool `json:"poll_ready"`
	RetryReady          bool `json:"retry_ready"`
	DLQReady            bool `json:"dlq_ready"`
	ManualReviewReady   bool `json:"manual_review_ready"`
	ArtifactReady       bool `json:"artifact_ready"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	DecidedAt           time.Time `json:"decided_at"`
}

type LiveIntegrationSuite struct {
	config RuntimeConfig
}

func NewLiveIntegrationSuite(config RuntimeConfig) (*LiveIntegrationSuite, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("e-belge live integration test suite is disabled")
	}
	if config.Mode == "" {
		return nil, errors.New("test mode is required")
	}
	if strings.TrimSpace(config.ProviderCode) == "" {
		return nil, errors.New("provider_code is required")
	}
	if strings.TrimSpace(config.EndpointBaseURL) == "" {
		return nil, errors.New("endpoint_base_url is required")
	}
	if strings.TrimSpace(config.CredentialRef) == "" {
		return nil, errors.New("credential_ref is required")
	}
	if strings.Contains(strings.ToLower(config.CredentialRef), "password") || strings.Contains(strings.ToLower(config.CredentialRef), "secret_value") {
		return nil, errors.New("credential_ref must not contain raw secret material")
	}
	if config.RawSecretPolicy != "CREDENTIAL_REF_ONLY_NO_RAW_SECRET" {
		return nil, errors.New("raw_secret_policy must be CREDENTIAL_REF_ONLY_NO_RAW_SECRET")
	}
	if len(config.SupportedDocuments) == 0 {
		return nil, errors.New("supported_documents are required")
	}
	if len(config.RequiredOperations) == 0 {
		return nil, errors.New("required_operations are required")
	}
	if config.Mode == TestModeProduction && (!config.RealProviderGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production e-belge live provider access is closed until legal/provider/security approvals")
	}
	return &LiveIntegrationSuite{config: config}, nil
}

func (s *LiveIntegrationSuite) ValidateLiveGate() LiveIntegrationResult {
	result := LiveIntegrationResult{
		ProviderCode:   s.config.ProviderCode,
		Operation:      OperationLiveSmokeReadiness,
		LiveGateOpen:   s.config.RealProviderGateOpen,
		SimulationOnly: !s.config.RealProviderGateOpen,
		DecidedAt:      time.Now().UTC(),
	}

	if s.config.Mode == TestModeProduction && (!s.config.RealProviderGateOpen || !s.config.ProductionApproved) {
		result.DecisionStatus = DecisionDenied
		result.ProviderCallAllowed = false
		result.AuditAction = "EBELGE_LIVE_GATE_DENIED"
		result.AuditDecisionReason = "production provider call is denied until approvals are complete"
		result.ErrorCode = "LIVE_PROVIDER_GATE_CLOSED"
		result.ErrorMessage = "live provider gate is closed"
		return result
	}

	if s.config.Mode == TestModeSandbox && s.config.LiveSmokeAllowedInSandbox {
		result.DecisionStatus = DecisionReady
		result.ProviderCallAllowed = true
		result.AuditAction = "EBELGE_SANDBOX_SMOKE_READY"
		result.AuditDecisionReason = "sandbox live smoke readiness is allowed by config"
		return result
	}

	result.DecisionStatus = DecisionSkipped
	result.ProviderCallAllowed = false
	result.AuditAction = "EBELGE_LIVE_PROVIDER_CALL_SKIPPED"
	result.AuditDecisionReason = "simulation mode validates readiness without external provider call"
	return result
}

func (s *LiveIntegrationSuite) ValidateSendDocument(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationSendDocument
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.UBLHash) == "" {
		return rejected(req, "UBL_HASH_REQUIRED", "ubl_hash is required"), errors.New("ubl_hash is required")
	}

	return accepted(req, ProviderStatusQueued, "EBELGE_SEND_DOCUMENT_READY", "document send contract validated without live provider call", s.config), nil
}

func (s *LiveIntegrationSuite) ValidateStatusCheck(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationCheckStatus
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderDocumentID) == "" {
		return rejected(req, "PROVIDER_DOCUMENT_ID_REQUIRED", "provider_document_id is required"), errors.New("provider_document_id is required")
	}

	return accepted(req, ProviderStatusAccepted, "EBELGE_STATUS_CHECK_READY", "status check contract validated without live provider call", s.config), nil
}

func (s *LiveIntegrationSuite) ValidateCancelDocument(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationCancelDocument
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderDocumentID) == "" {
		return rejected(req, "PROVIDER_DOCUMENT_ID_REQUIRED", "provider_document_id is required"), errors.New("provider_document_id is required")
	}
	if strings.TrimSpace(req.CancelReason) == "" {
		return rejected(req, "CANCEL_REASON_REQUIRED", "cancel_reason is required"), errors.New("cancel_reason is required")
	}

	return accepted(req, ProviderStatusCancelled, "EBELGE_CANCEL_DOCUMENT_READY", "cancel contract validated without live provider call", s.config), nil
}

func (s *LiveIntegrationSuite) ValidateDownloadArtifact(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	if req.DocumentKind == DocumentKindEFatura {
		req.Operation = OperationDownloadUBL
	} else {
		req.Operation = OperationDownloadPDF
	}

	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderDocumentID) == "" {
		return rejected(req, "PROVIDER_DOCUMENT_ID_REQUIRED", "provider_document_id is required"), errors.New("provider_document_id is required")
	}
	if strings.TrimSpace(req.UBLHash) == "" && strings.TrimSpace(req.PDFHash) == "" {
		return rejected(req, "ARTIFACT_HASH_REQUIRED", "ubl_hash or pdf_hash is required"), errors.New("ubl_hash or pdf_hash is required")
	}

	result := accepted(req, ProviderStatusAccepted, "EBELGE_DOWNLOAD_ARTIFACT_READY", "download artifact contract validated without live provider call", s.config)
	result.ArtifactReady = true
	return result, nil
}

func (s *LiveIntegrationSuite) ValidateCallback(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationHandleCallback
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if s.config.SignatureRequired && strings.TrimSpace(req.CallbackSignature) == "" {
		return rejected(req, "CALLBACK_SIGNATURE_REQUIRED", "callback_signature is required"), errors.New("callback_signature is required")
	}
	if strings.TrimSpace(req.CallbackPayloadHash) == "" {
		return rejected(req, "CALLBACK_PAYLOAD_HASH_REQUIRED", "callback_payload_hash is required"), errors.New("callback_payload_hash is required")
	}

	result := accepted(req, ProviderStatusAccepted, "EBELGE_CALLBACK_VERIFIED", "callback signature and payload hash contract validated", s.config)
	result.CallbackVerified = true
	return result, nil
}

func (s *LiveIntegrationSuite) ValidatePollPlan(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationPollStatus
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if !s.config.PollRequired {
		return rejected(req, "POLL_NOT_REQUIRED", "poll is not required by config"), errors.New("poll is not required by config")
	}

	result := accepted(req, ProviderStatusSent, "EBELGE_POLL_PLAN_READY", "poll readiness validated", s.config)
	result.PollReady = true
	return result, nil
}

func (s *LiveIntegrationSuite) ValidateRetryAndDLQ(req LiveIntegrationRequest) (LiveIntegrationResult, error) {
	req.Operation = OperationRetryFailed
	if err := s.validateBaseRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ErrorCode) == "" {
		return rejected(req, "ERROR_CODE_REQUIRED", "error_code is required"), errors.New("error_code is required")
	}
	if req.RetryCount < 0 {
		return rejected(req, "RETRY_COUNT_INVALID", "retry_count cannot be negative"), errors.New("retry_count cannot be negative")
	}

	result := accepted(req, ProviderStatusRetryable, "EBELGE_RETRY_READY", "retry and DLQ readiness validated", s.config)
	result.RetryReady = s.config.RetryRequired
	result.DLQReady = s.config.DLQRequired
	result.ManualReviewReady = s.config.ManualReviewRequired
	if req.RetryCount >= 3 {
		result.ProviderStatus = ProviderStatusDLQ
		result.AuditAction = "EBELGE_DLQ_ROUTE_READY"
		result.AuditDecisionReason = "retry count reached DLQ threshold"
	}
	return result, nil
}

func (s *LiveIntegrationSuite) RunReadinessMatrix(reqs []LiveIntegrationRequest) ([]LiveIntegrationResult, error) {
	if len(reqs) == 0 {
		return nil, errors.New("readiness matrix requests are required")
	}

	results := make([]LiveIntegrationResult, 0, len(reqs)+1)
	results = append(results, s.ValidateLiveGate())

	for _, req := range reqs {
		var (
			result LiveIntegrationResult
			err    error
		)

		switch req.Operation {
		case OperationSendDocument:
			result, err = s.ValidateSendDocument(req)
		case OperationCheckStatus:
			result, err = s.ValidateStatusCheck(req)
		case OperationCancelDocument:
			result, err = s.ValidateCancelDocument(req)
		case OperationDownloadUBL, OperationDownloadPDF:
			result, err = s.ValidateDownloadArtifact(req)
		case OperationHandleCallback:
			result, err = s.ValidateCallback(req)
		case OperationPollStatus:
			result, err = s.ValidatePollPlan(req)
		case OperationRetryFailed, OperationDLQRoute:
			result, err = s.ValidateRetryAndDLQ(req)
		default:
			result = rejected(req, "OPERATION_UNSUPPORTED", "operation is unsupported")
			err = errors.New("operation is unsupported")
		}

		if err != nil {
			return append(results, result), err
		}
		results = append(results, result)
	}

	return results, nil
}

func (s *LiveIntegrationSuite) validateBaseRequest(req LiveIntegrationRequest) error {
	if s.config.TenantRequired && strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if s.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if !s.documentSupported(req.DocumentKind) {
		return fmt.Errorf("document_kind is not supported: %s", req.DocumentKind)
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if req.ProviderCode != s.config.ProviderCode {
		return errors.New("provider_code mismatch")
	}
	if strings.TrimSpace(req.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (s *LiveIntegrationSuite) documentSupported(kind DocumentKind) bool {
	for _, supported := range s.config.SupportedDocuments {
		if supported == kind {
			return true
		}
	}
	return false
}

func accepted(req LiveIntegrationRequest, providerStatus ProviderStatus, action string, reason string, config RuntimeConfig) LiveIntegrationResult {
	return LiveIntegrationResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		DocumentKind:        req.DocumentKind,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		ProviderCode:        req.ProviderCode,
		ProviderDocumentID:  req.ProviderDocumentID,
		Operation:           req.Operation,
		DecisionStatus:      DecisionPassed,
		ProviderStatus:      providerStatus,
		ProviderCallAllowed: config.RealProviderGateOpen && config.ProductionApproved,
		LiveGateOpen:        config.RealProviderGateOpen,
		SimulationOnly:      !config.RealProviderGateOpen,
		AuditAction:         action,
		AuditDecisionReason: reason,
		DecidedAt:           time.Now().UTC(),
	}
}

func rejected(req LiveIntegrationRequest, code string, message string) LiveIntegrationResult {
	return LiveIntegrationResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		DocumentKind:        req.DocumentKind,
		DocumentID:          req.DocumentID,
		DocumentNo:          req.DocumentNo,
		ProviderCode:        req.ProviderCode,
		ProviderDocumentID:  req.ProviderDocumentID,
		Operation:           req.Operation,
		DecisionStatus:      DecisionDenied,
		ProviderStatus:      ProviderStatusRejected,
		ProviderCallAllowed: false,
		AuditAction:         "EBELGE_LIVE_INTEGRATION_REJECTED",
		AuditDecisionReason: "e-belge live integration test rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		DecidedAt:           time.Now().UTC(),
	}
}
