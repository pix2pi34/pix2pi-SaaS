package pluginruntime

import "testing"

func sandboxEnabledTestInstall(t *testing.T) TenantPluginInstall {
	t.Helper()
	return enabledPermissionTestInstall(t)
}

func TestPluginSandboxRuntimeBuildsExecutionContext(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	ctx, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID:      "tenant_7",
		Install:       install,
		Action:        PluginRuntimeActionERPRead,
		Resource:      "erp.stock",
		PayloadKind:   "json",
		ActorRef:      "plugin-worker",
		CorrelationID: "corr_1",
	})
	if err != nil {
		t.Fatalf("build sandbox context failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected sandbox allowed, got reason=%s", decision.Reason)
	}
	if ctx.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", ctx.TenantID)
	}
	if ctx.InstallID != install.InstallID {
		t.Fatalf("expected install id %s, got %s", install.InstallID, ctx.InstallID)
	}
	if ctx.RequiredPermission != "erp:read" {
		t.Fatalf("expected erp:read, got %s", ctx.RequiredPermission)
	}
	expectedNamespace := "plugin_sandbox:tenant_7:" + install.PluginID + ":" + install.InstallID
	if ctx.SandboxNamespace != expectedNamespace {
		t.Fatalf("expected namespace %s, got %s", expectedNamespace, ctx.SandboxNamespace)
	}
}

func TestPluginSandboxRuntimeRejectsMissingTenant(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		Install: install,
		Action:  PluginRuntimeActionERPRead,
	})
	if err != ErrPluginSandboxMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestPluginSandboxRuntimeRejectsCrossTenant(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID: "tenant_8",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginSandboxCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPluginSandboxRuntimeRejectsDisabledInstall(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)
	install.Status = PluginInstallStatusDisabled

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginSandboxInstallNotEnabled {
		t.Fatalf("expected install not enabled error, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonInstallNotEnabled {
		t.Fatalf("expected install not enabled reason, got %s", decision.Reason)
	}
}

func TestPluginSandboxRuntimeRejectsPermissionDenied(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionReportRead,
	})
	if err != ErrPluginSandboxPermissionDenied {
		t.Fatalf("expected sandbox permission denied, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonPermissionDenied {
		t.Fatalf("expected permission denied reason, got %s", decision.Reason)
	}
	if decision.RequiredPermission != "report:read" {
		t.Fatalf("expected report:read required permission, got %s", decision.RequiredPermission)
	}
}

func TestPluginSandboxRuntimeRejectsProductionEnvironment(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)
	install.Environment = PluginEnvironmentProduction

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID:    "tenant_7",
		Install:     install,
		Action:      PluginRuntimeActionERPRead,
		Environment: PluginEnvironmentProduction,
	})
	if err != ErrPluginSandboxProductionDenied {
		t.Fatalf("expected production denied, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonProductionDenied {
		t.Fatalf("expected production denied reason, got %s", decision.Reason)
	}
}

func TestPluginSandboxRuntimeRejectsEnvironmentMismatch(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID:    "tenant_7",
		Install:     install,
		Action:      PluginRuntimeActionERPRead,
		Environment: PluginEnvironmentProduction,
	})
	if err != ErrPluginSandboxEnvironmentMismatch {
		t.Fatalf("expected environment mismatch, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonEnvironmentMismatch {
		t.Fatalf("expected environment mismatch reason, got %s", decision.Reason)
	}
}

func TestPluginSandboxRuntimeCanExecute(t *testing.T) {
	permissionRuntime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permissionRuntime)
	install := sandboxEnabledTestInstall(t)

	if !sandboxRuntime.CanExecute(PluginSandboxExecutionRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPWrite,
	}) {
		t.Fatal("expected CanExecute true for ERP_WRITE")
	}

	if sandboxRuntime.CanExecute(PluginSandboxExecutionRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionReportRead,
	}) {
		t.Fatal("expected CanExecute false for REPORT_READ")
	}
}

func TestPluginSandboxNamespaceAndTenantMatch(t *testing.T) {
	namespace := BuildPluginSandboxNamespace("tenant_7", "plugin-a", "install-1")
	if namespace != "plugin_sandbox:tenant_7:plugin-a:install-1" {
		t.Fatalf("unexpected namespace %s", namespace)
	}

	ctx := PluginSandboxExecutionContext{
		TenantID: "tenant_7",
	}
	if !PluginSandboxContextMatchesTenant(ctx, "tenant_7") {
		t.Fatal("expected tenant match")
	}
	if PluginSandboxContextMatchesTenant(ctx, "tenant_8") {
		t.Fatal("expected tenant mismatch")
	}
}

func TestPluginSandboxRuntimeRejectsMissingPermissionRuntime(t *testing.T) {
	sandboxRuntime := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), nil)
	install := sandboxEnabledTestInstall(t)

	_, decision, err := sandboxRuntime.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginSandboxPermissionRuntimeNil {
		t.Fatalf("expected permission runtime missing, got %v", err)
	}
	if decision.Reason != PluginSandboxReasonPermissionRuntimeNil {
		t.Fatalf("expected permission runtime missing reason, got %s", decision.Reason)
	}
}
