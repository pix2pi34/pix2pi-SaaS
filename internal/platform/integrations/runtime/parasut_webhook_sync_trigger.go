package integrationruntime

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
)

type ParasutWebhookEventType string

const (
	ParasutWebhookEventCustomerCreated     ParasutWebhookEventType = "customer.created"
	ParasutWebhookEventCustomerUpdated     ParasutWebhookEventType = "customer.updated"
	ParasutWebhookEventProductCreated      ParasutWebhookEventType = "product.created"
	ParasutWebhookEventProductUpdated      ParasutWebhookEventType = "product.updated"
	ParasutWebhookEventSalesInvoiceCreated ParasutWebhookEventType = "sales_invoice.created"
	ParasutWebhookEventSalesInvoiceUpdated ParasutWebhookEventType = "sales_invoice.updated"
)

type ParasutWebhookSyncTriggerStatus string

const (
	ParasutWebhookStatusVerified             ParasutWebhookSyncTriggerStatus = "WEBHOOK_VERIFIED"
	ParasutWebhookStatusEventMapped          ParasutWebhookSyncTriggerStatus = "EVENT_MAPPED"
	ParasutWebhookStatusDuplicateIgnored     ParasutWebhookSyncTriggerStatus = "DUPLICATE_IGNORED"
	ParasutWebhookStatusSyncWorkerTriggered  ParasutWebhookSyncTriggerStatus = "SYNC_WORKER_TRIGGERED"
	ParasutWebhookStatusFailureDecisionReady ParasutWebhookSyncTriggerStatus = "FAILURE_DECISION_READY"
)

type ParasutWebhookEnvelope struct {
	TenantID                   string
	ProviderKey                string
	AppKey                     string
	EventID                    string
	EventType                  ParasutWebhookEventType
	RawPayload                 string
	Signature                  string
	Timestamp                  time.Time
	WebhookSecretRef           string
	DryRunSigningSecret        string
	CorrelationID              string
	ReceivedAt                 time.Time
	MaxSkew                    time.Duration
	RealWebhookEndpointEnabled bool
	RealProviderAPIEnabled     bool
	RealERPWriteEnabled        bool
}

type ParasutVerifiedWebhookEvent struct {
	TenantID         string
	ProviderKey      string
	AppKey           string
	EventID          string
	EventType        ParasutWebhookEventType
	RawPayload       string
	Signature        string
	Timestamp        time.Time
	WebhookSecretRef string
	CorrelationID    string
	Status           ParasutWebhookSyncTriggerStatus
	AuditDecision    AuditDecision
	ReceivedAt       time.Time
}

func BuildParasutWebhookDryRunSignature(secret string, timestamp time.Time, rawPayload string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(timestamp.UTC().Format(time.RFC3339)))
	mac.Write([]byte("."))
	mac.Write([]byte(rawPayload))
	return "sha256=" + hex.EncodeToString(mac.Sum(nil))
}

func VerifyParasutWebhookEnvelope(envelope ParasutWebhookEnvelope) (ParasutVerifiedWebhookEvent, error) {
	if err := validateParasutWebhookEnvelope(envelope); err != nil {
		return ParasutVerifiedWebhookEvent{AuditDecision: AuditDecisionDenied}, err
	}

	receivedAt := envelope.ReceivedAt
	if receivedAt.IsZero() {
		receivedAt = time.Now().UTC()
	}

	expectedSignature := BuildParasutWebhookDryRunSignature(envelope.DryRunSigningSecret, envelope.Timestamp, envelope.RawPayload)
	if !hmac.Equal([]byte(strings.TrimSpace(envelope.Signature)), []byte(expectedSignature)) {
		return ParasutVerifiedWebhookEvent{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: parasut webhook signature mismatch", ErrInvalidIntegrationRequest)
	}

	return ParasutVerifiedWebhookEvent{
		TenantID:         normalize(envelope.TenantID),
		ProviderKey:      ParasutProviderKey,
		AppKey:           normalize(envelope.AppKey),
		EventID:          normalize(envelope.EventID),
		EventType:        envelope.EventType,
		RawPayload:       envelope.RawPayload,
		Signature:        strings.TrimSpace(envelope.Signature),
		Timestamp:        envelope.Timestamp.UTC(),
		WebhookSecretRef: normalize(envelope.WebhookSecretRef),
		CorrelationID:    normalize(envelope.CorrelationID),
		Status:           ParasutWebhookStatusVerified,
		AuditDecision:    AuditDecisionAllowed,
		ReceivedAt:       receivedAt,
	}, nil
}

func validateParasutWebhookEnvelope(envelope ParasutWebhookEnvelope) error {
	if err := requireNonEmpty(envelope.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(envelope.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if normalize(envelope.ProviderKey) != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(envelope.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(envelope.EventID, "event_id"); err != nil {
		return err
	}
	if envelope.EventType == "" {
		return fmt.Errorf("%w: event_type required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(envelope.RawPayload, "raw_payload"); err != nil {
		return err
	}
	if err := requireNonEmpty(envelope.Signature, "signature"); err != nil {
		return err
	}
	if envelope.Timestamp.IsZero() {
		return fmt.Errorf("%w: timestamp required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(envelope.WebhookSecretRef, "webhook_secret_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(envelope.TenantID, envelope.WebhookSecretRef) {
		return fmt.Errorf("%w: webhook_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(envelope.DryRunSigningSecret, "dry_run_signing_secret"); err != nil {
		return err
	}
	if err := requireNonEmpty(envelope.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if envelope.RealWebhookEndpointEnabled {
		return fmt.Errorf("%w: real webhook endpoint must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}
	if envelope.RealProviderAPIEnabled {
		return fmt.Errorf("%w: real provider API must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}
	if envelope.RealERPWriteEnabled {
		return fmt.Errorf("%w: real ERP write must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}

	receivedAt := envelope.ReceivedAt
	if receivedAt.IsZero() {
		receivedAt = time.Now().UTC()
	}
	maxSkew := envelope.MaxSkew
	if maxSkew <= 0 {
		maxSkew = 5 * time.Minute
	}
	if absDuration(receivedAt.Sub(envelope.Timestamp)) > maxSkew {
		return fmt.Errorf("%w: webhook timestamp skew exceeded", ErrInvalidIntegrationRequest)
	}
	return nil
}

func absDuration(duration time.Duration) time.Duration {
	if duration < 0 {
		return -duration
	}
	return duration
}

type ParasutWebhookEventMapping struct {
	EventType  ParasutWebhookEventType
	ObjectType ParasutERPObjectType
	Operation  ConnectorOperation
	Status     ParasutWebhookSyncTriggerStatus
}

func MapParasutWebhookEventToSync(eventType ParasutWebhookEventType) (ParasutWebhookEventMapping, error) {
	switch eventType {
	case ParasutWebhookEventCustomerCreated, ParasutWebhookEventCustomerUpdated:
		return ParasutWebhookEventMapping{
			EventType:  eventType,
			ObjectType: ParasutERPObjectCustomer,
			Operation:  ConnectorOperationSyncCustomer,
			Status:     ParasutWebhookStatusEventMapped,
		}, nil
	case ParasutWebhookEventProductCreated, ParasutWebhookEventProductUpdated:
		return ParasutWebhookEventMapping{
			EventType:  eventType,
			ObjectType: ParasutERPObjectProduct,
			Operation:  ConnectorOperationSyncProduct,
			Status:     ParasutWebhookStatusEventMapped,
		}, nil
	case ParasutWebhookEventSalesInvoiceCreated, ParasutWebhookEventSalesInvoiceUpdated:
		return ParasutWebhookEventMapping{
			EventType:  eventType,
			ObjectType: ParasutERPObjectInvoice,
			Operation:  ConnectorOperationPullInvoice,
			Status:     ParasutWebhookStatusEventMapped,
		}, nil
	default:
		return ParasutWebhookEventMapping{}, fmt.Errorf("%w: unsupported parasut webhook event type", ErrInvalidIntegrationRequest)
	}
}

type ParasutWebhookIdempotencyRecord struct {
	TenantID       string
	ProviderKey    string
	AppKey         string
	EventID        string
	IdempotencyKey string
	CorrelationID  string
	CreatedAt      time.Time
}

type InMemoryParasutWebhookIdempotencyStore struct {
	records map[string]ParasutWebhookIdempotencyRecord
}

func NewInMemoryParasutWebhookIdempotencyStore() *InMemoryParasutWebhookIdempotencyStore {
	return &InMemoryParasutWebhookIdempotencyStore{
		records: map[string]ParasutWebhookIdempotencyRecord{},
	}
}

func BuildParasutWebhookIdempotencyKey(tenantID string, eventID string) string {
	return fmt.Sprintf("%s:%s:webhook:%s", normalize(tenantID), ParasutProviderKey, normalize(eventID))
}

func (store *InMemoryParasutWebhookIdempotencyStore) RecordFirstSeen(event ParasutVerifiedWebhookEvent) (bool, ParasutWebhookIdempotencyRecord, error) {
	if store == nil {
		return false, ParasutWebhookIdempotencyRecord{}, fmt.Errorf("%w: webhook idempotency store required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutVerifiedWebhookEvent(event); err != nil {
		return false, ParasutWebhookIdempotencyRecord{}, err
	}

	key := BuildParasutWebhookIdempotencyKey(event.TenantID, event.EventID)
	if existing, ok := store.records[key]; ok {
		return false, existing, nil
	}

	record := ParasutWebhookIdempotencyRecord{
		TenantID:       event.TenantID,
		ProviderKey:    ParasutProviderKey,
		AppKey:         event.AppKey,
		EventID:        event.EventID,
		IdempotencyKey: key,
		CorrelationID:  event.CorrelationID,
		CreatedAt:      event.ReceivedAt,
	}
	store.records[key] = record

	return true, record, nil
}

func validateParasutVerifiedWebhookEvent(event ParasutVerifiedWebhookEvent) error {
	if err := requireNonEmpty(event.TenantID, "tenant_id"); err != nil {
		return err
	}
	if event.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(event.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.EventID, "event_id"); err != nil {
		return err
	}
	if event.EventType == "" {
		return fmt.Errorf("%w: event_type required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(event.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

type ParasutWebhookSyncTriggerRequest struct {
	VerifiedEvent           ParasutVerifiedWebhookEvent
	IntegrationState        ParasutTenantIntegrationState
	TokenLifecycle          ParasutTokenLifecycle
	AccessTokenRef          string
	Source                  ParasutSyncSourceEnvelope
	RequestedBy             string
	RealProviderAPIEnabled  bool
	RealERPWriteEnabled     bool
	RealTokenRefreshEnabled bool
}

type ParasutWebhookSyncTriggerResult struct {
	TenantID         string
	ProviderKey      string
	AppKey           string
	EventID          string
	EventType        ParasutWebhookEventType
	ObjectType       ParasutERPObjectType
	Operation        ConnectorOperation
	IdempotencyKey   string
	Status           ParasutWebhookSyncTriggerStatus
	WorkerResult     ParasutSyncWorkerResult
	DuplicateIgnored bool
	AuditRecorded    bool
	RealProviderAPI  bool
	RealERPWrite     bool
	AuditDecision    AuditDecision
	CorrelationID    string
	CreatedAt        time.Time
}

func TriggerParasutSyncWorkerFromWebhook(
	obs *ConnectorObservabilityRuntime,
	store *InMemoryParasutWebhookIdempotencyStore,
	req ParasutWebhookSyncTriggerRequest,
) (ParasutWebhookSyncTriggerResult, error) {
	if err := validateParasutWebhookSyncTriggerRequest(req); err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}

	mapping, err := MapParasutWebhookEventToSync(req.VerifiedEvent.EventType)
	if err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}

	firstSeen, idemRecord, err := store.RecordFirstSeen(req.VerifiedEvent)
	if err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := time.Now().UTC()

	if !firstSeen {
		result := ParasutWebhookSyncTriggerResult{
			TenantID:         req.VerifiedEvent.TenantID,
			ProviderKey:      ParasutProviderKey,
			AppKey:           req.VerifiedEvent.AppKey,
			EventID:          req.VerifiedEvent.EventID,
			EventType:        req.VerifiedEvent.EventType,
			ObjectType:       mapping.ObjectType,
			Operation:        mapping.Operation,
			IdempotencyKey:   idemRecord.IdempotencyKey,
			Status:           ParasutWebhookStatusDuplicateIgnored,
			DuplicateIgnored: true,
			RealProviderAPI:  false,
			RealERPWrite:     false,
			AuditDecision:    AuditDecisionAllowed,
			CorrelationID:    req.VerifiedEvent.CorrelationID,
			CreatedAt:        now,
		}
		if err := RecordParasutWebhookTriggerAudit(obs, result); err != nil {
			return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
		}
		result.AuditRecorded = true
		return result, nil
	}

	schedule, err := BuildParasutSyncJobSchedule(ParasutSyncJobSchedule{
		JobKey:        "parasut-webhook-trigger-" + req.VerifiedEvent.EventID,
		TenantID:      req.VerifiedEvent.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        req.VerifiedEvent.AppKey,
		Operation:     mapping.Operation,
		RequestedBy:   req.RequestedBy,
		CorrelationID: req.VerifiedEvent.CorrelationID,
	})
	if err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}

	workerResult, err := ExecuteParasutSyncWorkerDryRun(obs, ParasutSyncWorkerRequest{
		Schedule:                schedule,
		IntegrationState:        req.IntegrationState,
		TokenLifecycle:          req.TokenLifecycle,
		AccessTokenRef:          req.AccessTokenRef,
		IdempotencyKey:          idemRecord.IdempotencyKey,
		Source:                  req.Source,
		RequestedBy:             req.RequestedBy,
		CorrelationID:           req.VerifiedEvent.CorrelationID,
		RealProviderAPIEnabled:  req.RealProviderAPIEnabled,
		RealERPWriteEnabled:     req.RealERPWriteEnabled,
		RealTokenRefreshEnabled: req.RealTokenRefreshEnabled,
	})
	if err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}

	result := ParasutWebhookSyncTriggerResult{
		TenantID:         req.VerifiedEvent.TenantID,
		ProviderKey:      ParasutProviderKey,
		AppKey:           req.VerifiedEvent.AppKey,
		EventID:          req.VerifiedEvent.EventID,
		EventType:        req.VerifiedEvent.EventType,
		ObjectType:       mapping.ObjectType,
		Operation:        mapping.Operation,
		IdempotencyKey:   idemRecord.IdempotencyKey,
		Status:           ParasutWebhookStatusSyncWorkerTriggered,
		WorkerResult:     workerResult,
		DuplicateIgnored: false,
		RealProviderAPI:  false,
		RealERPWrite:     false,
		AuditDecision:    AuditDecisionAllowed,
		CorrelationID:    req.VerifiedEvent.CorrelationID,
		CreatedAt:        now,
	}
	if err := RecordParasutWebhookTriggerAudit(obs, result); err != nil {
		return ParasutWebhookSyncTriggerResult{AuditDecision: AuditDecisionDenied}, err
	}
	result.AuditRecorded = true

	return result, nil
}

func validateParasutWebhookSyncTriggerRequest(req ParasutWebhookSyncTriggerRequest) error {
	if err := validateParasutVerifiedWebhookEvent(req.VerifiedEvent); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AccessTokenRef, "access_token_ref"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.VerifiedEvent.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutSyncSourceEnvelope(req.Source); err != nil {
		return err
	}
	if req.Source.ObjectType != mustMapParasutWebhookObjectType(req.VerifiedEvent.EventType) {
		return fmt.Errorf("%w: webhook source object type mismatch", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if req.RealProviderAPIEnabled {
		return fmt.Errorf("%w: real provider API must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}
	if req.RealERPWriteEnabled {
		return fmt.Errorf("%w: real ERP write must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}
	if req.RealTokenRefreshEnabled {
		return fmt.Errorf("%w: real token refresh must remain disabled in webhook sync trigger phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func mustMapParasutWebhookObjectType(eventType ParasutWebhookEventType) ParasutERPObjectType {
	mapping, err := MapParasutWebhookEventToSync(eventType)
	if err != nil {
		return ""
	}
	return mapping.ObjectType
}

func RecordParasutWebhookTriggerAudit(obs *ConnectorObservabilityRuntime, result ParasutWebhookSyncTriggerResult) error {
	if obs == nil {
		return fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(result.TenantID, "tenant_id"); err != nil {
		return err
	}
	if result.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(result.EventID, "event_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(result.CorrelationID, "correlation_id"); err != nil {
		return err
	}

	status := "TRIGGERED"
	if result.DuplicateIgnored {
		status = "DUPLICATE_IGNORED"
	}

	return obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      result.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        result.AppKey,
		Operation:     "WEBHOOK_TRIGGER_" + string(result.EventType),
		Status:        status,
		Decision:      result.AuditDecision,
		CorrelationID: result.CorrelationID,
		Message:       result.EventID,
		CreatedAt:     result.CreatedAt,
	})
}

type ParasutWebhookFailureDecision struct {
	Status        ParasutWebhookSyncTriggerStatus
	Mapping       ParasutProviderErrorMapping
	RetryDecision RetryDecision
	DLQReady      bool
	AuditDecision AuditDecision
	CorrelationID string
}

func EvaluateParasutWebhookFailure(tenantID string, appKey string, eventID string, eventType ParasutWebhookEventType, httpStatus int, providerMessage string, attempt int, correlationID string) (ParasutWebhookFailureDecision, error) {
	if err := requireNonEmpty(tenantID, "tenant_id"); err != nil {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(appKey, "app_key"); err != nil {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(eventID, "event_id"); err != nil {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, err
	}
	if eventType == "" {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: event_type required", ErrInvalidIntegrationRequest)
	}
	if attempt <= 0 {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: attempt must be positive", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(correlationID, "correlation_id"); err != nil {
		return ParasutWebhookFailureDecision{AuditDecision: AuditDecisionDenied}, err
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
		TenantID:      normalize(tenantID),
		ProviderKey:   ParasutProviderKey,
		AppKey:        normalize(appKey),
		Operation:     "WEBHOOK_TRIGGER_" + string(eventType),
		Attempt:       attempt,
		Kind:          kind,
		ErrorCode:     string(mapping.Code),
		CorrelationID: normalize(correlationID),
		Payload:       "event_id=" + normalize(eventID),
	})

	return ParasutWebhookFailureDecision{
		Status:        ParasutWebhookStatusFailureDecisionReady,
		Mapping:       mapping,
		RetryDecision: retryDecision,
		DLQReady:      mapping.MoveToDLQ,
		AuditDecision: AuditDecisionAllowed,
		CorrelationID: normalize(correlationID),
	}, nil
}

type ParasutWebhookSyncTriggerReadinessGateInput struct {
	WebhookIntakeSignatureReady  bool
	EventTypeMappingReady        bool
	IdempotencyDuplicateReady    bool
	SyncWorkerTriggerReady       bool
	RetryDLQReady                bool
	AuditObservabilityReady      bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealWebhookEndpointEnabled   bool
	RealProviderAPIEnabled       bool
	RealERPWriteEnabled          bool
	RealQueueTriggerEnabled      bool
}

type ParasutWebhookSyncTriggerReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutWebhookSyncTriggerReadinessGate(input ParasutWebhookSyncTriggerReadinessGateInput) ParasutWebhookSyncTriggerReadinessGateResult {
	blockers := []string{}

	if !input.WebhookIntakeSignatureReady {
		blockers = append(blockers, "webhook_intake_signature_not_ready")
	}
	if !input.EventTypeMappingReady {
		blockers = append(blockers, "event_type_mapping_not_ready")
	}
	if !input.IdempotencyDuplicateReady {
		blockers = append(blockers, "idempotency_duplicate_not_ready")
	}
	if !input.SyncWorkerTriggerReady {
		blockers = append(blockers, "sync_worker_trigger_not_ready")
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
	if input.RealWebhookEndpointEnabled {
		blockers = append(blockers, "real_webhook_endpoint_must_remain_false_in_webhook_trigger_phase")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_webhook_trigger_phase")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_webhook_trigger_phase")
	}
	if input.RealQueueTriggerEnabled {
		blockers = append(blockers, "real_queue_trigger_must_remain_false_in_webhook_trigger_phase")
	}

	if len(blockers) > 0 {
		return ParasutWebhookSyncTriggerReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutWebhookSyncTriggerReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_WEBHOOK_SYNC_TRIGGER_DRY_RUN_READY_WITH_REAL_API_AND_ERP_WRITE_CLOSED",
		Blockers: []string{},
	}
}
