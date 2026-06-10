package integrationtests

import (
	"errors"
	"fmt"
	"strings"
	"time"

	companypermission "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/companypermission"
	companyvisibility "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/companyvisibility"
	exportruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/exportruntime"
	multifirmaccess "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/multifirmaccess"
	subscriptionruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/subscriptionruntime"
)

type IntegrationStatus string

const (
	IntegrationStatusPass IntegrationStatus = "PASS"
	IntegrationStatusFail IntegrationStatus = "FAIL"
)

type RuntimeConfig struct {
	RuntimeEnabled          bool                         `json:"runtime_enabled"`
	DefaultCurrencyCode     string                       `json:"default_currency_code"`
	RequireSubscriptionFlow bool                         `json:"require_subscription_flow"`
	RequireVisibilityFlow   bool                         `json:"require_visibility_flow"`
	RequirePermissionFlow   bool                         `json:"require_permission_flow"`
	RequireExportFlow       bool                         `json:"require_export_flow"`
	RequireAllFormats       bool                         `json:"require_all_formats"`
	RequireAuditHash        bool                         `json:"require_audit_hash"`
	RequiredPermission      multifirmaccess.Permission   `json:"required_permission"`
	RequiredExportFormats   []exportruntime.ExportFormat `json:"required_export_formats"`
}

type IntegrationSuiteRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID string `json:"suite_id"`

	AccountantFirmID string `json:"accountant_firm_id"`
	AccountantUserID string `json:"accountant_user_id"`
	ActorID          string `json:"actor_id"`

	SubscriptionID   string `json:"subscription_id"`
	BillingProfileID string `json:"billing_profile_id"`

	AssignmentID       string `json:"assignment_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`
	TargetCompanyName  string `json:"target_company_name"`
	TargetCompanyTaxNo string `json:"target_company_tax_no"`
	TargetCompanyCity  string `json:"target_company_city"`

	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	RequestedAt time.Time `json:"requested_at"`
}

type IntegrationSuiteResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID string `json:"suite_id"`

	Status IntegrationStatus `json:"status"`

	SubscriptionDecision subscriptionruntime.SubscriptionDecision  `json:"subscription_decision"`
	VisibilityResult     companyvisibility.CompanyVisibilityResult `json:"visibility_result"`
	PermissionDecision   companypermission.EnforcementDecision     `json:"permission_decision"`
	ExportBundleResult   exportruntime.ExportBundleResult          `json:"export_bundle_result"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	IntegrationHash string `json:"integration_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type AccountantPortalIntegrationSuite struct {
	config              RuntimeConfig
	subscriptionRuntime *subscriptionruntime.MonthlySubscriptionRuntime
	visibilityRuntime   *companyvisibility.CompanyVisibilityRuntime
	permissionRuntime   *companypermission.CompanyPermissionEnforcementRuntime
	exportRuntime       *exportruntime.ExcelPDFTDHPExportRuntime
}

func NewAccountantPortalIntegrationSuite(config RuntimeConfig) (*AccountantPortalIntegrationSuite, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("accountant portal integration suite is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if strings.TrimSpace(string(config.RequiredPermission)) == "" {
		return nil, errors.New("required_permission is required")
	}
	if len(config.RequiredExportFormats) == 0 {
		return nil, errors.New("required_export_formats are required")
	}

	subscriptionRuntime, err := subscriptionruntime.NewMonthlySubscriptionRuntime(defaultSubscriptionConfig())
	if err != nil {
		return nil, err
	}

	visibilityRuntime, err := companyvisibility.NewCompanyVisibilityRuntime(defaultVisibilityConfig())
	if err != nil {
		return nil, err
	}

	permissionRuntime, err := companypermission.NewCompanyPermissionEnforcementRuntime(defaultPermissionConfig())
	if err != nil {
		return nil, err
	}

	exportRuntime, err := exportruntime.NewExcelPDFTDHPExportRuntime(defaultExportConfig())
	if err != nil {
		return nil, err
	}

	return &AccountantPortalIntegrationSuite{
		config:              config,
		subscriptionRuntime: subscriptionRuntime,
		visibilityRuntime:   visibilityRuntime,
		permissionRuntime:   permissionRuntime,
		exportRuntime:       exportRuntime,
	}, nil
}

func (s *AccountantPortalIntegrationSuite) RunFullPortalFlow(req IntegrationSuiteRequest) (IntegrationSuiteResult, error) {
	if err := s.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	passCount := 0
	failCount := 0

	subscriptionDecision, err := s.runSubscriptionFlow(req)
	if err != nil || !subscriptionDecision.Allowed {
		failCount++
		return s.failed(req, subscriptionDecision, companyvisibility.CompanyVisibilityResult{}, companypermission.EnforcementDecision{}, exportruntime.ExportBundleResult{}, passCount, failCount, "SUBSCRIPTION_FLOW_FAILED", err), err
	}
	passCount++

	account := subscriptionDecision.Account
	account.AssignedFirmCount = 1

	visibilityResult, err := s.runVisibilityFlow(req, account)
	if err != nil || visibilityResult.Status != companyvisibility.VisibilityStatusReady || visibilityResult.VisibleCompanyCount == 0 {
		failCount++
		return s.failed(req, subscriptionDecision, visibilityResult, companypermission.EnforcementDecision{}, exportruntime.ExportBundleResult{}, passCount, failCount, "VISIBILITY_FLOW_FAILED", err), err
	}
	passCount++

	permissionDecision, err := s.runPermissionFlow(req)
	if err != nil || !permissionDecision.Allowed {
		failCount++
		return s.failed(req, subscriptionDecision, visibilityResult, permissionDecision, exportruntime.ExportBundleResult{}, passCount, failCount, "PERMISSION_FLOW_FAILED", err), err
	}
	passCount++

	exportBundle, err := s.runExportFlow(req)
	if err != nil || exportBundle.Status != exportruntime.ExportStatusReady {
		failCount++
		return s.failed(req, subscriptionDecision, visibilityResult, permissionDecision, exportBundle, passCount, failCount, "EXPORT_FLOW_FAILED", err), err
	}
	passCount++

	result := IntegrationSuiteResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		SuiteID:              req.SuiteID,
		Status:               IntegrationStatusPass,
		SubscriptionDecision: subscriptionDecision,
		VisibilityResult:     visibilityResult,
		PermissionDecision:   permissionDecision,
		ExportBundleResult:   exportBundle,
		PassCount:            passCount,
		FailCount:            failCount,
		IntegrationHash:      buildIntegrationHash(req, subscriptionDecision, visibilityResult, permissionDecision, exportBundle),
		AuditAction:          "ACCOUNTANT_PORTAL_INTEGRATION_TESTS_PASS",
		AuditDecisionReason:  "subscription, visibility, permission and export flows passed end-to-end",
		CreatedAt:            time.Now().UTC(),
	}

	if s.config.RequireAuditHash && strings.TrimSpace(result.IntegrationHash) == "" {
		err := errors.New("integration_hash is required")
		return rejected(req, "INTEGRATION_HASH_MISSING", err.Error()), err
	}

	return result, nil
}

func (s *AccountantPortalIntegrationSuite) runSubscriptionFlow(req IntegrationSuiteRequest) (subscriptionruntime.SubscriptionDecision, error) {
	return s.subscriptionRuntime.ActivateMonthly(subscriptionruntime.SubscriptionCommandRequest{
		TenantID:         req.TenantID,
		CorrelationID:    req.CorrelationID,
		RequestID:        req.RequestID,
		IdempotencyKey:   req.IdempotencyKey + ":subscription",
		CommandID:        req.SuiteID + ":activate-subscription",
		SubscriptionID:   req.SubscriptionID,
		AccountantFirmID: req.AccountantFirmID,
		BillingProfileID: req.BillingProfileID,
		Plan:             defaultPlan(),
		ActorID:          req.ActorID,
		Reason:           "accountant portal integration test activation",
		EffectiveAt:      req.RequestedAt,
	})
}

func (s *AccountantPortalIntegrationSuite) runVisibilityFlow(req IntegrationSuiteRequest, account subscriptionruntime.SubscriptionAccount) (companyvisibility.CompanyVisibilityResult, error) {
	return s.visibilityRuntime.BuildVisibility(companyvisibility.CompanyVisibilityRequest{
		TenantID:           req.TenantID,
		CorrelationID:      req.CorrelationID,
		RequestID:          req.RequestID,
		IdempotencyKey:     req.IdempotencyKey + ":visibility",
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		RequiredPermission: s.config.RequiredPermission,
		Subscription:       account,
		Assignments: []multifirmaccess.FirmAssignment{
			defaultAssignment(req),
		},
		Companies: []companyvisibility.CompanyProfile{
			defaultCompany(req),
		},
		RequestedAt: req.RequestedAt,
	})
}

func (s *AccountantPortalIntegrationSuite) runPermissionFlow(req IntegrationSuiteRequest) (companypermission.EnforcementDecision, error) {
	return s.permissionRuntime.Enforce(companypermission.EnforcementRequest{
		TenantID:           req.TenantID,
		CorrelationID:      req.CorrelationID,
		RequestID:          req.RequestID,
		IdempotencyKey:     req.IdempotencyKey + ":permission",
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		AssignmentID:       req.AssignmentID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		ResourceType:       companypermission.ResourceTypeExport,
		RequiredPermission: companypermission.PermissionExportTDHP,
		AuditSubject:       req.TargetCompanyID + ":tdhp-export:" + req.PeriodCode,
		Grant:              defaultPermissionGrant(req),
		RequestedAt:        req.RequestedAt,
	})
}

func (s *AccountantPortalIntegrationSuite) runExportFlow(req IntegrationSuiteRequest) (exportruntime.ExportBundleResult, error) {
	base := exportruntime.PortalExportRequest{
		TenantID:           req.TenantID,
		CorrelationID:      req.CorrelationID,
		RequestID:          req.RequestID,
		IdempotencyKey:     req.IdempotencyKey + ":export-base",
		ExportID:           req.SuiteID + ":export-base",
		Format:             exportruntime.ExportFormatExcel,
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		AssignmentID:       req.AssignmentID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		TargetCompanyName:  req.TargetCompanyName,
		PeriodCode:         req.PeriodCode,
		FiscalYear:         req.FiscalYear,
		PermissionGrant:    defaultPermissionGrant(req),
		LedgerRows:         defaultLedgerRows(req),
		RequestedBy:        req.ActorID,
		RequestedAt:        req.RequestedAt,
	}

	return s.exportRuntime.ExportBundle(exportruntime.ExportBundleRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":export-bundle",
		BundleID:       req.SuiteID + ":export-bundle",
		Formats:        append([]exportruntime.ExportFormat(nil), s.config.RequiredExportFormats...),
		BaseRequest:    base,
		RequestedAt:    req.RequestedAt,
	})
}

func (s *AccountantPortalIntegrationSuite) validateRequest(req IntegrationSuiteRequest) error {
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
	if strings.TrimSpace(req.SuiteID) == "" {
		return errors.New("suite_id is required")
	}
	if strings.TrimSpace(req.AccountantFirmID) == "" {
		return errors.New("accountant_firm_id is required")
	}
	if strings.TrimSpace(req.AccountantUserID) == "" {
		return errors.New("accountant_user_id is required")
	}
	if strings.TrimSpace(req.ActorID) == "" {
		return errors.New("actor_id is required")
	}
	if strings.TrimSpace(req.SubscriptionID) == "" {
		return errors.New("subscription_id is required")
	}
	if strings.TrimSpace(req.BillingProfileID) == "" {
		return errors.New("billing_profile_id is required")
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
	if strings.TrimSpace(req.TargetCompanyName) == "" {
		return errors.New("target_company_name is required")
	}
	if strings.TrimSpace(req.TargetCompanyTaxNo) == "" {
		return errors.New("target_company_tax_no is required")
	}
	if strings.TrimSpace(req.PeriodCode) == "" {
		return errors.New("period_code is required")
	}
	if req.FiscalYear <= 2000 {
		return errors.New("fiscal_year is invalid")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (s *AccountantPortalIntegrationSuite) failed(req IntegrationSuiteRequest, sub subscriptionruntime.SubscriptionDecision, visibility companyvisibility.CompanyVisibilityResult, permission companypermission.EnforcementDecision, export exportruntime.ExportBundleResult, passCount int, failCount int, code string, err error) IntegrationSuiteResult {
	message := "integration flow failed"
	if err != nil {
		message = err.Error()
	}

	return IntegrationSuiteResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		SuiteID:              req.SuiteID,
		Status:               IntegrationStatusFail,
		SubscriptionDecision: sub,
		VisibilityResult:     visibility,
		PermissionDecision:   permission,
		ExportBundleResult:   export,
		PassCount:            passCount,
		FailCount:            failCount,
		ErrorCode:            code,
		ErrorMessage:         message,
		AuditAction:          "ACCOUNTANT_PORTAL_INTEGRATION_TESTS_FAIL",
		AuditDecisionReason:  message,
		CreatedAt:            time.Now().UTC(),
	}
}

func rejected(req IntegrationSuiteRequest, code string, message string) IntegrationSuiteResult {
	return IntegrationSuiteResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		SuiteID:             req.SuiteID,
		Status:              IntegrationStatusFail,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "ACCOUNTANT_PORTAL_INTEGRATION_TESTS_REJECTED",
		AuditDecisionReason: "integration suite rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}

func defaultPlan() subscriptionruntime.SubscriptionPlan {
	return subscriptionruntime.SubscriptionPlan{
		PlanCode:           "ACCOUNTANT_PRO",
		PlanName:           "Muhasebeci Pro",
		BillingCycle:       subscriptionruntime.BillingCycleMonthly,
		CurrencyCode:       "TRY",
		MonthlyPriceKurus:  199000,
		IncludedFirmLimit:  25,
		IncludedUserLimit:  8,
		ExportQuotaMonthly: 1000,
		TrialDays:          14,
	}
}

func defaultAssignment(req IntegrationSuiteRequest) multifirmaccess.FirmAssignment {
	return multifirmaccess.FirmAssignment{
		AssignmentID:       req.AssignmentID,
		TenantID:           req.TenantID,
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		TargetCompanyName:  req.TargetCompanyName,
		Status:             multifirmaccess.AssignmentStatusActive,
		Role:               multifirmaccess.PortalRoleStaff,
		Permissions: []multifirmaccess.Permission{
			multifirmaccess.PermissionViewFirm,
			multifirmaccess.PermissionViewLedger,
			multifirmaccess.PermissionExportExcel,
			multifirmaccess.PermissionExportPDF,
			multifirmaccess.PermissionExportTDHP,
		},
		ValidFrom:  req.RequestedAt.Add(-24 * time.Hour),
		ValidUntil: req.RequestedAt.Add(30 * 24 * time.Hour),
		AssignedBy: req.ActorID,
		AssignedAt: req.RequestedAt.Add(-24 * time.Hour),
	}
}

func defaultCompany(req IntegrationSuiteRequest) companyvisibility.CompanyProfile {
	return companyvisibility.CompanyProfile{
		TenantID:           req.TenantID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		TargetCompanyName:  req.TargetCompanyName,
		TaxNo:              req.TargetCompanyTaxNo,
		City:               req.TargetCompanyCity,
		Status:             companyvisibility.CompanyStatusActive,
		VisibleInPortal:    true,
		AssignedAt:         req.RequestedAt.Add(-24 * time.Hour),
		LastActivityAt:     req.RequestedAt,
	}
}

func defaultPermissionGrant(req IntegrationSuiteRequest) companypermission.CompanyPermissionGrant {
	return companypermission.CompanyPermissionGrant{
		GrantID:            "grant:" + req.AssignmentID,
		TenantID:           req.TenantID,
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		AssignmentID:       req.AssignmentID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		Role:               companypermission.PortalRoleStaff,
		Permissions: []companypermission.Permission{
			companypermission.PermissionViewFirm,
			companypermission.PermissionViewLedger,
			companypermission.PermissionExportExcel,
			companypermission.PermissionExportPDF,
			companypermission.PermissionExportTDHP,
		},
		ResourceTypes: []companypermission.ResourceType{
			companypermission.ResourceTypeFirm,
			companypermission.ResourceTypeLedger,
			companypermission.ResourceTypeExport,
		},
		Active:     true,
		ValidFrom:  req.RequestedAt.Add(-24 * time.Hour),
		ValidUntil: req.RequestedAt.Add(30 * 24 * time.Hour),
		GrantedBy:  req.ActorID,
		GrantedAt:  req.RequestedAt.Add(-24 * time.Hour),
	}
}

func defaultLedgerRows(req IntegrationSuiteRequest) []exportruntime.LedgerExportRow {
	return []exportruntime.LedgerExportRow{
		{
			TenantID:           req.TenantID,
			TargetFirmTenantID: req.TargetFirmTenantID,
			TargetCompanyID:    req.TargetCompanyID,
			PeriodCode:         req.PeriodCode,
			DocumentNo:         "INV-INT-001",
			DocumentDate:       req.RequestedAt,
			AccountCode:        "120.01",
			AccountName:        "Alıcılar",
			DebitKurus:         1200000,
			CreditKurus:        0,
			CurrencyCode:       "TRY",
			Description:        "Muhasebeci portal entegrasyon alıcı kaydı",
			PostingHash:        "posting:int:001",
			AuditTraceID:       "audit:int:001",
		},
		{
			TenantID:           req.TenantID,
			TargetFirmTenantID: req.TargetFirmTenantID,
			TargetCompanyID:    req.TargetCompanyID,
			PeriodCode:         req.PeriodCode,
			DocumentNo:         "INV-INT-001",
			DocumentDate:       req.RequestedAt,
			AccountCode:        "600.01",
			AccountName:        "Yurt içi satışlar",
			DebitKurus:         0,
			CreditKurus:        1000000,
			CurrencyCode:       "TRY",
			Description:        "Muhasebeci portal entegrasyon satış geliri",
			PostingHash:        "posting:int:002",
			AuditTraceID:       "audit:int:002",
		},
		{
			TenantID:           req.TenantID,
			TargetFirmTenantID: req.TargetFirmTenantID,
			TargetCompanyID:    req.TargetCompanyID,
			PeriodCode:         req.PeriodCode,
			DocumentNo:         "INV-INT-001",
			DocumentDate:       req.RequestedAt,
			AccountCode:        "391.01.20",
			AccountName:        "Hesaplanan KDV",
			DebitKurus:         0,
			CreditKurus:        200000,
			CurrencyCode:       "TRY",
			Description:        "Muhasebeci portal entegrasyon KDV",
			PostingHash:        "posting:int:003",
			AuditTraceID:       "audit:int:003",
		},
	}
}

func buildIntegrationHash(req IntegrationSuiteRequest, sub subscriptionruntime.SubscriptionDecision, visibility companyvisibility.CompanyVisibilityResult, permission companypermission.EnforcementDecision, export exportruntime.ExportBundleResult) string {
	parts := []string{
		req.TenantID,
		req.SuiteID,
		sub.DecisionHash,
		visibility.VisibilityHash,
		permission.DecisionHash,
		export.BundleHash,
		fmt.Sprintf("exports:%d", export.PassCount),
	}
	return "accountant-portal-integration:" + strings.Join(parts, ":")
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

func defaultVisibilityConfig() companyvisibility.RuntimeConfig {
	return companyvisibility.RuntimeConfig{
		RuntimeEnabled:             true,
		RequireTenantScope:         true,
		RequireCompanyScope:        true,
		RequireActiveSubscription:  true,
		RequireActiveAssignment:    true,
		RequireVisibleCompanyFlag:  true,
		RequireActiveCompanyStatus: true,
		RequireCompanyProfile:      true,
		RequirePermissionMatch:     true,
		RequireAuditHash:           true,
		MaxVisibleFirmCount:        100,
		AllowedCompanyStatuses:     []companyvisibility.CompanyStatus{companyvisibility.CompanyStatusActive},
		RequiredPortalPermissions: []multifirmaccess.Permission{
			multifirmaccess.PermissionViewFirm,
			multifirmaccess.PermissionViewLedger,
			multifirmaccess.PermissionExportExcel,
			multifirmaccess.PermissionExportPDF,
			multifirmaccess.PermissionExportTDHP,
		},
	}
}

func defaultPermissionConfig() companypermission.RuntimeConfig {
	return companypermission.RuntimeConfig{
		RuntimeEnabled:            true,
		RequireTenantScope:        true,
		RequireCompanyScope:       true,
		RequireAssignmentScope:    true,
		RequireResourcePermission: true,
		RequireRolePermissionMap:  true,
		RequireExplicitGrant:      true,
		RequireAuditSubject:       true,
		AllowSuperAdminOverride:   false,
		RequiredPermissions: []companypermission.Permission{
			companypermission.PermissionViewFirm,
			companypermission.PermissionViewLedger,
			companypermission.PermissionExportExcel,
			companypermission.PermissionExportPDF,
			companypermission.PermissionExportTDHP,
			companypermission.PermissionManageAssignment,
			companypermission.PermissionViewSubscription,
		},
		AllowedRoles: []companypermission.PortalRole{
			companypermission.PortalRoleOwner,
			companypermission.PortalRoleStaff,
			companypermission.PortalRoleReadOnly,
			companypermission.PortalRoleSuperAdmin,
		},
		AllowedResourceTypes: []companypermission.ResourceType{
			companypermission.ResourceTypeFirm,
			companypermission.ResourceTypeLedger,
			companypermission.ResourceTypeExport,
			companypermission.ResourceTypeAssignment,
			companypermission.ResourceTypeSubscription,
		},
	}
}

func defaultExportConfig() exportruntime.RuntimeConfig {
	return exportruntime.RuntimeConfig{
		RuntimeEnabled:            true,
		DefaultCurrencyCode:       "TRY",
		RequirePermissionDecision: true,
		RequireTenantScope:        true,
		RequireCompanyScope:       true,
		RequireLedgerRows:         true,
		RequireBalancedExport:     true,
		RequireExportHash:         true,
		RequireAuditSubject:       true,
		MaxRows:                   10000,
		AllowedFormats:            []exportruntime.ExportFormat{exportruntime.ExportFormatExcel, exportruntime.ExportFormatPDF, exportruntime.ExportFormatTDHP},
	}
}
