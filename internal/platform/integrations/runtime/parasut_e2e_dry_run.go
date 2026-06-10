package integrationruntime

import (
	"fmt"
	"time"
)

type ParasutConnectorE2EDryRunStatus string

const (
	ParasutConnectorE2EStatusStarted    ParasutConnectorE2EDryRunStatus = "E2E_DRY_RUN_STARTED"
	ParasutConnectorE2EStatusCompleted  ParasutConnectorE2EDryRunStatus = "E2E_DRY_RUN_COMPLETED"
	ParasutConnectorE2EStatusBlocked    ParasutConnectorE2EDryRunStatus = "E2E_DRY_RUN_BLOCKED"
	ParasutConnectorE2EStatusRetryReady ParasutConnectorE2EDryRunStatus = "E2E_RETRY_DLQ_READY"
)

type ParasutConnectorE2EDryRunInput struct {
	TenantID                   string
	AppKey                     string
	ClientID                   string
	ClientSecret               string
	AuthorizationCode          string
	WebhookSecretRef           string
	DryRunWebhookSigningSecret string
	WebhookEventID             string
	WebhookEventType           ParasutWebhookEventType
	Source                     ParasutSyncSourceEnvelope
	RequestedBy                string
	CorrelationID              string
	Now                        time.Time
	RealProviderAPIEnabled     bool
	RealWebhookEndpointEnabled bool
	RealERPWriteEnabled        bool
	RealQueueTriggerEnabled    bool
	RealTokenExchangeEnabled   bool
	RealTokenRefreshEnabled    bool
}

type ParasutConnectorE2EDryRunResult struct {
	TenantID              string
	ProviderKey           string
	AppKey                string
	Status                ParasutConnectorE2EDryRunStatus
	ClientSecretRef       string
	OAuthState            string
	AuthorizationURL      ParasutAuthorizationURLResult
	CallbackResult        ParasutOAuthCallbackResult
	TokenExchangeContract ParasutTokenExchangeContractResult
	TokenStorage          ParasutTokenExchangeStorageResult
	APIClientContract     ParasutAPIClientContract
	APIOperation          ParasutAPIOperationRequest
	APIResponse           ParasutAPIDryRunProviderResponse
	MappingRecord         Pix2piERPSyncRecord
	ERPWriteResult        ParasutERPWriteContractResult
	DirectWorkerResult    ParasutSyncWorkerResult
	VerifiedWebhook       ParasutVerifiedWebhookEvent
	WebhookTriggerResult  ParasutWebhookSyncTriggerResult
	FailureDecision       ParasutWebhookFailureDecision
	RealProviderAPI       bool
	RealWebhookEndpoint   bool
	RealERPWrite          bool
	RealQueueTrigger      bool
	AuditDecision         AuditDecision
	CorrelationID         string
	CreatedAt             time.Time
}

func ExecuteParasutConnectorE2EDryRun(input ParasutConnectorE2EDryRunInput) (ParasutConnectorE2EDryRunResult, error) {
	obs := NewConnectorObservabilityRuntime()
	vault := NewInMemoryParasutCredentialVault()
	webhookStore := NewInMemoryParasutWebhookIdempotencyStore()

	return ExecuteParasutConnectorE2EDryRunWithRuntime(obs, vault, webhookStore, input)
}

func ExecuteParasutConnectorE2EDryRunWithRuntime(
	obs *ConnectorObservabilityRuntime,
	vault *InMemoryParasutCredentialVault,
	webhookStore *InMemoryParasutWebhookIdempotencyStore,
	input ParasutConnectorE2EDryRunInput,
) (ParasutConnectorE2EDryRunResult, error) {
	if obs == nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if vault == nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: credential vault required", ErrInvalidIntegrationRequest)
	}
	if webhookStore == nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: webhook idempotency store required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutConnectorE2EDryRunInput(input); err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := input.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	clientSecretRef, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      input.TenantID,
		AppKey:        input.AppKey,
		SecretKind:    ParasutSecretKindClientSecret,
		RawSecret:     input.ClientSecret,
		CreatedBy:     input.RequestedBy,
		CorrelationID: input.CorrelationID,
		Now:           now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	oauthSurface := DefaultParasutOAuthConnectSurfaceContract()
	oauthState, err := BuildParasutOAuthState(ParasutOAuthStateRequest{
		TenantID:      input.TenantID,
		AppKey:        input.AppKey,
		RequestedBy:   input.RequestedBy,
		CorrelationID: input.CorrelationID,
		Nonce:         "nonce-" + input.CorrelationID,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	authorizationURL, err := BuildParasutAuthorizationURL(oauthSurface, ParasutAuthorizationURLRequest{
		TenantID:             input.TenantID,
		AppKey:               input.AppKey,
		Role:                 CredentialEntryRoleTenantAdmin,
		ClientID:             input.ClientID,
		RedirectURI:          "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		Scopes:               []string{"read", "write"},
		State:                oauthState,
		Nonce:                "nonce-" + input.CorrelationID,
		RequestedBy:          input.RequestedBy,
		CorrelationID:        input.CorrelationID,
		AuthorizationBaseURL: "https://api.parasut.local/oauth/authorize",
		RealAPIEnabled:       input.RealProviderAPIEnabled,
		Now:                  now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	callbackResult, err := HandleParasutOAuthCallback(ParasutOAuthCallbackRequest{
		TenantID:          input.TenantID,
		AppKey:            input.AppKey,
		AuthorizationCode: input.AuthorizationCode,
		ExpectedState:     oauthState,
		ReceivedState:     oauthState,
		Nonce:             "nonce-" + input.CorrelationID,
		RequestedBy:       input.RequestedBy,
		CorrelationID:     input.CorrelationID,
		RealAPIEnabled:    input.RealProviderAPIEnabled,
		Now:               now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	tokenContract, err := PrepareParasutTokenExchangeContract(ParasutTokenExchangeContractRequest{
		TenantID:                 input.TenantID,
		AppKey:                   input.AppKey,
		AuthorizationCode:        input.AuthorizationCode,
		RedirectURI:              "https://pix2pi.com.tr/integrations/parasut/oauth/callback",
		ClientID:                 input.ClientID,
		ClientSecretRef:          clientSecretRef.SecretRef,
		RequestedBy:              input.RequestedBy,
		CorrelationID:            input.CorrelationID,
		RealTokenExchangeEnabled: input.RealTokenExchangeEnabled,
		Now:                      now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	tokenStorage, err := StoreParasutSimulatedTokenResponse(vault, tokenContract, ParasutSimulatedTokenResponse{
		AccessToken:      "sim-e2e-access-token-" + input.CorrelationID,
		RefreshToken:     "sim-e2e-refresh-token-" + input.CorrelationID,
		ExpiresInSeconds: 3600,
		IssuedAt:         now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	eventMapping, err := MapParasutWebhookEventToSync(input.WebhookEventType)
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	apiClientContract, err := BuildParasutAPIClientContract(ParasutAPIClientContractRequest{
		TenantID:       input.TenantID,
		AppKey:         input.AppKey,
		AccessTokenRef: tokenStorage.AccessTokenRef,
		RequestedBy:    input.RequestedBy,
		CorrelationID:  input.CorrelationID,
		RealAPIEnabled: input.RealProviderAPIEnabled,
		Now:            now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	apiOperation, err := BuildParasutAPIOperationRequest(apiClientContract, eventMapping.Operation, "e2e-api-"+input.WebhookEventID, buildParasutSyncWorkerPayload(input.Source))
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	apiResponse, err := ExecuteParasutAPIDryRun(apiOperation)
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := RecordParasutAPIOperationAudit(obs, apiResponse); err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	mappingRecord, err := BuildParasutSyncWorkerMapping(input.Source)
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	erpWriteResult, err := BuildParasutERPWriteDryRunContract(ParasutERPWriteContractRequest{
		TenantID:            input.TenantID,
		AppKey:              input.AppKey,
		Record:              mappingRecord,
		RequestedBy:         input.RequestedBy,
		CorrelationID:       input.CorrelationID,
		RealERPWriteEnabled: input.RealERPWriteEnabled,
		Now:                 now,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := RecordParasutMappingAudit(obs, erpWriteResult); err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	directWorkerResult, err := ExecuteParasutSyncWorkerDryRun(obs, ParasutSyncWorkerRequest{
		Schedule: ParasutSyncJobSchedule{
			JobKey:        "parasut-e2e-direct-worker-" + input.WebhookEventID,
			TenantID:      input.TenantID,
			ProviderKey:   ParasutProviderKey,
			AppKey:        input.AppKey,
			Operation:     eventMapping.Operation,
			RequestedBy:   input.RequestedBy,
			CorrelationID: input.CorrelationID,
		},
		IntegrationState: ParasutTenantIntegrationState{
			TenantID: input.TenantID,
			AppKey:   input.AppKey,
			Enabled:  true,
			Status:   "ACTIVE",
		},
		TokenLifecycle:          tokenStorage.Lifecycle,
		AccessTokenRef:          tokenStorage.AccessTokenRef,
		IdempotencyKey:          "e2e-worker-" + input.WebhookEventID,
		Source:                  input.Source,
		RequestedBy:             input.RequestedBy,
		CorrelationID:           input.CorrelationID,
		RealProviderAPIEnabled:  input.RealProviderAPIEnabled,
		RealERPWriteEnabled:     input.RealERPWriteEnabled,
		RealTokenRefreshEnabled: input.RealTokenRefreshEnabled,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	webhookPayload := buildParasutE2ERawWebhookPayload(input)
	webhookSignature := BuildParasutWebhookDryRunSignature(input.DryRunWebhookSigningSecret, now, webhookPayload)

	verifiedWebhook, err := VerifyParasutWebhookEnvelope(ParasutWebhookEnvelope{
		TenantID:                   input.TenantID,
		ProviderKey:                ParasutProviderKey,
		AppKey:                     input.AppKey,
		EventID:                    input.WebhookEventID,
		EventType:                  input.WebhookEventType,
		RawPayload:                 webhookPayload,
		Signature:                  webhookSignature,
		Timestamp:                  now,
		WebhookSecretRef:           input.WebhookSecretRef,
		DryRunSigningSecret:        input.DryRunWebhookSigningSecret,
		CorrelationID:              input.CorrelationID,
		ReceivedAt:                 now.Add(time.Minute),
		MaxSkew:                    5 * time.Minute,
		RealWebhookEndpointEnabled: input.RealWebhookEndpointEnabled,
		RealProviderAPIEnabled:     input.RealProviderAPIEnabled,
		RealERPWriteEnabled:        input.RealERPWriteEnabled,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	webhookTriggerResult, err := TriggerParasutSyncWorkerFromWebhook(obs, webhookStore, ParasutWebhookSyncTriggerRequest{
		VerifiedEvent: verifiedWebhook,
		IntegrationState: ParasutTenantIntegrationState{
			TenantID: input.TenantID,
			AppKey:   input.AppKey,
			Enabled:  true,
			Status:   "ACTIVE",
		},
		TokenLifecycle:          tokenStorage.Lifecycle,
		AccessTokenRef:          tokenStorage.AccessTokenRef,
		Source:                  input.Source,
		RequestedBy:             input.RequestedBy,
		RealProviderAPIEnabled:  input.RealProviderAPIEnabled,
		RealERPWriteEnabled:     input.RealERPWriteEnabled,
		RealTokenRefreshEnabled: input.RealTokenRefreshEnabled,
	})
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	failureDecision, err := EvaluateParasutWebhookFailure(input.TenantID, input.AppKey, input.WebhookEventID, input.WebhookEventType, 499, "unknown", 1, input.CorrelationID)
	if err != nil {
		return ParasutConnectorE2EDryRunResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutConnectorE2EDryRunResult{
		TenantID:              normalize(input.TenantID),
		ProviderKey:           ParasutProviderKey,
		AppKey:                normalize(input.AppKey),
		Status:                ParasutConnectorE2EStatusCompleted,
		ClientSecretRef:       clientSecretRef.SecretRef,
		OAuthState:            oauthState,
		AuthorizationURL:      authorizationURL,
		CallbackResult:        callbackResult,
		TokenExchangeContract: tokenContract,
		TokenStorage:          tokenStorage,
		APIClientContract:     apiClientContract,
		APIOperation:          apiOperation,
		APIResponse:           apiResponse,
		MappingRecord:         mappingRecord,
		ERPWriteResult:        erpWriteResult,
		DirectWorkerResult:    directWorkerResult,
		VerifiedWebhook:       verifiedWebhook,
		WebhookTriggerResult:  webhookTriggerResult,
		FailureDecision:       failureDecision,
		RealProviderAPI:       false,
		RealWebhookEndpoint:   false,
		RealERPWrite:          false,
		RealQueueTrigger:      false,
		AuditDecision:         AuditDecisionAllowed,
		CorrelationID:         normalize(input.CorrelationID),
		CreatedAt:             now,
	}, nil
}

func validateParasutConnectorE2EDryRunInput(input ParasutConnectorE2EDryRunInput) error {
	if err := requireNonEmpty(input.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.ClientID, "client_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.ClientSecret, "client_secret"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.AuthorizationCode, "authorization_code"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.WebhookSecretRef, "webhook_secret_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(input.TenantID, input.WebhookSecretRef) {
		return fmt.Errorf("%w: webhook_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(input.DryRunWebhookSigningSecret, "dry_run_webhook_signing_secret"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.WebhookEventID, "webhook_event_id"); err != nil {
		return err
	}
	if input.WebhookEventType == "" {
		return fmt.Errorf("%w: webhook_event_type required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutSyncSourceEnvelope(input.Source); err != nil {
		return err
	}
	mapping, err := MapParasutWebhookEventToSync(input.WebhookEventType)
	if err != nil {
		return err
	}
	if mapping.ObjectType != input.Source.ObjectType {
		return fmt.Errorf("%w: e2e source object type must match webhook event type", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(input.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(input.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if input.RealProviderAPIEnabled {
		return fmt.Errorf("%w: real provider API must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	if input.RealWebhookEndpointEnabled {
		return fmt.Errorf("%w: real webhook endpoint must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	if input.RealERPWriteEnabled {
		return fmt.Errorf("%w: real ERP write must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	if input.RealQueueTriggerEnabled {
		return fmt.Errorf("%w: real queue trigger must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	if input.RealTokenExchangeEnabled {
		return fmt.Errorf("%w: real token exchange must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	if input.RealTokenRefreshEnabled {
		return fmt.Errorf("%w: real token refresh must remain disabled in e2e dry-run phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func buildParasutE2ERawWebhookPayload(input ParasutConnectorE2EDryRunInput) string {
	return fmt.Sprintf(`{"provider":"parasut","event_id":"%s","event_type":"%s","correlation_id":"%s"}`, normalize(input.WebhookEventID), input.WebhookEventType, normalize(input.CorrelationID))
}

type ParasutConnectorE2EReadinessGateInput struct {
	CredentialOAuthBridgeReady    bool
	TokenExchangeLifecycleReady   bool
	APIClientMappingERPWriteReady bool
	SyncWorkerWebhookTriggerReady bool
	AuditRetryDLQReady            bool
	TestsReady                    bool
	RealImplementationAuditReady  bool
	RealProviderAPIEnabled        bool
	RealWebhookEndpointEnabled    bool
	RealERPWriteEnabled           bool
	RealQueueTriggerEnabled       bool
	RealTokenExchangeEnabled      bool
	RealTokenRefreshEnabled       bool
}

type ParasutConnectorE2EReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutConnectorE2EReadinessGate(input ParasutConnectorE2EReadinessGateInput) ParasutConnectorE2EReadinessGateResult {
	blockers := []string{}

	if !input.CredentialOAuthBridgeReady {
		blockers = append(blockers, "credential_oauth_bridge_not_ready")
	}
	if !input.TokenExchangeLifecycleReady {
		blockers = append(blockers, "token_exchange_lifecycle_not_ready")
	}
	if !input.APIClientMappingERPWriteReady {
		blockers = append(blockers, "api_client_mapping_erp_write_not_ready")
	}
	if !input.SyncWorkerWebhookTriggerReady {
		blockers = append(blockers, "sync_worker_webhook_trigger_not_ready")
	}
	if !input.AuditRetryDLQReady {
		blockers = append(blockers, "audit_retry_dlq_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_e2e_dry_run_phase")
	}
	if input.RealWebhookEndpointEnabled {
		blockers = append(blockers, "real_webhook_endpoint_must_remain_false_in_e2e_dry_run_phase")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_e2e_dry_run_phase")
	}
	if input.RealQueueTriggerEnabled {
		blockers = append(blockers, "real_queue_trigger_must_remain_false_in_e2e_dry_run_phase")
	}
	if input.RealTokenExchangeEnabled {
		blockers = append(blockers, "real_token_exchange_must_remain_false_in_e2e_dry_run_phase")
	}
	if input.RealTokenRefreshEnabled {
		blockers = append(blockers, "real_token_refresh_must_remain_false_in_e2e_dry_run_phase")
	}

	if len(blockers) > 0 {
		return ParasutConnectorE2EReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutConnectorE2EReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_FULL_CONNECTOR_E2E_DRY_RUN_READY_WITH_REAL_API_WEBHOOK_ERP_CLOSED",
		Blockers: []string{},
	}
}
