package companyvisibility

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	multifirmaccess "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/multifirmaccess"
	subscriptionruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/subscriptionruntime"
)

type CompanyStatus string

const (
	CompanyStatusActive    CompanyStatus = "ACTIVE"
	CompanyStatusSuspended CompanyStatus = "SUSPENDED"
	CompanyStatusArchived  CompanyStatus = "ARCHIVED"
)

type VisibilityStatus string

const (
	VisibilityStatusReady    VisibilityStatus = "READY"
	VisibilityStatusRejected VisibilityStatus = "REJECTED"
)

type CompanyVisibilityDecision string

const (
	CompanyVisibilityVisible CompanyVisibilityDecision = "VISIBLE"
	CompanyVisibilityHidden  CompanyVisibilityDecision = "HIDDEN"
	CompanyVisibilityDenied  CompanyVisibilityDecision = "DENIED"
)

type RuntimeConfig struct {
	RuntimeEnabled             bool                         `json:"runtime_enabled"`
	RequireTenantScope         bool                         `json:"require_tenant_scope"`
	RequireCompanyScope        bool                         `json:"require_company_scope"`
	RequireActiveSubscription  bool                         `json:"require_active_subscription"`
	RequireActiveAssignment    bool                         `json:"require_active_assignment"`
	RequireVisibleCompanyFlag  bool                         `json:"require_visible_company_flag"`
	RequireActiveCompanyStatus bool                         `json:"require_active_company_status"`
	RequireCompanyProfile      bool                         `json:"require_company_profile"`
	RequirePermissionMatch     bool                         `json:"require_permission_match"`
	RequireAuditHash           bool                         `json:"require_audit_hash"`
	MaxVisibleFirmCount        int                          `json:"max_visible_firm_count"`
	AllowedCompanyStatuses     []CompanyStatus              `json:"allowed_company_statuses"`
	RequiredPortalPermissions  []multifirmaccess.Permission `json:"required_portal_permissions"`
}

type CompanyProfile struct {
	TenantID           string        `json:"tenant_id"`
	TargetFirmTenantID string        `json:"target_firm_tenant_id"`
	TargetCompanyID    string        `json:"target_company_id"`
	TargetCompanyName  string        `json:"target_company_name"`
	TaxNo              string        `json:"tax_no"`
	City               string        `json:"city"`
	Status             CompanyStatus `json:"status"`
	VisibleInPortal    bool          `json:"visible_in_portal"`
	AssignedAt         time.Time     `json:"assigned_at"`
	LastActivityAt     time.Time     `json:"last_activity_at"`
}

type CompanyVisibilityRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	RequiredPermission multifirmaccess.Permission `json:"required_permission"`

	Subscription subscriptionruntime.SubscriptionAccount `json:"subscription"`
	Assignments  []multifirmaccess.FirmAssignment        `json:"assignments"`
	Companies    []CompanyProfile                        `json:"companies"`

	RequestedAt time.Time `json:"requested_at"`
}

type CompanyVisibilityItem struct {
	AssignmentID       string                       `json:"assignment_id"`
	TargetFirmTenantID string                       `json:"target_firm_tenant_id"`
	TargetCompanyID    string                       `json:"target_company_id"`
	TargetCompanyName  string                       `json:"target_company_name"`
	TaxNo              string                       `json:"tax_no"`
	City               string                       `json:"city"`
	CompanyStatus      CompanyStatus                `json:"company_status"`
	Decision           CompanyVisibilityDecision    `json:"decision"`
	Role               multifirmaccess.PortalRole   `json:"role"`
	Permissions        []multifirmaccess.Permission `json:"permissions"`
	ReasonCode         string                       `json:"reason_code"`
	Reason             string                       `json:"reason"`
}

type CompanyVisibilityResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`

	Status VisibilityStatus `json:"status"`

	SubscriptionDecision subscriptionruntime.SubscriptionDecision `json:"subscription_decision"`

	VisibleCompanies []CompanyVisibilityItem `json:"visible_companies"`
	HiddenCompanies  []CompanyVisibilityItem `json:"hidden_companies"`
	DeniedCompanies  []CompanyVisibilityItem `json:"denied_companies"`

	TotalAssignmentCount int `json:"total_assignment_count"`
	VisibleCompanyCount  int `json:"visible_company_count"`
	HiddenCompanyCount   int `json:"hidden_company_count"`
	DeniedCompanyCount   int `json:"denied_company_count"`

	VisibilityHash string `json:"visibility_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type CompanyVisibilityRuntime struct {
	config              RuntimeConfig
	multiFirmRuntime    *multifirmaccess.MultiFirmAccessRuntime
	subscriptionRuntime *subscriptionruntime.MonthlySubscriptionRuntime
}

func NewCompanyVisibilityRuntime(config RuntimeConfig) (*CompanyVisibilityRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("company visibility runtime is disabled")
	}
	if config.MaxVisibleFirmCount <= 0 {
		return nil, errors.New("max_visible_firm_count must be positive")
	}
	if len(config.AllowedCompanyStatuses) == 0 {
		return nil, errors.New("allowed_company_statuses are required")
	}
	if len(config.RequiredPortalPermissions) == 0 {
		return nil, errors.New("required_portal_permissions are required")
	}

	multiFirmRuntime, err := multifirmaccess.NewMultiFirmAccessRuntime(defaultMultiFirmConfig())
	if err != nil {
		return nil, err
	}

	subscriptionRuntime, err := subscriptionruntime.NewMonthlySubscriptionRuntime(defaultSubscriptionConfig())
	if err != nil {
		return nil, err
	}

	return &CompanyVisibilityRuntime{
		config:              config,
		multiFirmRuntime:    multiFirmRuntime,
		subscriptionRuntime: subscriptionRuntime,
	}, nil
}

func (r *CompanyVisibilityRuntime) BuildVisibility(req CompanyVisibilityRequest) (CompanyVisibilityResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, subscriptionruntime.SubscriptionDecision{}, "VALIDATION_FAILED", err.Error()), err
	}

	subscriptionDecision, err := r.subscriptionRuntime.CheckAccess(subscriptionruntime.AccessCheckRequest{
		TenantID:          req.TenantID,
		CorrelationID:     req.CorrelationID,
		RequestID:         req.RequestID,
		IdempotencyKey:    req.IdempotencyKey + ":subscription",
		Subscription:      req.Subscription,
		RequiredFirmCount: len(req.Assignments),
		RequestedAt:       req.RequestedAt,
	})
	if err != nil || !subscriptionDecision.Allowed {
		if err == nil {
			err = errors.New("subscription access denied")
		}
		return rejected(req, subscriptionDecision, "SUBSCRIPTION_DENIED", err.Error()), err
	}

	multiFirmSubscription := toMultiFirmSubscription(req.Subscription)

	visibleFirmResult, err := r.multiFirmRuntime.ListVisibleFirms(multifirmaccess.VisibleFirmsRequest{
		TenantID:           req.TenantID,
		CorrelationID:      req.CorrelationID,
		RequestID:          req.RequestID,
		IdempotencyKey:     req.IdempotencyKey + ":multi-firm",
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		RequiredPermission: req.RequiredPermission,
		Subscription:       multiFirmSubscription,
		Assignments:        req.Assignments,
		RequestedAt:        req.RequestedAt,
	})
	if err != nil {
		return rejected(req, subscriptionDecision, "MULTI_FIRM_ACCESS_DENIED", err.Error()), err
	}

	companyByKey := map[string]CompanyProfile{}
	for _, company := range req.Companies {
		companyByKey[companyKey(company.TargetFirmTenantID, company.TargetCompanyID)] = company
	}

	visibleCompanies := make([]CompanyVisibilityItem, 0)
	hiddenCompanies := make([]CompanyVisibilityItem, 0)
	deniedCompanies := make([]CompanyVisibilityItem, 0)

	for _, visibleFirm := range visibleFirmResult.VisibleFirms {
		company, ok := companyByKey[companyKey(visibleFirm.TargetFirmTenantID, visibleFirm.TargetCompanyID)]
		if !ok {
			item := visibilityItemFromFirm(visibleFirm, CompanyProfile{}, CompanyVisibilityDenied, "COMPANY_PROFILE_MISSING", "company profile is required")
			deniedCompanies = append(deniedCompanies, item)
			continue
		}

		item, decisionErr := r.evaluateCompany(req, visibleFirm, company)
		if decisionErr != nil {
			if item.Decision == CompanyVisibilityHidden {
				hiddenCompanies = append(hiddenCompanies, item)
			} else {
				deniedCompanies = append(deniedCompanies, item)
			}
			continue
		}

		visibleCompanies = append(visibleCompanies, item)
	}

	sortVisibilityItems(visibleCompanies)
	sortVisibilityItems(hiddenCompanies)
	sortVisibilityItems(deniedCompanies)

	result := CompanyVisibilityResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		AccountantFirmID:     req.AccountantFirmID,
		AccountantUserID:     req.AccountantUserID,
		Status:               VisibilityStatusReady,
		SubscriptionDecision: subscriptionDecision,
		VisibleCompanies:     visibleCompanies,
		HiddenCompanies:      hiddenCompanies,
		DeniedCompanies:      deniedCompanies,
		TotalAssignmentCount: len(req.Assignments),
		VisibleCompanyCount:  len(visibleCompanies),
		HiddenCompanyCount:   len(hiddenCompanies),
		DeniedCompanyCount:   len(deniedCompanies),
		VisibilityHash:       buildVisibilityHash(req, visibleCompanies, hiddenCompanies, deniedCompanies),
		AuditAction:          "COMPANY_VISIBILITY_READY",
		AuditDecisionReason:  "company visibility filtered by subscription, multi-firm access, company status and visibility flag",
		CreatedAt:            time.Now().UTC(),
	}

	if r.config.RequireAuditHash && strings.TrimSpace(result.VisibilityHash) == "" {
		return rejected(req, subscriptionDecision, "VISIBILITY_HASH_MISSING", "visibility_hash is required"), errors.New("visibility_hash is required")
	}

	return result, nil
}

func (r *CompanyVisibilityRuntime) evaluateCompany(req CompanyVisibilityRequest, firm multifirmaccess.VisibleFirm, company CompanyProfile) (CompanyVisibilityItem, error) {
	if r.config.RequireTenantScope && company.TenantID != req.TenantID {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "COMPANY_TENANT_MISMATCH", "company tenant_id mismatch"), errors.New("company tenant_id mismatch")
	}
	if r.config.RequireTenantScope && company.TargetFirmTenantID != firm.TargetFirmTenantID {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "COMPANY_TARGET_TENANT_MISMATCH", "company target_firm_tenant_id mismatch"), errors.New("company target_firm_tenant_id mismatch")
	}
	if r.config.RequireCompanyScope && company.TargetCompanyID != firm.TargetCompanyID {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "COMPANY_ID_MISMATCH", "company target_company_id mismatch"), errors.New("company target_company_id mismatch")
	}
	if strings.TrimSpace(company.TargetCompanyName) == "" {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "COMPANY_NAME_MISSING", "target_company_name is required"), errors.New("target_company_name is required")
	}
	if strings.TrimSpace(company.TaxNo) == "" {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "COMPANY_TAX_NO_MISSING", "tax_no is required"), errors.New("tax_no is required")
	}
	if r.config.RequireActiveCompanyStatus && !hasCompanyStatus(r.config.AllowedCompanyStatuses, company.Status) {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityHidden, "COMPANY_STATUS_NOT_VISIBLE", "company status is not visible"), errors.New("company status is not visible")
	}
	if r.config.RequireVisibleCompanyFlag && !company.VisibleInPortal {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityHidden, "COMPANY_VISIBILITY_FLAG_OFF", "company visible_in_portal flag is false"), errors.New("company visible_in_portal flag is false")
	}
	if r.config.RequirePermissionMatch && !hasPortalPermission(firm.Permissions, req.RequiredPermission) {
		return visibilityItemFromFirm(firm, company, CompanyVisibilityDenied, "PERMISSION_NOT_VISIBLE", "required permission is not visible for firm"), errors.New("required permission is not visible for firm")
	}

	return visibilityItemFromFirm(firm, company, CompanyVisibilityVisible, "COMPANY_VISIBLE", "company is visible"), nil
}

func (r *CompanyVisibilityRuntime) validateRequest(req CompanyVisibilityRequest) error {
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
	if !hasPortalPermission(r.config.RequiredPortalPermissions, req.RequiredPermission) {
		return errors.New("required_permission is not allowed by runtime config")
	}
	if len(req.Assignments) == 0 {
		return errors.New("assignments are required")
	}
	if len(req.Assignments) > r.config.MaxVisibleFirmCount {
		return errors.New("assignments exceed max_visible_firm_count")
	}
	if r.config.RequireCompanyProfile && len(req.Companies) == 0 {
		return errors.New("companies are required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func visibilityItemFromFirm(firm multifirmaccess.VisibleFirm, company CompanyProfile, decision CompanyVisibilityDecision, reasonCode string, reason string) CompanyVisibilityItem {
	name := company.TargetCompanyName
	if strings.TrimSpace(name) == "" {
		name = firm.TargetCompanyName
	}

	return CompanyVisibilityItem{
		AssignmentID:       firm.AssignmentID,
		TargetFirmTenantID: firm.TargetFirmTenantID,
		TargetCompanyID:    firm.TargetCompanyID,
		TargetCompanyName:  name,
		TaxNo:              company.TaxNo,
		City:               company.City,
		CompanyStatus:      company.Status,
		Decision:           decision,
		Role:               firm.Role,
		Permissions:        append([]multifirmaccess.Permission(nil), firm.Permissions...),
		ReasonCode:         reasonCode,
		Reason:             reason,
	}
}

func toMultiFirmSubscription(sub subscriptionruntime.SubscriptionAccount) multifirmaccess.AccountantSubscription {
	status := multifirmaccess.SubscriptionStatusExpired
	switch sub.Status {
	case subscriptionruntime.SubscriptionStatusActive:
		status = multifirmaccess.SubscriptionStatusActive
	case subscriptionruntime.SubscriptionStatusTrialing:
		status = multifirmaccess.SubscriptionStatusTrialing
	case subscriptionruntime.SubscriptionStatusSuspended:
		status = multifirmaccess.SubscriptionStatusSuspended
	case subscriptionruntime.SubscriptionStatusCanceled:
		status = multifirmaccess.SubscriptionStatusCanceled
	case subscriptionruntime.SubscriptionStatusExpired:
		status = multifirmaccess.SubscriptionStatusExpired
	}

	return multifirmaccess.AccountantSubscription{
		SubscriptionID:    sub.SubscriptionID,
		TenantID:          sub.TenantID,
		AccountantFirmID:  sub.AccountantFirmID,
		Status:            status,
		ValidFrom:         sub.PeriodStart,
		ValidUntil:        sub.PeriodEnd,
		AssignedFirmLimit: sub.AssignedFirmLimit,
		AssignedFirmCount: sub.AssignedFirmCount,
	}
}

func sortVisibilityItems(items []CompanyVisibilityItem) {
	sort.SliceStable(items, func(i int, j int) bool {
		if items[i].TargetCompanyName == items[j].TargetCompanyName {
			return items[i].TargetCompanyID < items[j].TargetCompanyID
		}
		return items[i].TargetCompanyName < items[j].TargetCompanyName
	})
}

func companyKey(targetFirmTenantID string, targetCompanyID string) string {
	return targetFirmTenantID + ":" + targetCompanyID
}

func hasCompanyStatus(items []CompanyStatus, status CompanyStatus) bool {
	for _, item := range items {
		if item == status {
			return true
		}
	}
	return false
}

func hasPortalPermission(items []multifirmaccess.Permission, permission multifirmaccess.Permission) bool {
	for _, item := range items {
		if item == permission {
			return true
		}
	}
	return false
}

func buildVisibilityHash(req CompanyVisibilityRequest, visible []CompanyVisibilityItem, hidden []CompanyVisibilityItem, denied []CompanyVisibilityItem) string {
	parts := []string{
		req.TenantID,
		req.AccountantFirmID,
		req.AccountantUserID,
		string(req.RequiredPermission),
		fmt.Sprintf("visible:%d", len(visible)),
		fmt.Sprintf("hidden:%d", len(hidden)),
		fmt.Sprintf("denied:%d", len(denied)),
	}

	for _, item := range visible {
		parts = append(parts, "V:"+item.TargetFirmTenantID+":"+item.TargetCompanyID)
	}
	for _, item := range hidden {
		parts = append(parts, "H:"+item.TargetFirmTenantID+":"+item.TargetCompanyID+":"+item.ReasonCode)
	}
	for _, item := range denied {
		parts = append(parts, "D:"+item.TargetFirmTenantID+":"+item.TargetCompanyID+":"+item.ReasonCode)
	}

	return "company-visibility:" + strings.Join(parts, ":")
}

func rejected(req CompanyVisibilityRequest, decision subscriptionruntime.SubscriptionDecision, code string, message string) CompanyVisibilityResult {
	return CompanyVisibilityResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		AccountantFirmID:     req.AccountantFirmID,
		AccountantUserID:     req.AccountantUserID,
		Status:               VisibilityStatusRejected,
		SubscriptionDecision: decision,
		ErrorCode:            code,
		ErrorMessage:         message,
		AuditAction:          "COMPANY_VISIBILITY_REJECTED",
		AuditDecisionReason:  "company visibility rejected by runtime guard",
		CreatedAt:            time.Now().UTC(),
	}
}

func defaultMultiFirmConfig() multifirmaccess.RuntimeConfig {
	return multifirmaccess.RuntimeConfig{
		RuntimeEnabled:              true,
		DefaultCountryCode:          "TR",
		RequireActiveSubscription:   true,
		RequireActiveAssignment:     true,
		RequireTenantScope:          true,
		RequireCompanyScope:         true,
		RequirePermissionMatch:      true,
		RequireValidAssignmentDates: true,
		AllowSuperAdminOverride:     false,
		MaxAssignedFirmCount:        100,
		RequiredPermissions: []multifirmaccess.Permission{
			multifirmaccess.PermissionViewFirm,
			multifirmaccess.PermissionViewLedger,
			multifirmaccess.PermissionExportExcel,
			multifirmaccess.PermissionExportPDF,
			multifirmaccess.PermissionExportTDHP,
			multifirmaccess.PermissionManageAssignment,
			multifirmaccess.PermissionViewSubscription,
		},
		AllowedRoles: []multifirmaccess.PortalRole{
			multifirmaccess.PortalRoleOwner,
			multifirmaccess.PortalRoleStaff,
			multifirmaccess.PortalRoleReadOnly,
			multifirmaccess.PortalRoleSuperAdmin,
		},
	}
}

func defaultSubscriptionConfig() subscriptionruntime.RuntimeConfig {
	return subscriptionruntime.RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		RequireTenantScope:    true,
		RequireBillingProfile: true,
		RequireMonthlyCycle:   true,
		RequireFirmLimit:      true,
		RequireAuditActor:     true,
		AllowTrial:            true,
		AllowPlanChange:       true,
		AllowResumeSuspended:  true,
		DefaultTrialDays:      14,
		MaxAssignedFirmLimit:  100,
		AllowedPlanCodes:      []string{"ACCOUNTANT_STARTER", "ACCOUNTANT_PRO", "ACCOUNTANT_ENTERPRISE"},
		AllowedStatuses: []subscriptionruntime.SubscriptionStatus{
			subscriptionruntime.SubscriptionStatusDraft,
			subscriptionruntime.SubscriptionStatusTrialing,
			subscriptionruntime.SubscriptionStatusActive,
			subscriptionruntime.SubscriptionStatusSuspended,
			subscriptionruntime.SubscriptionStatusCanceled,
			subscriptionruntime.SubscriptionStatusExpired,
		},
	}
}
