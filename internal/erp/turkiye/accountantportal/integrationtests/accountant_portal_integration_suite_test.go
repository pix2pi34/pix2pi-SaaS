package integrationtests

import (
	"testing"
	"time"

	exportruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/exportruntime"
	multifirmaccess "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/multifirmaccess"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:          true,
		DefaultCurrencyCode:     "TRY",
		RequireSubscriptionFlow: true,
		RequireVisibilityFlow:   true,
		RequirePermissionFlow:   true,
		RequireExportFlow:       true,
		RequireAllFormats:       true,
		RequireAuditHash:        true,
		RequiredPermission:      multifirmaccess.PermissionExportTDHP,
		RequiredExportFormats: []exportruntime.ExportFormat{
			exportruntime.ExportFormatExcel,
			exportruntime.ExportFormatPDF,
			exportruntime.ExportFormatTDHP,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() IntegrationSuiteRequest {
	return IntegrationSuiteRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-accountant-integration-001",
		RequestID:          "req-accountant-integration-001",
		IdempotencyKey:     "idem-accountant-integration-001",
		SuiteID:            "suite-accountant-portal-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		ActorID:            "acc-owner-001",
		SubscriptionID:     "sub-001",
		BillingProfileID:   "billing-profile-001",
		AssignmentID:       "assign-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		TargetCompanyName:  "Pilot Market A.Ş.",
		TargetCompanyTaxNo: "1234567890",
		TargetCompanyCity:  "İstanbul",
		PeriodCode:         "2026-05",
		FiscalYear:         2026,
		RequestedAt:        validNow(),
	}
}

func newSuite(t *testing.T) *AccountantPortalIntegrationSuite {
	t.Helper()

	suite, err := NewAccountantPortalIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}
	return suite
}

func TestFullAccountantPortalIntegrationFlowPasses(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunFullPortalFlow(validRequest())
	if err != nil {
		t.Fatalf("expected integration flow pass, got error: %v", err)
	}

	if result.Status != IntegrationStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if result.PassCount != 4 {
		t.Fatalf("expected pass count 4, got %d", result.PassCount)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.IntegrationHash == "" {
		t.Fatal("expected integration hash")
	}
}

func TestIntegrationFlowActivatesSubscription(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunFullPortalFlow(validRequest())
	if err != nil {
		t.Fatalf("expected integration flow pass, got error: %v", err)
	}

	if !result.SubscriptionDecision.Allowed {
		t.Fatal("expected subscription decision allowed")
	}
	if result.SubscriptionDecision.Account.PlanCode != "ACCOUNTANT_PRO" {
		t.Fatalf("expected ACCOUNTANT_PRO, got %s", result.SubscriptionDecision.Account.PlanCode)
	}
}

func TestIntegrationFlowBuildsVisibleCompanyList(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunFullPortalFlow(validRequest())
	if err != nil {
		t.Fatalf("expected integration flow pass, got error: %v", err)
	}

	if result.VisibilityResult.VisibleCompanyCount != 1 {
		t.Fatalf("expected 1 visible company, got %d", result.VisibilityResult.VisibleCompanyCount)
	}
	if result.VisibilityResult.VisibleCompanies[0].TargetCompanyID != "company-001" {
		t.Fatalf("expected company-001, got %s", result.VisibilityResult.VisibleCompanies[0].TargetCompanyID)
	}
}

func TestIntegrationFlowAllowsTDHPPermission(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunFullPortalFlow(validRequest())
	if err != nil {
		t.Fatalf("expected integration flow pass, got error: %v", err)
	}

	if !result.PermissionDecision.Allowed {
		t.Fatal("expected TDHP permission allowed")
	}
	if result.PermissionDecision.ReasonCode != "PERMISSION_ALLOWED" {
		t.Fatalf("expected PERMISSION_ALLOWED, got %s", result.PermissionDecision.ReasonCode)
	}
}

func TestIntegrationFlowBuildsExcelPDFTDHPExports(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunFullPortalFlow(validRequest())
	if err != nil {
		t.Fatalf("expected integration flow pass, got error: %v", err)
	}

	if result.ExportBundleResult.PassCount != 3 {
		t.Fatalf("expected export pass count 3, got %d", result.ExportBundleResult.PassCount)
	}
	if len(result.ExportBundleResult.Exports) != 3 {
		t.Fatalf("expected 3 export files, got %d", len(result.ExportBundleResult.Exports))
	}
	if result.ExportBundleResult.Exports[0].Format != exportruntime.ExportFormatExcel {
		t.Fatalf("expected Excel first, got %s", result.ExportBundleResult.Exports[0].Format)
	}
	if result.ExportBundleResult.Exports[1].Format != exportruntime.ExportFormatPDF {
		t.Fatalf("expected PDF second, got %s", result.ExportBundleResult.Exports[1].Format)
	}
	if result.ExportBundleResult.Exports[2].Format != exportruntime.ExportFormatTDHP {
		t.Fatalf("expected TDHP third, got %s", result.ExportBundleResult.Exports[2].Format)
	}
}

func TestIntegrationFlowRejectsMissingTenant(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.TenantID = ""

	result, err := suite.RunFullPortalFlow(req)
	if err == nil {
		t.Fatal("expected validation failure")
	}
	if result.Status != IntegrationStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestIntegrationFlowRejectsMissingCompanyTaxNo(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.TargetCompanyTaxNo = ""

	result, err := suite.RunFullPortalFlow(req)
	if err == nil {
		t.Fatal("expected tax no validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestIntegrationFlowRejectsMissingBillingProfile(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.BillingProfileID = ""

	result, err := suite.RunFullPortalFlow(req)
	if err == nil {
		t.Fatal("expected billing profile validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewAccountantPortalIntegrationSuite(cfg)
	if err == nil {
		t.Fatal("expected disabled suite error")
	}
}

func TestRuntimeRejectsMissingExportFormatsConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredExportFormats = nil

	_, err := NewAccountantPortalIntegrationSuite(cfg)
	if err == nil {
		t.Fatal("expected missing export formats config error")
	}
}
