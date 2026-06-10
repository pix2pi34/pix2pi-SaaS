package pos

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

type POSOperation string

const (
	OperationAuthorize       POSOperation = "AUTHORIZE"
	OperationCapture         POSOperation = "CAPTURE"
	OperationSale            POSOperation = "SALE"
	OperationRefund          POSOperation = "REFUND"
	OperationVoid            POSOperation = "VOID"
	OperationStatusCheck     POSOperation = "STATUS_CHECK"
	OperationThreeDSInit     POSOperation = "THREE_DS_INIT"
	OperationThreeDSComplete POSOperation = "THREE_DS_COMPLETE"
)

type POSDecisionStatus string

const (
	DecisionAllowed POSDecisionStatus = "ALLOWED"
	DecisionDenied  POSDecisionStatus = "DENIED"
)

type POSTransactionStatus string

const (
	TransactionCreated    POSTransactionStatus = "CREATED"
	TransactionAuthorized POSTransactionStatus = "AUTHORIZED"
	TransactionCaptured   POSTransactionStatus = "CAPTURED"
	TransactionSold       POSTransactionStatus = "SOLD"
	TransactionRefunded   POSTransactionStatus = "REFUNDED"
	TransactionVoided     POSTransactionStatus = "VOIDED"
	TransactionFailed     POSTransactionStatus = "FAILED"
	TransactionPending3DS POSTransactionStatus = "PENDING_3DS"
)

type POSProviderConfig struct {
	ProviderCode        string       `json:"provider_code"`
	Mode                ProviderMode `json:"mode"`
	RealPaymentGateOpen bool         `json:"real_payment_gate_open"`
	ProductionApproved  bool         `json:"production_approved"`
	EndpointBaseURL     string       `json:"endpoint_base_url"`
	CredentialRef       string       `json:"credential_ref"`
	RequestTimeoutMS    int          `json:"request_timeout_ms"`
	MaxRetryCount       int          `json:"max_retry_count"`
	ThreeDSEnabled      bool         `json:"three_ds_enabled"`
	CaptureRequired     bool         `json:"capture_required"`
	IdempotencyRequired bool         `json:"idempotency_required"`
}

type POSRequest struct {
	TenantID       string       `json:"tenant_id"`
	CorrelationID  string       `json:"correlation_id"`
	RequestID      string       `json:"request_id"`
	IdempotencyKey string       `json:"idempotency_key"`
	Operation      POSOperation `json:"operation"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	SourceDocumentType   string `json:"source_document_type"`
	SourceDocumentID     string `json:"source_document_id"`
	SourceDocumentNo     string `json:"source_document_no"`

	MerchantID    string `json:"merchant_id"`
	TerminalID    string `json:"terminal_id"`
	ProviderCode  string `json:"provider_code"`
	ProviderTxnID string `json:"provider_transaction_id"`

	AmountKurus      int64  `json:"amount_kurus"`
	CurrencyCode     string `json:"currency_code"`
	InstallmentCount int    `json:"installment_count"`

	CardToken        string `json:"card_token"`
	MaskedCardPAN    string `json:"masked_card_pan"`
	CardHolderName   string `json:"card_holder_name"`
	ThreeDSReturnURL string `json:"three_ds_return_url"`
	ThreeDSMD        string `json:"three_ds_md"`
	ThreeDSPares     string `json:"three_ds_pares"`

	RefundReasonCode string `json:"refund_reason_code"`
	VoidReasonCode   string `json:"void_reason_code"`

	RequestedAt time.Time `json:"requested_at"`
}

type POSResponse struct {
	TenantID            string               `json:"tenant_id"`
	CorrelationID       string               `json:"correlation_id"`
	RequestID           string               `json:"request_id"`
	Operation           POSOperation         `json:"operation"`
	DecisionStatus      POSDecisionStatus    `json:"decision_status"`
	ProviderCode        string               `json:"provider_code"`
	ProviderTxnID       string               `json:"provider_transaction_id"`
	ProviderAuthCode    string               `json:"provider_auth_code"`
	ProviderBatchNo     string               `json:"provider_batch_no"`
	ProviderStatusCode  string               `json:"provider_status_code"`
	ProviderStatusText  string               `json:"provider_status_text"`
	TransactionStatus   POSTransactionStatus `json:"transaction_status"`
	ThreeDSRedirectURL  string               `json:"three_ds_redirect_url"`
	Retryable           bool                 `json:"retryable"`
	ErrorCode           string               `json:"error_code"`
	ErrorMessage        string               `json:"error_message"`
	AuditDecisionReason string               `json:"audit_decision_reason"`
	RespondedAt         time.Time            `json:"responded_at"`
}

type POSProviderAdapter interface {
	Authorize(req POSRequest) (POSResponse, error)
	Capture(req POSRequest) (POSResponse, error)
	Sale(req POSRequest) (POSResponse, error)
	Refund(req POSRequest) (POSResponse, error)
	Void(req POSRequest) (POSResponse, error)
	CheckStatus(req POSRequest) (POSResponse, error)
	ThreeDSInit(req POSRequest) (POSResponse, error)
	ThreeDSComplete(req POSRequest) (POSResponse, error)
}

type POSProviderRuntime struct {
	config POSProviderConfig
}

func NewPOSProviderRuntime(config POSProviderConfig) (*POSProviderRuntime, error) {
	if strings.TrimSpace(config.ProviderCode) == "" {
		return nil, errors.New("provider_code is required")
	}
	if config.Mode == "" {
		return nil, errors.New("provider mode is required")
	}
	if config.RequestTimeoutMS <= 0 {
		return nil, errors.New("request_timeout_ms must be positive")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max_retry_count cannot be negative")
	}
	if config.Mode == ProviderModeProduction && (!config.RealPaymentGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production real payment access is closed until approvals and real payment gate are open")
	}

	return &POSProviderRuntime{config: config}, nil
}

func (r *POSProviderRuntime) Authorize(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationAuthorize, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCardPaymentRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationAuthorize, "CARD_PAYMENT_VALIDATION_FAILED", err.Error()), err
	}

	return r.allowedResponse(req, OperationAuthorize, TransactionAuthorized, "SIMULATED_AUTHORIZED"), nil
}

func (r *POSProviderRuntime) Capture(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationCapture, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderTxnID) == "" {
		return deniedResponse(r.config, req, OperationCapture, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}

	return r.allowedResponse(req, OperationCapture, TransactionCaptured, "SIMULATED_CAPTURED"), nil
}

func (r *POSProviderRuntime) Sale(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSale, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCardPaymentRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationSale, "CARD_PAYMENT_VALIDATION_FAILED", err.Error()), err
	}

	return r.allowedResponse(req, OperationSale, TransactionSold, "SIMULATED_SALE_APPROVED"), nil
}

func (r *POSProviderRuntime) Refund(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationRefund, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderTxnID) == "" {
		return deniedResponse(r.config, req, OperationRefund, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}
	if strings.TrimSpace(req.RefundReasonCode) == "" {
		return deniedResponse(r.config, req, OperationRefund, "REFUND_REASON_REQUIRED", "refund_reason_code is required"), errors.New("refund_reason_code is required")
	}

	return r.allowedResponse(req, OperationRefund, TransactionRefunded, "SIMULATED_REFUNDED"), nil
}

func (r *POSProviderRuntime) Void(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationVoid, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderTxnID) == "" {
		return deniedResponse(r.config, req, OperationVoid, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}
	if strings.TrimSpace(req.VoidReasonCode) == "" {
		return deniedResponse(r.config, req, OperationVoid, "VOID_REASON_REQUIRED", "void_reason_code is required"), errors.New("void_reason_code is required")
	}

	return r.allowedResponse(req, OperationVoid, TransactionVoided, "SIMULATED_VOIDED"), nil
}

func (r *POSProviderRuntime) CheckStatus(req POSRequest) (POSResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationStatusCheck, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderTxnID) == "" {
		return deniedResponse(r.config, req, OperationStatusCheck, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}

	return r.allowedResponse(req, OperationStatusCheck, TransactionCaptured, "SIMULATED_STATUS_CAPTURED"), nil
}

func (r *POSProviderRuntime) ThreeDSInit(req POSRequest) (POSResponse, error) {
	if !r.config.ThreeDSEnabled {
		return deniedResponse(r.config, req, OperationThreeDSInit, "THREE_DS_DISABLED", "3DS is disabled"), errors.New("3DS is disabled")
	}
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationThreeDSInit, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCardPaymentRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationThreeDSInit, "CARD_PAYMENT_VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ThreeDSReturnURL) == "" {
		return deniedResponse(r.config, req, OperationThreeDSInit, "THREE_DS_RETURN_URL_REQUIRED", "three_ds_return_url is required"), errors.New("three_ds_return_url is required")
	}

	resp := r.allowedResponse(req, OperationThreeDSInit, TransactionPending3DS, "SIMULATED_3DS_INIT")
	resp.ThreeDSRedirectURL = fmt.Sprintf("https://simulation.local/3ds/%s/%s", r.config.ProviderCode, req.PaymentTransactionID)
	return resp, nil
}

func (r *POSProviderRuntime) ThreeDSComplete(req POSRequest) (POSResponse, error) {
	if !r.config.ThreeDSEnabled {
		return deniedResponse(r.config, req, OperationThreeDSComplete, "THREE_DS_DISABLED", "3DS is disabled"), errors.New("3DS is disabled")
	}
	if err := r.validateBaseRequest(req); err != nil {
		return deniedResponse(r.config, req, OperationThreeDSComplete, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ThreeDSMD) == "" {
		return deniedResponse(r.config, req, OperationThreeDSComplete, "THREE_DS_MD_REQUIRED", "three_ds_md is required"), errors.New("three_ds_md is required")
	}
	if strings.TrimSpace(req.ThreeDSPares) == "" {
		return deniedResponse(r.config, req, OperationThreeDSComplete, "THREE_DS_PARES_REQUIRED", "three_ds_pares is required"), errors.New("three_ds_pares is required")
	}

	return r.allowedResponse(req, OperationThreeDSComplete, TransactionAuthorized, "SIMULATED_3DS_COMPLETED"), nil
}

func (r *POSProviderRuntime) validateBaseRequest(req POSRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.PaymentTransactionID) == "" {
		return errors.New("payment_transaction_id is required")
	}
	if strings.TrimSpace(req.MerchantID) == "" {
		return errors.New("merchant_id is required")
	}
	if strings.TrimSpace(req.TerminalID) == "" {
		return errors.New("terminal_id is required")
	}
	if strings.TrimSpace(req.ProviderCode) == "" {
		return errors.New("provider_code is required")
	}
	if req.ProviderCode != r.config.ProviderCode {
		return errors.New("provider_code mismatch")
	}
	if req.AmountKurus <= 0 {
		return errors.New("amount_kurus must be positive")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.InstallmentCount < 0 {
		return errors.New("installment_count cannot be negative")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *POSProviderRuntime) validateCardPaymentRequest(req POSRequest) error {
	if strings.TrimSpace(req.CardToken) == "" {
		return errors.New("card_token is required")
	}
	if strings.TrimSpace(req.MaskedCardPAN) == "" {
		return errors.New("masked_card_pan is required")
	}
	if !strings.Contains(req.MaskedCardPAN, "*") {
		return errors.New("masked_card_pan must be masked")
	}
	return nil
}

func (r *POSProviderRuntime) allowedResponse(req POSRequest, op POSOperation, status POSTransactionStatus, providerStatus string) POSResponse {
	now := time.Now().UTC()

	providerTxnID := strings.TrimSpace(req.ProviderTxnID)
	if providerTxnID == "" {
		providerTxnID = fmt.Sprintf("%s-%s", r.config.ProviderCode, req.PaymentTransactionID)
	}

	return POSResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionAllowed,
		ProviderCode:        r.config.ProviderCode,
		ProviderTxnID:       providerTxnID,
		ProviderAuthCode:    fmt.Sprintf("AUTH-%s", req.PaymentTransactionID),
		ProviderBatchNo:     fmt.Sprintf("BATCH-%s", now.Format("20060102")),
		ProviderStatusCode:  providerStatus,
		ProviderStatusText:  "POS provider simulation response",
		TransactionStatus:   status,
		Retryable:           false,
		AuditDecisionReason: "POS provider runtime is running in controlled simulation/sandbox-safe mode",
		RespondedAt:         now,
	}
}

func deniedResponse(config POSProviderConfig, req POSRequest, op POSOperation, code string, message string) POSResponse {
	return POSResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionDenied,
		ProviderCode:        config.ProviderCode,
		ProviderStatusCode:  "DENIED",
		ProviderStatusText:  message,
		TransactionStatus:   TransactionFailed,
		Retryable:           false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditDecisionReason: "POS provider request denied by runtime validation guard",
		RespondedAt:         time.Now().UTC(),
	}
}
