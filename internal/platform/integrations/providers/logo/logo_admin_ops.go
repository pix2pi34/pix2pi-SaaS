package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L8 = "FAZ_7_8L.8"

	LogoAdminOpsMode               = "ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY"
	LogoAdminOpsStatus             = "READY"
	LogoManualReviewQueueStatus    = "READY"
	LogoManualReviewContractStatus = "READY"
)

type LogoManualReviewStatus string

const (
	LogoManualReviewStatusOpen     LogoManualReviewStatus = "OPEN"
	LogoManualReviewStatusAssigned LogoManualReviewStatus = "ASSIGNED"
	LogoManualReviewStatusResolved LogoManualReviewStatus = "RESOLVED"
	LogoManualReviewStatusRejected LogoManualReviewStatus = "REJECTED"
)

type LogoManualReviewReason string

const (
	LogoManualReviewReasonChecksumMismatch        LogoManualReviewReason = "CHECKSUM_MISMATCH"
	LogoManualReviewReasonUnknownProviderError    LogoManualReviewReason = "UNKNOWN_PROVIDER_ERROR"
	LogoManualReviewReasonTenantBoundaryViolation LogoManualReviewReason = "TENANT_BOUNDARY_VIOLATION"
	LogoManualReviewReasonValidationDLQ           LogoManualReviewReason = "VALIDATION_DLQ"
	LogoManualReviewReasonRetryLimitExceeded      LogoManualReviewReason = "RETRY_LIMIT_EXCEEDED"
)

type LogoAdminOpsOperationName string

const (
	LogoOperationDeclareAdminOpsContract      LogoAdminOpsOperationName = "DECLARE_LOGO_ADMIN_OPS_CONTRACT"
	LogoOperationCreateManualReviewItem       LogoAdminOpsOperationName = "CREATE_LOGO_MANUAL_REVIEW_ITEM"
	LogoOperationListManualReviews            LogoAdminOpsOperationName = "LIST_LOGO_MANUAL_REVIEWS"
	LogoOperationReadManualReview             LogoAdminOpsOperationName = "READ_LOGO_MANUAL_REVIEW"
	LogoOperationAssignManualReview           LogoAdminOpsOperationName = "ASSIGN_LOGO_MANUAL_REVIEW"
	LogoOperationResolveManualReview          LogoAdminOpsOperationName = "RESOLVE_LOGO_MANUAL_REVIEW"
	LogoOperationRejectManualReview           LogoAdminOpsOperationName = "REJECT_LOGO_MANUAL_REVIEW"
	LogoOperationValidateTenantReviewBoundary LogoAdminOpsOperationName = "VALIDATE_LOGO_TENANT_REVIEW_BOUNDARY"
	LogoOperationPrepareE2EDryRunHandoff      LogoAdminOpsOperationName = "PREPARE_LOGO_E2E_DRY_RUN_HANDOFF"
)

type LogoManualReviewContract struct {
	Declared                bool   `json:"declared"`
	Status                  string `json:"status"`
	DryRunOnly              bool   `json:"dry_run_only"`
	TenantScopeRequired     bool   `json:"tenant_scope_required"`
	CorrelationIDRequired   bool   `json:"correlation_id_required"`
	IdempotencyKeyRequired  bool   `json:"idempotency_key_required"`
	ReviewIDRequired        bool   `json:"review_id_required"`
	AuditFieldsRequired     bool   `json:"audit_fields_required"`
	ExternalCallAllowed     bool   `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool   `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool   `json:"erp_write_allowed"`
}

type LogoAdminOpsOperationContract struct {
	Name                    LogoAdminOpsOperationName `json:"name"`
	Mode                    string                    `json:"mode"`
	DryRunAdminOpsAllowed   bool                      `json:"dry_run_admin_ops_allowed"`
	ExternalCallAllowed     bool                      `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool                      `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool                      `json:"erp_write_allowed"`
}

type LogoAdminOpsContract struct {
	Module                  string                          `json:"module"`
	Step                    string                          `json:"step"`
	ProviderCode            string                          `json:"provider_code"`
	ProviderName            string                          `json:"provider_name"`
	ConnectorCode           string                          `json:"connector_code"`
	ConnectorFamily         string                          `json:"connector_family"`
	RuntimeMode             string                          `json:"runtime_mode"`
	AdminOpsMode            string                          `json:"admin_ops_mode"`
	TargetSystem            string                          `json:"target_system"`
	AdminOpsStatus          string                          `json:"admin_ops_status"`
	ManualReviewQueueStatus string                          `json:"manual_review_queue_status"`
	RealProviderAPIStatus   string                          `json:"real_provider_api_status"`
	RealFileDeliveryStatus  string                          `json:"real_file_delivery_status"`
	RealERPWriteStatus      string                          `json:"real_erp_write_status"`
	ManualReviewContract    LogoManualReviewContract        `json:"manual_review_contract"`
	Operations              []LogoAdminOpsOperationContract `json:"operations"`
}

type LogoManualReviewItem struct {
	ReviewID       string                 `json:"review_id"`
	TenantID       string                 `json:"tenant_id"`
	CorrelationID  string                 `json:"correlation_id"`
	IdempotencyKey string                 `json:"idempotency_key"`
	PackageID      string                 `json:"package_id"`
	DeliveryID     string                 `json:"delivery_id"`
	ErrorCode      LogoErrorCode          `json:"error_code"`
	ErrorClass     LogoErrorClass         `json:"error_class"`
	Reason         LogoManualReviewReason `json:"reason"`
	Status         LogoManualReviewStatus `json:"status"`
	AssignedTo     string                 `json:"assigned_to"`
	CreatedBy      string                 `json:"created_by"`
	ClosedBy       string                 `json:"closed_by"`
	ResolutionNote string                 `json:"resolution_note"`
	DryRunOnly     bool                   `json:"dry_run_only"`
}

type LogoAdminOpsRuntime struct {
	Contract LogoAdminOpsContract   `json:"contract"`
	Reviews  []LogoManualReviewItem `json:"reviews"`
}

func NewLogoAdminOpsContract() LogoAdminOpsContract {
	return LogoAdminOpsContract{
		Module:                  ModuleFAZ78L,
		Step:                    StepFAZ78L8,
		ProviderCode:            ProviderCode,
		ProviderName:            ProviderName,
		ConnectorCode:           ConnectorCode,
		ConnectorFamily:         ConnectorFamily,
		RuntimeMode:             RuntimeModeDryRun,
		AdminOpsMode:            LogoAdminOpsMode,
		TargetSystem:            LogoTargetSystem,
		AdminOpsStatus:          LogoAdminOpsStatus,
		ManualReviewQueueStatus: LogoManualReviewQueueStatus,
		RealProviderAPIStatus:   RealProviderAPIClosedStatus,
		RealFileDeliveryStatus:  RealFileDeliveryClosedStatus,
		RealERPWriteStatus:      RealERPWriteClosedStatus,
		ManualReviewContract: LogoManualReviewContract{
			Declared:                true,
			Status:                  LogoManualReviewContractStatus,
			DryRunOnly:              true,
			TenantScopeRequired:     true,
			CorrelationIDRequired:   true,
			IdempotencyKeyRequired:  true,
			ReviewIDRequired:        true,
			AuditFieldsRequired:     true,
			ExternalCallAllowed:     false,
			RealFileDeliveryAllowed: false,
			ERPWriteAllowed:         false,
		},
		Operations: []LogoAdminOpsOperationContract{
			{Name: LogoOperationDeclareAdminOpsContract, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationCreateManualReviewItem, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationListManualReviews, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationReadManualReview, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationAssignManualReview, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationResolveManualReview, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationRejectManualReview, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateTenantReviewBoundary, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareE2EDryRunHandoff, Mode: LogoAdminOpsMode, DryRunAdminOpsAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func NewLogoAdminOpsRuntime() LogoAdminOpsRuntime {
	return LogoAdminOpsRuntime{
		Contract: NewLogoAdminOpsContract(),
		Reviews:  []LogoManualReviewItem{},
	}
}

func NewLogoManualReviewItemFromDecision(envelope LogoImportDeliveryEnvelope, decision LogoRetryDecision, createdBy string) (LogoManualReviewItem, error) {
	if decision.Action != LogoDecisionManualReview || !decision.ManualReview {
		return LogoManualReviewItem{}, errors.New("manual review decision is required")
	}
	if err := envelope.Validate(); err != nil {
		return LogoManualReviewItem{}, err
	}

	reason := LogoManualReviewReason(decision.ErrorCode)
	item := LogoManualReviewItem{
		ReviewID:       fmt.Sprintf("logo-review:%s:%s:%s", envelope.TenantID, envelope.IdempotencyKey, decision.ErrorCode),
		TenantID:       envelope.TenantID,
		CorrelationID:  envelope.CorrelationID,
		IdempotencyKey: envelope.IdempotencyKey,
		PackageID:      envelope.PackageID,
		DeliveryID:     envelope.DeliveryID,
		ErrorCode:      decision.ErrorCode,
		ErrorClass:     decision.ErrorClass,
		Reason:         reason,
		Status:         LogoManualReviewStatusOpen,
		CreatedBy:      adminOpsTrim(createdBy),
		DryRunOnly:     true,
	}

	if item.CreatedBy == "" {
		item.CreatedBy = "system"
	}

	if err := item.Validate(); err != nil {
		return LogoManualReviewItem{}, err
	}

	return item, nil
}

func (c LogoAdminOpsContract) Validate() error {
	validationContract := NewLogoValidationRetryDLQContract()
	if err := validationContract.Validate(); err != nil {
		return fmt.Errorf("logo validation retry-DLQ must be valid before admin ops: %w", err)
	}

	if adminOpsTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if adminOpsTrim(c.Step) != StepFAZ78L8 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if adminOpsTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if adminOpsTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if adminOpsTrim(c.AdminOpsMode) != LogoAdminOpsMode {
		return fmt.Errorf("invalid admin ops mode: %s", c.AdminOpsMode)
	}
	if adminOpsTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if adminOpsTrim(c.AdminOpsStatus) != LogoAdminOpsStatus {
		return fmt.Errorf("invalid admin ops status: %s", c.AdminOpsStatus)
	}
	if adminOpsTrim(c.ManualReviewQueueStatus) != LogoManualReviewQueueStatus {
		return fmt.Errorf("invalid manual review queue status: %s", c.ManualReviewQueueStatus)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, and ERP write must remain closed")
	}
	if err := c.ManualReviewContract.Validate(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoAdminOpsContract) RealIntegrationsClosed() bool {
	return adminOpsTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		adminOpsTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		adminOpsTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoAdminOpsContract) ValidateOperations() error {
	requiredOperations := []LogoAdminOpsOperationName{
		LogoOperationDeclareAdminOpsContract,
		LogoOperationCreateManualReviewItem,
		LogoOperationListManualReviews,
		LogoOperationReadManualReview,
		LogoOperationAssignManualReview,
		LogoOperationResolveManualReview,
		LogoOperationRejectManualReview,
		LogoOperationValidateTenantReviewBoundary,
		LogoOperationPrepareE2EDryRunHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoAdminOpsMode {
			return fmt.Errorf("operation %s must use admin ops mode", operationName)
		}
		if !operation.DryRunAdminOpsAllowed {
			return fmt.Errorf("operation %s must allow dry-run admin ops", operationName)
		}
		if operation.ExternalCallAllowed {
			return fmt.Errorf("operation %s must not allow external calls", operationName)
		}
		if operation.RealFileDeliveryAllowed {
			return fmt.Errorf("operation %s must not allow real file delivery", operationName)
		}
		if operation.ERPWriteAllowed {
			return fmt.Errorf("operation %s must not allow ERP writes", operationName)
		}
	}
	return nil
}

func (c LogoAdminOpsContract) Operation(name LogoAdminOpsOperationName) (LogoAdminOpsOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoAdminOpsOperationContract{}, false
}

func (m LogoManualReviewContract) Validate() error {
	if !m.Declared {
		return errors.New("manual review contract must be declared")
	}
	if adminOpsTrim(m.Status) != LogoManualReviewContractStatus {
		return fmt.Errorf("invalid manual review contract status: %s", m.Status)
	}
	if !m.DryRunOnly {
		return errors.New("manual review contract must be dry-run only")
	}
	if !m.TenantScopeRequired {
		return errors.New("tenant scope is required")
	}
	if !m.CorrelationIDRequired {
		return errors.New("correlation id is required")
	}
	if !m.IdempotencyKeyRequired {
		return errors.New("idempotency key is required")
	}
	if !m.ReviewIDRequired {
		return errors.New("review id is required")
	}
	if !m.AuditFieldsRequired {
		return errors.New("audit fields are required")
	}
	if m.ExternalCallAllowed {
		return errors.New("external call must not be allowed")
	}
	if m.RealFileDeliveryAllowed {
		return errors.New("real file delivery must not be allowed")
	}
	if m.ERPWriteAllowed {
		return errors.New("ERP write must not be allowed")
	}
	return nil
}

func (r LogoManualReviewItem) Validate() error {
	if adminOpsTrim(r.ReviewID) == "" {
		return errors.New("review_id is required")
	}
	if adminOpsTrim(r.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if adminOpsTrim(r.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if adminOpsTrim(r.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if adminOpsTrim(r.PackageID) == "" {
		return errors.New("package_id is required")
	}
	if adminOpsTrim(r.DeliveryID) == "" {
		return errors.New("delivery_id is required")
	}
	if adminOpsTrim(string(r.ErrorCode)) == "" {
		return errors.New("error_code is required")
	}
	if adminOpsTrim(string(r.ErrorClass)) == "" {
		return errors.New("error_class is required")
	}
	if adminOpsTrim(string(r.Reason)) == "" {
		return errors.New("reason is required")
	}
	if !r.IsValidStatus() {
		return fmt.Errorf("invalid review status: %s", r.Status)
	}
	if adminOpsTrim(r.CreatedBy) == "" {
		return errors.New("created_by is required")
	}
	if !r.DryRunOnly {
		return errors.New("manual review item must be dry-run only")
	}
	return nil
}

func (r LogoManualReviewItem) IsValidStatus() bool {
	switch r.Status {
	case LogoManualReviewStatusOpen, LogoManualReviewStatusAssigned, LogoManualReviewStatusResolved, LogoManualReviewStatusRejected:
		return true
	default:
		return false
	}
}

func (r *LogoAdminOpsRuntime) CreateManualReviewItem(item LogoManualReviewItem) (LogoManualReviewItem, error) {
	if err := r.Contract.Validate(); err != nil {
		return LogoManualReviewItem{}, err
	}
	if err := item.Validate(); err != nil {
		return LogoManualReviewItem{}, err
	}
	if _, ok := r.findIndex(item.TenantID, item.ReviewID); ok {
		return LogoManualReviewItem{}, errors.New("manual review item already exists")
	}
	r.Reviews = append(r.Reviews, item)
	return item, nil
}

func (r LogoAdminOpsRuntime) ListManualReviews(tenantID string) ([]LogoManualReviewItem, error) {
	if err := r.Contract.Validate(); err != nil {
		return nil, err
	}
	if adminOpsTrim(tenantID) == "" {
		return nil, errors.New("tenant_id is required for list")
	}

	items := make([]LogoManualReviewItem, 0)
	for _, item := range r.Reviews {
		if item.TenantID == tenantID {
			items = append(items, item)
		}
	}
	return items, nil
}

func (r LogoAdminOpsRuntime) ReadManualReview(tenantID string, reviewID string) (LogoManualReviewItem, error) {
	if err := r.Contract.Validate(); err != nil {
		return LogoManualReviewItem{}, err
	}
	if adminOpsTrim(tenantID) == "" {
		return LogoManualReviewItem{}, errors.New("tenant_id is required for read")
	}
	if adminOpsTrim(reviewID) == "" {
		return LogoManualReviewItem{}, errors.New("review_id is required for read")
	}

	for _, item := range r.Reviews {
		if item.ReviewID == reviewID && item.TenantID == tenantID {
			return item, nil
		}
		if item.ReviewID == reviewID && item.TenantID != tenantID {
			return LogoManualReviewItem{}, errors.New("cross-tenant manual review access denied")
		}
	}
	return LogoManualReviewItem{}, errors.New("manual review item not found")
}

func (r *LogoAdminOpsRuntime) AssignManualReview(tenantID string, reviewID string, assignee string) (LogoManualReviewItem, error) {
	index, err := r.requireMutableReview(tenantID, reviewID)
	if err != nil {
		return LogoManualReviewItem{}, err
	}
	if adminOpsTrim(assignee) == "" {
		return LogoManualReviewItem{}, errors.New("assignee is required")
	}
	if r.Reviews[index].Status != LogoManualReviewStatusOpen && r.Reviews[index].Status != LogoManualReviewStatusAssigned {
		return LogoManualReviewItem{}, errors.New("only open or assigned review can be assigned")
	}

	r.Reviews[index].Status = LogoManualReviewStatusAssigned
	r.Reviews[index].AssignedTo = assignee
	return r.Reviews[index], nil
}

func (r *LogoAdminOpsRuntime) ResolveManualReview(tenantID string, reviewID string, closedBy string, note string) (LogoManualReviewItem, error) {
	index, err := r.requireMutableReview(tenantID, reviewID)
	if err != nil {
		return LogoManualReviewItem{}, err
	}
	if adminOpsTrim(closedBy) == "" {
		return LogoManualReviewItem{}, errors.New("closed_by is required")
	}
	if r.Reviews[index].Status != LogoManualReviewStatusAssigned {
		return LogoManualReviewItem{}, errors.New("only assigned review can be resolved")
	}

	r.Reviews[index].Status = LogoManualReviewStatusResolved
	r.Reviews[index].ClosedBy = closedBy
	r.Reviews[index].ResolutionNote = note
	return r.Reviews[index], nil
}

func (r *LogoAdminOpsRuntime) RejectManualReview(tenantID string, reviewID string, closedBy string, note string) (LogoManualReviewItem, error) {
	index, err := r.requireMutableReview(tenantID, reviewID)
	if err != nil {
		return LogoManualReviewItem{}, err
	}
	if adminOpsTrim(closedBy) == "" {
		return LogoManualReviewItem{}, errors.New("closed_by is required")
	}
	if r.Reviews[index].Status != LogoManualReviewStatusOpen && r.Reviews[index].Status != LogoManualReviewStatusAssigned {
		return LogoManualReviewItem{}, errors.New("only open or assigned review can be rejected")
	}

	r.Reviews[index].Status = LogoManualReviewStatusRejected
	r.Reviews[index].ClosedBy = closedBy
	r.Reviews[index].ResolutionNote = note
	return r.Reviews[index], nil
}

func (r *LogoAdminOpsRuntime) requireMutableReview(tenantID string, reviewID string) (int, error) {
	if err := r.Contract.Validate(); err != nil {
		return -1, err
	}
	if adminOpsTrim(tenantID) == "" {
		return -1, errors.New("tenant_id is required")
	}
	if adminOpsTrim(reviewID) == "" {
		return -1, errors.New("review_id is required")
	}

	for index, item := range r.Reviews {
		if item.ReviewID == reviewID && item.TenantID == tenantID {
			return index, nil
		}
		if item.ReviewID == reviewID && item.TenantID != tenantID {
			return -1, errors.New("cross-tenant manual review update denied")
		}
	}
	return -1, errors.New("manual review item not found")
}

func (r LogoAdminOpsRuntime) findIndex(tenantID string, reviewID string) (int, bool) {
	for index, item := range r.Reviews {
		if item.TenantID == tenantID && item.ReviewID == reviewID {
			return index, true
		}
	}
	return -1, false
}

func adminOpsTrim(value string) string {
	return strings.TrimSpace(value)
}
