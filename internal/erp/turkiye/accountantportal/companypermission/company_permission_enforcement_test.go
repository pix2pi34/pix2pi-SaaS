package companypermission

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:            true,
		RequireTenantScope:        true,
		RequireCompanyScope:       true,
		RequireAssignmentScope:    true,
		RequireResourcePermission: true,
		RequireRolePermissionMap:  true,
		RequireExplicitGrant:      true,
		RequireAuditSubject:       true,
		AllowSuperAdminOverride:   false,
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
		AllowedResourceTypes: []ResourceType{
			ResourceTypeFirm,
			ResourceTypeLedger,
			ResourceTypeExport,
			ResourceTypeAssignment,
			ResourceTypeSubscription,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validGrant() CompanyPermissionGrant {
	now := validNow()
	return CompanyPermissionGrant{
		GrantID:            "grant-001",
		TenantID:           "tenant-accountant-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		AssignmentID:       "assign-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		Role:               PortalRoleStaff,
		Permissions: []Permission{
			PermissionViewFirm,
			PermissionViewLedger,
			PermissionExportExcel,
			PermissionExportPDF,
			PermissionExportTDHP,
		},
		ResourceTypes: []ResourceType{
			ResourceTypeFirm,
			ResourceTypeLedger,
			ResourceTypeExport,
		},
		Active:     true,
		ValidFrom:  now.Add(-24 * time.Hour),
		ValidUntil: now.Add(30 * 24 * time.Hour),
		GrantedBy:  "acc-owner-001",
		GrantedAt:  now.Add(-24 * time.Hour),
	}
}

func validRequest() EnforcementRequest {
	return EnforcementRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-company-permission-001",
		RequestID:          "req-company-permission-001",
		IdempotencyKey:     "idem-company-permission-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		AssignmentID:       "assign-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		ResourceType:       ResourceTypeExport,
		RequiredPermission: PermissionExportTDHP,
		AuditSubject:       "company-001:export-tdhp",
		Grant:              validGrant(),
		RequestedAt:        validNow(),
	}
}

func newRuntime(t *testing.T) *CompanyPermissionEnforcementRuntime {
	t.Helper()

	runtime, err := NewCompanyPermissionEnforcementRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestEnforceAllowsExplicitCompanyPermission(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.Enforce(validRequest())
	if err != nil {
		t.Fatalf("expected permission allowed, got error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected allowed")
	}
	if decision.Status != EnforcementAllowed {
		t.Fatalf("expected ALLOWED, got %s", decision.Status)
	}
	if decision.DecisionHash == "" {
		t.Fatal("expected decision hash")
	}
}

func TestEnforceRejectsTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.TenantID = "tenant-other"

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if decision.Allowed {
		t.Fatal("expected denied")
	}
	if decision.ReasonCode != "GRANT_SCOPE_DENIED" {
		t.Fatalf("expected GRANT_SCOPE_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEnforceRejectsCompanyMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.TargetCompanyID = "company-other"

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected company mismatch error")
	}
	if decision.Allowed {
		t.Fatal("expected denied")
	}
}

func TestEnforceRejectsInactiveGrant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.Active = false

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected inactive grant error")
	}
	if decision.Allowed {
		t.Fatal("expected denied")
	}
}

func TestEnforceRejectsExpiredGrant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.ValidUntil = validNow().Add(-time.Hour)

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected expired grant error")
	}
	if decision.Allowed {
		t.Fatal("expected denied")
	}
}

func TestEnforceRejectsRolePermissionMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.Role = PortalRoleReadOnly
	req.RequiredPermission = PermissionExportTDHP

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected role permission denied")
	}
	if decision.ReasonCode != "ROLE_PERMISSION_DENIED" {
		t.Fatalf("expected ROLE_PERMISSION_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEnforceRejectsResourcePermissionMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.ResourceType = ResourceTypeLedger
	req.RequiredPermission = PermissionExportTDHP

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected resource permission denied")
	}
	if decision.ReasonCode != "RESOURCE_PERMISSION_DENIED" {
		t.Fatalf("expected RESOURCE_PERMISSION_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEnforceRejectsMissingExplicitGrant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.Permissions = []Permission{PermissionViewFirm}

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected explicit grant denied")
	}
	if decision.ReasonCode != "EXPLICIT_GRANT_DENIED" {
		t.Fatalf("expected EXPLICIT_GRANT_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEnforceRejectsResourceTypeNotGranted(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Grant.ResourceTypes = []ResourceType{ResourceTypeFirm}

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected resource type denied")
	}
	if decision.ReasonCode != "RESOURCE_TYPE_DENIED" {
		t.Fatalf("expected RESOURCE_TYPE_DENIED, got %s", decision.ReasonCode)
	}
}

func TestEnforceRejectsMissingAuditSubject(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.AuditSubject = ""

	decision, err := runtime.Enforce(req)
	if err == nil {
		t.Fatal("expected audit subject validation error")
	}
	if decision.ReasonCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", decision.ReasonCode)
	}
}

func TestEnforceBulkAllowsAllChecks(t *testing.T) {
	runtime := newRuntime(t)
	req1 := validRequest()

	req2 := validRequest()
	req2.IdempotencyKey = "idem-company-permission-002"
	req2.ResourceType = ResourceTypeLedger
	req2.RequiredPermission = PermissionViewLedger
	req2.AuditSubject = "company-001:ledger"

	bulk := BulkEnforcementRequest{
		TenantID:         "tenant-accountant-001",
		CorrelationID:    "corr-bulk-001",
		RequestID:        "req-bulk-001",
		IdempotencyKey:   "idem-bulk-001",
		AccountantFirmID: "acc-firm-001",
		AccountantUserID: "acc-user-001",
		Checks:           []EnforcementRequest{req1, req2},
		RequestedAt:      validNow(),
	}

	result, err := runtime.EnforceBulk(bulk)
	if err != nil {
		t.Fatalf("expected bulk allowed, got error: %v", err)
	}
	if !result.AllAllowed {
		t.Fatal("expected all allowed")
	}
	if result.AllowedCount != 2 {
		t.Fatalf("expected allowed count 2, got %d", result.AllowedCount)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestEnforceBulkReturnsDeniedWhenOneCheckFails(t *testing.T) {
	runtime := newRuntime(t)
	req1 := validRequest()

	req2 := validRequest()
	req2.IdempotencyKey = "idem-company-permission-002"
	req2.Grant.TargetCompanyID = "company-other"

	bulk := BulkEnforcementRequest{
		TenantID:         "tenant-accountant-001",
		CorrelationID:    "corr-bulk-001",
		RequestID:        "req-bulk-001",
		IdempotencyKey:   "idem-bulk-001",
		AccountantFirmID: "acc-firm-001",
		AccountantUserID: "acc-user-001",
		Checks:           []EnforcementRequest{req1, req2},
		RequestedAt:      validNow(),
	}

	result, err := runtime.EnforceBulk(bulk)
	if err == nil {
		t.Fatal("expected bulk partial denied error")
	}
	if result.AllAllowed {
		t.Fatal("expected not all allowed")
	}
	if result.DeniedCount != 1 {
		t.Fatalf("expected denied count 1, got %d", result.DeniedCount)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewCompanyPermissionEnforcementRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingResourceTypesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AllowedResourceTypes = nil

	_, err := NewCompanyPermissionEnforcementRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing resource types error")
	}
}
