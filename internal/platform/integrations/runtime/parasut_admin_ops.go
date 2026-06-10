package integrationruntime

import (
	"fmt"
	"sort"
	"time"
)

type ParasutAdminReviewType string

const (
	ParasutAdminReviewTypeFailedSync     ParasutAdminReviewType = "FAILED_SYNC"
	ParasutAdminReviewTypeRetryReview    ParasutAdminReviewType = "RETRY_REVIEW"
	ParasutAdminReviewTypeWebhookDispute ParasutAdminReviewType = "WEBHOOK_DISPUTE"
	ParasutAdminReviewTypeTokenReview    ParasutAdminReviewType = "TOKEN_REVIEW"
)

type ParasutAdminReviewStatus string

const (
	ParasutAdminReviewStatusOpen           ParasutAdminReviewStatus = "OPEN"
	ParasutAdminReviewStatusAssigned       ParasutAdminReviewStatus = "ASSIGNED"
	ParasutAdminReviewStatusRetryRequested ParasutAdminReviewStatus = "RETRY_REQUESTED"
	ParasutAdminReviewStatusIgnored        ParasutAdminReviewStatus = "IGNORED"
	ParasutAdminReviewStatusResolved       ParasutAdminReviewStatus = "RESOLVED"
	ParasutAdminReviewStatusRejected       ParasutAdminReviewStatus = "REJECTED"
)

type ParasutAdminOpsAction string

const (
	ParasutAdminOpsActionAssign  ParasutAdminOpsAction = "ASSIGN"
	ParasutAdminOpsActionRetry   ParasutAdminOpsAction = "RETRY"
	ParasutAdminOpsActionIgnore  ParasutAdminOpsAction = "IGNORE"
	ParasutAdminOpsActionResolve ParasutAdminOpsAction = "RESOLVE"
	ParasutAdminOpsActionReject  ParasutAdminOpsAction = "REJECT"
)

type ParasutAdminReviewItem struct {
	TenantID            string
	ProviderKey         string
	AppKey              string
	ReviewID            string
	ReviewType          ParasutAdminReviewType
	Status              ParasutAdminReviewStatus
	Operation           ConnectorOperation
	ObjectType          ParasutERPObjectType
	SourceEventID       string
	ProviderObjectID    string
	FailureCode         string
	Reason              string
	AssignedTo          string
	RetryRequested      bool
	RealRetryJob        bool
	RealProviderAPI     bool
	RealERPWrite        bool
	RealWebhookEndpoint bool
	CorrelationID       string
	CreatedAt           time.Time
	UpdatedAt           time.Time
	AuditDecision       AuditDecision
}

type ParasutAdminReviewCreateRequest struct {
	TenantID            string
	ProviderKey         string
	AppKey              string
	ReviewID            string
	ReviewType          ParasutAdminReviewType
	Operation           ConnectorOperation
	ObjectType          ParasutERPObjectType
	SourceEventID       string
	ProviderObjectID    string
	FailureCode         string
	Reason              string
	CorrelationID       string
	RealRetryJob        bool
	RealProviderAPI     bool
	RealERPWrite        bool
	RealWebhookEndpoint bool
	Now                 time.Time
}

type ParasutAdminReviewListFilter struct {
	TenantID    string
	ProviderKey string
	AppKey      string
	Status      ParasutAdminReviewStatus
}

type ParasutAdminReviewActionRequest struct {
	TenantID            string
	ReviewID            string
	Action              ParasutAdminOpsAction
	Actor               string
	Reason              string
	CorrelationID       string
	AssignTo            string
	RealRetryJob        bool
	RealProviderAPI     bool
	RealERPWrite        bool
	RealWebhookEndpoint bool
	Now                 time.Time
}

type ParasutAdminReviewActionResult struct {
	TenantID       string
	ReviewID       string
	Action         ParasutAdminOpsAction
	PreviousStatus ParasutAdminReviewStatus
	NewStatus      ParasutAdminReviewStatus
	AssignedTo     string
	RetryRequested bool
	RealRetryJob   bool
	AuditDecision  AuditDecision
	CorrelationID  string
	CreatedAt      time.Time
}

type ParasutAdminOpsQueueSnapshot struct {
	Total               int
	Open                int
	Assigned            int
	RetryRequested      int
	Ignored             int
	Resolved            int
	Rejected            int
	ByTenant            map[string]int
	ByStatus            map[ParasutAdminReviewStatus]int
	RealRetryJob        bool
	RealProviderAPI     bool
	RealERPWrite        bool
	RealWebhookEndpoint bool
}

type InMemoryParasutAdminOpsReviewQueue struct {
	items map[string]ParasutAdminReviewItem
}

func NewInMemoryParasutAdminOpsReviewQueue() *InMemoryParasutAdminOpsReviewQueue {
	return &InMemoryParasutAdminOpsReviewQueue{
		items: map[string]ParasutAdminReviewItem{},
	}
}

func BuildParasutAdminReviewKey(tenantID string, reviewID string) string {
	return normalize(tenantID) + ":parasut:review:" + normalize(reviewID)
}

func (queue *InMemoryParasutAdminOpsReviewQueue) EnqueueReview(req ParasutAdminReviewCreateRequest) (ParasutAdminReviewItem, error) {
	if queue == nil {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: admin ops review queue required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutAdminReviewCreateRequest(req); err != nil {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	item := ParasutAdminReviewItem{
		TenantID:            normalize(req.TenantID),
		ProviderKey:         ParasutProviderKey,
		AppKey:              normalize(req.AppKey),
		ReviewID:            normalize(req.ReviewID),
		ReviewType:          req.ReviewType,
		Status:              ParasutAdminReviewStatusOpen,
		Operation:           req.Operation,
		ObjectType:          req.ObjectType,
		SourceEventID:       normalize(req.SourceEventID),
		ProviderObjectID:    normalize(req.ProviderObjectID),
		FailureCode:         normalize(req.FailureCode),
		Reason:              normalize(req.Reason),
		RetryRequested:      false,
		RealRetryJob:        false,
		RealProviderAPI:     false,
		RealERPWrite:        false,
		RealWebhookEndpoint: false,
		CorrelationID:       normalize(req.CorrelationID),
		CreatedAt:           now,
		UpdatedAt:           now,
		AuditDecision:       AuditDecisionAllowed,
	}

	queue.items[BuildParasutAdminReviewKey(item.TenantID, item.ReviewID)] = item
	return item, nil
}

func validateParasutAdminReviewCreateRequest(req ParasutAdminReviewCreateRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if normalize(req.ProviderKey) != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ReviewID, "review_id"); err != nil {
		return err
	}
	if req.ReviewType == "" {
		return fmt.Errorf("%w: review_type required", ErrInvalidIntegrationRequest)
	}
	if req.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if req.ObjectType == "" {
		return fmt.Errorf("%w: object_type required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.SourceEventID, "source_event_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Reason, "reason"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealRetryJob {
		return fmt.Errorf("%w: real retry job must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealProviderAPI {
		return fmt.Errorf("%w: real provider API must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealERPWrite {
		return fmt.Errorf("%w: real ERP write must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealWebhookEndpoint {
		return fmt.Errorf("%w: real webhook endpoint must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func (queue *InMemoryParasutAdminOpsReviewQueue) ListByTenant(filter ParasutAdminReviewListFilter) ([]ParasutAdminReviewItem, error) {
	if queue == nil {
		return nil, fmt.Errorf("%w: admin ops review queue required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(filter.TenantID, "tenant_id"); err != nil {
		return nil, err
	}

	results := []ParasutAdminReviewItem{}
	for _, item := range queue.items {
		if item.TenantID != normalize(filter.TenantID) {
			continue
		}
		if filter.ProviderKey != "" && item.ProviderKey != normalize(filter.ProviderKey) {
			continue
		}
		if filter.AppKey != "" && item.AppKey != normalize(filter.AppKey) {
			continue
		}
		if filter.Status != "" && item.Status != filter.Status {
			continue
		}
		results = append(results, item)
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].ReviewID < results[j].ReviewID
	})

	return results, nil
}

func (queue *InMemoryParasutAdminOpsReviewQueue) ReadByTenant(tenantID string, reviewID string) (ParasutAdminReviewItem, error) {
	if queue == nil {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: admin ops review queue required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(tenantID, "tenant_id"); err != nil {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(reviewID, "review_id"); err != nil {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, err
	}

	item, ok := queue.items[BuildParasutAdminReviewKey(tenantID, reviewID)]
	if !ok {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: review item not found for tenant", ErrInvalidIntegrationRequest)
	}
	if item.TenantID != normalize(tenantID) {
		return ParasutAdminReviewItem{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: cross-tenant review read rejected", ErrInvalidIntegrationRequest)
	}

	return item, nil
}

func (queue *InMemoryParasutAdminOpsReviewQueue) ApplyAction(req ParasutAdminReviewActionRequest) (ParasutAdminReviewActionResult, error) {
	if queue == nil {
		return ParasutAdminReviewActionResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: admin ops review queue required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutAdminReviewActionRequest(req); err != nil {
		return ParasutAdminReviewActionResult{AuditDecision: AuditDecisionDenied}, err
	}

	key := BuildParasutAdminReviewKey(req.TenantID, req.ReviewID)
	item, ok := queue.items[key]
	if !ok {
		return ParasutAdminReviewActionResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: review item not found for tenant", ErrInvalidIntegrationRequest)
	}
	if item.TenantID != normalize(req.TenantID) {
		return ParasutAdminReviewActionResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: cross-tenant review action rejected", ErrInvalidIntegrationRequest)
	}

	previousStatus := item.Status
	newStatus, retryRequested, assignedTo, err := applyParasutAdminOpsTransition(item, req)
	if err != nil {
		return ParasutAdminReviewActionResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	item.Status = newStatus
	item.RetryRequested = retryRequested
	if assignedTo != "" {
		item.AssignedTo = assignedTo
	}
	item.Reason = normalize(req.Reason)
	item.UpdatedAt = now
	item.CorrelationID = normalize(req.CorrelationID)
	queue.items[key] = item

	return ParasutAdminReviewActionResult{
		TenantID:       item.TenantID,
		ReviewID:       item.ReviewID,
		Action:         req.Action,
		PreviousStatus: previousStatus,
		NewStatus:      item.Status,
		AssignedTo:     item.AssignedTo,
		RetryRequested: item.RetryRequested,
		RealRetryJob:   false,
		AuditDecision:  AuditDecisionAllowed,
		CorrelationID:  item.CorrelationID,
		CreatedAt:      now,
	}, nil
}

func validateParasutAdminReviewActionRequest(req ParasutAdminReviewActionRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ReviewID, "review_id"); err != nil {
		return err
	}
	if req.Action == "" {
		return fmt.Errorf("%w: action required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.Actor, "actor"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Reason, "reason"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.Action == ParasutAdminOpsActionAssign {
		if err := requireNonEmpty(req.AssignTo, "assign_to"); err != nil {
			return err
		}
	}
	if req.RealRetryJob {
		return fmt.Errorf("%w: real retry job must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealProviderAPI {
		return fmt.Errorf("%w: real provider API must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealERPWrite {
		return fmt.Errorf("%w: real ERP write must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	if req.RealWebhookEndpoint {
		return fmt.Errorf("%w: real webhook endpoint must remain disabled in admin ops readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func applyParasutAdminOpsTransition(item ParasutAdminReviewItem, req ParasutAdminReviewActionRequest) (ParasutAdminReviewStatus, bool, string, error) {
	if isParasutAdminReviewTerminal(item.Status) {
		return "", false, "", fmt.Errorf("%w: terminal review item cannot be changed", ErrInvalidIntegrationRequest)
	}

	switch req.Action {
	case ParasutAdminOpsActionAssign:
		return ParasutAdminReviewStatusAssigned, item.RetryRequested, normalize(req.AssignTo), nil
	case ParasutAdminOpsActionRetry:
		if item.Status != ParasutAdminReviewStatusOpen && item.Status != ParasutAdminReviewStatusAssigned {
			return "", false, "", fmt.Errorf("%w: retry action allowed only from OPEN or ASSIGNED", ErrInvalidIntegrationRequest)
		}
		return ParasutAdminReviewStatusRetryRequested, true, item.AssignedTo, nil
	case ParasutAdminOpsActionIgnore:
		return ParasutAdminReviewStatusIgnored, false, item.AssignedTo, nil
	case ParasutAdminOpsActionResolve:
		return ParasutAdminReviewStatusResolved, false, item.AssignedTo, nil
	case ParasutAdminOpsActionReject:
		return ParasutAdminReviewStatusRejected, false, item.AssignedTo, nil
	default:
		return "", false, "", fmt.Errorf("%w: unsupported admin ops action", ErrInvalidIntegrationRequest)
	}
}

func isParasutAdminReviewTerminal(status ParasutAdminReviewStatus) bool {
	return status == ParasutAdminReviewStatusIgnored ||
		status == ParasutAdminReviewStatusResolved ||
		status == ParasutAdminReviewStatusRejected
}

func RecordParasutAdminOpsActionAudit(obs *ConnectorObservabilityRuntime, item ParasutAdminReviewItem, action ParasutAdminReviewActionResult) error {
	if obs == nil {
		return fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if err := validateParasutAdminReviewItem(item); err != nil {
		return err
	}
	if err := requireNonEmpty(action.CorrelationID, "correlation_id"); err != nil {
		return err
	}

	return obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      item.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        item.AppKey,
		Operation:     "ADMIN_OPS_" + string(action.Action),
		Status:        string(action.NewStatus),
		Decision:      action.AuditDecision,
		CorrelationID: action.CorrelationID,
		Message:       item.SourceEventID,
		CreatedAt:     action.CreatedAt,
	})
}

func validateParasutAdminReviewItem(item ParasutAdminReviewItem) error {
	if err := requireNonEmpty(item.TenantID, "tenant_id"); err != nil {
		return err
	}
	if item.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(item.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(item.ReviewID, "review_id"); err != nil {
		return err
	}
	if item.ReviewType == "" {
		return fmt.Errorf("%w: review_type required", ErrInvalidIntegrationRequest)
	}
	if item.Status == "" {
		return fmt.Errorf("%w: review_status required", ErrInvalidIntegrationRequest)
	}
	if item.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(item.SourceEventID, "source_event_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(item.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

func (queue *InMemoryParasutAdminOpsReviewQueue) Snapshot() ParasutAdminOpsQueueSnapshot {
	snapshot := ParasutAdminOpsQueueSnapshot{
		ByTenant: map[string]int{},
		ByStatus: map[ParasutAdminReviewStatus]int{},
	}

	if queue == nil {
		return snapshot
	}

	for _, item := range queue.items {
		snapshot.Total++
		snapshot.ByTenant[item.TenantID]++
		snapshot.ByStatus[item.Status]++

		switch item.Status {
		case ParasutAdminReviewStatusOpen:
			snapshot.Open++
		case ParasutAdminReviewStatusAssigned:
			snapshot.Assigned++
		case ParasutAdminReviewStatusRetryRequested:
			snapshot.RetryRequested++
		case ParasutAdminReviewStatusIgnored:
			snapshot.Ignored++
		case ParasutAdminReviewStatusResolved:
			snapshot.Resolved++
		case ParasutAdminReviewStatusRejected:
			snapshot.Rejected++
		}

		if item.RealRetryJob {
			snapshot.RealRetryJob = true
		}
		if item.RealProviderAPI {
			snapshot.RealProviderAPI = true
		}
		if item.RealERPWrite {
			snapshot.RealERPWrite = true
		}
		if item.RealWebhookEndpoint {
			snapshot.RealWebhookEndpoint = true
		}
	}

	return snapshot
}

type ParasutAdminOpsReadinessGateInput struct {
	ManualReviewQueueReady       bool
	TenantSafeAdminReadReady     bool
	OpsActionContractReady       bool
	AuditObservabilityReady      bool
	RetryProviderGateReady       bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealRetryJobEnabled          bool
	RealProviderAPIEnabled       bool
	RealERPWriteEnabled          bool
	RealWebhookEndpointEnabled   bool
}

type ParasutAdminOpsReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutAdminOpsReadinessGate(input ParasutAdminOpsReadinessGateInput) ParasutAdminOpsReadinessGateResult {
	blockers := []string{}

	if !input.ManualReviewQueueReady {
		blockers = append(blockers, "manual_review_queue_not_ready")
	}
	if !input.TenantSafeAdminReadReady {
		blockers = append(blockers, "tenant_safe_admin_read_not_ready")
	}
	if !input.OpsActionContractReady {
		blockers = append(blockers, "ops_action_contract_not_ready")
	}
	if !input.AuditObservabilityReady {
		blockers = append(blockers, "audit_observability_not_ready")
	}
	if !input.RetryProviderGateReady {
		blockers = append(blockers, "retry_provider_gate_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealRetryJobEnabled {
		blockers = append(blockers, "real_retry_job_must_remain_false_in_admin_ops_phase")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_admin_ops_phase")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_admin_ops_phase")
	}
	if input.RealWebhookEndpointEnabled {
		blockers = append(blockers, "real_webhook_endpoint_must_remain_false_in_admin_ops_phase")
	}

	if len(blockers) > 0 {
		return ParasutAdminOpsReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutAdminOpsReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_ADMIN_OPS_MANUAL_REVIEW_READY_WITH_REAL_API_ERP_WEBHOOK_CLOSED",
		Blockers: []string{},
	}
}
