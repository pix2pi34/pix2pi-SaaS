package reviewqueue

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	contactextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/contactextraction"
	ocrprocessing "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/ocrprocessing"
	taxextraction "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/documentai/taxextraction"
)

type ReviewSourceType string

const (
	ReviewSourceOCR     ReviewSourceType = "OCR"
	ReviewSourceTax     ReviewSourceType = "TAX_EXTRACTION"
	ReviewSourceContact ReviewSourceType = "CONTACT_EXTRACTION"
)

type ReviewStatus string

const (
	ReviewStatusOpen             ReviewStatus = "OPEN"
	ReviewStatusAssigned         ReviewStatus = "ASSIGNED"
	ReviewStatusResolvedApproved ReviewStatus = "RESOLVED_APPROVED"
	ReviewStatusResolvedRejected ReviewStatus = "RESOLVED_REJECTED"
	ReviewStatusDismissed        ReviewStatus = "DISMISSED"
)

type ReviewPriority string

const (
	ReviewPriorityLow      ReviewPriority = "LOW"
	ReviewPriorityMedium   ReviewPriority = "MEDIUM"
	ReviewPriorityHigh     ReviewPriority = "HIGH"
	ReviewPriorityCritical ReviewPriority = "CRITICAL"
)

type ReviewAction string

const (
	ReviewActionRegister       ReviewAction = "REGISTER"
	ReviewActionAssign         ReviewAction = "ASSIGN"
	ReviewActionResolveApprove ReviewAction = "RESOLVE_APPROVE"
	ReviewActionResolveReject  ReviewAction = "RESOLVE_REJECT"
	ReviewActionDismiss        ReviewAction = "DISMISS"
	ReviewActionListOpen       ReviewAction = "LIST_OPEN"
)

type DecisionStatus string

const (
	DecisionAllowed DecisionStatus = "ALLOWED"
	DecisionDenied  DecisionStatus = "DENIED"
)

type RuntimeConfig struct {
	RuntimeEnabled            bool               `json:"runtime_enabled"`
	RequireTenantScope        bool               `json:"require_tenant_scope"`
	RequireSourceHash         bool               `json:"require_source_hash"`
	RequireReviewReason       bool               `json:"require_review_reason"`
	RequireActorForAction     bool               `json:"require_actor_for_action"`
	RequireAssigneeForAssign  bool               `json:"require_assignee_for_assign"`
	RequireResolutionNote     bool               `json:"require_resolution_note"`
	RequireDecisionHash       bool               `json:"require_decision_hash"`
	MinConfidenceBps          int                `json:"min_confidence_bps"`
	MediumPriorityBelowBps    int                `json:"medium_priority_below_bps"`
	HighPriorityBelowBps      int                `json:"high_priority_below_bps"`
	CriticalPriorityBelowBps  int                `json:"critical_priority_below_bps"`
	CriticalMissingFieldCount int                `json:"critical_missing_field_count"`
	MaxOpenItemsPerTenant     int                `json:"max_open_items_per_tenant"`
	AllowedSourceTypes        []ReviewSourceType `json:"allowed_source_types"`
	AllowedStatuses           []ReviewStatus     `json:"allowed_statuses"`
	AllowedActions            []ReviewAction     `json:"allowed_actions"`
}

type ReviewItem struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReviewID   string           `json:"review_id"`
	SourceType ReviewSourceType `json:"source_type"`
	SourceID   string           `json:"source_id"`
	DocumentID string           `json:"document_id"`
	SourceHash string           `json:"source_hash"`

	Status   ReviewStatus   `json:"status"`
	Priority ReviewPriority `json:"priority"`

	ConfidenceBps int      `json:"confidence_bps"`
	MissingFields []string `json:"missing_fields"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	AssignedTo string    `json:"assigned_to"`
	AssignedAt time.Time `json:"assigned_at"`

	ResolvedBy     string    `json:"resolved_by"`
	ResolutionNote string    `json:"resolution_note"`
	ResolvedAt     time.Time `json:"resolved_at"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ReviewDecision struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	Action   ReviewAction   `json:"action"`
	Status   DecisionStatus `json:"status"`
	Allowed  bool           `json:"allowed"`
	ReviewID string         `json:"review_id"`

	Item ReviewItem `json:"item"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	DecisionHash string `json:"decision_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type ReviewRegisterRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReviewID   string           `json:"review_id"`
	SourceType ReviewSourceType `json:"source_type"`
	SourceID   string           `json:"source_id"`
	DocumentID string           `json:"document_id"`
	SourceHash string           `json:"source_hash"`

	ConfidenceBps int      `json:"confidence_bps"`
	MissingFields []string `json:"missing_fields"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	RequestedAt time.Time `json:"requested_at"`
}

type ReviewActionRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReviewID string       `json:"review_id"`
	Action   ReviewAction `json:"action"`

	ActorID        string `json:"actor_id"`
	AssigneeID     string `json:"assignee_id"`
	ResolutionNote string `json:"resolution_note"`

	RequestedAt time.Time `json:"requested_at"`
}

type ReviewListRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SourceType  ReviewSourceType `json:"source_type"`
	RequestedAt time.Time        `json:"requested_at"`
}

type ReviewListResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	Items []ReviewItem `json:"items"`

	OpenCount     int `json:"open_count"`
	AssignedCount int `json:"assigned_count"`

	ResultHash string `json:"result_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	CreatedAt           time.Time `json:"created_at"`
}

type OCRReviewRegisterRequest struct {
	TenantID       string                      `json:"tenant_id"`
	CorrelationID  string                      `json:"correlation_id"`
	RequestID      string                      `json:"request_id"`
	IdempotencyKey string                      `json:"idempotency_key"`
	ReviewID       string                      `json:"review_id"`
	OCRResult      ocrprocessing.ProcessResult `json:"ocr_result"`
	RequestedAt    time.Time                   `json:"requested_at"`
}

type TaxReviewRegisterRequest struct {
	TenantID       string                                 `json:"tenant_id"`
	CorrelationID  string                                 `json:"correlation_id"`
	RequestID      string                                 `json:"request_id"`
	IdempotencyKey string                                 `json:"idempotency_key"`
	ReviewID       string                                 `json:"review_id"`
	TaxResult      taxextraction.TaxFieldExtractionResult `json:"tax_result"`
	RequestedAt    time.Time                              `json:"requested_at"`
}

type ContactReviewRegisterRequest struct {
	TenantID       string                                         `json:"tenant_id"`
	CorrelationID  string                                         `json:"correlation_id"`
	RequestID      string                                         `json:"request_id"`
	IdempotencyKey string                                         `json:"idempotency_key"`
	ReviewID       string                                         `json:"review_id"`
	ContactResult  contactextraction.ContactFieldExtractionResult `json:"contact_result"`
	RequestedAt    time.Time                                      `json:"requested_at"`
}

type ConfidenceReviewQueueRuntime struct {
	config RuntimeConfig
	mu     sync.Mutex
	items  map[string]ReviewItem
}

func NewConfidenceReviewQueueRuntime(config RuntimeConfig) (*ConfidenceReviewQueueRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("confidence review queue runtime is disabled")
	}
	if config.MinConfidenceBps <= 0 {
		return nil, errors.New("min_confidence_bps must be positive")
	}
	if config.CriticalPriorityBelowBps <= 0 {
		return nil, errors.New("critical_priority_below_bps must be positive")
	}
	if config.HighPriorityBelowBps <= config.CriticalPriorityBelowBps {
		return nil, errors.New("high_priority_below_bps must be greater than critical_priority_below_bps")
	}
	if config.MediumPriorityBelowBps <= config.HighPriorityBelowBps {
		return nil, errors.New("medium_priority_below_bps must be greater than high_priority_below_bps")
	}
	if config.CriticalMissingFieldCount <= 0 {
		return nil, errors.New("critical_missing_field_count must be positive")
	}
	if config.MaxOpenItemsPerTenant <= 0 {
		return nil, errors.New("max_open_items_per_tenant must be positive")
	}
	if len(config.AllowedSourceTypes) == 0 {
		return nil, errors.New("allowed_source_types are required")
	}
	if len(config.AllowedStatuses) == 0 {
		return nil, errors.New("allowed_statuses are required")
	}
	if len(config.AllowedActions) == 0 {
		return nil, errors.New("allowed_actions are required")
	}

	return &ConfidenceReviewQueueRuntime{
		config: config,
		items:  map[string]ReviewItem{},
	}, nil
}

func (r *ConfidenceReviewQueueRuntime) Register(req ReviewRegisterRequest) (ReviewDecision, error) {
	if err := r.validateRegister(req); err != nil {
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionRegister, req.ReviewID, ReviewItem{}, "VALIDATION_FAILED", err.Error()), err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	key := tenantReviewKey(req.TenantID, req.ReviewID)
	if _, exists := r.items[key]; exists {
		err := errors.New("review item already exists")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionRegister, req.ReviewID, r.items[key], "DUPLICATE_REVIEW", err.Error()), err
	}

	if r.openCountLocked(req.TenantID) >= r.config.MaxOpenItemsPerTenant {
		err := errors.New("max open items per tenant exceeded")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionRegister, req.ReviewID, ReviewItem{}, "MAX_OPEN_ITEMS_EXCEEDED", err.Error()), err
	}

	item := ReviewItem{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		ReviewID:       req.ReviewID,
		SourceType:     req.SourceType,
		SourceID:       req.SourceID,
		DocumentID:     req.DocumentID,
		SourceHash:     req.SourceHash,
		Status:         ReviewStatusOpen,
		Priority:       r.priority(req.ConfidenceBps, len(req.MissingFields)),
		ConfidenceBps:  req.ConfidenceBps,
		MissingFields:  append([]string(nil), req.MissingFields...),
		ReasonCode:     req.ReasonCode,
		Reason:         req.Reason,
		CreatedAt:      req.RequestedAt,
		UpdatedAt:      req.RequestedAt,
	}

	r.items[key] = item

	return r.allow(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionRegister, req.ReviewID, item, "REVIEW_REGISTERED", "review item registered"), nil
}

func (r *ConfidenceReviewQueueRuntime) RegisterOCRReview(req OCRReviewRegisterRequest) (ReviewDecision, error) {
	return r.Register(ReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		ReviewID:       req.ReviewID,
		SourceType:     ReviewSourceOCR,
		SourceID:       req.OCRResult.ProcessID,
		DocumentID:     req.OCRResult.DocumentID,
		SourceHash:     req.OCRResult.ResultHash,
		ConfidenceBps:  req.OCRResult.ConfidenceBps,
		MissingFields:  []string{},
		ReasonCode:     req.OCRResult.ReasonCode,
		Reason:         req.OCRResult.Reason,
		RequestedAt:    req.RequestedAt,
	})
}

func (r *ConfidenceReviewQueueRuntime) RegisterTaxReview(req TaxReviewRegisterRequest) (ReviewDecision, error) {
	missing := make([]string, 0, len(req.TaxResult.MissingRequiredFields))
	for _, field := range req.TaxResult.MissingRequiredFields {
		missing = append(missing, string(field))
	}

	return r.Register(ReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		ReviewID:       req.ReviewID,
		SourceType:     ReviewSourceTax,
		SourceID:       req.TaxResult.ExtractionID,
		DocumentID:     req.TaxResult.DocumentID,
		SourceHash:     req.TaxResult.ResultHash,
		ConfidenceBps:  req.TaxResult.ConfidenceBps,
		MissingFields:  missing,
		ReasonCode:     req.TaxResult.ReasonCode,
		Reason:         req.TaxResult.Reason,
		RequestedAt:    req.RequestedAt,
	})
}

func (r *ConfidenceReviewQueueRuntime) RegisterContactReview(req ContactReviewRegisterRequest) (ReviewDecision, error) {
	missing := make([]string, 0, len(req.ContactResult.MissingRequiredFields))
	for _, field := range req.ContactResult.MissingRequiredFields {
		missing = append(missing, string(field))
	}

	return r.Register(ReviewRegisterRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey,
		ReviewID:       req.ReviewID,
		SourceType:     ReviewSourceContact,
		SourceID:       req.ContactResult.ExtractionID,
		DocumentID:     req.ContactResult.DocumentID,
		SourceHash:     req.ContactResult.ResultHash,
		ConfidenceBps:  req.ContactResult.ConfidenceBps,
		MissingFields:  missing,
		ReasonCode:     req.ContactResult.ReasonCode,
		Reason:         req.ContactResult.Reason,
		RequestedAt:    req.RequestedAt,
	})
}

func (r *ConfidenceReviewQueueRuntime) Assign(req ReviewActionRequest) (ReviewDecision, error) {
	req.Action = ReviewActionAssign
	if err := r.validateAction(req); err != nil {
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionAssign, req.ReviewID, ReviewItem{}, "VALIDATION_FAILED", err.Error()), err
	}
	if r.config.RequireAssigneeForAssign && strings.TrimSpace(req.AssigneeID) == "" {
		err := errors.New("assignee_id is required")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionAssign, req.ReviewID, ReviewItem{}, "ASSIGNEE_REQUIRED", err.Error()), err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	item, err := r.findLocked(req.TenantID, req.ReviewID)
	if err != nil {
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionAssign, req.ReviewID, item, "REVIEW_NOT_FOUND", err.Error()), err
	}
	if item.Status != ReviewStatusOpen {
		err := errors.New("only OPEN review items can be assigned")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionAssign, req.ReviewID, item, "ASSIGN_STATUS_DENIED", err.Error()), err
	}

	item.Status = ReviewStatusAssigned
	item.AssignedTo = req.AssigneeID
	item.AssignedAt = req.RequestedAt
	item.UpdatedAt = req.RequestedAt
	r.items[tenantReviewKey(req.TenantID, req.ReviewID)] = item

	return r.allow(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, ReviewActionAssign, req.ReviewID, item, "REVIEW_ASSIGNED", "review item assigned"), nil
}

func (r *ConfidenceReviewQueueRuntime) ResolveApprove(req ReviewActionRequest) (ReviewDecision, error) {
	req.Action = ReviewActionResolveApprove
	return r.resolve(req, ReviewStatusResolvedApproved, "REVIEW_RESOLVED_APPROVED", "review item resolved as approved")
}

func (r *ConfidenceReviewQueueRuntime) ResolveReject(req ReviewActionRequest) (ReviewDecision, error) {
	req.Action = ReviewActionResolveReject
	return r.resolve(req, ReviewStatusResolvedRejected, "REVIEW_RESOLVED_REJECTED", "review item resolved as rejected")
}

func (r *ConfidenceReviewQueueRuntime) Dismiss(req ReviewActionRequest) (ReviewDecision, error) {
	req.Action = ReviewActionDismiss
	return r.resolve(req, ReviewStatusDismissed, "REVIEW_DISMISSED", "review item dismissed")
}

func (r *ConfidenceReviewQueueRuntime) ListOpen(req ReviewListRequest) (ReviewListResult, error) {
	if err := r.validateList(req); err != nil {
		return ReviewListResult{}, err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	items := make([]ReviewItem, 0)
	openCount := 0
	assignedCount := 0

	for _, item := range r.items {
		if item.TenantID != req.TenantID {
			continue
		}
		if req.SourceType != "" && item.SourceType != req.SourceType {
			continue
		}
		if item.Status == ReviewStatusOpen {
			openCount++
			items = append(items, item)
		}
		if item.Status == ReviewStatusAssigned {
			assignedCount++
			items = append(items, item)
		}
	}

	sort.SliceStable(items, func(i int, j int) bool {
		if priorityRank(items[i].Priority) == priorityRank(items[j].Priority) {
			return items[i].CreatedAt.Before(items[j].CreatedAt)
		}
		return priorityRank(items[i].Priority) > priorityRank(items[j].Priority)
	})

	return ReviewListResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		Items:               items,
		OpenCount:           openCount,
		AssignedCount:       assignedCount,
		ResultHash:          buildListHash(req, items),
		AuditAction:         "REVIEW_QUEUE_LIST_OPEN",
		AuditDecisionReason: "open and assigned review items listed",
		CreatedAt:           time.Now().UTC(),
	}, nil
}

func (r *ConfidenceReviewQueueRuntime) resolve(req ReviewActionRequest, targetStatus ReviewStatus, reasonCode string, reason string) (ReviewDecision, error) {
	if err := r.validateAction(req); err != nil {
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, req.Action, req.ReviewID, ReviewItem{}, "VALIDATION_FAILED", err.Error()), err
	}
	if r.config.RequireResolutionNote && strings.TrimSpace(req.ResolutionNote) == "" {
		err := errors.New("resolution_note is required")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, req.Action, req.ReviewID, ReviewItem{}, "RESOLUTION_NOTE_REQUIRED", err.Error()), err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	item, err := r.findLocked(req.TenantID, req.ReviewID)
	if err != nil {
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, req.Action, req.ReviewID, item, "REVIEW_NOT_FOUND", err.Error()), err
	}
	if item.Status != ReviewStatusOpen && item.Status != ReviewStatusAssigned {
		err := errors.New("only OPEN or ASSIGNED review items can be resolved")
		return r.deny(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, req.Action, req.ReviewID, item, "RESOLVE_STATUS_DENIED", err.Error()), err
	}

	item.Status = targetStatus
	item.ResolvedBy = req.ActorID
	item.ResolutionNote = req.ResolutionNote
	item.ResolvedAt = req.RequestedAt
	item.UpdatedAt = req.RequestedAt
	r.items[tenantReviewKey(req.TenantID, req.ReviewID)] = item

	return r.allow(req.TenantID, req.CorrelationID, req.RequestID, req.IdempotencyKey, req.Action, req.ReviewID, item, reasonCode, reason), nil
}

func (r *ConfidenceReviewQueueRuntime) validateRegister(req ReviewRegisterRequest) error {
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
	if strings.TrimSpace(req.ReviewID) == "" {
		return errors.New("review_id is required")
	}
	if !hasSourceType(r.config.AllowedSourceTypes, req.SourceType) {
		return errors.New("source_type is not allowed")
	}
	if strings.TrimSpace(req.SourceID) == "" {
		return errors.New("source_id is required")
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if r.config.RequireSourceHash && strings.TrimSpace(req.SourceHash) == "" {
		return errors.New("source_hash is required")
	}
	if req.ConfidenceBps < r.config.MinConfidenceBps {
		return errors.New("confidence_bps is below minimum")
	}
	if r.config.RequireReviewReason && strings.TrimSpace(req.ReasonCode) == "" {
		return errors.New("reason_code is required")
	}
	if r.config.RequireReviewReason && strings.TrimSpace(req.Reason) == "" {
		return errors.New("reason is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ConfidenceReviewQueueRuntime) validateAction(req ReviewActionRequest) error {
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
	if strings.TrimSpace(req.ReviewID) == "" {
		return errors.New("review_id is required")
	}
	if !hasAction(r.config.AllowedActions, req.Action) {
		return errors.New("action is not allowed")
	}
	if r.config.RequireActorForAction && strings.TrimSpace(req.ActorID) == "" {
		return errors.New("actor_id is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ConfidenceReviewQueueRuntime) validateList(req ReviewListRequest) error {
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
	if req.SourceType != "" && !hasSourceType(r.config.AllowedSourceTypes, req.SourceType) {
		return errors.New("source_type is not allowed")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ConfidenceReviewQueueRuntime) priority(confidence int, missingCount int) ReviewPriority {
	if missingCount >= r.config.CriticalMissingFieldCount {
		return ReviewPriorityCritical
	}
	if confidence < r.config.CriticalPriorityBelowBps {
		return ReviewPriorityCritical
	}
	if confidence < r.config.HighPriorityBelowBps {
		return ReviewPriorityHigh
	}
	if confidence < r.config.MediumPriorityBelowBps {
		return ReviewPriorityMedium
	}
	return ReviewPriorityLow
}

func (r *ConfidenceReviewQueueRuntime) openCountLocked(tenantID string) int {
	count := 0
	for _, item := range r.items {
		if item.TenantID == tenantID && (item.Status == ReviewStatusOpen || item.Status == ReviewStatusAssigned) {
			count++
		}
	}
	return count
}

func (r *ConfidenceReviewQueueRuntime) findLocked(tenantID string, reviewID string) (ReviewItem, error) {
	item, ok := r.items[tenantReviewKey(tenantID, reviewID)]
	if !ok {
		return ReviewItem{}, errors.New("review item not found")
	}
	return item, nil
}

func (r *ConfidenceReviewQueueRuntime) allow(tenantID string, correlationID string, requestID string, idempotencyKey string, action ReviewAction, reviewID string, item ReviewItem, reasonCode string, reason string) ReviewDecision {
	return ReviewDecision{
		TenantID:            tenantID,
		CorrelationID:       correlationID,
		RequestID:           requestID,
		IdempotencyKey:      idempotencyKey,
		Action:              action,
		Status:              DecisionAllowed,
		Allowed:             true,
		ReviewID:            reviewID,
		Item:                item,
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(tenantID, action, reviewID, item, DecisionAllowed, reasonCode),
		AuditAction:         "REVIEW_QUEUE_DECISION_ALLOWED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func (r *ConfidenceReviewQueueRuntime) deny(tenantID string, correlationID string, requestID string, idempotencyKey string, action ReviewAction, reviewID string, item ReviewItem, reasonCode string, reason string) ReviewDecision {
	return ReviewDecision{
		TenantID:            tenantID,
		CorrelationID:       correlationID,
		RequestID:           requestID,
		IdempotencyKey:      idempotencyKey,
		Action:              action,
		Status:              DecisionDenied,
		Allowed:             false,
		ReviewID:            reviewID,
		Item:                item,
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(tenantID, action, reviewID, item, DecisionDenied, reasonCode),
		AuditAction:         "REVIEW_QUEUE_DECISION_DENIED",
		AuditDecisionReason: reason,
		ErrorCode:           reasonCode,
		ErrorMessage:        reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func hasSourceType(items []ReviewSourceType, value ReviewSourceType) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func hasAction(items []ReviewAction, value ReviewAction) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}

func tenantReviewKey(tenantID string, reviewID string) string {
	return tenantID + ":" + reviewID
}

func priorityRank(priority ReviewPriority) int {
	switch priority {
	case ReviewPriorityCritical:
		return 4
	case ReviewPriorityHigh:
		return 3
	case ReviewPriorityMedium:
		return 2
	case ReviewPriorityLow:
		return 1
	default:
		return 0
	}
}

func buildDecisionHash(tenantID string, action ReviewAction, reviewID string, item ReviewItem, status DecisionStatus, reasonCode string) string {
	parts := []string{
		tenantID,
		string(action),
		reviewID,
		string(item.SourceType),
		item.SourceID,
		string(item.Status),
		string(item.Priority),
		string(status),
		reasonCode,
	}
	return "review-queue-decision:" + strings.Join(parts, ":")
}

func buildListHash(req ReviewListRequest, items []ReviewItem) string {
	parts := []string{
		req.TenantID,
		string(req.SourceType),
		fmt.Sprintf("items:%d", len(items)),
	}
	for _, item := range items {
		parts = append(parts, item.ReviewID+":"+string(item.Status)+":"+string(item.Priority))
	}
	return "review-queue-list:" + strings.Join(parts, ":")
}
