package zirve

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	ZirveAdminOpsModuleCode   = "FAZ_7_8Z_5"
	ZirveAdminOpsMode         = "ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY"
	ZirveAdminOpsStatus       = "READY_DRY_RUN_ONLY"
	ZirveAdminOpsQueuePolicy  = "QUEUE_VALIDATION_DLQ_AND_MANUAL_REVIEW_DECISIONS"
	ZirveAdminOpsActionPolicy = "ASSIGN_RESOLVE_REJECT_DRY_RUN_ONLY"
	ZirveAdminOpsAuditPolicy  = "EVERY_REVIEW_ACTION_REQUIRES_AUDIT_DECISION"
)

type ZirveManualReviewStatus string

const (
	ZirveManualReviewOpen     ZirveManualReviewStatus = "OPEN"
	ZirveManualReviewAssigned ZirveManualReviewStatus = "ASSIGNED"
	ZirveManualReviewResolved ZirveManualReviewStatus = "RESOLVED"
	ZirveManualReviewRejected ZirveManualReviewStatus = "REJECTED"
)

type ZirveManualReviewPriority string

const (
	ZirveManualReviewPriorityLow      ZirveManualReviewPriority = "LOW"
	ZirveManualReviewPriorityMedium   ZirveManualReviewPriority = "MEDIUM"
	ZirveManualReviewPriorityHigh     ZirveManualReviewPriority = "HIGH"
	ZirveManualReviewPriorityCritical ZirveManualReviewPriority = "CRITICAL"
)

type ZirveManualReviewAction string

const (
	ZirveManualReviewActionAssign  ZirveManualReviewAction = "ASSIGN"
	ZirveManualReviewActionResolve ZirveManualReviewAction = "RESOLVE"
	ZirveManualReviewActionReject  ZirveManualReviewAction = "REJECT"
)

type ZirveManualReviewSource string

const (
	ZirveManualReviewSourceValidationRetryDLQ ZirveManualReviewSource = "VALIDATION_RETRY_DLQ"
)

type ZirveManualReviewItem struct {
	ProviderID                        string
	ModuleCode                        string
	Mode                              string
	QueuePolicy                       string
	TenantID                          string
	ReviewID                          string
	Source                            ZirveManualReviewSource
	ValidationRunID                   string
	ExportRunID                       string
	DeliveryRunID                     string
	CorrelationID                     string
	ErrorCode                         ZirveValidationErrorCode
	Outcome                           ZirveValidationOutcome
	Priority                          ZirveManualReviewPriority
	Status                            ZirveManualReviewStatus
	AssignedTo                        string
	ResolutionNote                    string
	RejectionReason                   string
	RequiredAction                    string
	Decision                          ZirveValidationRetryDLQDecision
	AuditDecision                     OperationDecision
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	CreatedAtUTC                      time.Time
	UpdatedAtUTC                      time.Time
}

type ZirveManualReviewActionRequest struct {
	TenantID        string
	ReviewID        string
	Actor           string
	Action          ZirveManualReviewAction
	AssignTo        string
	ResolutionNote  string
	RejectionReason string
	CorrelationID   string
	DryRun          bool
	RequestedAt     time.Time
}

type ZirveAdminOpsRuntime struct {
	Identity ZirveProviderIdentity
	reviews  map[string]ZirveManualReviewItem
}

func NewZirveAdminOpsRuntime(identity ZirveProviderIdentity) ZirveAdminOpsRuntime {
	if strings.TrimSpace(identity.ProviderID) == "" {
		identity = NewZirveProviderIdentity(time.Now().UTC())
	}

	return ZirveAdminOpsRuntime{
		Identity: identity,
		reviews:  map[string]ZirveManualReviewItem{},
	}
}

func (r *ZirveAdminOpsRuntime) OpenManualReview(decision ZirveValidationRetryDLQDecision, reviewID string, requestedBy string, now time.Time) (ZirveManualReviewItem, error) {
	if err := r.Identity.Validate(); err != nil {
		return ZirveManualReviewItem{}, fmt.Errorf("zirve identity validation failed: %w", err)
	}

	if r.reviews == nil {
		r.reviews = map[string]ZirveManualReviewItem{}
	}

	reviewID = strings.TrimSpace(reviewID)
	requestedBy = strings.TrimSpace(requestedBy)

	if reviewID == "" {
		return ZirveManualReviewItem{}, errors.New("review id is required")
	}
	if requestedBy == "" {
		return ZirveManualReviewItem{}, errors.New("requested by is required")
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	if err := validateZirveValidationDecisionForManualReview(decision); err != nil {
		return ZirveManualReviewItem{}, err
	}

	if _, exists := r.reviews[reviewID]; exists {
		return ZirveManualReviewItem{}, errors.New("manual review already exists")
	}

	auditDecision := decideZirveAdminOpsOperation("DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_OPEN")
	if !auditDecision.Allowed {
		return ZirveManualReviewItem{}, fmt.Errorf("zirve admin ops open review denied: %s", auditDecision.Reason)
	}

	if r.Identity.CanRunRealOperatorProviderAction() {
		return ZirveManualReviewItem{}, errors.New("real operator provider action must remain closed in FAZ 7-8Z.5")
	}

	item := ZirveManualReviewItem{
		ProviderID:                        ProviderID,
		ModuleCode:                        ZirveAdminOpsModuleCode,
		Mode:                              ZirveAdminOpsMode,
		QueuePolicy:                       ZirveAdminOpsQueuePolicy,
		TenantID:                          decision.TenantID,
		ReviewID:                          reviewID,
		Source:                            ZirveManualReviewSourceValidationRetryDLQ,
		ValidationRunID:                   decision.ValidationRunID,
		ExportRunID:                       decision.ExportRunID,
		DeliveryRunID:                     decision.DeliveryRunID,
		CorrelationID:                     decision.CorrelationID,
		ErrorCode:                         decision.ErrorCode,
		Outcome:                           decision.Outcome,
		Priority:                          priorityForZirveManualReview(decision),
		Status:                            ZirveManualReviewOpen,
		RequiredAction:                    decision.RequiredAction,
		Decision:                          decision,
		AuditDecision:                     auditDecision,
		RealProviderAPIAllowed:            false,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		CreatedAtUTC:                      now.UTC(),
		UpdatedAtUTC:                      now.UTC(),
	}

	r.reviews[item.ReviewID] = item
	return item, nil
}

func (r *ZirveAdminOpsRuntime) ListTenantManualReviews(tenantID string) ([]ZirveManualReviewItem, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, errors.New("tenant id is required")
	}

	items := []ZirveManualReviewItem{}
	for _, item := range r.reviews {
		if item.TenantID == tenantID {
			items = append(items, item)
		}
	}

	sort.Slice(items, func(i, j int) bool {
		return items[i].CreatedAtUTC.Before(items[j].CreatedAtUTC)
	})

	return items, nil
}

func (r *ZirveAdminOpsRuntime) GetTenantManualReview(tenantID string, reviewID string) (ZirveManualReviewItem, error) {
	tenantID = strings.TrimSpace(tenantID)
	reviewID = strings.TrimSpace(reviewID)

	if tenantID == "" {
		return ZirveManualReviewItem{}, errors.New("tenant id is required")
	}
	if reviewID == "" {
		return ZirveManualReviewItem{}, errors.New("review id is required")
	}

	item, exists := r.reviews[reviewID]
	if !exists {
		return ZirveManualReviewItem{}, errors.New("manual review not found")
	}
	if item.TenantID != tenantID {
		return ZirveManualReviewItem{}, errors.New("manual review tenant boundary violation")
	}

	return item, nil
}

func (r *ZirveAdminOpsRuntime) ApplyManualReviewAction(request ZirveManualReviewActionRequest) (ZirveManualReviewItem, error) {
	normalized, err := normalizeZirveManualReviewActionRequest(request)
	if err != nil {
		return ZirveManualReviewItem{}, err
	}

	item, err := r.GetTenantManualReview(normalized.TenantID, normalized.ReviewID)
	if err != nil {
		return ZirveManualReviewItem{}, err
	}

	if item.Status == ZirveManualReviewResolved || item.Status == ZirveManualReviewRejected {
		return ZirveManualReviewItem{}, errors.New("manual review is already closed")
	}

	operationCode := fmt.Sprintf("DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_%s", normalized.Action)
	auditDecision := decideZirveAdminOpsOperation(operationCode)
	if !auditDecision.Allowed {
		return ZirveManualReviewItem{}, fmt.Errorf("zirve admin ops action denied: %s", auditDecision.Reason)
	}

	if r.Identity.CanUseRealProviderAPI() ||
		r.Identity.CanDeliverRealFile() ||
		r.Identity.CanWriteERP() ||
		r.Identity.CanRunRealOperatorProviderAction() {
		return ZirveManualReviewItem{}, errors.New("real provider side effects must remain closed in FAZ 7-8Z.5")
	}

	switch normalized.Action {
	case ZirveManualReviewActionAssign:
		if normalized.AssignTo == "" {
			return ZirveManualReviewItem{}, errors.New("assign_to is required for assign action")
		}
		item.AssignedTo = normalized.AssignTo
		item.Status = ZirveManualReviewAssigned
	case ZirveManualReviewActionResolve:
		if normalized.ResolutionNote == "" {
			return ZirveManualReviewItem{}, errors.New("resolution note is required for resolve action")
		}
		item.ResolutionNote = normalized.ResolutionNote
		item.Status = ZirveManualReviewResolved
	case ZirveManualReviewActionReject:
		if normalized.RejectionReason == "" {
			return ZirveManualReviewItem{}, errors.New("rejection reason is required for reject action")
		}
		item.RejectionReason = normalized.RejectionReason
		item.Status = ZirveManualReviewRejected
	default:
		return ZirveManualReviewItem{}, fmt.Errorf("unsupported manual review action: %s", normalized.Action)
	}

	item.AuditDecision = auditDecision
	item.CorrelationID = normalized.CorrelationID
	item.UpdatedAtUTC = normalized.RequestedAt.UTC()
	item.RealProviderAPIAllowed = false
	item.RealFileDeliveryAllowed = false
	item.RealDeliveryChannelAllowed = false
	item.RealERPWriteAllowed = false
	item.RealOperatorProviderActionAllowed = false

	r.reviews[item.ReviewID] = item
	return item, nil
}

func normalizeZirveManualReviewActionRequest(request ZirveManualReviewActionRequest) (ZirveManualReviewActionRequest, error) {
	request.TenantID = strings.TrimSpace(request.TenantID)
	request.ReviewID = strings.TrimSpace(request.ReviewID)
	request.Actor = strings.TrimSpace(request.Actor)
	request.AssignTo = strings.TrimSpace(request.AssignTo)
	request.ResolutionNote = strings.TrimSpace(request.ResolutionNote)
	request.RejectionReason = strings.TrimSpace(request.RejectionReason)
	request.CorrelationID = strings.TrimSpace(request.CorrelationID)

	if request.TenantID == "" {
		return request, errors.New("tenant id is required for manual review action")
	}
	if request.ReviewID == "" {
		return request, errors.New("review id is required for manual review action")
	}
	if request.Actor == "" {
		return request, errors.New("actor is required for manual review action")
	}
	if request.Action == "" {
		return request, errors.New("manual review action is required")
	}
	if request.CorrelationID == "" {
		return request, errors.New("correlation id is required for manual review action")
	}
	if !request.DryRun {
		return request, errors.New("Zirve admin ops manual review actions are dry-run only in FAZ 7-8Z.5")
	}
	if request.RequestedAt.IsZero() {
		request.RequestedAt = time.Now().UTC()
	}

	return request, nil
}

func validateZirveValidationDecisionForManualReview(decision ZirveValidationRetryDLQDecision) error {
	if strings.TrimSpace(decision.ProviderID) != ProviderID {
		return fmt.Errorf("validation decision provider id must be %s", ProviderID)
	}
	if strings.TrimSpace(decision.ModuleCode) != ZirveValidationRetryDLQModuleCode {
		return fmt.Errorf("validation decision module code must be %s", ZirveValidationRetryDLQModuleCode)
	}
	if strings.TrimSpace(decision.Mode) != ZirveValidationRetryDLQMode {
		return fmt.Errorf("validation decision mode must be %s", ZirveValidationRetryDLQMode)
	}
	if strings.TrimSpace(decision.TenantID) == "" {
		return errors.New("validation decision tenant id is required")
	}
	if strings.TrimSpace(decision.ValidationRunID) == "" {
		return errors.New("validation decision validation run id is required")
	}
	if strings.TrimSpace(decision.CorrelationID) == "" {
		return errors.New("validation decision correlation id is required")
	}
	if decision.RealProviderAPIAllowed {
		return errors.New("validation decision real provider API must be closed")
	}
	if decision.RealFileDeliveryAllowed {
		return errors.New("validation decision real file delivery must be closed")
	}
	if decision.RealDeliveryChannelAllowed {
		return errors.New("validation decision real delivery channel must be closed")
	}
	if decision.RealERPWriteAllowed {
		return errors.New("validation decision real ERP write must be closed")
	}
	if decision.RealOperatorProviderActionAllowed {
		return errors.New("validation decision real operator provider action must be closed")
	}

	if decision.Outcome == ZirveValidationOutcomePass || decision.Outcome == ZirveValidationOutcomeRetry {
		return errors.New("pass/retry decisions are not eligible for manual review queue")
	}

	if !decision.ManualReview && !decision.SendToDLQ && decision.Outcome != ZirveValidationOutcomeDeny {
		return errors.New("validation decision must require manual review, DLQ, or deny")
	}

	return nil
}

func priorityForZirveManualReview(decision ZirveValidationRetryDLQDecision) ZirveManualReviewPriority {
	if decision.Outcome == ZirveValidationOutcomeDeny || decision.ErrorCode == ZirveErrRealDeliveryAttempted {
		return ZirveManualReviewPriorityCritical
	}
	if decision.SendToDLQ {
		return ZirveManualReviewPriorityHigh
	}
	if decision.ManualReview {
		return ZirveManualReviewPriorityHigh
	}
	return ZirveManualReviewPriorityMedium
}

func decideZirveAdminOpsOperation(operationCode string) OperationDecision {
	operationCode = strings.TrimSpace(operationCode)

	switch operationCode {
	case "DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_OPEN",
		"DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_ASSIGN",
		"DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_RESOLVE",
		"DRY_RUN_ADMIN_OPS_MANUAL_REVIEW_REJECT":
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       true,
			Reason:        "dry-run admin ops manual review action is allowed without provider side effects",
			RequiredGate:  "ADMIN_OPS_MANUAL_REVIEW_ONLY",
		}
	default:
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       false,
			Reason:        "real admin/provider operation is closed until provider live module",
			RequiredGate:  HandoffGateStatus,
		}
	}
}
