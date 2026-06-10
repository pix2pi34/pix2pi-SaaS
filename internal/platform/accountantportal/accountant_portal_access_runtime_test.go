package accountantportal

import (
	"errors"
	"testing"
	"time"
)

func fixedAccessRuntime() *AccountantPortalAccessRuntime {
	r := NewDefaultAccountantPortalAccessRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 10, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenTenGrantAndSelectFirmContext(t *testing.T) {
	r := fixedAccessRuntime()
	grant, err := r.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Role:               AccountantAccessDefaultRoleOperator,
		Permissions:        []string{"firm.read", "report.view", "export.preview", "export.preview"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	if grant.Status != AccountantAccessStatusActiveDryRunOnly {
		t.Fatalf("grant must be active dry-run only, got %s", grant.Status)
	}
	if len(grant.Permissions) != 3 {
		t.Fatalf("permissions must be normalized and deduped, got %#v", grant.Permissions)
	}
	decision := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permission:         "firm.read",
	})
	if !decision.Allowed {
		t.Fatalf("firm context should be allowed, got decision %#v", decision)
	}
	if decision.SelectedFirmContext.ContainsRealCustomerData {
		t.Fatalf("selected firm context must not contain real customer data: %#v", decision.SelectedFirmContext)
	}
	if decision.SelectedFirmContext.RealProviderAPIAllowed || decision.SelectedFirmContext.RealERPWriteAllowed {
		t.Fatalf("selected firm context must not allow provider API or ERP write: %#v", decision.SelectedFirmContext)
	}
}

func TestSevenTenPermissionEnforcement(t *testing.T) {
	r := fixedAccessRuntime()
	_, err := r.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_8",
		UserID:             "user_2",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	allowed := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_8",
		UserID:             "user_2",
		PeriodYYYYMM:       "2026-05",
		Permission:         "firm.read",
	})
	if !allowed.Allowed {
		t.Fatalf("firm.read should be allowed: %#v", allowed)
	}
	denied := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_8",
		UserID:             "user_2",
		PeriodYYYYMM:       "2026-05",
		Permission:         "export.preview",
	})
	if denied.Allowed {
		t.Fatalf("export.preview must be denied without permission: %#v", denied)
	}
	if denied.DenyReason == "" {
		t.Fatalf("denied decision must include reason: %#v", denied)
	}
}

func TestSevenTenCrossTenantIsolation(t *testing.T) {
	r := fixedAccessRuntime()
	_, err := r.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	if got := r.ListVisibleFirms("accountant_tenant_2", "user_1", "2026-05"); len(got) != 0 {
		t.Fatalf("cross-accountant tenant list must be empty, got %#v", got)
	}
	if got := r.ListVisibleFirms("accountant_tenant_1", "other_user", "2026-05"); len(got) != 0 {
		t.Fatalf("cross-user list must be empty, got %#v", got)
	}
	decision := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_2",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permission:         "firm.read",
	})
	if decision.Allowed {
		t.Fatalf("cross-tenant firm context must be denied: %#v", decision)
	}
}

func TestSevenTenPeriodIsolationAndRevoke(t *testing.T) {
	r := fixedAccessRuntime()
	_, err := r.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_9",
		UserID:             "user_3",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read"},
	})
	if err != nil {
		t.Fatalf("GrantFirmAccess returned error: %v", err)
	}
	periodDenied := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_9",
		UserID:             "user_3",
		PeriodYYYYMM:       "2026-06",
		Permission:         "firm.read",
	})
	if periodDenied.Allowed {
		t.Fatalf("different period must be denied: %#v", periodDenied)
	}
	revoked, err := r.RevokeFirmAccess(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_9",
		UserID:             "user_3",
		PeriodYYYYMM:       "2026-05",
	})
	if err != nil {
		t.Fatalf("RevokeFirmAccess returned error: %v", err)
	}
	if revoked.Status != AccountantAccessStatusRevokedDryRunOnly {
		t.Fatalf("grant must be revoked, got %#v", revoked)
	}
	afterRevoke := r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_9",
		UserID:             "user_3",
		PeriodYYYYMM:       "2026-05",
		Permission:         "firm.read",
	})
	if afterRevoke.Allowed {
		t.Fatalf("revoked access must be denied: %#v", afterRevoke)
	}
}

func TestSevenTenLiveOperationsRemainClosed(t *testing.T) {
	r := fixedAccessRuntime()
	if err := r.Gate().AssertLiveOperationsClosed(); err != nil {
		t.Fatalf("gate must keep live operations closed: %v", err)
	}
	if err := r.RequestLiveCustomerDataExport("accountant_tenant_1", "firm_tenant_7", "user_1", "2026-05"); !errors.Is(err, ErrAccountantAccessLiveOperationClosed) {
		t.Fatalf("live customer data export must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderOperation("accountant_tenant_1", "firm_tenant_7", "user_1", "LOGO"); !errors.Is(err, ErrAccountantAccessLiveOperationClosed) {
		t.Fatalf("real provider operation must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite("accountant_tenant_1", "firm_tenant_7", "user_1", "2026-05"); !errors.Is(err, ErrAccountantAccessLiveOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
}

func TestSevenTenAuditTrailForAccessDecisions(t *testing.T) {
	r := fixedAccessRuntime()
	_, _ = r.GrantFirmAccess(FirmAccessRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permissions:        []string{"firm.read"},
	})
	_ = r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permission:         "firm.read",
	})
	_ = r.SelectFirmContext(FirmContextRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		UserID:             "user_1",
		PeriodYYYYMM:       "2026-05",
		Permission:         "export.preview",
	})
	events := r.AuditEvents()
	if len(events) != 3 {
		t.Fatalf("expected three audit events, got %#v", events)
	}
	for _, event := range events {
		if event.AccountantTenantID == "" || event.UserID == "" || event.Status == "" {
			t.Fatalf("audit event must carry tenant/user/status: %#v", event)
		}
	}
}
