package companyvisibility

import (
	"testing"
	"time"

	multifirmaccess "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/multifirmaccess"
	subscriptionruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/subscriptionruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
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
		AllowedCompanyStatuses:     []CompanyStatus{CompanyStatusActive},
		RequiredPortalPermissions: []multifirmaccess.Permission{
			multifirmaccess.PermissionViewFirm,
			multifirmaccess.PermissionViewLedger,
			multifirmaccess.PermissionExportExcel,
			multifirmaccess.PermissionExportPDF,
			multifirmaccess.PermissionExportTDHP,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validSubscription() subscriptionruntime.SubscriptionAccount {
	now := validNow()
	return subscriptionruntime.SubscriptionAccount{
		TenantID:           "tenant-accountant-001",
		SubscriptionID:     "sub-001",
		AccountantFirmID:   "acc-firm-001",
		BillingProfileID:   "billing-profile-001",
		PlanCode:           "ACCOUNTANT_PRO",
		PlanName:           "Muhasebeci Pro",
		Status:             subscriptionruntime.SubscriptionStatusActive,
		BillingCycle:       subscriptionruntime.BillingCycleMonthly,
		CurrencyCode:       "TRY",
		MonthlyPriceKurus:  199000,
		AssignedFirmLimit:  25,
		AssignedFirmCount:  2,
		IncludedUserLimit:  8,
		ExportQuotaMonthly: 1000,
		PeriodStart:        time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC),
		PeriodEnd:          time.Date(2026, 5, 31, 23, 59, 59, 0, time.UTC),
		LastRenewedAt:      now,
		AuditActorID:       "acc-owner-001",
		UpdatedAt:          now,
	}
}

func validAssignment(id string, targetTenant string, companyID string, name string) multifirmaccess.FirmAssignment {
	now := validNow()
	return multifirmaccess.FirmAssignment{
		AssignmentID:       id,
		TenantID:           "tenant-accountant-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		TargetFirmTenantID: targetTenant,
		TargetCompanyID:    companyID,
		TargetCompanyName:  name,
		Status:             multifirmaccess.AssignmentStatusActive,
		Role:               multifirmaccess.PortalRoleStaff,
		Permissions: []multifirmaccess.Permission{
			multifirmaccess.PermissionViewFirm,
			multifirmaccess.PermissionViewLedger,
			multifirmaccess.PermissionExportExcel,
			multifirmaccess.PermissionExportPDF,
			multifirmaccess.PermissionExportTDHP,
		},
		ValidFrom:  now.Add(-24 * time.Hour),
		ValidUntil: now.Add(30 * 24 * time.Hour),
		AssignedBy: "acc-owner-001",
		AssignedAt: now.Add(-24 * time.Hour),
	}
}

func validCompany(targetTenant string, companyID string, name string) CompanyProfile {
	now := validNow()
	return CompanyProfile{
		TenantID:           "tenant-accountant-001",
		TargetFirmTenantID: targetTenant,
		TargetCompanyID:    companyID,
		TargetCompanyName:  name,
		TaxNo:              "1234567890",
		City:               "İstanbul",
		Status:             CompanyStatusActive,
		VisibleInPortal:    true,
		AssignedAt:         now.Add(-24 * time.Hour),
		LastActivityAt:     now,
	}
}

func validRequest() CompanyVisibilityRequest {
	return CompanyVisibilityRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-company-visibility-001",
		RequestID:          "req-company-visibility-001",
		IdempotencyKey:     "idem-company-visibility-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		RequiredPermission: multifirmaccess.PermissionExportTDHP,
		Subscription:       validSubscription(),
		Assignments: []multifirmaccess.FirmAssignment{
			validAssignment("assign-001", "tenant-firm-001", "company-001", "Pilot Market A.Ş."),
			validAssignment("assign-002", "tenant-firm-002", "company-002", "Pilot Market B.Ş."),
		},
		Companies: []CompanyProfile{
			validCompany("tenant-firm-001", "company-001", "Pilot Market A.Ş."),
			validCompany("tenant-firm-002", "company-002", "Pilot Market B.Ş."),
		},
		RequestedAt: validNow(),
	}
}

func newRuntime(t *testing.T) *CompanyVisibilityRuntime {
	t.Helper()

	runtime, err := NewCompanyVisibilityRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestBuildVisibilityShowsAssignedCompanies(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.BuildVisibility(validRequest())
	if err != nil {
		t.Fatalf("expected visibility ready, got error: %v", err)
	}
	if result.Status != VisibilityStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.VisibleCompanyCount != 2 {
		t.Fatalf("expected 2 visible companies, got %d", result.VisibleCompanyCount)
	}
	if result.HiddenCompanyCount != 0 {
		t.Fatalf("expected 0 hidden companies, got %d", result.HiddenCompanyCount)
	}
	if result.DeniedCompanyCount != 0 {
		t.Fatalf("expected 0 denied companies, got %d", result.DeniedCompanyCount)
	}
	if result.VisibilityHash == "" {
		t.Fatal("expected visibility hash")
	}
}

func TestBuildVisibilityHidesCompanyWhenVisibilityFlagOff(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Companies[1].VisibleInPortal = false

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.VisibleCompanyCount != 1 {
		t.Fatalf("expected 1 visible company, got %d", result.VisibleCompanyCount)
	}
	if result.HiddenCompanyCount != 1 {
		t.Fatalf("expected 1 hidden company, got %d", result.HiddenCompanyCount)
	}
	if result.HiddenCompanies[0].ReasonCode != "COMPANY_VISIBILITY_FLAG_OFF" {
		t.Fatalf("expected COMPANY_VISIBILITY_FLAG_OFF, got %s", result.HiddenCompanies[0].ReasonCode)
	}
}

func TestBuildVisibilityHidesSuspendedCompany(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Companies[1].Status = CompanyStatusSuspended

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.HiddenCompanyCount != 1 {
		t.Fatalf("expected 1 hidden company, got %d", result.HiddenCompanyCount)
	}
	if result.HiddenCompanies[0].ReasonCode != "COMPANY_STATUS_NOT_VISIBLE" {
		t.Fatalf("expected COMPANY_STATUS_NOT_VISIBLE, got %s", result.HiddenCompanies[0].ReasonCode)
	}
}

func TestBuildVisibilityRejectsSuspendedSubscription(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Subscription.Status = subscriptionruntime.SubscriptionStatusSuspended

	result, err := runtime.BuildVisibility(req)
	if err == nil {
		t.Fatal("expected subscription denied")
	}
	if result.Status != VisibilityStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.ErrorCode != "SUBSCRIPTION_DENIED" {
		t.Fatalf("expected SUBSCRIPTION_DENIED, got %s", result.ErrorCode)
	}
}

func TestBuildVisibilityDeniesMissingCompanyProfile(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Companies = req.Companies[:1]

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.DeniedCompanyCount != 1 {
		t.Fatalf("expected 1 denied company, got %d", result.DeniedCompanyCount)
	}
	if result.DeniedCompanies[0].ReasonCode != "COMPANY_PROFILE_MISSING" {
		t.Fatalf("expected COMPANY_PROFILE_MISSING, got %s", result.DeniedCompanies[0].ReasonCode)
	}
}

func TestBuildVisibilityDeniesCompanyTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Companies[0].TenantID = "tenant-other"

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.DeniedCompanyCount != 1 {
		t.Fatalf("expected 1 denied company, got %d", result.DeniedCompanyCount)
	}
	if result.DeniedCompanies[0].ReasonCode != "COMPANY_TENANT_MISMATCH" {
		t.Fatalf("expected COMPANY_TENANT_MISMATCH, got %s", result.DeniedCompanies[0].ReasonCode)
	}
}

func TestBuildVisibilityFiltersInactiveAssignment(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Assignments[1].Status = multifirmaccess.AssignmentStatusRevoked

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.VisibleCompanyCount != 1 {
		t.Fatalf("expected 1 visible company, got %d", result.VisibleCompanyCount)
	}
	if result.TotalAssignmentCount != 2 {
		t.Fatalf("expected total assignments 2, got %d", result.TotalAssignmentCount)
	}
}

func TestBuildVisibilityRejectsAssignmentLimit(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Subscription.AssignedFirmLimit = 1

	result, err := runtime.BuildVisibility(req)
	if err == nil {
		t.Fatal("expected subscription firm limit denial")
	}
	if result.ErrorCode != "SUBSCRIPTION_DENIED" {
		t.Fatalf("expected SUBSCRIPTION_DENIED, got %s", result.ErrorCode)
	}
}

func TestBuildVisibilityRejectsMissingPermissionFromAssignment(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Assignments[0].Permissions = []multifirmaccess.Permission{multifirmaccess.PermissionViewFirm}

	result, err := runtime.BuildVisibility(req)
	if err != nil {
		t.Fatalf("expected visibility result, got error: %v", err)
	}
	if result.VisibleCompanyCount != 1 {
		t.Fatalf("expected 1 visible company, got %d", result.VisibleCompanyCount)
	}
}

func TestBuildVisibilityRejectsTooManyAssignments(t *testing.T) {
	cfg := validConfig()
	cfg.MaxVisibleFirmCount = 1

	runtime, err := NewCompanyVisibilityRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.BuildVisibility(validRequest())
	if err == nil {
		t.Fatal("expected max visible firm count error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewCompanyVisibilityRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingStatusesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AllowedCompanyStatuses = nil

	_, err := NewCompanyVisibilityRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing company statuses error")
	}
}
