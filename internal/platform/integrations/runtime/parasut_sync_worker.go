package integrationruntime

import (
	"fmt"
	"time"
)

type ParasutSyncWorkerStatus string

const (
	ParasutSyncWorkerStatusScheduleReady        ParasutSyncWorkerStatus = "SYNC_JOB_SCHEDULE_READY"
	ParasutSyncWorkerStatusIntegrationDisabled  ParasutSyncWorkerStatus = "INTEGRATION_DISABLED"
	ParasutSyncWorkerStatusTokenActive          ParasutSyncWorkerStatus = "TOKEN_ACTIVE"
	ParasutSyncWorkerStatusTokenRefreshRequired ParasutSyncWorkerStatus = "TOKEN_REFRESH_REQUIRED"
	ParasutSyncWorkerStatusTokenExpired         ParasutSyncWorkerStatus = "TOKEN_EXPIRED"
	ParasutSyncWorkerStatusTokenRevoked         ParasutSyncWorkerStatus = "TOKEN_REVOKED"
	ParasutSyncWorkerStatusAPIDryRunDone        ParasutSyncWorkerStatus = "API_DRY_RUN_DONE"
	ParasutSyncWorkerStatusMappingDone          ParasutSyncWorkerStatus = "MAPPING_DONE"
	ParasutSyncWorkerStatusERPWriteDryRunDone   ParasutSyncWorkerStatus = "ERP_WRITE_DRY_RUN_DONE"
	ParasutSyncWorkerStatusFailureDecisionReady ParasutSyncWorkerStatus = "FAILURE_DECISION_READY"
)

type ParasutSyncJobSchedule struct {
	JobKey                   string
	TenantID                 string
	ProviderKey              string
	AppKey                   string
	Operation                ConnectorOperation
	IntervalSeconds          int
	DryRunOnly               bool
	RealSchedulerEnabled     bool
	RealQueueConsumerEnabled bool
	RequestedBy              string
	CorrelationID            string
	CreatedAt                time.Time
}

func BuildParasutSyncJobSchedule(schedule ParasutSyncJobSchedule) (ParasutSyncJobSchedule, error) {
	if err := validateParasutSyncJobSchedule(schedule); err != nil {
		return ParasutSyncJobSchedule{}, err
	}

	if schedule.IntervalSeconds <= 0 {
		schedule.IntervalSeconds = 900
	}
	if schedule.CreatedAt.IsZero() {
		schedule.CreatedAt = time.Now().UTC()
	}

	schedule.TenantID = normalize(schedule.TenantID)
	schedule.ProviderKey = ParasutProviderKey
	schedule.AppKey = normalize(schedule.AppKey)
	schedule.JobKey = normalize(schedule.JobKey)
	schedule.RequestedBy = normalize(schedule.RequestedBy)
	schedule.CorrelationID = normalize(schedule.CorrelationID)
	schedule.DryRunOnly = true
	schedule.RealSchedulerEnabled = false
	schedule.RealQueueConsumerEnabled = false

	return schedule, nil
}

func validateParasutSyncJobSchedule(schedule ParasutSyncJobSchedule) error {
	if err := requireNonEmpty(schedule.JobKey, "job_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(schedule.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(schedule.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if normalize(schedule.ProviderKey) != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(schedule.AppKey, "app_key"); err != nil {
		return err
	}
	if schedule.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(schedule.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(schedule.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if schedule.RealSchedulerEnabled {
		return fmt.Errorf("%w: real scheduler must remain disabled in sync worker dry-run phase", ErrInvalidIntegrationRequest)
	}
	if schedule.RealQueueConsumerEnabled {
		return fmt.Errorf("%w: real queue consumer must remain disabled in sync worker dry-run phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutTenantIntegrationState struct {
	TenantID  string
	AppKey    string
	Enabled   bool
	Status    string
	UpdatedBy string
	UpdatedAt time.Time
}

func ValidateParasutTenantIntegrationEnabled(state ParasutTenantIntegrationState) error {
	if err := requireNonEmpty(state.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(state.AppKey, "app_key"); err != nil {
		return err
	}
	if !state.Enabled {
		return fmt.Errorf("%w: parasut tenant integration disabled", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutSyncSourceEnvelope struct {
	ObjectType ParasutERPObjectType
	Customer   *ParasutCustomerSource
	Product    *ParasutProductSource
	Invoice    *ParasutInvoiceSource
}

type ParasutSyncWorkerRequest struct {
	Schedule                ParasutSyncJobSchedule
	IntegrationState        ParasutTenantIntegrationState
	TokenLifecycle          ParasutTokenLifecycle
	AccessTokenRef          string
	IdempotencyKey          string
	Source                  ParasutSyncSourceEnvelope
	RequestedBy             string
	CorrelationID           string
	RealProviderAPIEnabled  bool
	RealERPWriteEnabled     bool
	RealTokenRefreshEnabled bool
}

type ParasutSyncWorkerResult struct {
	TenantID        string
	ProviderKey     string
	AppKey          string
	Operation       ConnectorOperation
	ObjectType      ParasutERPObjectType
	Status          ParasutSyncWorkerStatus
	TokenStatus     ParasutTokenStatus
	APIResponse     ParasutAPIDryRunProviderResponse
	MappingRecord   Pix2piERPSyncRecord
	ERPWriteResult  ParasutERPWriteContractResult
	AuditRecorded   bool
	RealProviderAPI bool
	RealERPWrite    bool
	AuditDecision   AuditDecision
	CorrelationID   string
	CreatedAt       time.Time
}

func ExecuteParasutSyncWorkerDryRun(obs *ConnectorObservabilityRuntime, req ParasutSyncWorkerRequest) (ParasutSyncWorkerResult, error) {
	if err := validateParasutSyncWorkerRequest(req); err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := time.Now().UTC()

	if err := ValidateParasutTenantIntegrationEnabled(req.IntegrationState); err != nil {
		return ParasutSyncWorkerResult{
			TenantID:        normalize(req.Schedule.TenantID),
			ProviderKey:     ParasutProviderKey,
			AppKey:          normalize(req.Schedule.AppKey),
			Operation:       req.Schedule.Operation,
			Status:          ParasutSyncWorkerStatusIntegrationDisabled,
			TokenStatus:     req.TokenLifecycle.Status,
			AuditDecision:   AuditDecisionDenied,
			CorrelationID:   normalize(req.CorrelationID),
			CreatedAt:       now,
			RealProviderAPI: false,
			RealERPWrite:    false,
		}, nil
	}

	tokenDecision := EvaluateParasutAccessTokenRefreshNeed(req.TokenLifecycle)
	if tokenDecision.NeedsRefresh || req.TokenLifecycle.Status == ParasutTokenStatusRevoked {
		status := ParasutSyncWorkerStatusTokenRefreshRequired
		if req.TokenLifecycle.Status == ParasutTokenStatusExpired {
			status = ParasutSyncWorkerStatusTokenExpired
		}
		if req.TokenLifecycle.Status == ParasutTokenStatusRevoked {
			status = ParasutSyncWorkerStatusTokenRevoked
		}

		return ParasutSyncWorkerResult{
			TenantID:        normalize(req.Schedule.TenantID),
			ProviderKey:     ParasutProviderKey,
			AppKey:          normalize(req.Schedule.AppKey),
			Operation:       req.Schedule.Operation,
			Status:          status,
			TokenStatus:     req.TokenLifecycle.Status,
			AuditDecision:   AuditDecisionDenied,
			CorrelationID:   normalize(req.CorrelationID),
			CreatedAt:       now,
			RealProviderAPI: false,
			RealERPWrite:    false,
		}, nil
	}

	apiContract, err := BuildParasutAPIClientContract(ParasutAPIClientContractRequest{
		TenantID:       req.Schedule.TenantID,
		AppKey:         req.Schedule.AppKey,
		AccessTokenRef: req.AccessTokenRef,
		RequestedBy:    req.RequestedBy,
		CorrelationID:  req.CorrelationID,
		RealAPIEnabled: req.RealProviderAPIEnabled,
	})
	if err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	apiOperation, err := BuildParasutAPIOperationRequest(apiContract, req.Schedule.Operation, req.IdempotencyKey, buildParasutSyncWorkerPayload(req.Source))
	if err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	apiResponse, err := ExecuteParasutAPIDryRun(apiOperation)
	if err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	if err := RecordParasutAPIOperationAudit(obs, apiResponse); err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	mappingRecord, err := BuildParasutSyncWorkerMapping(req.Source)
	if err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	writeResult, err := BuildParasutERPWriteDryRunContract(ParasutERPWriteContractRequest{
		TenantID:            req.Schedule.TenantID,
		AppKey:              req.Schedule.AppKey,
		Record:              mappingRecord,
		RequestedBy:         req.RequestedBy,
		CorrelationID:       req.CorrelationID,
		RealERPWriteEnabled: req.RealERPWriteEnabled,
	})
	if err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	if err := RecordParasutMappingAudit(obs, writeResult); err != nil {
		return ParasutSyncWorkerResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutSyncWorkerResult{
		TenantID:        normalize(req.Schedule.TenantID),
		ProviderKey:     ParasutProviderKey,
		AppKey:          normalize(req.Schedule.AppKey),
		Operation:       req.Schedule.Operation,
		ObjectType:      mappingRecord.ObjectType,
		Status:          ParasutSyncWorkerStatusERPWriteDryRunDone,
		TokenStatus:     req.TokenLifecycle.Status,
		APIResponse:     apiResponse,
		MappingRecord:   mappingRecord,
		ERPWriteResult:  writeResult,
		AuditRecorded:   true,
		RealProviderAPI: false,
		RealERPWrite:    false,
		AuditDecision:   AuditDecisionAllowed,
		CorrelationID:   normalize(req.CorrelationID),
		CreatedAt:       now,
	}, nil
}

func validateParasutSyncWorkerRequest(req ParasutSyncWorkerRequest) error {
	if _, err := BuildParasutSyncJobSchedule(req.Schedule); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.Schedule.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.IdempotencyKey, "idempotency_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealProviderAPIEnabled {
		return fmt.Errorf("%w: real provider API must remain disabled in sync worker dry-run phase", ErrInvalidIntegrationRequest)
	}
	if req.RealERPWriteEnabled {
		return fmt.Errorf("%w: real ERP write must remain disabled in sync worker dry-run phase", ErrInvalidIntegrationRequest)
	}
	if req.RealTokenRefreshEnabled {
		return fmt.Errorf("%w: real token refresh must remain disabled in sync worker dry-run phase", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutSyncSourceEnvelope(req.Source); err != nil {
		return err
	}
	return nil
}

func validateParasutSyncSourceEnvelope(source ParasutSyncSourceEnvelope) error {
	switch source.ObjectType {
	case ParasutERPObjectCustomer:
		if source.Customer == nil {
			return fmt.Errorf("%w: customer source required", ErrInvalidIntegrationRequest)
		}
	case ParasutERPObjectProduct:
		if source.Product == nil {
			return fmt.Errorf("%w: product source required", ErrInvalidIntegrationRequest)
		}
	case ParasutERPObjectInvoice:
		if source.Invoice == nil {
			return fmt.Errorf("%w: invoice source required", ErrInvalidIntegrationRequest)
		}
	default:
		return fmt.Errorf("%w: unsupported sync source object type", ErrInvalidIntegrationRequest)
	}
	return nil
}

func BuildParasutSyncWorkerMapping(source ParasutSyncSourceEnvelope) (Pix2piERPSyncRecord, error) {
	if err := validateParasutSyncSourceEnvelope(source); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}

	switch source.ObjectType {
	case ParasutERPObjectCustomer:
		return BuildParasutCustomerERPSync(*source.Customer)
	case ParasutERPObjectProduct:
		return BuildParasutProductERPSync(*source.Product)
	case ParasutERPObjectInvoice:
		return BuildParasutInvoiceERPSync(*source.Invoice)
	default:
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: unsupported sync source object type", ErrInvalidIntegrationRequest)
	}
}

func buildParasutSyncWorkerPayload(source ParasutSyncSourceEnvelope) map[string]string {
	payload := map[string]string{
		"mode":        "dry_run",
		"object_type": string(source.ObjectType),
	}

	switch source.ObjectType {
	case ParasutERPObjectCustomer:
		if source.Customer != nil {
			payload["external_object_id"] = source.Customer.ExternalObjectID
			payload["tax_number"] = source.Customer.TaxNumber
		}
	case ParasutERPObjectProduct:
		if source.Product != nil {
			payload["external_object_id"] = source.Product.ExternalObjectID
			payload["sku"] = source.Product.SKU
		}
	case ParasutERPObjectInvoice:
		if source.Invoice != nil {
			payload["external_object_id"] = source.Invoice.ExternalObjectID
			payload["invoice_number"] = source.Invoice.InvoiceNumber
		}
	}

	return payload
}

type ParasutSyncWorkerFailureDecision struct {
	Status        ParasutSyncWorkerStatus
	Mapping       ParasutProviderErrorMapping
	RetryDecision RetryDecision
	DLQReady      bool
	AuditDecision AuditDecision
	CorrelationID string
}

func EvaluateParasutSyncWorkerFailure(req ParasutAPIOperationRequest, httpStatus int, providerMessage string, attempt int) (ParasutSyncWorkerFailureDecision, error) {
	decision, err := EvaluateParasutAPIOperationFailure(req, httpStatus, providerMessage, attempt)
	if err != nil {
		return ParasutSyncWorkerFailureDecision{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutSyncWorkerFailureDecision{
		Status:        ParasutSyncWorkerStatusFailureDecisionReady,
		Mapping:       decision.Mapping,
		RetryDecision: decision.RetryDecision,
		DLQReady:      decision.Mapping.MoveToDLQ,
		AuditDecision: AuditDecisionAllowed,
		CorrelationID: req.CorrelationID,
	}, nil
}

type ParasutSyncWorkerReadinessGateInput struct {
	SyncJobScheduleReady           bool
	TenantIntegrationGateReady     bool
	TokenLifecycleGateReady        bool
	APIOperationOrchestrationReady bool
	DataMappingOrchestrationReady  bool
	ERPWriteDryRunReady            bool
	RetryDLQReady                  bool
	AuditObservabilityReady        bool
	TestsReady                     bool
	RealImplementationAuditReady   bool
	RealProviderAPIEnabled         bool
	RealERPWriteEnabled            bool
	RealSchedulerEnabled           bool
	RealQueueConsumerEnabled       bool
}

type ParasutSyncWorkerReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutSyncWorkerReadinessGate(input ParasutSyncWorkerReadinessGateInput) ParasutSyncWorkerReadinessGateResult {
	blockers := []string{}

	if !input.SyncJobScheduleReady {
		blockers = append(blockers, "sync_job_schedule_not_ready")
	}
	if !input.TenantIntegrationGateReady {
		blockers = append(blockers, "tenant_integration_gate_not_ready")
	}
	if !input.TokenLifecycleGateReady {
		blockers = append(blockers, "token_lifecycle_gate_not_ready")
	}
	if !input.APIOperationOrchestrationReady {
		blockers = append(blockers, "api_operation_orchestration_not_ready")
	}
	if !input.DataMappingOrchestrationReady {
		blockers = append(blockers, "data_mapping_orchestration_not_ready")
	}
	if !input.ERPWriteDryRunReady {
		blockers = append(blockers, "erp_write_dry_run_not_ready")
	}
	if !input.RetryDLQReady {
		blockers = append(blockers, "retry_dlq_not_ready")
	}
	if !input.AuditObservabilityReady {
		blockers = append(blockers, "audit_observability_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_sync_worker_phase")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_sync_worker_phase")
	}
	if input.RealSchedulerEnabled {
		blockers = append(blockers, "real_scheduler_must_remain_false_in_sync_worker_phase")
	}
	if input.RealQueueConsumerEnabled {
		blockers = append(blockers, "real_queue_consumer_must_remain_false_in_sync_worker_phase")
	}

	if len(blockers) > 0 {
		return ParasutSyncWorkerReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutSyncWorkerReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_SYNC_WORKER_DRY_RUN_READY_WITH_REAL_API_AND_ERP_WRITE_CLOSED",
		Blockers: []string{},
	}
}
