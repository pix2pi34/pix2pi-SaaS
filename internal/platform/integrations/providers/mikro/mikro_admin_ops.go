package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroAdminOpsPhase        = "FAZ_7_8M_5"
	MikroAdminOpsModule       = "MIKRO_ADMIN_OPS_MANUAL_REVIEW"
	MikroAdminOpsModuleName   = "Mikro Admin / Ops / Manual Review Readiness"
	MikroAdminOpsMode         = "ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY"
	MikroAdminOpsDirection    = "PIX2PI_TO_MIKRO"
	MikroAdminOpsSourceSystem = "PIX2PI_ERP"
	MikroAdminOpsTargetSystem = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroAdminOpsGate         = "READY_AFTER_TEST_AND_AUDIT_PASS"

	MikroManualReviewQueueStatus          = "READY"
	MikroTenantSafeReviewBoundaryStatus   = "READY"
	MikroOperatorActionContractStatus     = "READY"
	MikroRealManualReviewQueueWritePolicy = "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE"
	MikroRealOperatorProviderActionStatus = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"

	MikroManualReviewStatusOpen      = "OPEN"
	MikroManualReviewStatusAssigned  = "ASSIGNED"
	MikroManualReviewStatusRetry     = "RETRY_DRY_RUN"
	MikroManualReviewStatusDLQ       = "DLQ_DRY_RUN"
	MikroManualReviewStatusResolved  = "RESOLVED_DRY_RUN"
	MikroManualReviewStatusEscalated = "ESCALATED_MANUAL_REVIEW"

	MikroOperatorActionView     = "VIEW"
	MikroOperatorActionAssign   = "ASSIGN"
	MikroOperatorActionRetry    = "MARK_RETRY_DRY_RUN"
	MikroOperatorActionDLQ      = "MARK_DLQ_DRY_RUN"
	MikroOperatorActionResolve  = "RESOLVE_DRY_RUN"
	MikroOperatorActionEscalate = "ESCALATE_MANUAL_REVIEW"

	MikroAdminOpsDecisionReviewItemReady        = "MIKRO_ADMIN_OPS_REVIEW_ITEM_READY"
	MikroAdminOpsDecisionOperatorActionReady    = "MIKRO_ADMIN_OPS_OPERATOR_ACTION_READY"
	MikroAdminOpsDecisionUnsupportedAction      = "MIKRO_ADMIN_OPS_OPERATOR_ACTION_UNSUPPORTED"
	MikroAdminOpsDecisionInvalidTransition      = "MIKRO_ADMIN_OPS_STATUS_TRANSITION_INVALID"
	MikroAdminOpsDecisionInvalidReviewInput     = "MIKRO_ADMIN_OPS_REVIEW_INPUT_INVALID"
	MikroAdminOpsDecisionSecretDenied           = "MIKRO_ADMIN_OPS_SECRET_FIELD_FORBIDDEN"
	MikroAdminOpsDecisionRealProviderAPI        = "MIKRO_ADMIN_OPS_REAL_PROVIDER_API_CLOSED"
	MikroAdminOpsDecisionRealFileDelivery       = "MIKRO_ADMIN_OPS_REAL_FILE_DELIVERY_CLOSED"
	MikroAdminOpsDecisionRealERPWrite           = "MIKRO_ADMIN_OPS_REAL_ERP_WRITE_CLOSED"
	MikroAdminOpsDecisionRealDeliveryChannel    = "MIKRO_ADMIN_OPS_REAL_DELIVERY_CHANNEL_CLOSED"
	MikroAdminOpsDecisionRealProviderAction     = "MIKRO_ADMIN_OPS_REAL_OPERATOR_PROVIDER_ACTION_CLOSED"
	MikroAdminOpsDecisionProviderLiveModeClosed = "MIKRO_ADMIN_OPS_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroAdminOpsContract = errors.New("invalid mikro admin ops contract")
	ErrInvalidMikroAdminOpsRequest  = errors.New("invalid mikro admin ops request")
	ErrMikroAdminOpsSecretForbidden = errors.New("mikro admin ops secret field is forbidden")
)

type MikroAdminOpsContract struct {
	Phase                            string
	Module                           string
	ModuleName                       string
	ProviderID                       string
	ProviderName                     string
	ProviderCategory                 string
	AdminOpsMode                     string
	Direction                        string
	SourceSystem                     string
	TargetSystem                     string
	AdminOpsGate                     string
	ManualReviewQueueStatus          string
	TenantSafeReviewBoundaryStatus   string
	OperatorActionContractStatus     string
	RealManualReviewQueueWritePolicy string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	SupportedOperatorActions         []string
	ManualReviewStatuses             []string
	RequiredContextFields            []string
	ForbiddenFieldLabels             []string
}

type MikroManualReviewItem struct {
	ReviewID             string
	TenantID             string
	ActorUserID          string
	CorrelationID        string
	PackageID            string
	ERPObjectType        string
	MikroObjectType      string
	ProviderErrorCode    string
	ProviderErrorClass   string
	ValidationReason     string
	ValidationAction     string
	ReviewStatus         string
	ManualReviewRequired bool
	DLQRecommended       bool
	RetryRecommended     bool
	ExternalActionTaken  bool
	RealProviderAction   bool
}

type MikroManualReviewRequest struct {
	TenantID                          string
	ActorUserID                       string
	CorrelationID                     string
	ReviewID                          string
	RequestedMode                     string
	InjectedFieldName                 string
	ValidationDecision                MikroValidationDecision
	Package                           MikroDryRunPackage
	RealProviderAPIEnabled            bool
	RealFileDeliveryEnabled           bool
	RealERPWriteEnabled               bool
	RealDeliveryEnabled               bool
	RealOperatorProviderActionEnabled bool
}

type MikroOperatorActionRequest struct {
	TenantID                          string
	ActorUserID                       string
	CorrelationID                     string
	ReviewID                          string
	PackageID                         string
	CurrentStatus                     string
	OperatorAction                    string
	OperatorNote                      string
	RequestedMode                     string
	InjectedFieldName                 string
	RealProviderAPIEnabled            bool
	RealFileDeliveryEnabled           bool
	RealERPWriteEnabled               bool
	RealDeliveryEnabled               bool
	RealOperatorProviderActionEnabled bool
}

type MikroAdminOpsDecision struct {
	Allowed                          bool
	Phase                            string
	Module                           string
	ProviderID                       string
	ProviderName                     string
	ReviewID                         string
	PackageID                        string
	ERPObjectType                    string
	MikroObjectType                  string
	AdminOpsMode                     string
	Direction                        string
	TargetSystem                     string
	Reason                           string
	OperatorAction                   string
	PreviousStatus                   string
	NextStatus                       string
	ManualReviewQueueStatus          string
	TenantSafeReviewBoundaryStatus   string
	OperatorActionContractStatus     string
	RealManualReviewQueueWritePolicy string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	AuditFields                      map[string]string
}

type MikroAdminOpsRuntime struct {
	Contract MikroAdminOpsContract
}

func NewMikroAdminOpsContract() MikroAdminOpsContract {
	return MikroAdminOpsContract{
		Phase:                            MikroAdminOpsPhase,
		Module:                           MikroAdminOpsModule,
		ModuleName:                       MikroAdminOpsModuleName,
		ProviderID:                       ProviderID,
		ProviderName:                     ProviderName,
		ProviderCategory:                 ProviderCategory,
		AdminOpsMode:                     MikroAdminOpsMode,
		Direction:                        MikroAdminOpsDirection,
		SourceSystem:                     MikroAdminOpsSourceSystem,
		TargetSystem:                     MikroAdminOpsTargetSystem,
		AdminOpsGate:                     MikroAdminOpsGate,
		ManualReviewQueueStatus:          MikroManualReviewQueueStatus,
		TenantSafeReviewBoundaryStatus:   MikroTenantSafeReviewBoundaryStatus,
		OperatorActionContractStatus:     MikroOperatorActionContractStatus,
		RealManualReviewQueueWritePolicy: MikroRealManualReviewQueueWritePolicy,
		RealProviderAPIStatus:            MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:           MikroRealFileDeliveryStatus,
		RealERPWriteStatus:               MikroRealERPWriteStatus,
		RealDeliveryChannelStatus:        MikroRealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: MikroRealOperatorProviderActionStatus,
		SupportedOperatorActions: []string{
			MikroOperatorActionView,
			MikroOperatorActionAssign,
			MikroOperatorActionRetry,
			MikroOperatorActionDLQ,
			MikroOperatorActionResolve,
			MikroOperatorActionEscalate,
		},
		ManualReviewStatuses: []string{
			MikroManualReviewStatusOpen,
			MikroManualReviewStatusAssigned,
			MikroManualReviewStatusRetry,
			MikroManualReviewStatusDLQ,
			MikroManualReviewStatusResolved,
			MikroManualReviewStatusEscalated,
		},
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"review_id",
			"package_id",
		},
		ForbiddenFieldLabels: []string{
			"client_secret",
			"access_token",
			"refresh_token",
			"password",
			"real_provider_endpoint",
			"real_delivery_endpoint",
			"secret",
			"token",
		},
	}
}

func NewMikroAdminOpsRuntime() MikroAdminOpsRuntime {
	return MikroAdminOpsRuntime{
		Contract: NewMikroAdminOpsContract(),
	}
}

func (c MikroAdminOpsContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroAdminOpsPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroAdminOpsContract, MikroAdminOpsPhase)
	}
	if strings.TrimSpace(c.Module) != MikroAdminOpsModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroAdminOpsContract, MikroAdminOpsModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroAdminOpsContract, ProviderID)
	}
	if strings.TrimSpace(c.AdminOpsMode) != MikroAdminOpsMode {
		return fmt.Errorf("%w: admin ops mode mismatch", ErrInvalidMikroAdminOpsContract)
	}
	if strings.TrimSpace(c.Direction) != MikroAdminOpsDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroAdminOpsContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroAdminOpsTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroAdminOpsContract)
	}
	if c.ManualReviewQueueStatus != MikroManualReviewQueueStatus {
		return fmt.Errorf("%w: manual review queue status must be ready", ErrInvalidMikroAdminOpsContract)
	}
	if c.TenantSafeReviewBoundaryStatus != MikroTenantSafeReviewBoundaryStatus {
		return fmt.Errorf("%w: tenant safe review boundary must be ready", ErrInvalidMikroAdminOpsContract)
	}
	if c.OperatorActionContractStatus != MikroOperatorActionContractStatus {
		return fmt.Errorf("%w: operator action contract must be ready", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealManualReviewQueueWritePolicy != MikroRealManualReviewQueueWritePolicy {
		return fmt.Errorf("%w: real manual review queue write must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		return fmt.Errorf("%w: real delivery channel must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if c.RealOperatorProviderActionStatus != MikroRealOperatorProviderActionStatus {
		return fmt.Errorf("%w: real operator provider action must stay closed", ErrInvalidMikroAdminOpsContract)
	}
	if len(c.SupportedOperatorActions) < 6 {
		return fmt.Errorf("%w: supported operator actions are incomplete", ErrInvalidMikroAdminOpsContract)
	}
	if len(c.ManualReviewStatuses) < 6 {
		return fmt.Errorf("%w: manual review statuses are incomplete", ErrInvalidMikroAdminOpsContract)
	}
	if len(c.RequiredContextFields) < 5 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroAdminOpsContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden fields are required", ErrInvalidMikroAdminOpsContract)
	}
	return nil
}

func (c MikroAdminOpsContract) SupportsOperatorAction(action string) bool {
	normalized := normalizeExportMappingValue(action)
	for _, supported := range c.SupportedOperatorActions {
		if supported == normalized {
			return true
		}
	}
	return false
}

func (c MikroAdminOpsContract) SupportsReviewStatus(status string) bool {
	normalized := normalizeExportMappingValue(status)
	for _, supported := range c.ManualReviewStatuses {
		if supported == normalized {
			return true
		}
	}
	return false
}

func (r MikroAdminOpsRuntime) CreateManualReviewItem(req MikroManualReviewRequest) (MikroManualReviewItem, MikroAdminOpsDecision, error) {
	item := MikroManualReviewItem{}
	packageID := strings.TrimSpace(req.Package.Manifest.PackageID)

	decision := r.baseDecision(req.TenantID, req.ActorUserID, req.CorrelationID, req.ReviewID, packageID)
	decision.ERPObjectType = normalizeExportMappingValue(req.Package.Manifest.ERPObjectType)
	decision.MikroObjectType = req.Package.Manifest.MikroObjectType

	if err := r.Contract.Validate(); err != nil {
		return item, decision, err
	}
	if err := validateMikroManualReviewRequest(req); err != nil {
		decision.Reason = MikroAdminOpsDecisionInvalidReviewInput
		return item, decision, err
	}
	if err := r.guardClosedRealOperations(req.RequestedMode, req.InjectedFieldName, req.RealProviderAPIEnabled, req.RealFileDeliveryEnabled, req.RealERPWriteEnabled, req.RealDeliveryEnabled, req.RealOperatorProviderActionEnabled, &decision); err != nil {
		return item, decision, err
	}
	if decision.Reason != "" {
		return item, decision, nil
	}
	if err := verifyMikroDryRunPackage(req.Package); err != nil {
		decision.Reason = MikroAdminOpsDecisionInvalidReviewInput
		return item, decision, err
	}
	if !req.ValidationDecision.ManualReview && !req.ValidationDecision.SendToDLQ {
		decision.Reason = MikroAdminOpsDecisionInvalidReviewInput
		return item, decision, fmt.Errorf("%w: validation decision must require manual review or DLQ", ErrInvalidMikroAdminOpsRequest)
	}

	item = MikroManualReviewItem{
		ReviewID:             strings.TrimSpace(req.ReviewID),
		TenantID:             strings.TrimSpace(req.TenantID),
		ActorUserID:          strings.TrimSpace(req.ActorUserID),
		CorrelationID:        strings.TrimSpace(req.CorrelationID),
		PackageID:            packageID,
		ERPObjectType:        normalizeExportMappingValue(req.Package.Manifest.ERPObjectType),
		MikroObjectType:      req.Package.Manifest.MikroObjectType,
		ProviderErrorCode:    normalizeExportMappingValue(req.ValidationDecision.ProviderErrorCode),
		ProviderErrorClass:   normalizeExportMappingValue(req.ValidationDecision.ProviderErrorClass),
		ValidationReason:     req.ValidationDecision.Reason,
		ValidationAction:     req.ValidationDecision.Action,
		ReviewStatus:         MikroManualReviewStatusOpen,
		ManualReviewRequired: req.ValidationDecision.ManualReview,
		DLQRecommended:       req.ValidationDecision.SendToDLQ,
		RetryRecommended:     req.ValidationDecision.RetryAllowed,
		ExternalActionTaken:  false,
		RealProviderAction:   false,
	}

	decision.Allowed = true
	decision.Reason = MikroAdminOpsDecisionReviewItemReady
	decision.NextStatus = MikroManualReviewStatusOpen
	return item, decision, nil
}

func (r MikroAdminOpsRuntime) EvaluateOperatorAction(req MikroOperatorActionRequest) (MikroAdminOpsDecision, error) {
	decision := r.baseDecision(req.TenantID, req.ActorUserID, req.CorrelationID, req.ReviewID, req.PackageID)
	decision.OperatorAction = normalizeExportMappingValue(req.OperatorAction)
	decision.PreviousStatus = normalizeExportMappingValue(req.CurrentStatus)

	if err := r.Contract.Validate(); err != nil {
		return decision, err
	}
	if err := validateMikroOperatorActionRequest(req); err != nil {
		decision.Reason = MikroAdminOpsDecisionInvalidReviewInput
		return decision, err
	}
	if err := r.guardClosedRealOperations(req.RequestedMode, req.InjectedFieldName, req.RealProviderAPIEnabled, req.RealFileDeliveryEnabled, req.RealERPWriteEnabled, req.RealDeliveryEnabled, req.RealOperatorProviderActionEnabled, &decision); err != nil {
		return decision, err
	}
	if decision.Reason != "" {
		return decision, nil
	}
	if !r.Contract.SupportsOperatorAction(req.OperatorAction) {
		decision.Reason = MikroAdminOpsDecisionUnsupportedAction
		return decision, nil
	}
	if !r.Contract.SupportsReviewStatus(req.CurrentStatus) {
		decision.Reason = MikroAdminOpsDecisionInvalidTransition
		return decision, nil
	}

	nextStatus, ok := nextMikroManualReviewStatus(req.CurrentStatus, req.OperatorAction)
	if !ok {
		decision.Reason = MikroAdminOpsDecisionInvalidTransition
		return decision, nil
	}

	decision.Allowed = true
	decision.Reason = MikroAdminOpsDecisionOperatorActionReady
	decision.NextStatus = nextStatus
	return decision, nil
}

func (r MikroAdminOpsRuntime) baseDecision(tenantID string, actorUserID string, correlationID string, reviewID string, packageID string) MikroAdminOpsDecision {
	return MikroAdminOpsDecision{
		Allowed:                          false,
		Phase:                            r.Contract.Phase,
		Module:                           r.Contract.Module,
		ProviderID:                       r.Contract.ProviderID,
		ProviderName:                     r.Contract.ProviderName,
		ReviewID:                         strings.TrimSpace(reviewID),
		PackageID:                        strings.TrimSpace(packageID),
		AdminOpsMode:                     r.Contract.AdminOpsMode,
		Direction:                        r.Contract.Direction,
		TargetSystem:                     r.Contract.TargetSystem,
		ManualReviewQueueStatus:          r.Contract.ManualReviewQueueStatus,
		TenantSafeReviewBoundaryStatus:   r.Contract.TenantSafeReviewBoundaryStatus,
		OperatorActionContractStatus:     r.Contract.OperatorActionContractStatus,
		RealManualReviewQueueWritePolicy: r.Contract.RealManualReviewQueueWritePolicy,
		RealProviderAPIStatus:            r.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus:           r.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:               r.Contract.RealERPWriteStatus,
		RealDeliveryChannelStatus:        r.Contract.RealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: r.Contract.RealOperatorProviderActionStatus,
		AuditFields: map[string]string{
			"tenant_id":                   strings.TrimSpace(tenantID),
			"actor_user_id":               strings.TrimSpace(actorUserID),
			"correlation_id":              strings.TrimSpace(correlationID),
			"review_id":                   strings.TrimSpace(reviewID),
			"package_id":                  strings.TrimSpace(packageID),
			"provider_id":                 r.Contract.ProviderID,
			"phase":                       r.Contract.Phase,
			"admin_ops_mode":              r.Contract.AdminOpsMode,
			"tenant_safe_boundary":        r.Contract.TenantSafeReviewBoundaryStatus,
			"real_queue_write_policy":     r.Contract.RealManualReviewQueueWritePolicy,
			"real_provider_action_status": r.Contract.RealOperatorProviderActionStatus,
		},
	}
}

func (r MikroAdminOpsRuntime) guardClosedRealOperations(
	requestedMode string,
	injectedFieldName string,
	realProviderAPIEnabled bool,
	realFileDeliveryEnabled bool,
	realERPWriteEnabled bool,
	realDeliveryEnabled bool,
	realOperatorProviderActionEnabled bool,
	decision *MikroAdminOpsDecision,
) error {
	if containsForbiddenMappingField(injectedFieldName) {
		decision.Reason = MikroAdminOpsDecisionSecretDenied
		return ErrMikroAdminOpsSecretForbidden
	}
	if normalizeExportMappingValue(requestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroAdminOpsDecisionProviderLiveModeClosed
		return nil
	}
	if realProviderAPIEnabled {
		decision.Reason = MikroAdminOpsDecisionRealProviderAPI
		return nil
	}
	if realFileDeliveryEnabled {
		decision.Reason = MikroAdminOpsDecisionRealFileDelivery
		return nil
	}
	if realERPWriteEnabled {
		decision.Reason = MikroAdminOpsDecisionRealERPWrite
		return nil
	}
	if realDeliveryEnabled {
		decision.Reason = MikroAdminOpsDecisionRealDeliveryChannel
		return nil
	}
	if realOperatorProviderActionEnabled {
		decision.Reason = MikroAdminOpsDecisionRealProviderAction
		return nil
	}
	return nil
}

func validateMikroManualReviewRequest(req MikroManualReviewRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.ReviewID) == "" {
		return fmt.Errorf("%w: review_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.Package.Manifest.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	return nil
}

func validateMikroOperatorActionRequest(req MikroOperatorActionRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.ReviewID) == "" {
		return fmt.Errorf("%w: review_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.OperatorAction) == "" {
		return fmt.Errorf("%w: operator_action is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.CurrentStatus) == "" {
		return fmt.Errorf("%w: current_status is required", ErrInvalidMikroAdminOpsRequest)
	}
	if strings.TrimSpace(req.OperatorNote) == "" && normalizeExportMappingValue(req.OperatorAction) != MikroOperatorActionView {
		return fmt.Errorf("%w: operator_note is required for mutating actions", ErrInvalidMikroAdminOpsRequest)
	}
	return nil
}

func nextMikroManualReviewStatus(currentStatus string, action string) (string, bool) {
	current := normalizeExportMappingValue(currentStatus)
	normalizedAction := normalizeExportMappingValue(action)

	switch normalizedAction {
	case MikroOperatorActionView:
		return current, true
	case MikroOperatorActionAssign:
		if current == MikroManualReviewStatusOpen {
			return MikroManualReviewStatusAssigned, true
		}
	case MikroOperatorActionRetry:
		if current == MikroManualReviewStatusOpen || current == MikroManualReviewStatusAssigned {
			return MikroManualReviewStatusRetry, true
		}
	case MikroOperatorActionDLQ:
		if current == MikroManualReviewStatusOpen || current == MikroManualReviewStatusAssigned {
			return MikroManualReviewStatusDLQ, true
		}
	case MikroOperatorActionResolve:
		if current == MikroManualReviewStatusOpen || current == MikroManualReviewStatusAssigned || current == MikroManualReviewStatusRetry || current == MikroManualReviewStatusDLQ {
			return MikroManualReviewStatusResolved, true
		}
	case MikroOperatorActionEscalate:
		if current == MikroManualReviewStatusOpen || current == MikroManualReviewStatusAssigned {
			return MikroManualReviewStatusEscalated, true
		}
	}

	return "", false
}
