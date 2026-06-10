package earsiv

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
	OperationDownloadPDF ProviderOperation = "DOWNLOAD_PDF"
	OperationDownloadUBL ProviderOperation = "DOWNLOAD_UBL"
)

type ProviderDecisionStatus string

const (
	DecisionAllowed ProviderDecisionStatus = "ALLOWED"
	DecisionDenied  ProviderDecisionStatus = "DENIED"
)

type EArsivDocumentType string

const (
	EArsivInvoice EArsivDocumentType = "E_ARSIV"
)

type EArsivStatus string

const (
	EArsivReady          EArsivStatus = "READY"
	EArsivProviderQueued EArsivStatus = "PROVIDER_QUEUED"
	EArsivSent           EArsivStatus = "SENT"
	EArsivDelivered      EArsivStatus = "DELIVERED"
	EArsivReported       EArsivStatus = "REPORTED"
	EArsivFailed         EArsivStatus = "FAILED"
	EArsivCanceled       EArsivStatus = "CANCELED"
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
	PDFRequired        bool         `json:"pdf_required"`
	ProductionApproved bool         `json:"production_approved"`
}

type ProviderRequest struct {
	TenantID         string             `json:"tenant_id"`
	CorrelationID    string             `json:"correlation_id"`
	RequestID        string             `json:"request_id"`
	IdempotencyKey   string             `json:"idempotency_key"`
	Operation        ProviderOperation  `json:"operation"`
	DocumentID       string             `json:"document_id"`
	DocumentNo       string             `json:"document_no"`
	DocumentType     EArsivDocumentType `json:"document_type"`
	TaxIdentityNo    string             `json:"tax_identity_no"`
	PartyTitle       string             `json:"party_title"`
	BuyerEmail       string             `json:"buyer_email"`
	CurrencyCode     string             `json:"currency_code"`
	TotalAmount      int64              `json:"total_amount_kurus"`
	UBLHash          string             `json:"ubl_hash"`
	PDFHash          string             `json:"pdf_hash"`
	CancelReasonCode string             `json:"cancel_reason_code"`
	CancelReasonText string             `json:"cancel_reason_text"`
	RequestedAt      time.Time          `json:"requested_at"`
}

type ProviderResponse struct {
	TenantID            string                 `json:"tenant_id"`
	CorrelationID       string                 `json:"correlation_id"`
	RequestID           string                 `json:"request_id"`
	Operation           ProviderOperation      `json:"operation"`
	DecisionStatus      ProviderDecisionStatus `json:"decision_status"`
	ProviderCode        string                 `json:"provider_code"`
	ProviderDocumentID  string                 `json:"provider_document_id"`
	ProviderReportID    string                 `json:"provider_report_id"`
	ProviderStatusCode  string                 `json:"provider_status_code"`
	ProviderStatusText  string                 `json:"provider_status_text"`
	EArsivStatus        EArsivStatus           `json:"e_arsiv_status"`
	Retryable           bool                   `json:"retryable"`
	ErrorCode           string                 `json:"error_code"`
	ErrorMessage        string                 `json:"error_message"`
	AuditDecisionReason string                 `json:"audit_decision_reason"`
	RespondedAt         time.Time              `json:"responded_at"`
}

type ProviderAdapter interface {
	SendArchive(req ProviderRequest) (ProviderResponse, error)
	CheckStatus(req ProviderRequest) (ProviderResponse, error)
	CancelArchive(req ProviderRequest) (ProviderResponse, error)
	DownloadPDF(req ProviderRequest) (ProviderResponse, error)
	DownloadUBL(req ProviderRequest) (ProviderResponse, error)
}

type EArsivProviderRuntime struct {
	config ProviderConfig
}

func NewEArsivProviderRuntime(config ProviderConfig) (*EArsivProviderRuntime, error) {
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

	return &EArsivProviderRuntime{config: config}, nil
}

func (r *EArsivProviderRuntime) SendArchive(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "VALIDATION_FAILED", err.Error()), err
	}
	if err := validateSendRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "SEND_VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationSend, EArsivProviderQueued, "SIMULATED_E_ARSIV_SEND_ACCEPTED"), nil
}

func (r *EArsivProviderRuntime) CheckStatus(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationStatus, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationStatus, EArsivReported, "SIMULATED_E_ARSIV_REPORTED"), nil
}

func (r *EArsivProviderRuntime) CancelArchive(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationCancel, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.CancelReasonCode) == "" {
		return deniedResponse(r.config, req, OperationCancel, "CANCEL_REASON_REQUIRED", "cancel reason code is required"), errors.New("cancel reason code is required")
	}

	return r.simulatedAllowedResponse(req, OperationCancel, EArsivCanceled, "SIMULATED_E_ARSIV_CANCEL_ACCEPTED"), nil
}

func (r *EArsivProviderRuntime) DownloadPDF(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationDownloadPDF, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationDownloadPDF, EArsivReported, "SIMULATED_E_ARSIV_PDF_READY"), nil
}

func (r *EArsivProviderRuntime) DownloadUBL(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationDownloadUBL, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationDownloadUBL, EArsivReported, "SIMULATED_E_ARSIV_UBL_READY"), nil
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
	if req.DocumentType != EArsivInvoice {
		return errors.New("document_type must be E_ARSIV")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func validateSendRequest(req ProviderRequest) error {
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
	if strings.TrimSpace(req.PDFHash) == "" {
		return errors.New("pdf_hash is required")
	}
	return nil
}

func (r *EArsivProviderRuntime) simulatedAllowedResponse(req ProviderRequest, op ProviderOperation, status EArsivStatus, providerStatus string) ProviderResponse {
	now := time.Now().UTC()
	return ProviderResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionAllowed,
		ProviderCode:        r.config.ProviderCode,
		ProviderDocumentID:  fmt.Sprintf("%s-%s", r.config.ProviderCode, req.DocumentID),
		ProviderReportID:    fmt.Sprintf("REPORT-%s-%s", r.config.ProviderCode, req.DocumentNo),
		ProviderStatusCode:  providerStatus,
		ProviderStatusText:  "provider integration dry-run response",
		EArsivStatus:        status,
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
		EArsivStatus:        EArsivFailed,
		Retryable:           false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditDecisionReason: "request denied by provider runtime validation guard",
		RespondedAt:         time.Now().UTC(),
	}
}
