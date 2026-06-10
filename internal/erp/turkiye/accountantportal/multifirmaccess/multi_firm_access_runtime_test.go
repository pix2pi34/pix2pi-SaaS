package multifirmaccess

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
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
		RequiredPermissions: []Permission{
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
			PermissionManageAssignment,
			PermissionViewSubscription,
		},
		AllowedRoles: []PortalRole{
			PortalRoleOwner,
			PortalRoleStaff,
			PortalRoleReadOnly,
			PortalRoleSuperAdmin,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validSubscription() AccountantSubscription {
	now := validNow()
	return AccountantSubscription{
		SubscriptionID:    "sub-001",
		TenantID:          "tenant-accountant-001",
		AccountantFirmID:  "acc-firm-001",
		Status:            SubscriptionStatusActive,
		ValidFrom:         now.Add(-24 * time.Hour),
		ValidUntil:        now.Add(30 * 24 * time.Hour),
		AssignedFirmLimit: 20,
		AssignedFirmCount: 2,
	}
}

func validAssignment() FirmAssignment {
	now := validNow()
	return FirmAssignment{
		AssignmentID:       "assign-001",
		TenantID:           "tenant-accountant-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		TargetCompanyName:  "Pilot Market A.Ş.",
		Status:             AssignmentStatusActive,
		Role:               PortalRoleStaff,
		Permissions: []Permission{
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
		},
		ValidFrom:  now.Add(-24 * time.Hour),
		ValidUntil: now.Add(30 * 24 * time.Hour),
		AssignedBy: "acc-owner-001",
		AssignedAt: now.Add(-24 * time.Hour),
	}
}

func validAccessRequest() AccessRequest {
	return AccessRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-multi-firm-001",
		RequestID:          "req-multi-firm-001",
		IdempotencyKey:     "idem-multi-firm-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		RequiredPermission: PermissionExportTDHP,
		Subscription:       validSubscription(),
		Assignment:         validAssignment(),
		RequestedAt:        validNow(),
	}
}

func newRuntime(t *testing.T) *MultiFirmAccessRuntime {
	t.Helper()

	runtime, err := NewMultiFirmAccessRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestEvaluateAccessAllowsAssignedFirm(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.EvaluateAccess(validAccessRequest())
	if err != nil {
		t.Fatalf("expected access allowed, got error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected allowed decision")
	}
	if decision.Status != AccessDecisionAllowed {
		t.Fatalf("expected ALLOWED, got %s", decision.Status)
	}
	if decision.VisibilityStatus != VisibilityVisible {
		t.Fatalf("expected VISIBLE, got %s", decision.VisibilityStatus)
	}
	if decision.AccessHash == "" {
		t.Fatal("expected access hash")
	}
}

func TestEvaluateAccessRejectsInactiveSubscription(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Subscription.Status = SubscriptionStatusSuspended

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected subscription error")
	}
	if decision.Allowed {
		t.Fatal("expected denied decision")
	}
	if decision.ReasonCode != "SUBSCRIPTION_DENIED" {
		t.Fatalf("expected SUBSCRIPTION_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEvaluateAccessRejectsExpiredSubscription(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Subscription.ValidUntil = validNow().Add(-time.Hour)

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected expired subscription error")
	}
	if decision.Allowed {
		t.Fatal("expected denied decision")
	}
}

func TestEvaluateAccessRejectsInactiveAssignment(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Assignment.Status = AssignmentStatusRevoked

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected inactive assignment error")
	}
	if decision.ReasonCode != "ASSIGNMENT_DENIED" {
		t.Fatalf("expected ASSIGNMENT_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEvaluateAccessRejectsTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Assignment.TenantID = "tenant-other"

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if decision.Allowed {
		t.Fatal("expected denied decision")
	}
}

func TestEvaluateAccessRejectsCompanyMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Assignment.TargetCompanyID = "company-other"

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected company mismatch error")
	}
	if decision.Allowed {
		t.Fatal("expected denied decision")
	}
}

func TestEvaluateAccessRejectsMissingPermission(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.RequiredPermission = PermissionManageAssignment

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected permission denied error")
	}
	if decision.ReasonCode != "PERMISSION_DENIED" {
		t.Fatalf("expected PERMISSION_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEvaluateAccessRejectsExpiredAssignment(t *testing.T) {
	runtime := newRuntime(t)
	req := validAccessRequest()
	req.Assignment.ValidUntil = validNow().Add(-time.Hour)

	decision, err := runtime.EvaluateAccess(req)
	if err == nil {
		t.Fatal("expected expired assignment error")
	}
	if decision.Allowed {
		t.Fatal("expected denied decision")
	}
}

func TestListVisibleFirmsFiltersDeniedAssignments(t *testing.T) {
	runtime := newRuntime(t)
	valid := validAssignment()

	denied := validAssignment()
	denied.AssignmentID = "assign-002"
	denied.TargetFirmTenantID = "tenant-firm-002"
	denied.TargetCompanyID = "company-002"
	denied.TargetCompanyName = "Kapalı Firma Ltd."
	denied.Status = AssignmentStatusRevoked

	req := VisibleFirmsRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-visible-001",
		RequestID:          "req-visible-001",
		IdempotencyKey:     "idem-visible-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		RequiredPermission: PermissionExportTDHP,
		Subscription:       validSubscription(),
		Assignments:        []FirmAssignment{denied, valid},
		RequestedAt:        validNow(),
	}

	result, err := runtime.ListVisibleFirms(req)
	if err != nil {
		t.Fatalf("expected visible firm list, got error: %v", err)
	}
	if result.Status != ResultStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.VisibleFirmCount != 1 {
		t.Fatalf("expected 1 visible firm, got %d", result.VisibleFirmCount)
	}
	if result.DeniedFirmCount != 1 {
		t.Fatalf("expected 1 denied firm, got %d", result.DeniedFirmCount)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestListVisibleFirmsRejectsAssignmentLimit(t *testing.T) {
	cfg := validConfig()
	cfg.MaxAssignedFirmCount = 1

	runtime, err := NewMultiFirmAccessRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := VisibleFirmsRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-visible-001",
		RequestID:          "req-visible-001",
		IdempotencyKey:     "idem-visible-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		RequiredPermission: PermissionExportTDHP,
		Subscription:       validSubscription(),
		Assignments:        []FirmAssignment{validAssignment(), validAssignment()},
		RequestedAt:        validNow(),
	}

	result, err := runtime.ListVisibleFirms(req)
	if err == nil {
		t.Fatal("expected assignment limit error")
	}
	if result.Status != ResultStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewMultiFirmAccessRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingPermissionsConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredPermissions = nil

	_, err := NewMultiFirmAccessRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing permissions error")
	}
}
