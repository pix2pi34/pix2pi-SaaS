package companypermission

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
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

type ResourceType string

const (
	ResourceTypeFirm         ResourceType = "FIRM"
	ResourceTypeLedger       ResourceType = "LEDGER"
	ResourceTypeExport       ResourceType = "EXPORT"
	ResourceTypeAssignment   ResourceType = "ASSIGNMENT"
	ResourceTypeSubscription ResourceType = "SUBSCRIPTION"
)

type EnforcementStatus string

const (
	EnforcementAllowed EnforcementStatus = "ALLOWED"
	EnforcementDenied  EnforcementStatus = "DENIED"
)

type RuntimeConfig struct {
	RuntimeEnabled            bool           `json:"runtime_enabled"`
	RequireTenantScope        bool           `json:"require_tenant_scope"`
	RequireCompanyScope       bool           `json:"require_company_scope"`
	RequireAssignmentScope    bool           `json:"require_assignment_scope"`
	RequireResourcePermission bool           `json:"require_resource_permission"`
	RequireRolePermissionMap  bool           `json:"require_role_permission_map"`
	RequireExplicitGrant      bool           `json:"require_explicit_grant"`
	RequireAuditSubject       bool           `json:"require_audit_subject"`
	AllowSuperAdminOverride   bool           `json:"allow_super_admin_override"`
	RequiredPermissions       []Permission   `json:"required_permissions"`
	AllowedRoles              []PortalRole   `json:"allowed_roles"`
	AllowedResourceTypes      []ResourceType `json:"allowed_resource_types"`
}

type CompanyPermissionGrant struct {
	GrantID            string         `json:"grant_id"`
	TenantID           string         `json:"tenant_id"`
	AccountantFirmID   string         `json:"accountant_firm_id"`
	AccountantUserID   string         `json:"accountant_user_id"`
	AssignmentID       string         `json:"assignment_id"`
	TargetFirmTenantID string         `json:"target_firm_tenant_id"`
	TargetCompanyID    string         `json:"target_company_id"`
	Role               PortalRole     `json:"role"`
	Permissions        []Permission   `json:"permissions"`
	ResourceTypes      []ResourceType `json:"resource_types"`
	Active             bool           `json:"active"`
	ValidFrom          time.Time      `json:"valid_from"`
	ValidUntil         time.Time      `json:"valid_until"`
	GrantedBy          string         `json:"granted_by"`
	GrantedAt          time.Time      `json:"granted_at"`
}

type EnforcementRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID   string `json:"accountant_firm_id"`
	AccountantUserID   string `json:"accountant_user_id"`
	AssignmentID       string `json:"assignment_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	ResourceType       ResourceType `json:"resource_type"`
	RequiredPermission Permission   `json:"required_permission"`
	AuditSubject       string       `json:"audit_subject"`

	Grant CompanyPermissionGrant `json:"grant"`

	RequestedAt time.Time `json:"requested_at"`
}

type EnforcementDecision struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID   string `json:"accountant_firm_id"`
	AccountantUserID   string `json:"accountant_user_id"`
	AssignmentID       string `json:"assignment_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	ResourceType       ResourceType `json:"resource_type"`
	RequiredPermission Permission   `json:"required_permission"`

	Status  EnforcementStatus `json:"status"`
	Allowed bool              `json:"allowed"`

	Role        PortalRole   `json:"role"`
	Permissions []Permission `json:"permissions"`

	ReasonCode string `json:"reason_code"`
	Reason     string `json:"reason"`

	DecisionHash string `json:"decision_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	CreatedAt           time.Time `json:"created_at"`
}

type BulkEnforcementRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	Checks []EnforcementRequest `json:"checks"`

	RequestedAt time.Time `json:"requested_at"`
}

type BulkEnforcementResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	Decisions []EnforcementDecision `json:"decisions"`

	AllowedCount int `json:"allowed_count"`
	DeniedCount  int `json:"denied_count"`

	AllAllowed bool `json:"all_allowed"`

	ResultHash string `json:"result_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type CompanyPermissionEnforcementRuntime struct {
	config                RuntimeConfig
	rolePermissionMap     map[PortalRole][]Permission
	resourcePermissionMap map[ResourceType][]Permission
}

func NewCompanyPermissionEnforcementRuntime(config RuntimeConfig) (*CompanyPermissionEnforcementRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("company permission enforcement runtime is disabled")
	}
	if len(config.RequiredPermissions) == 0 {
		return nil, errors.New("required_permissions are required")
	}
	if len(config.AllowedRoles) == 0 {
		return nil, errors.New("allowed_roles are required")
	}
	if len(config.AllowedResourceTypes) == 0 {
		return nil, errors.New("allowed_resource_types are required")
	}

	return &CompanyPermissionEnforcementRuntime{
		config:                config,
		rolePermissionMap:     defaultRolePermissionMap(),
		resourcePermissionMap: defaultResourcePermissionMap(),
	}, nil
}

func (r *CompanyPermissionEnforcementRuntime) Enforce(req EnforcementRequest) (EnforcementDecision, error) {
	if err := r.validateRequest(req); err != nil {
		return r.deny(req, "VALIDATION_FAILED", err.Error()), err
	}

	if req.Grant.Role == PortalRoleSuperAdmin && r.config.AllowSuperAdminOverride {
		return r.allow(req, "SUPER_ADMIN_OVERRIDE", "super admin override allowed"), nil
	}

	if err := r.validateGrantScope(req, req.Grant); err != nil {
		return r.deny(req, "GRANT_SCOPE_DENIED", err.Error()), err
	}

	if r.config.RequireRolePermissionMap {
		allowedByRole := r.rolePermissionMap[req.Grant.Role]
		if !hasPermission(allowedByRole, req.RequiredPermission) {
			err := errors.New("role is not allowed to use required permission")
			return r.deny(req, "ROLE_PERMISSION_DENIED", err.Error()), err
		}
	}

	if r.config.RequireResourcePermission {
		allowedByResource := r.resourcePermissionMap[req.ResourceType]
		if !hasPermission(allowedByResource, req.RequiredPermission) {
			err := errors.New("permission is not allowed for requested resource type")
			return r.deny(req, "RESOURCE_PERMISSION_DENIED", err.Error()), err
		}
	}

	if r.config.RequireExplicitGrant && !hasPermission(req.Grant.Permissions, req.RequiredPermission) {
		err := errors.New("required permission is not explicitly granted")
		return r.deny(req, "EXPLICIT_GRANT_DENIED", err.Error()), err
	}

	if !hasResourceType(req.Grant.ResourceTypes, req.ResourceType) {
		err := errors.New("resource type is not explicitly granted")
		return r.deny(req, "RESOURCE_TYPE_DENIED", err.Error()), err
	}

	return r.allow(req, "PERMISSION_ALLOWED", "company permission enforcement allowed request"), nil
}

func (r *CompanyPermissionEnforcementRuntime) EnforceBulk(req BulkEnforcementRequest) (BulkEnforcementResult, error) {
	if err := r.validateBulkRequest(req); err != nil {
		return rejectedBulk(req, "VALIDATION_FAILED", err.Error()), err
	}

	decisions := make([]EnforcementDecision, 0, len(req.Checks))
	allowedCount := 0
	deniedCount := 0

	for _, check := range req.Checks {
		decision, err := r.Enforce(check)
		decisions = append(decisions, decision)
		if err != nil || !decision.Allowed {
			deniedCount++
			continue
		}
		allowedCount++
	}

	sort.SliceStable(decisions, func(i int, j int) bool {
		if decisions[i].TargetCompanyID == decisions[j].TargetCompanyID {
			return decisions[i].ResourceType < decisions[j].ResourceType
		}
		return decisions[i].TargetCompanyID < decisions[j].TargetCompanyID
	})

	allAllowed := deniedCount == 0

	result := BulkEnforcementResult{
		TenantID:         req.TenantID,
		CorrelationID:    req.CorrelationID,
		RequestID:        req.RequestID,
		IdempotencyKey:   req.IdempotencyKey,
		AccountantFirmID: req.AccountantFirmID,
		AccountantUserID: req.AccountantUserID,
		Decisions:        decisions,
		AllowedCount:     allowedCount,
		DeniedCount:      deniedCount,
		AllAllowed:       allAllowed,
		ResultHash:       buildBulkHash(req, decisions),
		CreatedAt:        time.Now().UTC(),
	}

	if !allAllowed {
		result.AuditAction = "COMPANY_PERMISSION_BULK_PARTIAL_DENIED"
		result.AuditDecisionReason = "one or more company permission checks were denied"
		result.ErrorCode = "BULK_PERMISSION_DENIED"
		result.ErrorMessage = "bulk permission enforcement contains denied decisions"
		return result, errors.New("bulk permission enforcement contains denied decisions")
	}

	result.AuditAction = "COMPANY_PERMISSION_BULK_ALLOWED"
	result.AuditDecisionReason = "all company permission checks were allowed"
	return result, nil
}

func (r *CompanyPermissionEnforcementRuntime) validateRequest(req EnforcementRequest) error {
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
	if strings.TrimSpace(req.AssignmentID) == "" {
		return errors.New("assignment_id is required")
	}
	if strings.TrimSpace(req.TargetFirmTenantID) == "" {
		return errors.New("target_firm_tenant_id is required")
	}
	if strings.TrimSpace(req.TargetCompanyID) == "" {
		return errors.New("target_company_id is required")
	}
	if strings.TrimSpace(string(req.ResourceType)) == "" {
		return errors.New("resource_type is required")
	}
	if !hasResourceType(r.config.AllowedResourceTypes, req.ResourceType) {
		return errors.New("resource_type is not allowed by runtime config")
	}
	if strings.TrimSpace(string(req.RequiredPermission)) == "" {
		return errors.New("required_permission is required")
	}
	if !hasPermission(r.config.RequiredPermissions, req.RequiredPermission) {
		return errors.New("required_permission is not allowed by runtime config")
	}
	if r.config.RequireAuditSubject && strings.TrimSpace(req.AuditSubject) == "" {
		return errors.New("audit_subject is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *CompanyPermissionEnforcementRuntime) validateBulkRequest(req BulkEnforcementRequest) error {
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
	if len(req.Checks) == 0 {
		return errors.New("permission checks are required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *CompanyPermissionEnforcementRuntime) validateGrantScope(req EnforcementRequest, grant CompanyPermissionGrant) error {
	if strings.TrimSpace(grant.GrantID) == "" {
		return errors.New("grant_id is required")
	}
	if r.config.RequireTenantScope && grant.TenantID != req.TenantID {
		return errors.New("grant tenant_id mismatch")
	}
	if grant.AccountantFirmID != req.AccountantFirmID {
		return errors.New("grant accountant_firm_id mismatch")
	}
	if grant.AccountantUserID != req.AccountantUserID {
		return errors.New("grant accountant_user_id mismatch")
	}
	if r.config.RequireAssignmentScope && grant.AssignmentID != req.AssignmentID {
		return errors.New("grant assignment_id mismatch")
	}
	if grant.TargetFirmTenantID != req.TargetFirmTenantID {
		return errors.New("grant target_firm_tenant_id mismatch")
	}
	if r.config.RequireCompanyScope && grant.TargetCompanyID != req.TargetCompanyID {
		return errors.New("grant target_company_id mismatch")
	}
	if !grant.Active {
		return errors.New("grant must be active")
	}
	if !hasAllowedRole(r.config.AllowedRoles, grant.Role) {
		return errors.New("grant role is not allowed")
	}
	if len(grant.Permissions) == 0 {
		return errors.New("grant permissions are required")
	}
	if len(grant.ResourceTypes) == 0 {
		return errors.New("grant resource_types are required")
	}
	if grant.ValidFrom.IsZero() {
		return errors.New("grant valid_from is required")
	}
	if grant.ValidUntil.IsZero() {
		return errors.New("grant valid_until is required")
	}
	if req.RequestedAt.Before(grant.ValidFrom) {
		return errors.New("grant is not active yet")
	}
	if req.RequestedAt.After(grant.ValidUntil) {
		return errors.New("grant is expired")
	}
	if strings.TrimSpace(grant.GrantedBy) == "" {
		return errors.New("granted_by is required")
	}
	if grant.GrantedAt.IsZero() {
		return errors.New("granted_at is required")
	}
	return nil
}

func (r *CompanyPermissionEnforcementRuntime) allow(req EnforcementRequest, reasonCode string, reason string) EnforcementDecision {
	return EnforcementDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		AssignmentID:        req.AssignmentID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		ResourceType:        req.ResourceType,
		RequiredPermission:  req.RequiredPermission,
		Status:              EnforcementAllowed,
		Allowed:             true,
		Role:                req.Grant.Role,
		Permissions:         append([]Permission(nil), req.Grant.Permissions...),
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(req, EnforcementAllowed, reasonCode),
		AuditAction:         "COMPANY_PERMISSION_ALLOWED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func (r *CompanyPermissionEnforcementRuntime) deny(req EnforcementRequest, reasonCode string, reason string) EnforcementDecision {
	return EnforcementDecision{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		AssignmentID:        req.AssignmentID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		ResourceType:        req.ResourceType,
		RequiredPermission:  req.RequiredPermission,
		Status:              EnforcementDenied,
		Allowed:             false,
		Role:                req.Grant.Role,
		Permissions:         append([]Permission(nil), req.Grant.Permissions...),
		ReasonCode:          reasonCode,
		Reason:              reason,
		DecisionHash:        buildDecisionHash(req, EnforcementDenied, reasonCode),
		AuditAction:         "COMPANY_PERMISSION_DENIED",
		AuditDecisionReason: reason,
		CreatedAt:           time.Now().UTC(),
	}
}

func hasPermission(items []Permission, required Permission) bool {
	for _, item := range items {
		if item == required {
			return true
		}
	}
	return false
}

func hasResourceType(items []ResourceType, required ResourceType) bool {
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

func defaultRolePermissionMap() map[PortalRole][]Permission {
	return map[PortalRole][]Permission{
		PortalRoleOwner: {
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
			PermissionManageAssignment,
			PermissionViewSubscription,
		},
		PortalRoleStaff: {
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
		},
		PortalRoleReadOnly: {
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionViewSubscription,
		},
		PortalRoleSuperAdmin: {
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
			PermissionManageAssignment,
			PermissionViewSubscription,
		},
	}
}

func defaultResourcePermissionMap() map[ResourceType][]Permission {
	return map[ResourceType][]Permission{
		ResourceTypeFirm: {
			PermissionViewFirm,
		},
		ResourceTypeLedger: {
			PermissionViewLedger,
		},
		ResourceTypeExport: {
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
		},
		ResourceTypeAssignment: {
			PermissionManageAssignment,
		},
		ResourceTypeSubscription: {
			PermissionViewSubscription,
		},
	}
}

func buildDecisionHash(req EnforcementRequest, status EnforcementStatus, reasonCode string) string {
	parts := []string{
		req.TenantID,
		req.AccountantFirmID,
		req.AccountantUserID,
		req.AssignmentID,
		req.TargetFirmTenantID,
		req.TargetCompanyID,
		string(req.ResourceType),
		string(req.RequiredPermission),
		string(status),
		reasonCode,
	}
	return "company-permission:" + strings.Join(parts, ":")
}

func buildBulkHash(req BulkEnforcementRequest, decisions []EnforcementDecision) string {
	parts := []string{
		req.TenantID,
		req.AccountantFirmID,
		req.AccountantUserID,
		fmt.Sprintf("decisions:%d", len(decisions)),
	}
	for _, decision := range decisions {
		parts = append(parts, decision.DecisionHash)
	}
	return "company-permission-bulk:" + strings.Join(parts, ":")
}

func rejectedBulk(req BulkEnforcementRequest, code string, message string) BulkEnforcementResult {
	return BulkEnforcementResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		AllAllowed:          false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "COMPANY_PERMISSION_BULK_REJECTED",
		AuditDecisionReason: "bulk permission request rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}
