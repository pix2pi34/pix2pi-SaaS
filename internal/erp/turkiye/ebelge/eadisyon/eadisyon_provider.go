package eadisyon

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
	OperationOpen        ProviderOperation = "OPEN_ADISYON"
	OperationClose       ProviderOperation = "CLOSE_ADISYON"
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

type EAdisyonDocumentType string

const (
	EAdisyonReceipt EAdisyonDocumentType = "E_ADISYON"
)

type EAdisyonStatus string

const (
	EAdisyonReady          EAdisyonStatus = "READY"
	EAdisyonOpened         EAdisyonStatus = "OPENED"
	EAdisyonClosed         EAdisyonStatus = "CLOSED"
	EAdisyonProviderQueued EAdisyonStatus = "PROVIDER_QUEUED"
	EAdisyonSent           EAdisyonStatus = "SENT"
	EAdisyonReported       EAdisyonStatus = "REPORTED"
	EAdisyonFailed         EAdisyonStatus = "FAILED"
	EAdisyonCanceled       EAdisyonStatus = "CANCELED"
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
	TenantID       string               `json:"tenant_id"`
	CorrelationID  string               `json:"correlation_id"`
	RequestID      string               `json:"request_id"`
	IdempotencyKey string               `json:"idempotency_key"`
	Operation      ProviderOperation    `json:"operation"`
	DocumentID     string               `json:"document_id"`
	DocumentNo     string               `json:"document_no"`
	DocumentType   EAdisyonDocumentType `json:"document_type"`

	VenueID    string `json:"venue_id"`
	VenueName  string `json:"venue_name"`
	TableNo    string `json:"table_no"`
	AdisyonNo  string `json:"adisyon_no"`
	WaiterCode string `json:"waiter_code"`

	TaxIdentityNo string `json:"tax_identity_no"`
	PartyTitle    string `json:"party_title"`
	CurrencyCode  string `json:"currency_code"`

	SubtotalAmount      int64 `json:"subtotal_amount_kurus"`
	TaxAmount           int64 `json:"tax_amount_kurus"`
	ServiceChargeAmount int64 `json:"service_charge_amount_kurus"`
	TotalAmount         int64 `json:"total_amount_kurus"`

	OpenedAt time.Time `json:"opened_at"`
	ClosedAt time.Time `json:"closed_at"`

	UBLHash string `json:"ubl_hash"`
	PDFHash string `json:"pdf_hash"`

	CancelReasonCode string    `json:"cancel_reason_code"`
	CancelReasonText string    `json:"cancel_reason_text"`
	RequestedAt      time.Time `json:"requested_at"`
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
	EAdisyonStatus      EAdisyonStatus         `json:"e_adisyon_status"`
	Retryable           bool                   `json:"retryable"`
	ErrorCode           string                 `json:"error_code"`
	ErrorMessage        string                 `json:"error_message"`
	AuditDecisionReason string                 `json:"audit_decision_reason"`
	RespondedAt         time.Time              `json:"responded_at"`
}

type ProviderAdapter interface {
	OpenAdisyon(req ProviderRequest) (ProviderResponse, error)
	CloseAdisyon(req ProviderRequest) (ProviderResponse, error)
	SendAdisyon(req ProviderRequest) (ProviderResponse, error)
	CheckStatus(req ProviderRequest) (ProviderResponse, error)
	CancelAdisyon(req ProviderRequest) (ProviderResponse, error)
	DownloadPDF(req ProviderRequest) (ProviderResponse, error)
	DownloadUBL(req ProviderRequest) (ProviderResponse, error)
}

type EAdisyonProviderRuntime struct {
	config ProviderConfig
}

func NewEAdisyonProviderRuntime(config ProviderConfig) (*EAdisyonProviderRuntime, error) {
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

	return &EAdisyonProviderRuntime{config: config}, nil
}

func (r *EAdisyonProviderRuntime) OpenAdisyon(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationOpen, "VALIDATION_FAILED", err.Error()), err
	}
	if err := validateVenueRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationOpen, "VENUE_VALIDATION_FAILED", err.Error()), err
	}
	if req.OpenedAt.IsZero() {
		return deniedResponse(r.config, req, OperationOpen, "OPENED_AT_REQUIRED", "opened_at is required"), errors.New("opened_at is required")
	}

	return r.simulatedAllowedResponse(req, OperationOpen, EAdisyonOpened, "SIMULATED_E_ADISYON_OPENED"), nil
}

func (r *EAdisyonProviderRuntime) CloseAdisyon(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationClose, "VALIDATION_FAILED", err.Error()), err
	}
	if err := validateVenueRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationClose, "VENUE_VALIDATION_FAILED", err.Error()), err
	}
	if req.OpenedAt.IsZero() {
		return deniedResponse(r.config, req, OperationClose, "OPENED_AT_REQUIRED", "opened_at is required"), errors.New("opened_at is required")
	}
	if req.ClosedAt.IsZero() {
		return deniedResponse(r.config, req, OperationClose, "CLOSED_AT_REQUIRED", "closed_at is required"), errors.New("closed_at is required")
	}
	if req.ClosedAt.Before(req.OpenedAt) {
		return deniedResponse(r.config, req, OperationClose, "CLOSED_AT_BEFORE_OPENED_AT", "closed_at cannot be before opened_at"), errors.New("closed_at cannot be before opened_at")
	}

	return r.simulatedAllowedResponse(req, OperationClose, EAdisyonClosed, "SIMULATED_E_ADISYON_CLOSED"), nil
}

func (r *EAdisyonProviderRuntime) SendAdisyon(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "VALIDATION_FAILED", err.Error()), err
	}
	if err := validateSendRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSend, "SEND_VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationSend, EAdisyonProviderQueued, "SIMULATED_E_ADISYON_SEND_ACCEPTED"), nil
}

func (r *EAdisyonProviderRuntime) CheckStatus(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationStatus, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationStatus, EAdisyonReported, "SIMULATED_E_ADISYON_REPORTED"), nil
}

func (r *EAdisyonProviderRuntime) CancelAdisyon(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationCancel, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.CancelReasonCode) == "" {
		return deniedResponse(r.config, req, OperationCancel, "CANCEL_REASON_REQUIRED", "cancel reason code is required"), errors.New("cancel reason code is required")
	}

	return r.simulatedAllowedResponse(req, OperationCancel, EAdisyonCanceled, "SIMULATED_E_ADISYON_CANCEL_ACCEPTED"), nil
}

func (r *EAdisyonProviderRuntime) DownloadPDF(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationDownloadPDF, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationDownloadPDF, EAdisyonReported, "SIMULATED_E_ADISYON_PDF_READY"), nil
}

func (r *EAdisyonProviderRuntime) DownloadUBL(req ProviderRequest) (ProviderResponse, error) {
	if err := validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationDownloadUBL, "VALIDATION_FAILED", err.Error()), err
	}

	return r.simulatedAllowedResponse(req, OperationDownloadUBL, EAdisyonReported, "SIMULATED_E_ADISYON_UBL_READY"), nil
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
	if req.DocumentType != EAdisyonReceipt {
		return errors.New("document_type must be E_ADISYON")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func validateVenueRequest(req ProviderRequest) error {
	if strings.TrimSpace(req.VenueID) == "" {
		return errors.New("venue_id is required")
	}
	if strings.TrimSpace(req.VenueName) == "" {
		return errors.New("venue_name is required")
	}
	if strings.TrimSpace(req.TableNo) == "" {
		return errors.New("table_no is required")
	}
	if strings.TrimSpace(req.AdisyonNo) == "" {
		return errors.New("adisyon_no is required")
	}
	return nil
}

func validateSendRequest(req ProviderRequest) error {
	if err := validateVenueRequest(req); err != nil {
		return err
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.TotalAmount <= 0 {
		return errors.New("total_amount must be positive")
	}
	if req.SubtotalAmount < 0 || req.TaxAmount < 0 || req.ServiceChargeAmount < 0 {
		return errors.New("subtotal, tax and service charge cannot be negative")
	}
	if strings.TrimSpace(req.UBLHash) == "" {
		return errors.New("ubl_hash is required")
	}
	if strings.TrimSpace(req.PDFHash) == "" {
		return errors.New("pdf_hash is required")
	}
	if req.OpenedAt.IsZero() {
		return errors.New("opened_at is required")
	}
	if req.ClosedAt.IsZero() {
		return errors.New("closed_at is required")
	}
	if req.ClosedAt.Before(req.OpenedAt) {
		return errors.New("closed_at cannot be before opened_at")
	}
	return nil
}

func (r *EAdisyonProviderRuntime) simulatedAllowedResponse(req ProviderRequest, op ProviderOperation, status EAdisyonStatus, providerStatus string) ProviderResponse {
	now := time.Now().UTC()
	return ProviderResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionAllowed,
		ProviderCode:        r.config.ProviderCode,
		ProviderDocumentID:  fmt.Sprintf("%s-%s", r.config.ProviderCode, req.DocumentID),
		ProviderReportID:    fmt.Sprintf("ADISYON-REPORT-%s-%s", r.config.ProviderCode, req.AdisyonNo),
		ProviderStatusCode:  providerStatus,
		ProviderStatusText:  "provider integration dry-run response",
		EAdisyonStatus:      status,
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
		EAdisyonStatus:      EAdisyonFailed,
		Retryable:           false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditDecisionReason: "request denied by provider runtime validation guard",
		RespondedAt:         time.Now().UTC(),
	}
}
