package paymentadapter

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

var ErrPaymentAdminOpsInvalidDependency = errors.New("payment admin ops invalid dependency")
var ErrPaymentAdminOpsInvalidRequest = errors.New("payment admin ops invalid request")
var ErrPaymentAdminOpsReviewNotFound = errors.New("payment admin ops review not found")
var ErrPaymentAdminOpsActionDenied = errors.New("payment admin ops action denied")

type PaymentReviewType string

const (
	PaymentReviewFailedPayment  PaymentReviewType = "FAILED_PAYMENT"
	PaymentReviewRetryReview    PaymentReviewType = "RETRY_REVIEW"
	PaymentReviewWebhookDispute PaymentReviewType = "WEBHOOK_DISPUTE"
)

type PaymentReviewStatus string

const (
	PaymentReviewOpen     PaymentReviewStatus = "OPEN"
	PaymentReviewInReview PaymentReviewStatus = "IN_REVIEW"
	PaymentReviewResolved PaymentReviewStatus = "RESOLVED"
	PaymentReviewRejected PaymentReviewStatus = "REJECTED"
)

type PaymentOpsAction string

const (
	PaymentOpsActionAssign  PaymentOpsAction = "ASSIGN"
	PaymentOpsActionResolve PaymentOpsAction = "RESOLVE"
	PaymentOpsActionReject  PaymentOpsAction = "REJECT"
)

type PaymentManualReviewItem struct {
	ReviewID        string
	TenantID        string
	AttemptID       string
	ProviderCode    string
	ReviewType      PaymentReviewType
	Status          PaymentReviewStatus
	Priority        int
	Reason          string
	ErrorCode       ContractErrorCode
	CorrelationID   string
	AssignedTo      string
	CreatedAt       time.Time
	UpdatedAt       time.Time
	ResolvedMessage string
}

type PaymentOpsActionRequest struct {
	TenantID string
	ReviewID string
	Action   PaymentOpsAction
	Actor    string
	Message  string
}

type PaymentOpsAuditTrailQuery struct {
	TenantID  string
	AttemptID string
	EventType string
}

type PaymentAdminOpsRuntime struct {
	repo          PaymentAttemptRepository
	observability *PaymentObservabilityRuntime
	reviews       map[string]PaymentManualReviewItem
	now           func() time.Time
}

func NewPaymentAdminOpsRuntime(repo PaymentAttemptRepository, observability *PaymentObservabilityRuntime) (*PaymentAdminOpsRuntime, error) {
	if repo == nil {
		return nil, fmt.Errorf("%w: payment attempt repository is required", ErrPaymentAdminOpsInvalidDependency)
	}
	if observability == nil {
		return nil, fmt.Errorf("%w: payment observability runtime is required", ErrPaymentAdminOpsInvalidDependency)
	}

	return &PaymentAdminOpsRuntime{
		repo:          repo,
		observability: observability,
		reviews:       map[string]PaymentManualReviewItem{},
		now:           func() time.Time { return time.Now().UTC() },
	}, nil
}

func (r *PaymentAdminOpsRuntime) QueueFailedPayment(result PaymentOperationResult) (PaymentManualReviewItem, error) {
	attempt := result.Attempt
	if strings.TrimSpace(attempt.TenantID) == "" {
		return PaymentManualReviewItem{}, fmt.Errorf("%w: tenant id is required", ErrPaymentAdminOpsInvalidRequest)
	}
	if strings.TrimSpace(attempt.AttemptID) == "" {
		return PaymentManualReviewItem{}, fmt.Errorf("%w: attempt id is required", ErrPaymentAdminOpsInvalidRequest)
	}
	if attempt.Status != AttemptStatusFailed && attempt.FailureCode == ErrorNone {
		return PaymentManualReviewItem{}, fmt.Errorf("%w: only failed payment can be queued", ErrPaymentAdminOpsInvalidRequest)
	}

	item := r.newReviewItem(
		"review_failed_"+attempt.AttemptID,
		attempt,
		PaymentReviewFailedPayment,
		10,
		"failed payment requires manual review",
		attempt.FailureCode,
	)

	r.saveReview(item)
	return item, nil
}

func (r *PaymentAdminOpsRuntime) QueueRetryReview(tenantID string, attemptID string, decision PaymentRetryDecision) (PaymentManualReviewItem, error) {
	attempt, exists, err := r.repo.FindByAttemptID(tenantID, attemptID)
	if err != nil {
		return PaymentManualReviewItem{}, err
	}
	if !exists {
		return PaymentManualReviewItem{}, ErrPaymentAttemptNotFound
	}

	item := r.newReviewItem(
		"review_retry_"+attempt.AttemptID+"_"+strings.ToLower(string(decision.Status)),
		attempt,
		PaymentReviewRetryReview,
		5,
		decision.Message,
		decision.ErrorCode,
	)

	r.saveReview(item)
	return item, nil
}

func (r *PaymentAdminOpsRuntime) QueueWebhookDispute(tenantID string, attemptID string, reason string) (PaymentManualReviewItem, error) {
	if strings.TrimSpace(reason) == "" {
		return PaymentManualReviewItem{}, fmt.Errorf("%w: webhook dispute reason is required", ErrPaymentAdminOpsInvalidRequest)
	}

	attempt, exists, err := r.repo.FindByAttemptID(tenantID, attemptID)
	if err != nil {
		return PaymentManualReviewItem{}, err
	}
	if !exists {
		return PaymentManualReviewItem{}, ErrPaymentAttemptNotFound
	}

	item := r.newReviewItem(
		"review_webhook_"+attempt.AttemptID,
		attempt,
		PaymentReviewWebhookDispute,
		7,
		reason,
		attempt.FailureCode,
	)

	r.saveReview(item)
	return item, nil
}

func (r *PaymentAdminOpsRuntime) ListTenantReviews(tenantID string) ([]PaymentManualReviewItem, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, fmt.Errorf("%w: tenant id is required", ErrPaymentAdminOpsInvalidRequest)
	}

	var items []PaymentManualReviewItem
	for _, item := range r.reviews {
		if item.TenantID == tenantID {
			items = append(items, item)
		}
	}

	sort.SliceStable(items, func(i, j int) bool {
		if items[i].Priority == items[j].Priority {
			return items[i].CreatedAt.Before(items[j].CreatedAt)
		}
		return items[i].Priority > items[j].Priority
	})

	return items, nil
}

func (r *PaymentAdminOpsRuntime) GetReview(tenantID string, reviewID string) (PaymentManualReviewItem, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentManualReviewItem{}, false, fmt.Errorf("%w: tenant id is required", ErrPaymentAdminOpsInvalidRequest)
	}
	if strings.TrimSpace(reviewID) == "" {
		return PaymentManualReviewItem{}, false, fmt.Errorf("%w: review id is required", ErrPaymentAdminOpsInvalidRequest)
	}

	item, exists := r.reviews[paymentAdminOpsReviewKey(tenantID, reviewID)]
	if !exists {
		return PaymentManualReviewItem{}, false, nil
	}

	return item, true, nil
}

func (r *PaymentAdminOpsRuntime) ApplyAction(req PaymentOpsActionRequest) (PaymentManualReviewItem, error) {
	if strings.TrimSpace(req.Actor) == "" {
		return PaymentManualReviewItem{}, fmt.Errorf("%w: actor is required", ErrPaymentAdminOpsInvalidRequest)
	}

	item, exists, err := r.GetReview(req.TenantID, req.ReviewID)
	if err != nil {
		return PaymentManualReviewItem{}, err
	}
	if !exists {
		return PaymentManualReviewItem{}, ErrPaymentAdminOpsReviewNotFound
	}

	switch req.Action {
	case PaymentOpsActionAssign:
		if item.Status != PaymentReviewOpen {
			return PaymentManualReviewItem{}, fmt.Errorf("%w: assign requires OPEN status", ErrPaymentAdminOpsActionDenied)
		}
		item.Status = PaymentReviewInReview
		item.AssignedTo = req.Actor
	case PaymentOpsActionResolve:
		if item.Status != PaymentReviewInReview {
			return PaymentManualReviewItem{}, fmt.Errorf("%w: resolve requires IN_REVIEW status", ErrPaymentAdminOpsActionDenied)
		}
		item.Status = PaymentReviewResolved
		item.ResolvedMessage = req.Message
	case PaymentOpsActionReject:
		if item.Status != PaymentReviewInReview {
			return PaymentManualReviewItem{}, fmt.Errorf("%w: reject requires IN_REVIEW status", ErrPaymentAdminOpsActionDenied)
		}
		item.Status = PaymentReviewRejected
		item.ResolvedMessage = req.Message
	default:
		return PaymentManualReviewItem{}, fmt.Errorf("%w: unsupported ops action", ErrPaymentAdminOpsActionDenied)
	}

	item.UpdatedAt = r.now().UTC()
	r.saveReview(item)
	return item, nil
}

func (r *PaymentAdminOpsRuntime) ReadTenantAuditTrail(query PaymentOpsAuditTrailQuery) ([]PaymentAuditTrailRecord, error) {
	if strings.TrimSpace(query.TenantID) == "" {
		return nil, fmt.Errorf("%w: tenant id is required", ErrPaymentAdminOpsInvalidRequest)
	}

	records, err := r.observability.ExportTenantAuditTrail(query.TenantID)
	if err != nil {
		return nil, err
	}

	var filtered []PaymentAuditTrailRecord
	for _, record := range records {
		if strings.TrimSpace(query.AttemptID) != "" && record.AttemptID != query.AttemptID {
			continue
		}
		if strings.TrimSpace(query.EventType) != "" && record.EventType != query.EventType {
			continue
		}
		filtered = append(filtered, record)
	}

	return filtered, nil
}

func (r *PaymentAdminOpsRuntime) newReviewItem(reviewID string, attempt PaymentAttempt, reviewType PaymentReviewType, priority int, reason string, errorCode ContractErrorCode) PaymentManualReviewItem {
	now := r.now().UTC()
	return PaymentManualReviewItem{
		ReviewID:      reviewID,
		TenantID:      attempt.TenantID,
		AttemptID:     attempt.AttemptID,
		ProviderCode:  attempt.ProviderCode,
		ReviewType:    reviewType,
		Status:        PaymentReviewOpen,
		Priority:      priority,
		Reason:        reason,
		ErrorCode:     errorCode,
		CorrelationID: attempt.CorrelationID,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

func (r *PaymentAdminOpsRuntime) saveReview(item PaymentManualReviewItem) {
	r.reviews[paymentAdminOpsReviewKey(item.TenantID, item.ReviewID)] = item
}

func paymentAdminOpsReviewKey(tenantID string, reviewID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(reviewID)
}

func PaymentAdminOpsReviewTypes() []PaymentReviewType {
	return []PaymentReviewType{
		PaymentReviewFailedPayment,
		PaymentReviewRetryReview,
		PaymentReviewWebhookDispute,
	}
}

func PaymentAdminOpsReviewStatuses() []PaymentReviewStatus {
	return []PaymentReviewStatus{
		PaymentReviewOpen,
		PaymentReviewInReview,
		PaymentReviewResolved,
		PaymentReviewRejected,
	}
}

func PaymentAdminOpsActions() []PaymentOpsAction {
	return []PaymentOpsAction{
		PaymentOpsActionAssign,
		PaymentOpsActionResolve,
		PaymentOpsActionReject,
	}
}
