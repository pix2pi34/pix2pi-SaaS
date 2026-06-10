package multifirmaccess

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

type SubscriptionStatus string

const (
	SubscriptionStatusActive    SubscriptionStatus = "ACTIVE"
	SubscriptionStatusTrialing  SubscriptionStatus = "TRIALING"
	SubscriptionStatusSuspended SubscriptionStatus = "SUSPENDED"
	SubscriptionStatusExpired   SubscriptionStatus = "EXPIRED"
	SubscriptionStatusCanceled  SubscriptionStatus = "CANCELED"
)

type AssignmentStatus string

const (
	AssignmentStatusActive   AssignmentStatus = "ACTIVE"
	AssignmentStatusInactive AssignmentStatus = "INACTIVE"
	AssignmentStatusRevoked  AssignmentStatus = "REVOKED"
)

type PortalRole string

const (
	PortalRoleOwner      PortalRole = "ACCOUNTANT_OWNER"
	PortalRoleStaff      PortalRole = "ACCOUNTANT_STAFF"
	PortalRoleReadOnly   PortalRole = "ACCOUNTANT_READ_ONLY"
	PortalRoleSuperAdmin PortalRole = "SUPER_ADMIN"
)

type Permission string

const (
	PermissionViewFirm         Permission = "VIEW_FIRM"
	PermissionViewLedger       Permission = "VIEW_LEDGER"
	PermissionExportExcel      Permission = "EXPORT_EXCEL"
	PermissionExportPDF        Permission = "EXPORT_PDF"
	PermissionExportTDHP       Permission = "EXPORT_TDHP"
	PermissionManageAssignment Permission = "MANAGE_ASSIGNMENT"
	PermissionViewSubscription Permission = "VIEW_SUBSCRIPTION"
)

type AccessDecisionStatus string

const (
	AccessDecisionAllowed AccessDecisionStatus = "ALLOWED"
	AccessDecisionDenied  AccessDecisionStatus = "DENIED"
)

type VisibilityStatus string

const (
	VisibilityVisible VisibilityStatus = "VISIBLE"
	VisibilityHidden  VisibilityStatus = "HIDDEN"
	VisibilityDenied  VisibilityStatus = "DENIED"
)

type RuntimeConfig struct {
	RuntimeEnabled              bool         `json:"runtime_enabled"`
	DefaultCountryCode          string       `json:"default_country_code"`
	RequireActiveSubscription   bool         `json:"require_active_subscription"`
	RequireActiveAssignment     bool         `json:"require_active_assignment"`
	RequireTenantScope          bool         `json:"require_tenant_scope"`
	RequireCompanyScope         bool         `json:"require_company_scope"`
	RequirePermissionMatch      bool         `json:"require_permission_match"`
	RequireValidAssignmentDates bool         `json:"require_valid_assignment_dates"`
	AllowSuperAdminOverride     bool         `json:"allow_super_admin_override"`
	MaxAssignedFirmCount        int          `json:"max_assigned_firm_count"`
	RequiredPermissions         []Permission `json:"required_permissions"`
	AllowedRoles                []PortalRole `json:"allowed_roles"`
}

type AccountantSubscription struct {
	SubscriptionID    string             `json:"subscription_id"`
	TenantID          string             `json:"tenant_id"`
	AccountantFirmID  string             `json:"accountant_firm_id"`
	Status            SubscriptionStatus `json:"status"`
	ValidFrom         time.Time          `json:"valid_from"`
	ValidUntil        time.Time          `json:"valid_until"`
	AssignedFirmLimit int                `json:"assigned_firm_limit"`
	AssignedFirmCount int                `json:"assigned_firm_count"`
}

type FirmAssignment struct {
	AssignmentID       string           `json:"assignment_id"`
	TenantID           string           `json:"tenant_id"`
	AccountantFirmID   string           `json:"accountant_firm_id"`
	AccountantUserID   string           `json:"accountant_user_id"`
	TargetFirmTenantID string           `json:"target_firm_tenant_id"`
	TargetCompanyID    string           `json:"target_company_id"`
	TargetCompanyName  string           `json:"target_company_name"`
	Status             AssignmentStatus `json:"status"`
	Role               PortalRole       `json:"role"`
	Permissions        []Permission     `json:"permissions"`
	ValidFrom          time.Time        `json:"valid_from"`
	ValidUntil         time.Time        `json:"valid_until"`
	AssignedBy         string           `json:"assigned_by"`
	AssignedAt         time.Time        `json:"assigned_at"`
}

type AccessRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	RequiredPermission Permission `json:"required_permission"`

	Subscription AccountantSubscription `json:"subscription"`
	Assignment   FirmAssignment         `json:"assignment"`

	RequestedAt time.Time `json:"requested_at"`
}

type AccessDecision struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID   string `json:"accountant_firm_id"`
	AccountantUserID   string `json:"accountant_user_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	Status           AccessDecisionStatus `json:"status"`
	VisibilityStatus VisibilityStatus     `json:"visibility_status"`
	Allowed          bool                 `json:"allowed"`

	Role        PortalRole   `json:"role"`
	Permissions []Permission `json:"permissions"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	AccessHash string `json:"access_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	CreatedAt           time.Time `json:"created_at"`
}

type VisibleFirmsRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	RequiredPermission Permission `json:"required_permission"`

	Subscription AccountantSubscription `json:"subscription"`
	Assignments  []FirmAssignment       `json:"assignments"`

	RequestedAt time.Time `json:"requested_at"`
}

type VisibleFirm struct {
	AssignmentID       string       `json:"assignment_id"`
	TargetFirmTenantID string       `json:"target_firm_tenant_id"`
	TargetCompanyID    string       `json:"target_company_id"`
	TargetCompanyName  string       `json:"target_company_name"`
	Role               PortalRole   `json:"role"`
	Permissions        []Permission `json:"permissions"`
	Visible            bool         `json:"visible"`
}

type VisibleFirmsResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	Status MatrixLikeStatus `json:"status"`

	VisibleFirms []VisibleFirm `json:"visible_firms"`

	TotalAssignmentCount int `json:"total_assignment_count"`
	VisibleFirmCount     int `json:"visible_firm_count"`
	DeniedFirmCount      int `json:"denied_firm_count"`

	ResultHash string `json:"result_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type MatrixLikeStatus string

const (
	ResultStatusReady    MatrixLikeStatus = "READY"
	ResultStatusRejected MatrixLikeStatus = "REJECTED"
)

type MultiFirmAccessRuntime struct {
	config RuntimeConfig
}

func NewMultiFirmAccessRuntime(config RuntimeConfig) (*MultiFirmAccessRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("multi-firm access runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCountryCode) == "" {
		return nil, errors.New("default_country_code is required")
	}
	if config.MaxAssignedFirmCount <= 0 {
		return nil, errors.New("max_assigned_firm_count must be positive")
	}
	if len(config.RequiredPermissions) == 0 {
		return nil, errors.New("required_permissions are required")
	}
	if len(config.AllowedRoles) == 0 {
		return nil, errors.New("allowed_roles are required")
	}

	return &MultiFirmAccessRuntime{config: config}, nil
}

func (r *MultiFirmAccessRuntime) EvaluateAccess(req AccessRequest) (AccessDecision, error) {
	if err := r.validateAccessRequest(req); err != nil {
		return r.deny(req, "VALIDATION_FAILED", err.Error()), err
	}

	if r.isSuperAdmin(req.Assignment.Role) && r.config.AllowSuperAdminOverride {
		return r.allow(req, "SUPER_ADMIN_OVERRIDE", "super admin override allowed"), nil
	}

	if r.config.RequireActiveSubscription {
		if err := r.validateSubscription(req.TenantID, req.AccountantFirmID, req.Subscription, req.RequestedAt); err != nil {
			return r.deny(req, "SUBSCRIPTION_DENIED", err.Error()), err
		}
	}

	if r.config.RequireActiveAssignment {
		if err := r.validateAssignment(req, req.Assignment); err != nil {
			return r.deny(req, "ASSIGNMENT_DENIED", err.Error()), err
		}
	}

	if r.config.RequirePermissionMatch && !hasPermission(req.Assignment.Permissions, req.RequiredPermission) {
		err := errors.New("required permission is not assigned to accountant user")
		return r.deny(req, "PERMISSION_DENIED", err.Error()), err
	}

	return r.allow(req, "ACCESS_ALLOWED", "accountant user can access assigned company"), nil
}

func (r *MultiFirmAccessRuntime) ListVisibleFirms(req VisibleFirmsRequest) (VisibleFirmsResult, error) {
	if err := r.validateVisibleFirmsRequest(req); err != nil {
		return rejectedVisibleFirms(req, "VALIDATION_FAILED", err.Error()), err
	}

	if r.config.RequireActiveSubscription {
		if err := r.validateSubscription(req.TenantID, req.AccountantFirmID, req.Subscription, req.RequestedAt); err != nil {
			return rejectedVisibleFirms(req, "SUBSCRIPTION_DENIED", err.Error()), err
		}
	}

	visible := make([]VisibleFirm, 0)
	deniedCount := 0

	assignments := append([]FirmAssignment(nil), req.Assignments...)
	sort.SliceStable(assignments, func(i int, j int) bool {
		return assignments[i].TargetCompanyName < assignments[j].TargetCompanyName
	})

	for _, assignment := range assignments {
		accessReq := AccessRequest{
			TenantID:           req.TenantID,
			CorrelationID:      req.CorrelationID,
			RequestID:          req.RequestID,
			IdempotencyKey:     req.IdempotencyKey + ":" + assignment.AssignmentID,
			AccountantFirmID:   req.AccountantFirmID,
			AccountantUserID:   req.AccountantUserID,
			TargetFirmTenantID: assignment.TargetFirmTenantID,
			TargetCompanyID:    assignment.TargetCompanyID,
			RequiredPermission: req.RequiredPermission,
			Subscription:       req.Subscription,
			Assignment:         assignment,
			RequestedAt:        req.RequestedAt,
		}

		decision, err := r.EvaluateAccess(accessReq)
		if err != nil || !decision.Allowed {
			deniedCount++
			continue
		}

		visible = append(visible, VisibleFirm{
			AssignmentID:       assignment.AssignmentID,
			TargetFirmTenantID: assignment.TargetFirmTenantID,
			TargetCompanyID:    assignment.TargetCompanyID,
			TargetCompanyName:  assignment.TargetCompanyName,
			Role:               assignment.Role,
			Permissions:        append([]Permission(nil), assignment.Permissions...),
			Visible:            true,
		})
	}

	result := VisibleFirmsResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		AccountantFirmID:     req.AccountantFirmID,
		AccountantUserID:     req.AccountantUserID,
		Status:               ResultStatusReady,
		VisibleFirms:         visible,
		TotalAssignmentCount: len(req.Assignments),
		VisibleFirmCount:     len(visible),
		DeniedFirmCount:      deniedCount,
		ResultHash:           buildVisibleFirmsHash(req, visible, deniedCount),
		AuditAction:          "MULTI_FIRM_VISIBLE_LIST_READY",
		AuditDecisionReason:  "visible firms filtered by tenant-safe assignment, subscription and permission guards",
		CreatedAt:            time.Now().UTC(),
	}

	return result, nil
}

func (r *MultiFirmAccessRuntime) validateAccessRequest(req AccessRequest) error {
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
	if strings.TrimSpace(req.AccountantFirmID) == "" {
		return errors.New("accountant_firm_id is required")
	}
	if strings.TrimSpace(req.AccountantUserID) == "" {
		return errors.New("accountant_user_id is required")
	}
	if strings.TrimSpace(req.TargetFirmTenantID) == "" {
		return errors.New("target_firm_tenant_id is required")
	}
	if strings.TrimSpace(req.TargetCompanyID) == "" {
		return errors.New("target_company_id is required")
	}
	if strings.TrimSpace(string(req.RequiredPermission)) == "" {
		return errors.New("required_permission is required")
	}
	if !hasRequiredPermission(r.config.RequiredPermissions, req.RequiredPermission) {
		return errors.New("required_permission is not supported by runtime config")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *MultiFirmAccessRuntime) validateVisibleFirmsRequest(req VisibleFirmsRequest) error {
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
	if strings.TrimSpace(req.AccountantFirmID) == "" {
		return errors.New("accountant_firm_id is required")
	}
	if strings.TrimSpace(req.AccountantUserID) == "" {
		return errors.New("accountant_user_id is required")
	}
	if strings.TrimSpace(string(req.RequiredPermission)) == "" {
		return errors.New("required_permission is required")
	}
	if len(req.Assignments) > r.config.MaxAssignedFirmCount {
		return errors.New("assignment count exceeds max_assigned_firm_count")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *MultiFirmAccessRuntime) validateSubscription(expectedTenantID string, expectedAccountantFirmID string, sub AccountantSubscription, now time.Time) error {
	if strings.TrimSpace(sub.SubscriptionID) == "" {
		return errors.New("subscription_id is required")
	}
	if r.config.RequireTenantScope && sub.TenantID != expectedTenantID {
		return errors.New("subscription tenant_id mismatch")
	}
	if sub.AccountantFirmID != expectedAccountantFirmID {
		return errors.New("subscription accountant_firm_id mismatch")
	}
	if sub.Status != SubscriptionStatusActive && sub.Status != SubscriptionStatusTrialing {
		return errors.New("subscription status must be ACTIVE or TRIALING")
	}
	if sub.ValidFrom.IsZero() {
		return errors.New("subscription valid_from is required")
	}
	if sub.ValidUntil.IsZero() {
		return errors.New("subscription valid_until is required")
	}
	if now.Before(sub.ValidFrom) {
		return errors.New("subscription is not active yet")
	}
	if now.After(sub.ValidUntil) {
		return errors.New("subscription is expired")
	}
	if sub.AssignedFirmLimit <= 0 {
		return errors.New("assigned_firm_limit must be positive")
	}
	if sub.AssignedFirmCount > sub.AssignedFirmLimit {
		return errors.New("assigned firm count exceeds subscription limit")
	}
	return nil
}

func (r *MultiFirmAccessRuntime) validateAssignment(req AccessRequest, assignment FirmAssignment) error {
	if strings.TrimSpace(assignment.AssignmentID) == "" {
		return errors.New("assignment_id is required")
	}
	if r.config.RequireTenantScope && assignment.TenantID != req.TenantID {
		return errors.New("assignment tenant_id mismatch")
	}
	if assignment.AccountantFirmID != req.AccountantFirmID {
		return errors.New("assignment accountant_firm_id mismatch")
	}
	if assignment.AccountantUserID != req.AccountantUserID {
		return errors.New("assignment accountant_user_id mismatch")
	}
	if assignment.TargetFirmTenantID != req.TargetFirmTenantID {
		return errors.New("assignment target_firm_tenant_id mismatch")
	}
	if r.config.RequireCompanyScope && assignment.TargetCompanyID != req.TargetCompanyID {
		return errors.New("assignment target_company_id mismatch")
	}
	if assignment.Status != AssignmentStatusActive {
		return errors.New("assignment status must be ACTIVE")
	}
	if !hasAllowedRole(r.config.AllowedRoles, assignment.Role) {
		return errors.New("assignment role is not allowed")
	}
	if len(assignment.Permissions) == 0 {
		return errors.New("assignment permissions are required")
	}
	if r.config.RequireValidAssignmentDates {
		if assignment.ValidFrom.IsZero() {
			return errors.New("assignment valid_from is required")
		}
		if assignment.ValidUntil.IsZero() {
			return errors.New("assignment valid_until is required")
		}
		if req.RequestedAt.Before(assignment.ValidFrom) {
			return errors.New("assignment is not active yet")
		}
		if req.RequestedAt.After(assignment.ValidUntil) {
			return errors.New("assignment is expired")
		}
	}
	if strings.TrimSpace(assignment.AssignedBy) == "" {
		return errors.New("assigned_by is required")
	}
	if assignment.AssignedAt.IsZero() {
		return errors.New("assigned_at is required")
	}
	return nil
}

func (r *MultiFirmAccessRuntime) allow(req AccessRequest, reasonCode string, reason string) AccessDecision {
	return AccessDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		Status:              AccessDecisionAllowed,
		VisibilityStatus:    VisibilityVisible,
		Allowed:             true,
		Role:                req.Assignment.Role,
		Permissions:         append([]Permission(nil), req.Assignment.Permissions...),
		ReasonCode:          reasonCode,
		Reason:              reason,
		AccessHash:          buildAccessHash(req, AccessDecisionAllowed, reasonCode),
		AuditAction:         "MULTI_FIRM_ACCESS_ALLOWED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func (r *MultiFirmAccessRuntime) deny(req AccessRequest, reasonCode string, reason string) AccessDecision {
	return AccessDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		Status:              AccessDecisionDenied,
		VisibilityStatus:    VisibilityDenied,
		Allowed:             false,
		Role:                req.Assignment.Role,
		Permissions:         append([]Permission(nil), req.Assignment.Permissions...),
		ReasonCode:          reasonCode,
		Reason:              reason,
		AccessHash:          buildAccessHash(req, AccessDecisionDenied, reasonCode),
		AuditAction:         "MULTI_FIRM_ACCESS_DENIED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func (r *MultiFirmAccessRuntime) isSuperAdmin(role PortalRole) bool {
	return role == PortalRoleSuperAdmin
}

func hasPermission(items []Permission, required Permission) bool {
	for _, item := range items {
		if item == required {
			return true
		}
	}
	return false
}

func hasRequiredPermission(items []Permission, required Permission) bool {
	for _, item := range items {
		if item == required {
			return true
		}
	}
	return false
}

func hasAllowedRole(items []PortalRole, role PortalRole) bool {
	for _, item := range items {
		if item == role {
			return true
		}
	}
	return false
}

func buildAccessHash(req AccessRequest, status AccessDecisionStatus, reasonCode string) string {
	parts := []string{
		req.TenantID,
		req.AccountantFirmID,
		req.AccountantUserID,
		req.TargetFirmTenantID,
		req.TargetCompanyID,
		string(req.RequiredPermission),
		string(status),
		reasonCode,
	}
	return "multi-firm-access:" + strings.Join(parts, ":")
}

func buildVisibleFirmsHash(req VisibleFirmsRequest, visible []VisibleFirm, deniedCount int) string {
	parts := []string{
		req.TenantID,
		req.AccountantFirmID,
		req.AccountantUserID,
		string(req.RequiredPermission),
		fmt.Sprintf("visible:%d", len(visible)),
		fmt.Sprintf("denied:%d", deniedCount),
	}
	for _, firm := range visible {
		parts = append(parts, firm.TargetFirmTenantID, firm.TargetCompanyID, firm.AssignmentID)
	}
	return "visible-firms:" + strings.Join(parts, ":")
}

func rejectedVisibleFirms(req VisibleFirmsRequest, code string, message string) VisibleFirmsResult {
	return VisibleFirmsResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		Status:              ResultStatusRejected,
		VisibleFirms:        nil,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "MULTI_FIRM_VISIBLE_LIST_REJECTED",
		AuditDecisionReason: "visible firm list rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}
