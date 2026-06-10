package accountantportal

import (
	"errors"
	"testing"
	"time"
)

func fixedRuntime() *AccountantPortalRuntime {
	r := NewDefaultRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 9, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenNineCommercialSurfaceKeepsLiveOperationsClosed(t *testing.T) {
	r := fixedRuntime()
	surface, err := r.BuildCommercialSurface("accountant_tenant_1", "2026-05")
	if err != nil {
		t.Fatalf("BuildCommercialSurface returned error: %v", err)
	}
	if surface.ModuleCode != ModuleCode {
		t.Fatalf("unexpected module code: %s", surface.ModuleCode)
	}
	if surface.Mode != ModeCommercialSurfaceDryRunOnly {
		t.Fatalf("surface mode must be dry-run only, got %s", surface.Mode)
	}
	if err := surface.Gate.AssertLiveOperationsClosed(); err != nil {
		t.Fatalf("live gate must remain closed: %v", err)
	}
	if err := r.RequestLiveCommercialOperation("capture_real_accountant_payment"); !errors.Is(err, ErrLiveOperationClosed) {
		t.Fatalf("live commercial operation must be blocked, got %v", err)
	}
}

func TestSevenNineFirmSlotAssignmentTenantSafe(t *testing.T) {
	r := fixedRuntime()
	assignment, err := r.AssignFirm(AssignFirmRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		PlanCode:           "ACCOUNTANT_STARTER",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read", "export.preview", "export.preview"},
	})
	if err != nil {
		t.Fatalf("AssignFirm returned error: %v", err)
	}
	if assignment.AccountantTenantID != "accountant_tenant_1" || assignment.FirmTenantID != "firm_tenant_7" {
		t.Fatalf("assignment tenant boundary mismatch: %#v", assignment)
	}
	if len(assignment.Permissions) != 2 {
		t.Fatalf("permissions should be normalized and deduped, got %#v", assignment.Permissions)
	}
	if got := r.ListAssignments("other_accountant", "2026-05"); len(got) != 0 {
		t.Fatalf("cross-accountant list must not expose assignments, got %#v", got)
	}
	if _, err := r.AssignFirm(AssignFirmRequest{AccountantTenantID: "same", FirmTenantID: "same", PlanCode: "ACCOUNTANT_STARTER", PeriodYYYYMM: "2026-05"}); err == nil {
		t.Fatal("same accountant and firm tenant must be rejected")
	}
}

func TestSevenNineBillingDraftIsDraftOnly(t *testing.T) {
	r := fixedRuntime()
	draft, err := r.CreateBillingDraft(BillingDraftRequest{
		AccountantTenantID: "accountant_tenant_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		FirmSlotCount:      10,
	})
	if err != nil {
		t.Fatalf("CreateBillingDraft returned error: %v", err)
	}
	if draft.Status != StatusDraftOnlyNoRealInvoice {
		t.Fatalf("billing draft must remain draft-only, got %s", draft.Status)
	}
	if draft.RealInvoiceCreated || draft.RealPaymentCaptureEnabled || draft.ProviderTransactionID != "" {
		t.Fatalf("real billing/payment must not be created: %#v", draft)
	}
}

func TestSevenNineExportPreviewNoRealDataProviderAPIsClosed(t *testing.T) {
	r := fixedRuntime()
	_, err := r.AssignFirm(AssignFirmRequest{AccountantTenantID: "accountant_tenant_1", FirmTenantID: "firm_tenant_7", PlanCode: "ACCOUNTANT_PRO", PeriodYYYYMM: "2026-05"})
	if err != nil {
		t.Fatalf("AssignFirm returned error: %v", err)
	}
	for _, provider := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		preview, err := r.BuildExportPreview(ExportPreviewRequest{
			AccountantTenantID: "accountant_tenant_1",
			FirmTenantID:       "firm_tenant_7",
			ProviderCode:       provider,
			PeriodYYYYMM:       "2026-05",
			Format:             provider + "_DRY_RUN",
		})
		if err != nil {
			t.Fatalf("BuildExportPreview(%s) returned error: %v", provider, err)
		}
		if preview.Status != StatusPreviewOnlyNoRealCustomerData {
			t.Fatalf("preview must be no-real-data only, got %#v", preview)
		}
		if preview.ContainsRealCustomerData || preview.LiveDeliveryRequested || preview.RealProviderAPIRequested || preview.RealERPWriteRequested {
			t.Fatalf("live export/provider/erp operation must be disabled: %#v", preview)
		}
	}
}

func TestSevenNineAuditTrailCreatedForCommercialActions(t *testing.T) {
	r := fixedRuntime()
	_, _ = r.AssignFirm(AssignFirmRequest{AccountantTenantID: "accountant_tenant_1", FirmTenantID: "firm_tenant_7", PlanCode: "ACCOUNTANT_PRO", PeriodYYYYMM: "2026-05"})
	_, _ = r.CreateBillingDraft(BillingDraftRequest{AccountantTenantID: "accountant_tenant_1", PlanCode: "ACCOUNTANT_PRO", PeriodYYYYMM: "2026-05", FirmSlotCount: 1})
	_, _ = r.BuildExportPreview(ExportPreviewRequest{AccountantTenantID: "accountant_tenant_1", FirmTenantID: "firm_tenant_7", ProviderCode: "LOGO", PeriodYYYYMM: "2026-05"})
	if len(r.AuditEvents()) != 3 {
		t.Fatalf("expected three audit events, got %#v", r.AuditEvents())
	}
	for _, event := range r.AuditEvents() {
		if event.AccountantTenantID != "accountant_tenant_1" {
			t.Fatalf("audit event must carry accountant tenant id: %#v", event)
		}
		if event.Status == "" {
			t.Fatalf("audit event must carry status: %#v", event)
		}
	}
}
