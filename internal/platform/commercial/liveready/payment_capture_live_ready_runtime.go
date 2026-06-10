package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	PaymentCaptureLiveReadyModuleCode = "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"

	PaymentCaptureLiveReadyMode = "PAYMENT_CAPTURE_LIVE_READY_WITH_REAL_CAPTURE_DISABLED"

	PaymentCaptureLiveReadyStatusReady               = "PAYMENT_CAPTURE_LIVE_READY_RUNTIME_READY"
	PaymentCaptureLiveReadyStatusPlanBuilt           = "PAYMENT_CAPTURE_PLAN_BUILT_NO_REAL_CAPTURE"
	PaymentCaptureLiveReadyStatusBlocked             = "BLOCKED"
	PaymentCaptureLiveReadyStatusClosed              = "CLOSED"
	PaymentCaptureLiveReadyStatusRequirementReady    = "REQUIRED_READY"
	PaymentCaptureLiveReadyStatusRequirementNotReady = "REQUIRED_NOT_READY"
	PaymentCaptureLiveReadyStatusProductionLocked    = "PRODUCTION_PAYMENT_CAPTURE_LOCKED_IN_FAZ_7_15"
	PaymentCaptureLiveReadyStatusIdempotent          = "IDEMPOTENT"
	PaymentCaptureLiveReadyStatusRetryReady          = "RETRY_READY"
	PaymentCaptureLiveReadyStatusDLQReady            = "DLQ_READY"
	PaymentCaptureLiveReadyStatusWebhookReady        = "WEBHOOK_READY"
	PaymentCaptureLiveReadyStatusAuditReady          = "AUDIT_READY"
	PaymentCaptureLiveReadyStatusRollbackReady       = "ROLLBACK_READY"

	PaymentCaptureClosedUntilPaymentLiveModule    = "CLOSED_UNTIL_PAYMENT_LIVE_MODULE"
	PaymentCaptureClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	PaymentCaptureClosedUntilApprovalMatrix       = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	PaymentCaptureClosedUntilWebhookLiveModule    = "CLOSED_UNTIL_WEBHOOK_LIVE_MODULE"
	PaymentCaptureClosedUntilSettlementLiveModule = "CLOSED_UNTIL_SETTLEMENT_LIVE_MODULE"

	PaymentCaptureNoRealAuthorizationPolicy = "NO_REAL_PAYMENT_AUTHORIZATION_IN_FAZ_7_15"
	PaymentCaptureNoRealCapturePolicy       = "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_15"
	PaymentCaptureNoRealRefundPolicy        = "NO_REAL_PAYMENT_REFUND_IN_FAZ_7_15"
	PaymentCaptureNoRealVoidPolicy          = "NO_REAL_PAYMENT_VOID_IN_FAZ_7_15"
	PaymentCaptureNoRealMoneyPolicy         = "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_15"
	PaymentCaptureNoRealProviderAPIPolicy   = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_15"
	PaymentCaptureNoRealSettlementPolicy    = "NO_REAL_SETTLEMENT_IN_FAZ_7_15"
	PaymentCaptureNoRealWebhookPolicy       = "NO_REAL_PROVIDER_WEBHOOK_INGESTION_IN_FAZ_7_15"

	PaymentRequirementBillingLiveReady         = "billing_live_ready"
	PaymentRequirementProviderContractReady    = "provider_contract_ready"
	PaymentRequirementPaymentAttemptReady      = "payment_attempt_model_ready"
	PaymentRequirementAuthorizationReady       = "authorization_plan_ready"
	PaymentRequirementCapturePolicyReady       = "capture_policy_ready"
	PaymentRequirementRefundVoidPolicyReady    = "refund_void_policy_ready"
	PaymentRequirementIdempotencyReady         = "payment_idempotency_ready"
	PaymentRequirementRetryDLQReady            = "payment_retry_dlq_ready"
	PaymentRequirementWebhookVerificationReady = "webhook_verification_ready"
	PaymentRequirementAuditReady               = "payment_audit_ready"
	PaymentRequirementRollbackReady            = "payment_rollback_ready"
	PaymentRequirementLegalApprovalReady       = "legal_approval_gate_ready"
	PaymentRequirementFinanceApprovalReady     = "finance_approval_gate_ready"
	PaymentRequirementSecurityApprovalReady    = "security_gate_ready"
	PaymentRequirementObservabilityReady       = "payment_observability_ready"
)

var ErrPaymentCaptureRealOperationClosed = errors.New("payment capture real operation is closed in FAZ 7-15")

type PaymentCaptureLiveReadyGate struct {
	ProductionPaymentAllowed    bool `json:"production_payment_allowed"`
	RealAuthorizationAllowed    bool `json:"real_authorization_allowed"`
	RealCaptureAllowed          bool `json:"real_capture_allowed"`
	RealRefundAllowed           bool `json:"real_refund_allowed"`
	RealVoidAllowed             bool `json:"real_void_allowed"`
	RealMoneyMovementAllowed    bool `json:"real_money_movement_allowed"`
	RealProviderAPICallAllowed  bool `json:"real_provider_api_call_allowed"`
	RealSettlementAllowed       bool `json:"real_settlement_allowed"`
	RealWebhookIngestionAllowed bool `json:"real_webhook_ingestion_allowed"`

	PaymentLiveModuleStatus    string `json:"payment_live_module_status"`
	ProviderLiveModuleStatus   string `json:"provider_live_module_status"`
	ApprovalMatrixStatus       string `json:"approval_matrix_status"`
	WebhookLiveModuleStatus    string `json:"webhook_live_module_status"`
	SettlementLiveModuleStatus string `json:"settlement_live_module_status"`
	ProductionPaymentLock      string `json:"production_payment_lock"`
	ControlPlaneGate           string `json:"control_plane_gate"`
}

func DefaultPaymentCaptureLiveReadyGate() PaymentCaptureLiveReadyGate {
	return PaymentCaptureLiveReadyGate{
		ProductionPaymentAllowed:    false,
		RealAuthorizationAllowed:    false,
		RealCaptureAllowed:          false,
		RealRefundAllowed:           false,
		RealVoidAllowed:             false,
		RealMoneyMovementAllowed:    false,
		RealProviderAPICallAllowed:  false,
		RealSettlementAllowed:       false,
		RealWebhookIngestionAllowed: false,

		PaymentLiveModuleStatus:    PaymentCaptureLiveReadyStatusReady,
		ProviderLiveModuleStatus:   PaymentCaptureClosedUntilProviderLiveModule,
		ApprovalMatrixStatus:       PaymentCaptureClosedUntilApprovalMatrix,
		WebhookLiveModuleStatus:    PaymentCaptureClosedUntilWebhookLiveModule,
		SettlementLiveModuleStatus: PaymentCaptureClosedUntilSettlementLiveModule,
		ProductionPaymentLock:      PaymentCaptureLiveReadyStatusProductionLocked,
		ControlPlaneGate:           CommercialLiveReadyGateReady,
	}
}

func (g PaymentCaptureLiveReadyGate) AssertRealPaymentClosed() error {
	checks := map[string]bool{
		"production_payment_allowed":     g.ProductionPaymentAllowed,
		"real_authorization_allowed":     g.RealAuthorizationAllowed,
		"real_capture_allowed":           g.RealCaptureAllowed,
		"real_refund_allowed":            g.RealRefundAllowed,
		"real_void_allowed":              g.RealVoidAllowed,
		"real_money_movement_allowed":    g.RealMoneyMovementAllowed,
		"real_provider_api_call_allowed": g.RealProviderAPICallAllowed,
		"real_settlement_allowed":        g.RealSettlementAllowed,
		"real_webhook_ingestion_allowed": g.RealWebhookIngestionAllowed,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-15", name)
		}
	}
	if g.ProductionPaymentLock != PaymentCaptureLiveReadyStatusProductionLocked {
		return fmt.Errorf("production payment lock must remain %s", PaymentCaptureLiveReadyStatusProductionLocked)
	}
	return nil
}

type PaymentCaptureLiveReadyInput struct {
	BillingLiveReady         bool
	ProviderContractReady    bool
	PaymentAttemptModelReady bool
	AuthorizationPlanReady   bool
	CapturePolicyReady       bool
	RefundVoidPolicyReady    bool
	IdempotencyReady         bool
	RetryDLQReady            bool
	WebhookVerificationReady bool
	AuditReady               bool
	RollbackReady            bool
	LegalApprovalReady       bool
	FinanceApprovalReady     bool
	SecurityApprovalReady    bool
	ObservabilityReady       bool
}

type PaymentCaptureLiveReadyRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type PaymentCapturePlanRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	BillingPlanID      string
	PaymentAttemptID   string
	ProviderCode       string
	Currency           string
	AmountMinor        int
	IdempotencyKey     string
	CaptureMode        string
}

type PaymentCapturePlan struct {
	PlanID                        string    `json:"plan_id"`
	ModuleCode                    string    `json:"module_code"`
	Mode                          string    `json:"mode"`
	AccountantTenantID            string    `json:"accountant_tenant_id"`
	FirmTenantID                  string    `json:"firm_tenant_id"`
	BillingPlanID                 string    `json:"billing_plan_id"`
	PaymentAttemptID              string    `json:"payment_attempt_id"`
	ProviderCode                  string    `json:"provider_code"`
	Currency                      string    `json:"currency"`
	AmountMinor                   int       `json:"amount_minor"`
	IdempotencyKey                string    `json:"idempotency_key"`
	CaptureMode                   string    `json:"capture_mode"`
	Status                        string    `json:"status"`
	RetryPolicyStatus             string    `json:"retry_policy_status"`
	DLQPolicyStatus               string    `json:"dlq_policy_status"`
	WebhookVerificationStatus     string    `json:"webhook_verification_status"`
	RealAuthorizationRequested    bool      `json:"real_authorization_requested"`
	RealCaptureRequested          bool      `json:"real_capture_requested"`
	RealRefundRequested           bool      `json:"real_refund_requested"`
	RealVoidRequested             bool      `json:"real_void_requested"`
	RealMoneyMovementAllowed      bool      `json:"real_money_movement_allowed"`
	RealProviderAPICallRequested  bool      `json:"real_provider_api_call_requested"`
	RealSettlementRequested       bool      `json:"real_settlement_requested"`
	RealWebhookIngestionRequested bool      `json:"real_webhook_ingestion_requested"`
	LiveOperationPolicy           string    `json:"live_operation_policy"`
	CreatedAt                     time.Time `json:"created_at"`
}

type PaymentCaptureLiveReadyReport struct {
	ModuleCode                 string                               `json:"module_code"`
	Mode                       string                               `json:"mode"`
	Status                     string                               `json:"status"`
	Gate                       PaymentCaptureLiveReadyGate          `json:"gate"`
	Requirements               []PaymentCaptureLiveReadyRequirement `json:"requirements"`
	LiveOperationPolicies      map[string]string                    `json:"live_operation_policies"`
	ProductionPaymentAllowed   bool                                 `json:"production_payment_allowed"`
	RealAuthorizationAllowed   bool                                 `json:"real_authorization_allowed"`
	RealCaptureAllowed         bool                                 `json:"real_capture_allowed"`
	RealRefundAllowed          bool                                 `json:"real_refund_allowed"`
	RealVoidAllowed            bool                                 `json:"real_void_allowed"`
	RealMoneyMovementAllowed   bool                                 `json:"real_money_movement_allowed"`
	RealProviderAPICallAllowed bool                                 `json:"real_provider_api_call_allowed"`
	NextModule                 string                               `json:"next_module"`
	CreatedAt                  time.Time                            `json:"created_at"`
}

type PaymentCaptureAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id,omitempty"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type PaymentCaptureLiveReadyRuntime struct {
	gate        PaymentCaptureLiveReadyGate
	plans       map[string]PaymentCapturePlan
	auditEvents []PaymentCaptureAuditEvent
	now         func() time.Time
}

func NewDefaultPaymentCaptureLiveReadyRuntime() *PaymentCaptureLiveReadyRuntime {
	return &PaymentCaptureLiveReadyRuntime{
		gate:        DefaultPaymentCaptureLiveReadyGate(),
		plans:       map[string]PaymentCapturePlan{},
		auditEvents: []PaymentCaptureAuditEvent{},
		now:         time.Now,
	}
}

func (r *PaymentCaptureLiveReadyRuntime) BuildPaymentCaptureLiveReadyReport(input PaymentCaptureLiveReadyInput) (PaymentCaptureLiveReadyReport, error) {
	if err := r.gate.AssertRealPaymentClosed(); err != nil {
		r.appendAudit("PAYMENT_CAPTURE_LIVE_READY_REPORT_DENIED", "", "", PaymentCaptureLiveReadyStatusBlocked, err.Error())
		return PaymentCaptureLiveReadyReport{}, err
	}
	report := PaymentCaptureLiveReadyReport{
		ModuleCode:                 PaymentCaptureLiveReadyModuleCode,
		Mode:                       PaymentCaptureLiveReadyMode,
		Status:                     PaymentCaptureLiveReadyStatusReady,
		Gate:                       r.gate,
		Requirements:               BuildPaymentCaptureLiveReadyRequirements(input),
		LiveOperationPolicies:      DefaultPaymentCaptureLiveReadyPolicies(),
		ProductionPaymentAllowed:   false,
		RealAuthorizationAllowed:   false,
		RealCaptureAllowed:         false,
		RealRefundAllowed:          false,
		RealVoidAllowed:            false,
		RealMoneyMovementAllowed:   false,
		RealProviderAPICallAllowed: false,
		NextModule:                 "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS",
		CreatedAt:                  r.now().UTC(),
	}
	r.appendAudit("PAYMENT_CAPTURE_LIVE_READY_REPORT_BUILT", "", "", PaymentCaptureLiveReadyStatusReady, "")
	return report, nil
}

func (r *PaymentCaptureLiveReadyRuntime) BuildCapturePlan(req PaymentCapturePlanRequest) (PaymentCapturePlan, error) {
	if err := r.gate.AssertRealPaymentClosed(); err != nil {
		r.appendAudit("PAYMENT_CAPTURE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, PaymentCaptureLiveReadyStatusBlocked, err.Error())
		return PaymentCapturePlan{}, err
	}
	if err := validatePaymentCapturePlanRequest(req); err != nil {
		r.appendAudit("PAYMENT_CAPTURE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, PaymentCaptureLiveReadyStatusBlocked, err.Error())
		return PaymentCapturePlan{}, err
	}
	key := paymentCapturePlanKey(req.AccountantTenantID, req.FirmTenantID, req.PaymentAttemptID, req.IdempotencyKey)
	if existing, ok := r.plans[key]; ok {
		r.appendAudit("PAYMENT_CAPTURE_PLAN_IDEMPOTENCY_REPLAY", req.AccountantTenantID, req.FirmTenantID, PaymentCaptureLiveReadyStatusIdempotent, "")
		return existing, nil
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	currency := strings.ToUpper(strings.TrimSpace(req.Currency))
	captureMode := strings.ToUpper(strings.TrimSpace(req.CaptureMode))
	if captureMode == "" {
		captureMode = "MANUAL_CAPTURE_READY"
	}
	plan := PaymentCapturePlan{
		PlanID:                        paymentCaptureLiveReadyID("PAYMENT-CAPTURE-PLAN", req.AccountantTenantID, req.FirmTenantID, req.PaymentAttemptID, req.IdempotencyKey),
		ModuleCode:                    PaymentCaptureLiveReadyModuleCode,
		Mode:                          PaymentCaptureLiveReadyMode,
		AccountantTenantID:            req.AccountantTenantID,
		FirmTenantID:                  req.FirmTenantID,
		BillingPlanID:                 req.BillingPlanID,
		PaymentAttemptID:              req.PaymentAttemptID,
		ProviderCode:                  provider,
		Currency:                      currency,
		AmountMinor:                   req.AmountMinor,
		IdempotencyKey:                req.IdempotencyKey,
		CaptureMode:                   captureMode,
		Status:                        PaymentCaptureLiveReadyStatusPlanBuilt,
		RetryPolicyStatus:             PaymentCaptureLiveReadyStatusRetryReady,
		DLQPolicyStatus:               PaymentCaptureLiveReadyStatusDLQReady,
		WebhookVerificationStatus:     PaymentCaptureLiveReadyStatusWebhookReady,
		RealAuthorizationRequested:    false,
		RealCaptureRequested:          false,
		RealRefundRequested:           false,
		RealVoidRequested:             false,
		RealMoneyMovementAllowed:      false,
		RealProviderAPICallRequested:  false,
		RealSettlementRequested:       false,
		RealWebhookIngestionRequested: false,
		LiveOperationPolicy:           PaymentCaptureNoRealCapturePolicy,
		CreatedAt:                     r.now().UTC(),
	}
	r.plans[key] = plan
	r.appendAudit("PAYMENT_CAPTURE_PLAN_BUILT", req.AccountantTenantID, req.FirmTenantID, PaymentCaptureLiveReadyStatusPlanBuilt, "")
	return plan, nil
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealAuthorization() error {
	r.appendAudit("PAYMENT_REAL_AUTHORIZATION_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealAuthorizationPolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealCapture() error {
	r.appendAudit("PAYMENT_REAL_CAPTURE_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealCapturePolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealRefund() error {
	r.appendAudit("PAYMENT_REAL_REFUND_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealRefundPolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealVoid() error {
	r.appendAudit("PAYMENT_REAL_VOID_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealVoidPolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealProviderAPI() error {
	r.appendAudit("PAYMENT_REAL_PROVIDER_API_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealProviderAPIPolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) RequestRealSettlement() error {
	r.appendAudit("PAYMENT_REAL_SETTLEMENT_BLOCKED", "", "", PaymentCaptureLiveReadyStatusClosed, PaymentCaptureNoRealSettlementPolicy)
	return ErrPaymentCaptureRealOperationClosed
}

func (r *PaymentCaptureLiveReadyRuntime) Gate() PaymentCaptureLiveReadyGate {
	return r.gate
}

func (r *PaymentCaptureLiveReadyRuntime) AuditEvents() []PaymentCaptureAuditEvent {
	out := make([]PaymentCaptureAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *PaymentCaptureLiveReadyRuntime) appendAudit(code, accountantTenantID, firmTenantID, status, reason string) {
	r.auditEvents = append(r.auditEvents, PaymentCaptureAuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		Status:             status,
		Reason:             reason,
		CreatedAt:          r.now().UTC(),
	})
}

func BuildPaymentCaptureLiveReadyRequirements(input PaymentCaptureLiveReadyInput) []PaymentCaptureLiveReadyRequirement {
	requirements := []PaymentCaptureLiveReadyRequirement{
		paymentRequirement(PaymentRequirementBillingLiveReady, input.BillingLiveReady, "billing live-ready runtime is prepared"),
		paymentRequirement(PaymentRequirementProviderContractReady, input.ProviderContractReady, "provider contract is prepared"),
		paymentRequirement(PaymentRequirementPaymentAttemptReady, input.PaymentAttemptModelReady, "payment attempt model is prepared"),
		paymentRequirement(PaymentRequirementAuthorizationReady, input.AuthorizationPlanReady, "authorization plan is prepared"),
		paymentRequirement(PaymentRequirementCapturePolicyReady, input.CapturePolicyReady, "capture policy is prepared"),
		paymentRequirement(PaymentRequirementRefundVoidPolicyReady, input.RefundVoidPolicyReady, "refund and void policy is prepared"),
		paymentRequirement(PaymentRequirementIdempotencyReady, input.IdempotencyReady, "payment idempotency guard is prepared"),
		paymentRequirement(PaymentRequirementRetryDLQReady, input.RetryDLQReady, "payment retry and DLQ policy is prepared"),
		paymentRequirement(PaymentRequirementWebhookVerificationReady, input.WebhookVerificationReady, "webhook verification is prepared"),
		paymentRequirement(PaymentRequirementAuditReady, input.AuditReady, "payment audit trail is prepared"),
		paymentRequirement(PaymentRequirementRollbackReady, input.RollbackReady, "payment rollback is prepared"),
		paymentRequirement(PaymentRequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate is modeled"),
		paymentRequirement(PaymentRequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate is modeled"),
		paymentRequirement(PaymentRequirementSecurityApprovalReady, input.SecurityApprovalReady, "security gate is modeled"),
		paymentRequirement(PaymentRequirementObservabilityReady, input.ObservabilityReady, "payment observability is prepared"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingPaymentCaptureLiveReadyRequirements(input PaymentCaptureLiveReadyInput) []string {
	missing := []string{}
	for _, req := range BuildPaymentCaptureLiveReadyRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllPaymentCaptureLiveReadyInput() PaymentCaptureLiveReadyInput {
	return PaymentCaptureLiveReadyInput{
		BillingLiveReady:         true,
		ProviderContractReady:    true,
		PaymentAttemptModelReady: true,
		AuthorizationPlanReady:   true,
		CapturePolicyReady:       true,
		RefundVoidPolicyReady:    true,
		IdempotencyReady:         true,
		RetryDLQReady:            true,
		WebhookVerificationReady: true,
		AuditReady:               true,
		RollbackReady:            true,
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		SecurityApprovalReady:    true,
		ObservabilityReady:       true,
	}
}

func DefaultPaymentCaptureLiveReadyPolicies() map[string]string {
	return map[string]string{
		"authorization":     PaymentCaptureNoRealAuthorizationPolicy,
		"capture":           PaymentCaptureNoRealCapturePolicy,
		"refund":            PaymentCaptureNoRealRefundPolicy,
		"void":              PaymentCaptureNoRealVoidPolicy,
		"money_movement":    PaymentCaptureNoRealMoneyPolicy,
		"provider_api":      PaymentCaptureNoRealProviderAPIPolicy,
		"settlement":        PaymentCaptureNoRealSettlementPolicy,
		"webhook_ingestion": PaymentCaptureNoRealWebhookPolicy,
	}
}

func validatePaymentCapturePlanRequest(req PaymentCapturePlanRequest) error {
	if strings.TrimSpace(req.AccountantTenantID) == "" {
		return errors.New("accountant tenant id is required")
	}
	if strings.TrimSpace(req.FirmTenantID) == "" {
		return errors.New("firm tenant id is required")
	}
	if strings.TrimSpace(req.BillingPlanID) == "" {
		return errors.New("billing plan id is required")
	}
	if strings.TrimSpace(req.PaymentAttemptID) == "" {
		return errors.New("payment attempt id is required")
	}
	if strings.TrimSpace(req.ProviderCode) == "" {
		return errors.New("provider code is required")
	}
	if strings.TrimSpace(req.Currency) == "" {
		return errors.New("currency is required")
	}
	if req.AmountMinor <= 0 {
		return errors.New("amount minor must be positive")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency key is required")
	}
	return nil
}

func paymentRequirement(code string, ready bool, description string) PaymentCaptureLiveReadyRequirement {
	status := PaymentCaptureLiveReadyStatusRequirementNotReady
	if ready {
		status = PaymentCaptureLiveReadyStatusRequirementReady
	}
	return PaymentCaptureLiveReadyRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func paymentCapturePlanKey(accountantTenantID, firmTenantID, paymentAttemptID, idempotencyKey string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + paymentAttemptID + "|" + idempotencyKey
}

func paymentCaptureLiveReadyID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
