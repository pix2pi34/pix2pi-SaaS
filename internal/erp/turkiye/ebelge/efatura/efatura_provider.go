package efatura

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type ProviderMode string

const (
	ProviderModeSimulation ProviderMode = "SIMULATION"
	ProviderModeSandbox    ProviderMode = "SANDBOX"
	ProviderModeProduction ProviderMode = "PRODUCTION"
)

type ProviderOperation string

const (
	OperationSend        ProviderOperation = "SEND"
	OperationStatus      ProviderOperation = "STATUS_CHECK"
	OperationCancel      ProviderOperation = "CANCEL"
	OperationDownloadUBL ProviderOperation = "DOWNLOAD_UBL"
)

type ProviderDecisionStatus string

const (
	DecisionAllowed ProviderDecisionStatus = "ALLOWED"
	DecisionDenied  ProviderDecisionStatus = "DENIED"
)

type EFaturaDocumentType string

const (
	EFaturaInvoice EFaturaDocumentType = "E_FATURA"
)

type EFaturaStatus string

const (
	EFaturaReady          EFaturaStatus = "READY"
	EFaturaProviderQueued EFaturaStatus = "PROVIDER_QUEUED"
	EFaturaSent           EFaturaStatus = "SENT"
	EFaturaDelivered      EFaturaStatus = "DELIVERED"
	EFaturaAccepted       EFaturaStatus = "ACCEPTED"
	EFaturaRejected       EFaturaStatus = "REJECTED"
	EFaturaFailed         EFaturaStatus = "FAILED"
	EFaturaCanceled       EFaturaStatus = "CANCELED"
)

type ProviderConfig struct {
	ProviderCode       string       `json:"provider_code"`
	Mode               ProviderMode `json:"mode"`
	RealAPIGateOpen    bool         `json:"real_api_gate_open"`
	EndpointBaseURL    string       `json:"endpoint_base_url"`
	CredentialRef      string       `json:"credential_ref"`
	RequestTimeoutMS   int          `json:"request_timeout_ms"`
	MaxRetryCount      int          `json:"max_retry_count"`
	SignatureRequired  bool         `json:"signature_required"`
	UBLRequired        bool         `json:"ubl_required"`
	ProductionApproved bool         `json:"production_approved"`
}

type ProviderRequest struct {
	TenantID         string              `json:"tenant_id"`
	CorrelationID    string              `json:"correlation_id"`
	RequestID        string              `json:"request_id"`
	IdempotencyKey   string              `json:"idempotency_key"`
	Operation        ProviderOperation   `json:"operation"`
	DocumentID       string              `json:"document_id"`
	DocumentNo       string              `json:"document_no"`
	DocumentType     EFaturaDocumentType `json:"document_type"`
	TaxIdentityNo    string              `json:"tax_identity_no"`
	PartyTitle       string              `json:"party_title"`
	CurrencyCode     string              `json:"currency_code"`
	TotalAmount      int64               `json:"total_amount_kurus"`
	UBLHash          string              `json:"ubl_hash"`
	CancelReasonCode string              `json:"cancel_reason_code"`
	CancelReasonText string              `json:"cancel_reason_text"`
	RequestedAt      time.Time           `json:"requested_at"`
}

type ProviderResponse struct {
	TenantID            string                 `json:"tenant_id"`
	CorrelationID       string                 `json:"correlation_id"`
	RequestID           string                 `json:"request_id"`
	Operation           ProviderOperation      `json:"operation"`
	DecisionStatus      ProviderDecisionStatus `json:"decision_status"`
	ProviderCode        string                 `json:"provider_code"`
	ProviderDocumentID  string                 `json:"provider_document_id"`
	ProviderEnvelopeID  string                 `json:"provider_envelope_id"`
	ProviderStatusCode  string                 `json:"provider_status_code"`
	ProviderStatusText  string                 `json:"provider_status_text"`
	EFaturaStatus       EFaturaStatus          `json:"e_fatura_status"`
	Retryable           bool                   `json:"retryable"`
	ErrorCode           string                 `json:"error_code"`
	ErrorMessage        string                 `json:"error_message"`
	AuditDecisionReason string                 `json:"audit_decision_reason"`
	RespondedAt         time.Time              `json:"responded_at"`
}

type ProviderAdapter interface {
	SendInvoice(req ProviderRequest) (ProviderResponse, error)
	CheckStatus(req ProviderRequest) (ProviderResponse, error)
	CancelInvoice(req ProviderRequest) (ProviderResponse, error)
	DownloadUBL(req ProviderRequest) (ProviderResponse, error)
}

type EFaturaProviderRuntime struct {
	config ProviderConfig
}

func NewEFaturaProviderRuntime(config ProviderConfig) (*EFaturaProviderRuntime, error) {
	if strings.TrimSpace(config.ProviderCode) == "" {
		return nil, errors.New("provider code is required")
	}
	if config.Mode == "" {
		return nil, errors.New("provider mode is required")
	}
	if config.RequestTimeoutMS <= 0 {
		return nil, errors.New("request timeout must be positive")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max retry count cannot be negative")
	}
	if config.Mode == ProviderModeProduction && (!config.RealAPIGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production provider access is closed until approvals and real api gate are open")
	}

	return &EFaturaProviderRuntime{config: config}, nil
}

func (r *EFaturaProviderRuntime) SendInvoice(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "VALIDATION_FAILED", err.Error()), err
	}
	if err := validateSendRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "SEND_VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationSend, EFaturaProviderQueued, "SIMULATED_SEND_ACCEPTED"), nil
}

func (r *EFaturaProviderRuntime) CheckStatus(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationStatus, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationStatus, EFaturaDelivered, "SIMULATED_STATUS_DELIVERED"), nil
}

func (r *EFaturaProviderRuntime) CancelInvoice(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationCancel, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.CancelReasonCode) == "" {
		return deniedResponse(r.config, req, OperationCancel, "CANCEL_REASON_REQUIRED", "cancel reason code is required"), errors.New("cancel reason code is required")
	}

	return r.simulatedAllowedResponse(req, OperationCancel, EFaturaCanceled, "SIMULATED_CANCEL_ACCEPTED"), nil
}

func (r *EFaturaProviderRuntime) DownloadUBL(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationDownloadUBL, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationDownloadUBL, EFaturaDelivered, "SIMULATED_UBL_READY"), nil
}

func validateBaseRequest(req ProviderRequest) error {
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
	if req.DocumentType != EFaturaInvoice {
		return errors.New("document_type must be E_FATURA")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func validateSendRequest(req ProviderRequest) error {
	if strings.TrimSpace(req.TaxIdentityNo) == "" {
		return errors.New("tax_identity_no is required")
	}
	if strings.TrimSpace(req.PartyTitle) == "" {
		return errors.New("party_title is required")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.TotalAmount <= 0 {
		return errors.New("total_amount must be positive")
	}
	if strings.TrimSpace(req.UBLHash) == "" {
		return errors.New("ubl_hash is required")
	}
	return nil
}

func (r *EFaturaProviderRuntime) simulatedAllowedResponse(req ProviderRequest, op ProviderOperation, status EFaturaStatus, providerStatus string) ProviderResponse {
	now := time.Now().UTC()
	return ProviderResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionAllowed,
		ProviderCode:        r.config.ProviderCode,
		ProviderDocumentID:  fmt.Sprintf("%s-%s", r.config.ProviderCode, req.DocumentID),
		ProviderEnvelopeID:  fmt.Sprintf("ENV-%s-%s", r.config.ProviderCode, req.DocumentNo),
		ProviderStatusCode:  providerStatus,
		ProviderStatusText:  "provider integration dry-run response",
		EFaturaStatus:       status,
		Retryable:           false,
		AuditDecisionReason: "provider adapter is running in controlled simulation/sandbox-safe mode",
		RespondedAt:         now,
	}
}

func deniedResponse(config ProviderConfig, req ProviderRequest, op ProviderOperation, code string, message string) ProviderResponse {
	return ProviderResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionDenied,
		ProviderCode:        config.ProviderCode,
		ProviderStatusCode:  "DENIED",
		ProviderStatusText:  message,
		EFaturaStatus:       EFaturaFailed,
		Retryable:           false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditDecisionReason: "request denied by provider runtime validation guard",
		RespondedAt:         time.Now().UTC(),
	}
}
