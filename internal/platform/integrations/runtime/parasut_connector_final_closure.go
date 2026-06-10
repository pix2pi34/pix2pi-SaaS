package integrationruntime

import (
	"fmt"
	"sort"
	"time"
)

type ParasutConnectorFinalClosureStatus string

const (
	ParasutConnectorFinalClosureStatusPass    ParasutConnectorFinalClosureStatus = "PASS"
	ParasutConnectorFinalClosureStatusBlocked ParasutConnectorFinalClosureStatus = "BLOCKED"
)

type ParasutConnectorRequiredModuleKey string

const (
	ParasutRequiredModuleIntegrationRuntime ParasutConnectorRequiredModuleKey = "FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION"
	ParasutRequiredModuleFoundation         ParasutConnectorRequiredModuleKey = "FAZ_7_8P_PARASUT_CONNECTOR_FOUNDATION"
	ParasutRequiredModuleLiveContract       ParasutConnectorRequiredModuleKey = "FAZ_7_8P_1_PARASUT_LIVE_CONTRACT"
	ParasutRequiredModuleTokenVault         ParasutConnectorRequiredModuleKey = "FAZ_7_8P_2_PARASUT_TOKEN_VAULT"
	ParasutRequiredModuleCredentialUI       ParasutConnectorRequiredModuleKey = "FAZ_7_8P_3_PARASUT_CREDENTIAL_UI"
	ParasutRequiredModuleOAuthFlow          ParasutConnectorRequiredModuleKey = "FAZ_7_8P_4_PARASUT_OAUTH_FLOW"
	ParasutRequiredModuleTokenExchange      ParasutConnectorRequiredModuleKey = "FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE"
	ParasutRequiredModuleAPIClient          ParasutConnectorRequiredModuleKey = "FAZ_7_8P_6_PARASUT_API_CLIENT"
	ParasutRequiredModuleDataMapping        ParasutConnectorRequiredModuleKey = "FAZ_7_8P_7_PARASUT_DATA_MAPPING"
	ParasutRequiredModuleSyncWorker         ParasutConnectorRequiredModuleKey = "FAZ_7_8P_8_PARASUT_SYNC_WORKER"
	ParasutRequiredModuleWebhookTrigger     ParasutConnectorRequiredModuleKey = "FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER"
	ParasutRequiredModuleE2EDryRun          ParasutConnectorRequiredModuleKey = "FAZ_7_8P_10_PARASUT_E2E_DRY_RUN"
	ParasutRequiredModuleAdminOps           ParasutConnectorRequiredModuleKey = "FAZ_7_8P_11_PARASUT_ADMIN_OPS"
)

type ParasutConnectorModuleClosureEvidence struct {
	ModuleKey    ParasutConnectorRequiredModuleKey
	ModuleName   string
	FinalStatus  string
	SealStatus   string
	GateStatus   string
	PassCount    int
	FailCount    int
	RequiredFail int
	OptionalWarn int
	EvidenceFile string
	BackupDir    string
	CompletedAt  time.Time
}

type ParasutConnectorFinalClosureInput struct {
	TenantID                   string
	AppKey                     string
	RequestedBy                string
	CorrelationID              string
	ModuleEvidence             []ParasutConnectorModuleClosureEvidence
	RealProviderAPIEnabled     bool
	RealWebhookEndpointEnabled bool
	RealERPWriteEnabled        bool
	RealQueueTriggerEnabled    bool
	RealTokenExchangeEnabled   bool
	RealTokenRefreshEnabled    bool
	RealRetryJobEnabled        bool
	Now                        time.Time
}

type ParasutConnectorFinalClosureResult struct {
	TenantID                  string
	ProviderKey               string
	AppKey                    string
	Status                    ParasutConnectorFinalClosureStatus
	FinalStatus               string
	ModuleFinalSealStatus     string
	ProviderLiveHandoffGate   string
	RequiredModuleCount       int
	PassedModuleCount         int
	FailedModuleCount         int
	TotalPassCount            int
	TotalFailCount            int
	TotalRequiredFail         int
	TotalOptionalWarn         int
	RealProviderAPI           bool
	RealWebhookEndpoint       bool
	RealERPWrite              bool
	RealQueueTrigger          bool
	RealTokenExchange         bool
	RealTokenRefresh          bool
	RealRetryJob              bool
	RealProviderAPIStatus     string
	RealWebhookEndpointStatus string
	RealERPWriteStatus        string
	RealQueueTriggerStatus    string
	Blockers                  []string
	AuditDecision             AuditDecision
	CorrelationID             string
	CreatedAt                 time.Time
}

type ParasutProviderLiveHandoffPackage struct {
	TenantID                                string
	ProviderKey                             string
	AppKey                                  string
	ProviderLiveModuleHandoffGate           string
	ApprovalRequired                        bool
	RealCredentialSecretRequired            bool
	SandboxLiveCredentialSeparationRequired bool
	RealWebhookEndpointApprovalRequired     bool
	LiveSyncWorkerApprovalRequired          bool
	ProductionRolloutChecklistRequired      bool
	RollbackSafeDisableRequired             bool
	RealProviderAPIStatus                   string
	RealWebhookEndpointStatus               string
	RealERPWriteStatus                      string
	AuditDecision                           AuditDecision
	CorrelationID                           string
	CreatedAt                               time.Time
}

func RequiredParasutConnectorClosureModules() []ParasutConnectorRequiredModuleKey {
	return []ParasutConnectorRequiredModuleKey{
		ParasutRequiredModuleIntegrationRuntime,
		ParasutRequiredModuleFoundation,
		ParasutRequiredModuleLiveContract,
		ParasutRequiredModuleTokenVault,
		ParasutRequiredModuleCredentialUI,
		ParasutRequiredModuleOAuthFlow,
		ParasutRequiredModuleTokenExchange,
		ParasutRequiredModuleAPIClient,
		ParasutRequiredModuleDataMapping,
		ParasutRequiredModuleSyncWorker,
		ParasutRequiredModuleWebhookTrigger,
		ParasutRequiredModuleE2EDryRun,
		ParasutRequiredModuleAdminOps,
	}
}

func EvaluateParasutConnectorFinalClosure(input ParasutConnectorFinalClosureInput) (ParasutConnectorFinalClosureResult, error) {
	if err := validateParasutConnectorFinalClosureInput(input); err != nil {
		return ParasutConnectorFinalClosureResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := input.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	blockers := []string{}
	required := RequiredParasutConnectorClosureModules()
	evidenceByModule := map[ParasutConnectorRequiredModuleKey]ParasutConnectorModuleClosureEvidence{}

	for _, evidence := range input.ModuleEvidence {
		evidenceByModule[evidence.ModuleKey] = evidence
	}

	totalPass := 0
	totalFail := 0
	totalRequiredFail := 0
	totalOptionalWarn := 0
	passedModules := 0

	for _, moduleKey := range required {
		evidence, ok := evidenceByModule[moduleKey]
		if !ok {
			blockers = append(blockers, "missing_module_evidence:"+string(moduleKey))
			continue
		}

		moduleBlockers := validateParasutModuleClosureEvidence(evidence)
		if len(moduleBlockers) > 0 {
			blockers = append(blockers, moduleBlockers...)
			continue
		}

		passedModules++
		totalPass += evidence.PassCount
		totalFail += evidence.FailCount
		totalRequiredFail += evidence.RequiredFail
		totalOptionalWarn += evidence.OptionalWarn
	}

	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_final_closure")
	}
	if input.RealWebhookEndpointEnabled {
		blockers = append(blockers, "real_webhook_endpoint_must_remain_false_in_final_closure")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_final_closure")
	}
	if input.RealQueueTriggerEnabled {
		blockers = append(blockers, "real_queue_trigger_must_remain_false_in_final_closure")
	}
	if input.RealTokenExchangeEnabled {
		blockers = append(blockers, "real_token_exchange_must_remain_false_in_final_closure")
	}
	if input.RealTokenRefreshEnabled {
		blockers = append(blockers, "real_token_refresh_must_remain_false_in_final_closure")
	}
	if input.RealRetryJobEnabled {
		blockers = append(blockers, "real_retry_job_must_remain_false_in_final_closure")
	}

	sort.Strings(blockers)

	if len(blockers) > 0 {
		return ParasutConnectorFinalClosureResult{
			TenantID:                  normalize(input.TenantID),
			ProviderKey:               ParasutProviderKey,
			AppKey:                    normalize(input.AppKey),
			Status:                    ParasutConnectorFinalClosureStatusBlocked,
			FinalStatus:               "FAIL",
			ModuleFinalSealStatus:     "PENDING",
			ProviderLiveHandoffGate:   "BLOCKED",
			RequiredModuleCount:       len(required),
			PassedModuleCount:         passedModules,
			FailedModuleCount:         len(required) - passedModules,
			TotalPassCount:            totalPass,
			TotalFailCount:            totalFail,
			TotalRequiredFail:         totalRequiredFail,
			TotalOptionalWarn:         totalOptionalWarn,
			RealProviderAPI:           false,
			RealWebhookEndpoint:       false,
			RealERPWrite:              false,
			RealQueueTrigger:          false,
			RealTokenExchange:         false,
			RealTokenRefresh:          false,
			RealRetryJob:              false,
			RealProviderAPIStatus:     "CLOSED",
			RealWebhookEndpointStatus: "CLOSED",
			RealERPWriteStatus:        "CLOSED",
			RealQueueTriggerStatus:    "CLOSED",
			Blockers:                  blockers,
			AuditDecision:             AuditDecisionDenied,
			CorrelationID:             normalize(input.CorrelationID),
			CreatedAt:                 now,
		}, nil
	}

	return ParasutConnectorFinalClosureResult{
		TenantID:                  normalize(input.TenantID),
		ProviderKey:               ParasutProviderKey,
		AppKey:                    normalize(input.AppKey),
		Status:                    ParasutConnectorFinalClosureStatusPass,
		FinalStatus:               "PASS",
		ModuleFinalSealStatus:     "SEALED",
		ProviderLiveHandoffGate:   "READY_FOR_PROVIDER_LIVE_MODULE",
		RequiredModuleCount:       len(required),
		PassedModuleCount:         passedModules,
		FailedModuleCount:         0,
		TotalPassCount:            totalPass,
		TotalFailCount:            totalFail,
		TotalRequiredFail:         totalRequiredFail,
		TotalOptionalWarn:         totalOptionalWarn,
		RealProviderAPI:           false,
		RealWebhookEndpoint:       false,
		RealERPWrite:              false,
		RealQueueTrigger:          false,
		RealTokenExchange:         false,
		RealTokenRefresh:          false,
		RealRetryJob:              false,
		RealProviderAPIStatus:     "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
		RealWebhookEndpointStatus: "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
		RealERPWriteStatus:        "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE",
		RealQueueTriggerStatus:    "CLOSED_UNTIL_PROVIDER_LIVE_MODULE",
		Blockers:                  []string{},
		AuditDecision:             AuditDecisionAllowed,
		CorrelationID:             normalize(input.CorrelationID),
		CreatedAt:                 now,
	}, nil
}

func validateParasutConnectorFinalClosureInput(input ParasutConnectorFinalClosureInput) error {
	if err := requireNonEmpty(input.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if len(input.ModuleEvidence) == 0 {
		return fmt.Errorf("%w: module evidence required", ErrInvalidIntegrationRequest)
	}
	return nil
}

func validateParasutModuleClosureEvidence(evidence ParasutConnectorModuleClosureEvidence) []string {
	blockers := []string{}

	if evidence.ModuleKey == "" {
		blockers = append(blockers, "module_key_required")
	}
	if normalize(evidence.ModuleName) == "" {
		blockers = append(blockers, "module_name_required:"+string(evidence.ModuleKey))
	}
	if evidence.FinalStatus != "PASS" {
		blockers = append(blockers, "module_final_status_not_pass:"+string(evidence.ModuleKey))
	}
	if evidence.SealStatus != "SEALED" {
		blockers = append(blockers, "module_seal_status_not_sealed:"+string(evidence.ModuleKey))
	}
	if evidence.GateStatus != "" && evidence.GateStatus != "READY" && evidence.GateStatus != "READY_FOR_PROVIDER_MODULE" && evidence.GateStatus != "READY_FOR_PROVIDER_LIVE_MODULE" {
		blockers = append(blockers, "module_gate_not_ready:"+string(evidence.ModuleKey))
	}
	if evidence.PassCount <= 0 {
		blockers = append(blockers, "module_pass_count_not_positive:"+string(evidence.ModuleKey))
	}
	if evidence.FailCount != 0 {
		blockers = append(blockers, "module_fail_count_not_zero:"+string(evidence.ModuleKey))
	}
	if evidence.RequiredFail != 0 {
		blockers = append(blockers, "module_required_fail_not_zero:"+string(evidence.ModuleKey))
	}
	if normalize(evidence.EvidenceFile) == "" {
		blockers = append(blockers, "module_evidence_file_required:"+string(evidence.ModuleKey))
	}

	return blockers
}

func BuildParasutProviderLiveHandoffPackage(result ParasutConnectorFinalClosureResult) (ParasutProviderLiveHandoffPackage, error) {
	if result.Status != ParasutConnectorFinalClosureStatusPass {
		return ParasutProviderLiveHandoffPackage{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: final closure must pass before provider live handoff", ErrInvalidIntegrationRequest)
	}
	if result.ProviderKey != ParasutProviderKey {
		return ParasutProviderLiveHandoffPackage{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if result.ProviderLiveHandoffGate != "READY_FOR_PROVIDER_LIVE_MODULE" {
		return ParasutProviderLiveHandoffPackage{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: provider live handoff gate not ready", ErrInvalidIntegrationRequest)
	}
	if result.RealProviderAPI || result.RealWebhookEndpoint || result.RealERPWrite || result.RealQueueTrigger {
		return ParasutProviderLiveHandoffPackage{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: real gates must remain closed before live module", ErrInvalidIntegrationRequest)
	}

	return ParasutProviderLiveHandoffPackage{
		TenantID:                                result.TenantID,
		ProviderKey:                             ParasutProviderKey,
		AppKey:                                  result.AppKey,
		ProviderLiveModuleHandoffGate:           "READY_FOR_PROVIDER_LIVE_MODULE",
		ApprovalRequired:                        true,
		RealCredentialSecretRequired:            true,
		SandboxLiveCredentialSeparationRequired: true,
		RealWebhookEndpointApprovalRequired:     true,
		LiveSyncWorkerApprovalRequired:          true,
		ProductionRolloutChecklistRequired:      true,
		RollbackSafeDisableRequired:             true,
		RealProviderAPIStatus:                   result.RealProviderAPIStatus,
		RealWebhookEndpointStatus:               result.RealWebhookEndpointStatus,
		RealERPWriteStatus:                      result.RealERPWriteStatus,
		AuditDecision:                           AuditDecisionAllowed,
		CorrelationID:                           result.CorrelationID,
		CreatedAt:                               result.CreatedAt,
	}, nil
}

func RecordParasutConnectorFinalClosureAudit(obs *ConnectorObservabilityRuntime, result ParasutConnectorFinalClosureResult) error {
	if obs == nil {
		return fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if result.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(result.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(result.CorrelationID, "correlation_id"); err != nil {
		return err
	}

	return obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      result.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        result.AppKey,
		Operation:     "PARASUT_CONNECTOR_FINAL_CLOSURE",
		Status:        result.FinalStatus,
		Decision:      result.AuditDecision,
		CorrelationID: result.CorrelationID,
		Message:       result.ProviderLiveHandoffGate,
		CreatedAt:     result.CreatedAt,
	})
}

type ParasutConnectorFinalClosureReadinessGateInput struct {
	ModuleClosureEvidenceReady   bool
	CounterEvidenceReady         bool
	RealGateSafetyReady          bool
	ProviderLiveHandoffReady     bool
	FinalConnectorSealReady      bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealProviderAPIEnabled       bool
	RealWebhookEndpointEnabled   bool
	RealERPWriteEnabled          bool
	RealQueueTriggerEnabled      bool
	RealTokenExchangeEnabled     bool
	RealTokenRefreshEnabled      bool
	RealRetryJobEnabled          bool
}

type ParasutConnectorFinalClosureReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutConnectorFinalClosureReadinessGate(input ParasutConnectorFinalClosureReadinessGateInput) ParasutConnectorFinalClosureReadinessGateResult {
	blockers := []string{}

	if !input.ModuleClosureEvidenceReady {
		blockers = append(blockers, "module_closure_evidence_not_ready")
	}
	if !input.CounterEvidenceReady {
		blockers = append(blockers, "counter_evidence_not_ready")
	}
	if !input.RealGateSafetyReady {
		blockers = append(blockers, "real_gate_safety_not_ready")
	}
	if !input.ProviderLiveHandoffReady {
		blockers = append(blockers, "provider_live_handoff_not_ready")
	}
	if !input.FinalConnectorSealReady {
		blockers = append(blockers, "final_connector_seal_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_final_closure_gate")
	}
	if input.RealWebhookEndpointEnabled {
		blockers = append(blockers, "real_webhook_endpoint_must_remain_false_in_final_closure_gate")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_final_closure_gate")
	}
	if input.RealQueueTriggerEnabled {
		blockers = append(blockers, "real_queue_trigger_must_remain_false_in_final_closure_gate")
	}
	if input.RealTokenExchangeEnabled {
		blockers = append(blockers, "real_token_exchange_must_remain_false_in_final_closure_gate")
	}
	if input.RealTokenRefreshEnabled {
		blockers = append(blockers, "real_token_refresh_must_remain_false_in_final_closure_gate")
	}
	if input.RealRetryJobEnabled {
		blockers = append(blockers, "real_retry_job_must_remain_false_in_final_closure_gate")
	}

	if len(blockers) > 0 {
		sort.Strings(blockers)
		return ParasutConnectorFinalClosureReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutConnectorFinalClosureReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_CONNECTOR_FINAL_CLOSURE_READY_FOR_PROVIDER_LIVE_MODULE_HANDOFF",
		Blockers: []string{},
	}
}
