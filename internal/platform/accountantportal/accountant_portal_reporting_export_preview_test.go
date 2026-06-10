package accountantportal

import (
	"errors"
	"testing"
	"time"
)

func fixedReportingRuntimeWithAccess(t *testing.T) (*AccountantPortalReportingRuntime, *AccountantPortalAccessRuntime) {
	t.Helper()
	access := NewDefaultAccountantPortalAccessRuntime()
	access.now = func() time.Time { return time.Date(2026, 5, 3, 11, 0, 0, 0, time.UTC) }
	_, err := access.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Role:               AccountantAccessDefaultRoleOperator,
		Permissions:        []string{"firm.read", "report.view", "export.preview"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	reporting := NewDefaultAccountantPortalReportingRuntime(access)
	reporting.now = func() time.Time { return time.Date(2026, 5, 3, 11, 5, 0, 0, time.UTC) }
	return reporting, access
}

func TestSevenElevenBuildReportPreviewRequiresAccess(t *testing.T) {
	reporting, _ := fixedReportingRuntimeWithAccess(t)
	preview, err := reporting.BuildReportPreview(AccountantReportPreviewRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		ReportType:         AccountantReportingReportTypeFirmSummary,
	})
	if err != nil {
		t.Fatalf("BuildReportPreview returned error: %v", err)
	}
	if preview.ModuleCode != AccountantReportingModuleCode {
		t.Fatalf("unexpected module code: %s", preview.ModuleCode)
	}
	if preview.Mode != AccountantReportingModePreviewDryRunOnly {
		t.Fatalf("preview must be dry-run only, got %s", preview.Mode)
	}
	if preview.ContainsRealCustomerData || preview.RealCustomerDataExportAllowed || preview.RealProviderAPIAllowed || preview.RealERPWriteAllowed || preview.RealFileDeliveryAllowed {
		t.Fatalf("report preview must not allow live data/export/provider/erp/delivery: %#v", preview)
	}
	if len(preview.Rows) == 0 {
		t.Fatal("report preview must include synthetic rows")
	}
	for _, row := range preview.Rows {
		if row.ContainsRealData {
			t.Fatalf("preview row must not contain real data: %#v", row)
		}
	}
}

func TestSevenElevenReportPreviewDeniedWithoutAccess(t *testing.T) {
	access := NewDefaultAccountantPortalAccessRuntime()
	reporting := NewDefaultAccountantPortalReportingRuntime(access)
	_, err := reporting.BuildReportPreview(AccountantReportPreviewRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_404",
		UserID:             "user_404",
		PeriodYYYYMM:       "2026-05",
		ReportType:         AccountantReportingReportTypeTaxSummary,
	})
	if err == nil {
		t.Fatal("report preview must be denied without active firm access")
	}
	if len(reporting.AuditEvents()) == 0 {
		t.Fatal("denied report preview must create audit event")
	}
}

func TestSevenElevenExportPackagePreviewForSealedDryRunProviders(t *testing.T) {
	reporting, _ := fixedReportingRuntimeWithAccess(t)
	for _, provider := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		preview, err := reporting.BuildExportPackagePreview(AccountantExportPackagePreviewRequest{
			AccountantTenantID: "accountant_tenant_1",
			FirmTenantID:       "firm_tenant_7",
			UserID:             "user_1",
			PeriodYYYYMM:       "2026-05",
			ProviderCode:       provider,
			Format:             provider + "_DRY_RUN_PREVIEW",
		})
		if err != nil {
			t.Fatalf("BuildExportPackagePreview(%s) returned error: %v", provider, err)
		}
		if preview.ProviderCode != provider {
			t.Fatalf("unexpected provider code: %#v", preview)
		}
		if preview.ContainsRealCustomerData || preview.LiveDeliveryRequested || preview.RealProviderAPIRequested || preview.RealERPWriteRequested || preview.RealFileDeliveryAllowed {
			t.Fatalf("export package preview must not allow live operation: %#v", preview)
		}
		if len(preview.Manifest) == 0 {
			t.Fatalf("export package preview must include synthetic manifest: %#v", preview)
		}
		for _, item := range preview.Manifest {
			if item.ContainsRealData || !item.SyntheticPreview {
				t.Fatalf("manifest item must be synthetic and no-real-data: %#v", item)
			}
		}
	}
}

func TestSevenElevenExportPreviewRequiresExportPermission(t *testing.T) {
	access := NewDefaultAccountantPortalAccessRuntime()
	_, err := access.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_8",
		UserID:             "user_2",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read", "report.view"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	reporting := NewDefaultAccountantPortalReportingRuntime(access)
	_, err = reporting.BuildExportPackagePreview(AccountantExportPackagePreviewRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_8",
		UserID:             "user_2",
		PeriodYYYYMM:       "2026-05",
		ProviderCode:       "LOGO",
		Format:             "LOGO_DRY_RUN_PREVIEW",
	})
	if err == nil {
		t.Fatal("export package preview must require export.preview permission")
	}
}

func TestSevenElevenLiveOperationsRemainClosed(t *testing.T) {
	reporting, _ := fixedReportingRuntimeWithAccess(t)
	if err := reporting.Gate().AssertLiveOperationsClosed(); err != nil {
		t.Fatalf("gate must keep live operations closed: %v", err)
	}
	if err := reporting.RequestLiveCustomerDataExport("accountant_tenant_1", "firm_tenant_7", "user_1", "2026-05"); !errors.Is(err, ErrAccountantReportingLiveOperationClosed) {
		t.Fatalf("live customer data export must be blocked, got %v", err)
	}
	if err := reporting.RequestRealProviderExport("accountant_tenant_1", "firm_tenant_7", "user_1", "LOGO"); !errors.Is(err, ErrAccountantReportingLiveOperationClosed) {
		t.Fatalf("real provider export must be blocked, got %v", err)
	}
	if err := reporting.RequestRealFileDelivery("accountant_tenant_1", "firm_tenant_7", "user_1", "2026-05"); !errors.Is(err, ErrAccountantReportingLiveOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := reporting.RequestRealERPWrite("accountant_tenant_1", "firm_tenant_7", "user_1", "2026-05"); !errors.Is(err, ErrAccountantReportingLiveOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
}

func TestSevenElevenReportingAuditTrail(t *testing.T) {
	reporting, _ := fixedReportingRuntimeWithAccess(t)
	_, _ = reporting.BuildReportPreview(AccountantReportPreviewRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		ReportType:         AccountantReportingReportTypeIntegrationStatus,
	})
	_, _ = reporting.BuildExportPackagePreview(AccountantExportPackagePreviewRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		ProviderCode:       "MIKRO",
	})
	events := reporting.AuditEvents()
	if len(events) != 2 {
		t.Fatalf("expected two reporting audit events, got %#v", events)
	}
	for _, event := range events {
		if event.AccountantTenantID == "" || event.FirmTenantID == "" || event.UserID == "" || event.Status == "" {
			t.Fatalf("audit event must carry tenant/firm/user/status: %#v", event)
		}
	}
}
