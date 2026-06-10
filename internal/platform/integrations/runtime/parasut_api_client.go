package integrationruntime

import (
	"fmt"
	"strings"
	"time"
)

type ParasutAPIClientRuntimeStatus string

const (
	ParasutAPIClientStatusContractReady     ParasutAPIClientRuntimeStatus = "API_CLIENT_CONTRACT_READY"
	ParasutAPIClientStatusOperationReady    ParasutAPIClientRuntimeStatus = "OPERATION_REQUEST_READY"
	ParasutAPIClientStatusDryRunSucceeded   ParasutAPIClientRuntimeStatus = "DRY_RUN_SUCCEEDED"
	ParasutAPIClientStatusDryRunFailed      ParasutAPIClientRuntimeStatus = "DRY_RUN_FAILED"
	ParasutAPIClientStatusPolicyBridgeReady ParasutAPIClientRuntimeStatus = "POLICY_BRIDGE_READY"
	ParasutAPIClientStatusAuditRecorded     ParasutAPIClientRuntimeStatus = "AUDIT_RECORDED"
)

type ParasutAPIClientContractRequest struct {
	TenantID                 string
	AppKey                   string
	AccessTokenRef           string
	RequestedBy              string
	CorrelationID            string
	ProviderLiveModuleOpened bool
	RealAPIEnabled           bool
	Now                      time.Time
}

type ParasutAPIClientContract struct {
	TenantID       string
	ProviderKey    string
	AppKey         string
	AccessTokenRef string
	RequestedBy    string
	CorrelationID  string
	Status         ParasutAPIClientRuntimeStatus
	RealAPIEnabled bool
	AuditDecision  AuditDecision
	CreatedAt      time.Time
}

func BuildParasutAPIClientContract(req ParasutAPIClientContractRequest) (ParasutAPIClientContract, error) {
	if err := validateParasutAPIClientContractRequest(req); err != nil {
		return ParasutAPIClientContract{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutAPIClientContract{
		TenantID:       normalize(req.TenantID),
		ProviderKey:    ParasutProviderKey,
		AppKey:         normalize(req.AppKey),
		AccessTokenRef: normalize(req.AccessTokenRef),
		RequestedBy:    normalize(req.RequestedBy),
		CorrelationID:  normalize(req.CorrelationID),
		Status:         ParasutAPIClientStatusContractReady,
		RealAPIEnabled: false,
		AuditDecision:  AuditDecisionAllowed,
		CreatedAt:      now,
	}, nil
}

func validateParasutAPIClientContractRequest(req ParasutAPIClientContractRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealAPIEnabled {
		return fmt.Errorf("%w: real parasut api must remain disabled in api client dry-run phase", ErrInvalidIntegrationRequest)
	}
	if req.ProviderLiveModuleOpened && req.RealAPIEnabled {
		return fmt.Errorf("%w: provider live module real api call belongs to later phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutAPIOperationRequest struct {
	TenantID       string
	ProviderKey    string
	AppKey         string
	Operation      ConnectorOperation
	Endpoint       ParasutAPIEndpointContract
	AccessTokenRef string
	IdempotencyKey string
	CorrelationID  string
	Payload        map[string]string
	Status         ParasutAPIClientRuntimeStatus
	CreatedAt      time.Time
}

func BuildParasutAPIOperationRequest(
	contract ParasutAPIClientContract,
	operation ConnectorOperation,
	idempotencyKey string,
	payload map[string]string,
) (ParasutAPIOperationRequest, error) {
	if err := validateParasutAPIClientContract(contract); err != nil {
		return ParasutAPIOperationRequest{}, err
	}
	if operation == "" {
		return ParasutAPIOperationRequest{}, fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(idempotencyKey, "idempotency_key"); err != nil {
		return ParasutAPIOperationRequest{}, err
	}
	if payload == nil {
		return ParasutAPIOperationRequest{}, fmt.Errorf("%w: operation payload required", ErrInvalidIntegrationRequest)
	}

	endpoints := DefaultParasutAPIEndpointContracts()
	endpoint, ok := endpoints[operation]
	if !ok {
		return ParasutAPIOperationRequest{}, fmt.Errorf("%w: parasut endpoint contract missing for operation", ErrInvalidIntegrationRequest)
	}
	if err := ValidateParasutAPIEndpointContract(endpoint); err != nil {
		return ParasutAPIOperationRequest{}, err
	}

	return ParasutAPIOperationRequest{
		TenantID:       contract.TenantID,
		ProviderKey:    ParasutProviderKey,
		AppKey:         contract.AppKey,
		Operation:      operation,
		Endpoint:       endpoint,
		AccessTokenRef: contract.AccessTokenRef,
		IdempotencyKey: normalize(idempotencyKey),
		CorrelationID:  contract.CorrelationID,
		Payload:        copyStringMap(payload),
		Status:         ParasutAPIClientStatusOperationReady,
		CreatedAt:      time.Now().UTC(),
	}, nil
}

func validateParasutAPIClientContract(contract ParasutAPIClientContract) error {
	if err := requireNonEmpty(contract.TenantID, "tenant_id"); err != nil {
		return err
	}
	if contract.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(contract.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(contract.TenantID, contract.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(contract.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if contract.RealAPIEnabled {
		return fmt.Errorf("%w: real parasut api must remain disabled in api client dry-run phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutAPIDryRunProviderResponse struct {
	TenantID              string
	ProviderKey           string
	AppKey                string
	Operation             ConnectorOperation
	HTTPStatus            int
	ProviderObjectID      string
	ProviderTransactionID string
	RawResponse           string
	Status                ParasutAPIClientRuntimeStatus
	RealHTTPCall          bool
	PlaintextTokenUsed    bool
	AuditDecision         AuditDecision
	CorrelationID         string
	CreatedAt             time.Time
}

func ExecuteParasutAPIDryRun(req ParasutAPIOperationRequest) (ParasutAPIDryRunProviderResponse, error) {
	if err := validateParasutAPIOperationRequest(req); err != nil {
		return ParasutAPIDryRunProviderResponse{AuditDecision: AuditDecisionDenied}, err
	}

	providerObjectID := fmt.Sprintf("parasut-dryrun-%s-%s", strings.ToLower(string(req.Operation)), req.IdempotencyKey)
	providerTransactionID := fmt.Sprintf("parasut-dryrun-txn-%s", req.CorrelationID)

	return ParasutAPIDryRunProviderResponse{
		TenantID:              req.TenantID,
		ProviderKey:           ParasutProviderKey,
		AppKey:                req.AppKey,
		Operation:             req.Operation,
		HTTPStatus:            200,
		ProviderObjectID:      providerObjectID,
		ProviderTransactionID: providerTransactionID,
		RawResponse:           `{"mode":"dry_run","provider":"parasut","real_http_call":false}`,
		Status:                ParasutAPIClientStatusDryRunSucceeded,
		RealHTTPCall:          false,
		PlaintextTokenUsed:    false,
		AuditDecision:         AuditDecisionAllowed,
		CorrelationID:         req.CorrelationID,
		CreatedAt:             time.Now().UTC(),
	}, nil
}

func validateParasutAPIOperationRequest(req ParasutAPIOperationRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if req.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if req.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.IdempotencyKey, "idempotency_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.Payload == nil {
		return fmt.Errorf("%w: operation payload required", ErrInvalidIntegrationRequest)
	}
	if err := ValidateParasutAPIEndpointContract(req.Endpoint); err != nil {
		return err
	}
	return nil
}

type ParasutAPIOperationPolicyBridge struct {
	Operation          ConnectorOperation
	Timeout            time.Duration
	RateLimitPerMinute int
	RetryPolicy        RetryPolicy
	Status             ParasutAPIClientRuntimeStatus
}

func BuildParasutAPIOperationPolicyBridge(operation ConnectorOperation) (ParasutAPIOperationPolicyBridge, error) {
	endpoints := DefaultParasutAPIEndpointContracts()
	endpoint, ok := endpoints[operation]
	if !ok {
		return ParasutAPIOperationPolicyBridge{}, fmt.Errorf("%w: endpoint contract missing for operation", ErrInvalidIntegrationRequest)
	}
	if err := ValidateParasutAPIEndpointContract(endpoint); err != nil {
		return ParasutAPIOperationPolicyBridge{}, err
	}

	return ParasutAPIOperationPolicyBridge{
		Operation:          operation,
		Timeout:            endpoint.Timeout,
		RateLimitPerMinute: endpoint.RateLimitPerMinute,
		RetryPolicy:        DefaultRetryPolicy(),
		Status:             ParasutAPIClientStatusPolicyBridgeReady,
	}, nil
}

type ParasutAPIOperationFailureDecision struct {
	Mapping       ParasutProviderErrorMapping
	RetryDecision RetryDecision
}

func EvaluateParasutAPIOperationFailure(
	req ParasutAPIOperationRequest,
	httpStatus int,
	providerMessage string,
	attempt int,
) (ParasutAPIOperationFailureDecision, error) {
	if err := validateParasutAPIOperationRequest(req); err != nil {
		return ParasutAPIOperationFailureDecision{}, err
	}
	if attempt <= 0 {
		return ParasutAPIOperationFailureDecision{}, fmt.Errorf("%w: attempt must be positive", ErrInvalidIntegrationRequest)
	}

	mapping := MapParasutProviderError(httpStatus, providerMessage)
	kind := FailureKindNonRetryable
	if mapping.Retryable {
		kind = FailureKindRetryable
	}
	if mapping.MoveToDLQ {
		kind = FailureKindPoison
	}

	retryDecision := EvaluateRetry(DefaultRetryPolicy(), FailureRecord{
		TenantID:      req.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        req.AppKey,
		Operation:     string(req.Operation),
		Attempt:       attempt,
		Kind:          kind,
		ErrorCode:     string(mapping.Code),
		CorrelationID: req.CorrelationID,
		Payload:       req.RawPayloadForFailure(),
	})

	return ParasutAPIOperationFailureDecision{
		Mapping:       mapping,
		RetryDecision: retryDecision,
	}, nil
}

func (req ParasutAPIOperationRequest) RawPayloadForFailure() string {
	return fmt.Sprintf("operation=%s,idempotency_key=%s", req.Operation, req.IdempotencyKey)
}

func RecordParasutAPIOperationAudit(
	obs *ConnectorObservabilityRuntime,
	response ParasutAPIDryRunProviderResponse,
) error {
	if obs == nil {
		return fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutAPIDryRunResponse(response); err != nil {
		return err
	}

	status := "SUCCEEDED"
	if response.Status == ParasutAPIClientStatusDryRunFailed || response.HTTPStatus >= 400 {
		status = "FAILED"
	}

	return obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      response.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        response.AppKey,
		Operation:     string(response.Operation),
		Status:        status,
		Decision:      response.AuditDecision,
		CorrelationID: response.CorrelationID,
		Message:       response.ProviderTransactionID,
		CreatedAt:     response.CreatedAt,
	})
}

func validateParasutAPIDryRunResponse(response ParasutAPIDryRunProviderResponse) error {
	if err := requireNonEmpty(response.TenantID, "tenant_id"); err != nil {
		return err
	}
	if response.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(response.AppKey, "app_key"); err != nil {
		return err
	}
	if response.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if response.HTTPStatus <= 0 {
		return fmt.Errorf("%w: http_status required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(response.ProviderObjectID, "provider_object_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(response.ProviderTransactionID, "provider_transaction_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(response.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if response.RealHTTPCall {
		return fmt.Errorf("%w: real http call must remain false in dry-run phase", ErrInvalidIntegrationRequest)
	}
	if response.PlaintextTokenUsed {
		return fmt.Errorf("%w: plaintext token usage is forbidden in dry-run phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutAPIClientReadinessGateInput struct {
	APIClientContractReady        bool
	OperationRequestBuilderReady  bool
	DryRunProviderResponseReady   bool
	PolicyBridgeReady             bool
	AuditObservabilityBridgeReady bool
	TestsReady                    bool
	RealImplementationAuditReady  bool
	RealAPIEnabled                bool
	RealHTTPClientEnabled         bool
	PlaintextTokenResolveEnabled  bool
}

type ParasutAPIClientReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutAPIClientReadinessGate(input ParasutAPIClientReadinessGateInput) ParasutAPIClientReadinessGateResult {
	blockers := []string{}

	if !input.APIClientContractReady {
		blockers = append(blockers, "api_client_contract_not_ready")
	}
	if !input.OperationRequestBuilderReady {
		blockers = append(blockers, "operation_request_builder_not_ready")
	}
	if !input.DryRunProviderResponseReady {
		blockers = append(blockers, "dry_run_provider_response_not_ready")
	}
	if !input.PolicyBridgeReady {
		blockers = append(blockers, "policy_bridge_not_ready")
	}
	if !input.AuditObservabilityBridgeReady {
		blockers = append(blockers, "audit_observability_bridge_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_api_client_phase")
	}
	if input.RealHTTPClientEnabled {
		blockers = append(blockers, "real_http_client_must_remain_false_in_api_client_phase")
	}
	if input.PlaintextTokenResolveEnabled {
		blockers = append(blockers, "plaintext_token_resolve_must_remain_false_in_api_client_phase")
	}

	if len(blockers) > 0 {
		return ParasutAPIClientReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutAPIClientReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_API_CLIENT_OPERATION_DRY_RUN_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
