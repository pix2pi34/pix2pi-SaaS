package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	ProviderLiveAdapterReadinessModuleCode = "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"

	ProviderLiveAdapterReadinessMode = "PROVIDER_LIVE_ADAPTER_READY_WITH_REAL_PROVIDER_API_DISABLED"

	ProviderLiveAdapterReadinessStatusReady                  = "PROVIDER_LIVE_ADAPTER_READINESS_READY"
	ProviderLiveAdapterReadinessStatusPlanBuilt              = "PROVIDER_OPERATION_PLAN_BUILT_NO_REAL_API"
	ProviderLiveAdapterReadinessStatusBlocked                = "BLOCKED"
	ProviderLiveAdapterReadinessStatusClosed                 = "CLOSED"
	ProviderLiveAdapterReadinessStatusRequirementReady       = "REQUIRED_READY"
	ProviderLiveAdapterReadinessStatusRequirementNotReady    = "REQUIRED_NOT_READY"
	ProviderLiveAdapterReadinessStatusProductionLocked       = "PRODUCTION_PROVIDER_API_LOCKED_IN_FAZ_7_16"
	ProviderLiveAdapterReadinessStatusSecretContractReady    = "SECRET_CONTRACT_READY"
	ProviderLiveAdapterReadinessStatusEndpointContractReady  = "ENDPOINT_CONTRACT_READY"
	ProviderLiveAdapterReadinessStatusOperationContractReady = "OPERATION_CONTRACT_READY"
	ProviderLiveAdapterReadinessStatusWebhookContractReady   = "WEBHOOK_CONTRACT_READY"
	ProviderLiveAdapterReadinessStatusRollbackReady          = "ROLLBACK_READY"
	ProviderLiveAdapterReadinessStatusAuditReady             = "AUDIT_READY"
	ProviderLiveAdapterReadinessStatusDryRunSealed           = "DRY_RUN_SEALED"

	ProviderLiveAdapterClosedUntilProviderLiveModule = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	ProviderLiveAdapterClosedUntilSecretApproval     = "CLOSED_UNTIL_SECRET_APPROVAL"
	ProviderLiveAdapterClosedUntilApprovalMatrix     = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	ProviderLiveAdapterClosedUntilWebhookLiveModule  = "CLOSED_UNTIL_WEBHOOK_LIVE_MODULE"
	ProviderLiveAdapterClosedUntilFileDeliveryModule = "CLOSED_UNTIL_FILE_DELIVERY_LIVE_MODULE"
	ProviderLiveAdapterClosedUntilERPWriteModule     = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"

	ProviderLiveAdapterNoRealProviderAPIPolicy    = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealSecretUsePolicy      = "NO_REAL_PROVIDER_SECRET_USE_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealWebhookPolicy        = "NO_REAL_PROVIDER_WEBHOOK_INGESTION_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealFileDeliveryPolicy   = "NO_REAL_FILE_DELIVERY_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealERPWritePolicy       = "NO_REAL_ERP_WRITE_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealCustomerDataPolicy   = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_16"
	ProviderLiveAdapterNoRealOperatorActionPolicy = "NO_REAL_OPERATOR_PROVIDER_ACTION_IN_FAZ_7_16"

	ProviderRequirementPaymentCaptureReady    = "payment_capture_live_ready"
	ProviderRequirementAdapterInterfaceReady  = "provider_adapter_interface_ready"
	ProviderRequirementSecretContractReady    = "provider_secret_contract_ready"
	ProviderRequirementEndpointContractReady  = "provider_endpoint_contract_ready"
	ProviderRequirementOperationContractReady = "provider_operation_contract_ready"
	ProviderRequirementWebhookContractReady   = "provider_webhook_contract_ready"
	ProviderRequirementRetryDLQReady          = "provider_retry_dlq_ready"
	ProviderRequirementIdempotencyReady       = "provider_idempotency_ready"
	ProviderRequirementAuditReady             = "provider_audit_ready"
	ProviderRequirementRollbackReady          = "provider_rollback_ready"
	ProviderRequirementLegalApprovalReady     = "legal_approval_gate_ready"
	ProviderRequirementFinanceApprovalReady   = "finance_approval_gate_ready"
	ProviderRequirementSecurityApprovalReady  = "security_gate_ready"
	ProviderRequirementObservabilityReady     = "provider_observability_ready"

	ProviderCodeParasut = "PARASUT"
	ProviderCodeLogo    = "LOGO"
	ProviderCodeMikro   = "MIKRO"
	ProviderCodeZirve   = "ZIRVE"
)

var ErrProviderLiveAdapterRealOperationClosed = errors.New("provider live adapter real operation is closed in FAZ 7-16")

type ProviderLiveAdapterReadinessGate struct {
	ProductionProviderAPIAllowed      bool `json:"production_provider_api_allowed"`
	RealProviderAPICallAllowed        bool `json:"real_provider_api_call_allowed"`
	RealProviderSecretUseAllowed      bool `json:"real_provider_secret_use_allowed"`
	RealWebhookIngestionAllowed       bool `json:"real_webhook_ingestion_allowed"`
	RealFileDeliveryAllowed           bool `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed               bool `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed     bool `json:"real_customer_data_export_allowed"`
	RealOperatorProviderActionAllowed bool `json:"real_operator_provider_action_allowed"`

	ProviderLiveModuleStatus string `json:"provider_live_module_status"`
	SecretApprovalStatus     string `json:"secret_approval_status"`
	ApprovalMatrixStatus     string `json:"approval_matrix_status"`
	WebhookLiveModuleStatus  string `json:"webhook_live_module_status"`
	FileDeliveryModuleStatus string `json:"file_delivery_module_status"`
	ERPWriteModuleStatus     string `json:"erp_write_module_status"`
	ProductionProviderLock   string `json:"production_provider_lock"`
	ControlPlaneGate         string `json:"control_plane_gate"`
	ProviderDryRunSet        string `json:"provider_dry_run_set"`
}

func DefaultProviderLiveAdapterReadinessGate() ProviderLiveAdapterReadinessGate {
	return ProviderLiveAdapterReadinessGate{
		ProductionProviderAPIAllowed:      false,
		RealProviderAPICallAllowed:        false,
		RealProviderSecretUseAllowed:      false,
		RealWebhookIngestionAllowed:       false,
		RealFileDeliveryAllowed:           false,
		RealERPWriteAllowed:               false,
		RealCustomerDataExportAllowed:     false,
		RealOperatorProviderActionAllowed: false,

		ProviderLiveModuleStatus: ProviderLiveAdapterReadinessStatusReady,
		SecretApprovalStatus:     ProviderLiveAdapterClosedUntilSecretApproval,
		ApprovalMatrixStatus:     ProviderLiveAdapterClosedUntilApprovalMatrix,
		WebhookLiveModuleStatus:  ProviderLiveAdapterClosedUntilWebhookLiveModule,
		FileDeliveryModuleStatus: ProviderLiveAdapterClosedUntilFileDeliveryModule,
		ERPWriteModuleStatus:     ProviderLiveAdapterClosedUntilERPWriteModule,
		ProductionProviderLock:   ProviderLiveAdapterReadinessStatusProductionLocked,
		ControlPlaneGate:         CommercialLiveReadyGateReady,
		ProviderDryRunSet:        CommercialLiveReadyProviderDryRunSet,
	}
}

func (g ProviderLiveAdapterReadinessGate) AssertRealProviderOperationsClosed() error {
	checks := map[string]bool{
		"production_provider_api_allowed":       g.ProductionProviderAPIAllowed,
		"real_provider_api_call_allowed":        g.RealProviderAPICallAllowed,
		"real_provider_secret_use_allowed":      g.RealProviderSecretUseAllowed,
		"real_webhook_ingestion_allowed":        g.RealWebhookIngestionAllowed,
		"real_file_delivery_allowed":            g.RealFileDeliveryAllowed,
		"real_erp_write_allowed":                g.RealERPWriteAllowed,
		"real_customer_data_export_allowed":     g.RealCustomerDataExportAllowed,
		"real_operator_provider_action_allowed": g.RealOperatorProviderActionAllowed,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-16", name)
		}
	}
	if g.ProductionProviderLock != ProviderLiveAdapterReadinessStatusProductionLocked {
		return fmt.Errorf("production provider lock must remain %s", ProviderLiveAdapterReadinessStatusProductionLocked)
	}
	return nil
}

type ProviderLiveAdapterReadinessInput struct {
	PaymentCaptureReady    bool
	AdapterInterfaceReady  bool
	SecretContractReady    bool
	EndpointContractReady  bool
	OperationContractReady bool
	WebhookContractReady   bool
	RetryDLQReady          bool
	IdempotencyReady       bool
	AuditReady             bool
	RollbackReady          bool
	LegalApprovalReady     bool
	FinanceApprovalReady   bool
	SecurityApprovalReady  bool
	ObservabilityReady     bool
}

type ProviderLiveAdapterRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type ProviderSecretContract struct {
	ProviderCode     string `json:"provider_code"`
	SecretRef        string `json:"secret_ref"`
	RotationPolicy   string `json:"rotation_policy"`
	SecretUseAllowed bool   `json:"secret_use_allowed"`
	Status           string `json:"status"`
}

type ProviderEndpointContract struct {
	ProviderCode        string   `json:"provider_code"`
	BaseURLRef          string   `json:"base_url_ref"`
	Operations          []string `json:"operations"`
	RealEndpointAllowed bool     `json:"real_endpoint_allowed"`
	Status              string   `json:"status"`
}

type ProviderOperationPlanRequest struct {
	ProviderCode      string
	OperationCode     string
	CorrelationID     string
	IdempotencyKey    string
	TenantID          string
	DryRunReferenceID string
}

type ProviderOperationPlan struct {
	PlanID                          string    `json:"plan_id"`
	ModuleCode                      string    `json:"module_code"`
	Mode                            string    `json:"mode"`
	ProviderCode                    string    `json:"provider_code"`
	OperationCode                   string    `json:"operation_code"`
	CorrelationID                   string    `json:"correlation_id"`
	IdempotencyKey                  string    `json:"idempotency_key"`
	TenantID                        string    `json:"tenant_id"`
	DryRunReferenceID               string    `json:"dry_run_reference_id"`
	Status                          string    `json:"status"`
	SecretContractStatus            string    `json:"secret_contract_status"`
	EndpointContractStatus          string    `json:"endpoint_contract_status"`
	OperationContractStatus         string    `json:"operation_contract_status"`
	WebhookContractStatus           string    `json:"webhook_contract_status"`
	RollbackStatus                  string    `json:"rollback_status"`
	RealProviderAPICallRequested    bool      `json:"real_provider_api_call_requested"`
	RealProviderSecretUseRequested  bool      `json:"real_provider_secret_use_requested"`
	RealWebhookIngestionRequested   bool      `json:"real_webhook_ingestion_requested"`
	RealFileDeliveryRequested       bool      `json:"real_file_delivery_requested"`
	RealERPWriteRequested           bool      `json:"real_erp_write_requested"`
	RealCustomerDataExportRequested bool      `json:"real_customer_data_export_requested"`
	LiveOperationPolicy             string    `json:"live_operation_policy"`
	CreatedAt                       time.Time `json:"created_at"`
}

type ProviderLiveAdapterReadinessReport struct {
	ModuleCode                   string                           `json:"module_code"`
	Mode                         string                           `json:"mode"`
	Status                       string                           `json:"status"`
	Gate                         ProviderLiveAdapterReadinessGate `json:"gate"`
	Requirements                 []ProviderLiveAdapterRequirement `json:"requirements"`
	SecretContracts              []ProviderSecretContract         `json:"secret_contracts"`
	EndpointContracts            []ProviderEndpointContract       `json:"endpoint_contracts"`
	SupportedProviders           []string                         `json:"supported_providers"`
	LiveOperationPolicies        map[string]string                `json:"live_operation_policies"`
	ProductionProviderAPIAllowed bool                             `json:"production_provider_api_allowed"`
	RealProviderAPICallAllowed   bool                             `json:"real_provider_api_call_allowed"`
	RealProviderSecretUseAllowed bool                             `json:"real_provider_secret_use_allowed"`
	RealWebhookIngestionAllowed  bool                             `json:"real_webhook_ingestion_allowed"`
	RealFileDeliveryAllowed      bool                             `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed          bool                             `json:"real_erp_write_allowed"`
	NextModule                   string                           `json:"next_module"`
	CreatedAt                    time.Time                        `json:"created_at"`
}

type ProviderLiveAdapterAuditEvent struct {
	EventCode    string    `json:"event_code"`
	ProviderCode string    `json:"provider_code,omitempty"`
	TenantID     string    `json:"tenant_id,omitempty"`
	Status       string    `json:"status"`
	Reason       string    `json:"reason,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type ProviderLiveAdapterReadinessRuntime struct {
	gate        ProviderLiveAdapterReadinessGate
	plans       map[string]ProviderOperationPlan
	auditEvents []ProviderLiveAdapterAuditEvent
	now         func() time.Time
}

func NewDefaultProviderLiveAdapterReadinessRuntime() *ProviderLiveAdapterReadinessRuntime {
	return &ProviderLiveAdapterReadinessRuntime{
		gate:        DefaultProviderLiveAdapterReadinessGate(),
		plans:       map[string]ProviderOperationPlan{},
		auditEvents: []ProviderLiveAdapterAuditEvent{},
		now:         time.Now,
	}
}

func (r *ProviderLiveAdapterReadinessRuntime) BuildProviderLiveAdapterReadinessReport(input ProviderLiveAdapterReadinessInput) (ProviderLiveAdapterReadinessReport, error) {
	if err := r.gate.AssertRealProviderOperationsClosed(); err != nil {
		r.appendAudit("PROVIDER_LIVE_ADAPTER_READINESS_REPORT_DENIED", "", "", ProviderLiveAdapterReadinessStatusBlocked, err.Error())
		return ProviderLiveAdapterReadinessReport{}, err
	}
	report := ProviderLiveAdapterReadinessReport{
		ModuleCode:                   ProviderLiveAdapterReadinessModuleCode,
		Mode:                         ProviderLiveAdapterReadinessMode,
		Status:                       ProviderLiveAdapterReadinessStatusReady,
		Gate:                         r.gate,
		Requirements:                 BuildProviderLiveAdapterRequirements(input),
		SecretContracts:              DefaultProviderSecretContracts(),
		EndpointContracts:            DefaultProviderEndpointContracts(),
		SupportedProviders:           SupportedLiveReadyProviders(),
		LiveOperationPolicies:        DefaultProviderLiveAdapterPolicies(),
		ProductionProviderAPIAllowed: false,
		RealProviderAPICallAllowed:   false,
		RealProviderSecretUseAllowed: false,
		RealWebhookIngestionAllowed:  false,
		RealFileDeliveryAllowed:      false,
		RealERPWriteAllowed:          false,
		NextModule:                   "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE",
		CreatedAt:                    r.now().UTC(),
	}
	r.appendAudit("PROVIDER_LIVE_ADAPTER_READINESS_REPORT_BUILT", "", "", ProviderLiveAdapterReadinessStatusReady, "")
	return report, nil
}

func (r *ProviderLiveAdapterReadinessRuntime) BuildProviderOperationPlan(req ProviderOperationPlanRequest) (ProviderOperationPlan, error) {
	if err := r.gate.AssertRealProviderOperationsClosed(); err != nil {
		r.appendAudit("PROVIDER_OPERATION_PLAN_DENIED", req.ProviderCode, req.TenantID, ProviderLiveAdapterReadinessStatusBlocked, err.Error())
		return ProviderOperationPlan{}, err
	}
	if err := validateProviderOperationPlanRequest(req); err != nil {
		r.appendAudit("PROVIDER_OPERATION_PLAN_DENIED", req.ProviderCode, req.TenantID, ProviderLiveAdapterReadinessStatusBlocked, err.Error())
		return ProviderOperationPlan{}, err
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	operation := strings.ToUpper(strings.TrimSpace(req.OperationCode))
	key := providerOperationPlanKey(provider, operation, req.TenantID, req.IdempotencyKey)
	if existing, ok := r.plans[key]; ok {
		r.appendAudit("PROVIDER_OPERATION_PLAN_IDEMPOTENCY_REPLAY", provider, req.TenantID, ProviderLiveAdapterReadinessStatusReady, "")
		return existing, nil
	}
	plan := ProviderOperationPlan{
		PlanID:                          providerLiveAdapterID("PROVIDER-OPERATION-PLAN", provider, operation, req.TenantID, req.IdempotencyKey),
		ModuleCode:                      ProviderLiveAdapterReadinessModuleCode,
		Mode:                            ProviderLiveAdapterReadinessMode,
		ProviderCode:                    provider,
		OperationCode:                   operation,
		CorrelationID:                   req.CorrelationID,
		IdempotencyKey:                  req.IdempotencyKey,
		TenantID:                        req.TenantID,
		DryRunReferenceID:               req.DryRunReferenceID,
		Status:                          ProviderLiveAdapterReadinessStatusPlanBuilt,
		SecretContractStatus:            ProviderLiveAdapterReadinessStatusSecretContractReady,
		EndpointContractStatus:          ProviderLiveAdapterReadinessStatusEndpointContractReady,
		OperationContractStatus:         ProviderLiveAdapterReadinessStatusOperationContractReady,
		WebhookContractStatus:           ProviderLiveAdapterReadinessStatusWebhookContractReady,
		RollbackStatus:                  ProviderLiveAdapterReadinessStatusRollbackReady,
		RealProviderAPICallRequested:    false,
		RealProviderSecretUseRequested:  false,
		RealWebhookIngestionRequested:   false,
		RealFileDeliveryRequested:       false,
		RealERPWriteRequested:           false,
		RealCustomerDataExportRequested: false,
		LiveOperationPolicy:             ProviderLiveAdapterNoRealProviderAPIPolicy,
		CreatedAt:                       r.now().UTC(),
	}
	r.plans[key] = plan
	r.appendAudit("PROVIDER_OPERATION_PLAN_BUILT", provider, req.TenantID, ProviderLiveAdapterReadinessStatusPlanBuilt, "")
	return plan, nil
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealProviderAPI(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_API_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealProviderAPIPolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealProviderSecretUse(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_SECRET_USE_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealSecretUsePolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealWebhookIngestion(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_WEBHOOK_INGESTION_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealWebhookPolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealFileDelivery(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_FILE_DELIVERY_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealFileDeliveryPolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealERPWrite(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_ERP_WRITE_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealERPWritePolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) RequestRealOperatorProviderAction(providerCode string) error {
	r.appendAudit("PROVIDER_REAL_OPERATOR_ACTION_BLOCKED", providerCode, "", ProviderLiveAdapterReadinessStatusClosed, ProviderLiveAdapterNoRealOperatorActionPolicy)
	return ErrProviderLiveAdapterRealOperationClosed
}

func (r *ProviderLiveAdapterReadinessRuntime) Gate() ProviderLiveAdapterReadinessGate {
	return r.gate
}

func (r *ProviderLiveAdapterReadinessRuntime) AuditEvents() []ProviderLiveAdapterAuditEvent {
	out := make([]ProviderLiveAdapterAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *ProviderLiveAdapterReadinessRuntime) appendAudit(code, providerCode, tenantID, status, reason string) {
	r.auditEvents = append(r.auditEvents, ProviderLiveAdapterAuditEvent{
		EventCode:    code,
		ProviderCode: strings.ToUpper(strings.TrimSpace(providerCode)),
		TenantID:     tenantID,
		Status:       status,
		Reason:       reason,
		CreatedAt:    r.now().UTC(),
	})
}

func BuildProviderLiveAdapterRequirements(input ProviderLiveAdapterReadinessInput) []ProviderLiveAdapterRequirement {
	requirements := []ProviderLiveAdapterRequirement{
		providerRequirement(ProviderRequirementPaymentCaptureReady, input.PaymentCaptureReady, "payment capture live-ready runtime is prepared"),
		providerRequirement(ProviderRequirementAdapterInterfaceReady, input.AdapterInterfaceReady, "provider adapter interface is prepared"),
		providerRequirement(ProviderRequirementSecretContractReady, input.SecretContractReady, "provider secret contract is prepared"),
		providerRequirement(ProviderRequirementEndpointContractReady, input.EndpointContractReady, "provider endpoint contract is prepared"),
		providerRequirement(ProviderRequirementOperationContractReady, input.OperationContractReady, "provider operation contract is prepared"),
		providerRequirement(ProviderRequirementWebhookContractReady, input.WebhookContractReady, "provider webhook contract is prepared"),
		providerRequirement(ProviderRequirementRetryDLQReady, input.RetryDLQReady, "provider retry and DLQ policy is prepared"),
		providerRequirement(ProviderRequirementIdempotencyReady, input.IdempotencyReady, "provider idempotency is prepared"),
		providerRequirement(ProviderRequirementAuditReady, input.AuditReady, "provider audit trail is prepared"),
		providerRequirement(ProviderRequirementRollbackReady, input.RollbackReady, "provider rollback policy is prepared"),
		providerRequirement(ProviderRequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate is modeled"),
		providerRequirement(ProviderRequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate is modeled"),
		providerRequirement(ProviderRequirementSecurityApprovalReady, input.SecurityApprovalReady, "security approval gate is modeled"),
		providerRequirement(ProviderRequirementObservabilityReady, input.ObservabilityReady, "provider observability is prepared"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingProviderLiveAdapterRequirements(input ProviderLiveAdapterReadinessInput) []string {
	missing := []string{}
	for _, req := range BuildProviderLiveAdapterRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllProviderLiveAdapterReadinessInput() ProviderLiveAdapterReadinessInput {
	return ProviderLiveAdapterReadinessInput{
		PaymentCaptureReady:    true,
		AdapterInterfaceReady:  true,
		SecretContractReady:    true,
		EndpointContractReady:  true,
		OperationContractReady: true,
		WebhookContractReady:   true,
		RetryDLQReady:          true,
		IdempotencyReady:       true,
		AuditReady:             true,
		RollbackReady:          true,
		LegalApprovalReady:     true,
		FinanceApprovalReady:   true,
		SecurityApprovalReady:  true,
		ObservabilityReady:     true,
	}
}

func SupportedLiveReadyProviders() []string {
	return []string{ProviderCodeLogo, ProviderCodeMikro, ProviderCodeParasut, ProviderCodeZirve}
}

func DefaultProviderSecretContracts() []ProviderSecretContract {
	contracts := []ProviderSecretContract{}
	for _, provider := range SupportedLiveReadyProviders() {
		contracts = append(contracts, ProviderSecretContract{
			ProviderCode:     provider,
			SecretRef:        "secret://pix2pi/provider/" + strings.ToLower(provider) + "/production",
			RotationPolicy:   "ROTATION_REQUIRED_BEFORE_LIVE",
			SecretUseAllowed: false,
			Status:           ProviderLiveAdapterReadinessStatusSecretContractReady,
		})
	}
	return contracts
}

func DefaultProviderEndpointContracts() []ProviderEndpointContract {
	contracts := []ProviderEndpointContract{}
	for _, provider := range SupportedLiveReadyProviders() {
		contracts = append(contracts, ProviderEndpointContract{
			ProviderCode:        provider,
			BaseURLRef:          "config://provider/" + strings.ToLower(provider) + "/base_url",
			Operations:          []string{"AUTHORIZE", "CAPTURE", "REFUND", "VOID", "WEBHOOK_VERIFY", "EXPORT_DELIVERY"},
			RealEndpointAllowed: false,
			Status:              ProviderLiveAdapterReadinessStatusEndpointContractReady,
		})
	}
	return contracts
}

func DefaultProviderLiveAdapterPolicies() map[string]string {
	return map[string]string{
		"provider_api":      ProviderLiveAdapterNoRealProviderAPIPolicy,
		"secret_use":        ProviderLiveAdapterNoRealSecretUsePolicy,
		"webhook_ingestion": ProviderLiveAdapterNoRealWebhookPolicy,
		"file_delivery":     ProviderLiveAdapterNoRealFileDeliveryPolicy,
		"erp_write":         ProviderLiveAdapterNoRealERPWritePolicy,
		"customer_export":   ProviderLiveAdapterNoRealCustomerDataPolicy,
		"operator_action":   ProviderLiveAdapterNoRealOperatorActionPolicy,
	}
}

func validateProviderOperationPlanRequest(req ProviderOperationPlanRequest) error {
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	if !isLiveReadyProvider(provider) {
		return errors.New("unsupported provider code")
	}
	if strings.TrimSpace(req.OperationCode) == "" {
		return errors.New("operation code is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency key is required")
	}
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant id is required")
	}
	if strings.TrimSpace(req.DryRunReferenceID) == "" {
		return errors.New("dry-run reference id is required")
	}
	return nil
}

func isLiveReadyProvider(provider string) bool {
	for _, supported := range SupportedLiveReadyProviders() {
		if provider == supported {
			return true
		}
	}
	return false
}

func providerRequirement(code string, ready bool, description string) ProviderLiveAdapterRequirement {
	status := ProviderLiveAdapterReadinessStatusRequirementNotReady
	if ready {
		status = ProviderLiveAdapterReadinessStatusRequirementReady
	}
	return ProviderLiveAdapterRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func providerOperationPlanKey(provider, operation, tenantID, idempotencyKey string) string {
	return provider + "|" + operation + "|" + tenantID + "|" + idempotencyKey
}

func providerLiveAdapterID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
