package pluginruntime

import "testing"

func enabledPermissionTestInstall(t *testing.T) TenantPluginInstall {
	t.Helper()

	loader := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())
	manifest, _, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_7",
		RawManifest: validPluginManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}

	lifecycle := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	install, _, err := lifecycle.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	install, _, err = lifecycle.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
	})
	if err != nil {
		t.Fatalf("enable plugin failed: %v", err)
	}

	return install
}

func TestPluginPermissionEnforcementRuntimeAllowsGrantedPermission(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
		Resource: "erp.stock",
		ActorRef: "plugin-worker",
	})
	if err != nil {
		t.Fatalf("permission check failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected permission allowed, got reason=%s", decision.Reason)
	}
	if decision.RequiredPermission != "erp:read" {
		t.Fatalf("expected erp:read permission, got %s", decision.RequiredPermission)
	}
	if decision.InstallID != install.InstallID {
		t.Fatalf("expected install id %s, got %s", install.InstallID, decision.InstallID)
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesMissingTenant(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		Install: install,
		Action:  PluginRuntimeActionERPRead,
	})
	if err != ErrPluginPermissionMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesCrossTenant(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_8",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginPermissionCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesDisabledInstall(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)
	install.Status = PluginInstallStatusDisabled

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginPermissionInstallNotEnabled {
		t.Fatalf("expected install not enabled error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonInstallNotEnabled {
		t.Fatalf("expected install not enabled reason, got %s", decision.Reason)
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesUnknownAction(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   "ROOT_DELETE",
	})
	if err != ErrPluginPermissionActionUnknown {
		t.Fatalf("expected unknown action error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonActionUnknown {
		t.Fatalf("expected unknown action reason, got %s", decision.Reason)
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesPermissionNotGranted(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionReportRead,
	})
	if err != ErrPluginPermissionDenied {
		t.Fatalf("expected permission denied error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonPermissionDenied {
		t.Fatalf("expected permission denied reason, got %s", decision.Reason)
	}
	if decision.RequiredPermission != "report:read" {
		t.Fatalf("expected report:read required permission, got %s", decision.RequiredPermission)
	}
}

func TestPluginPermissionEnforcementRuntimeCanPerform(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	if !runtime.CanPerform(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionERPWrite,
	}) {
		t.Fatal("expected CanPerform true for erp write")
	}

	if runtime.CanPerform(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
		Action:   PluginRuntimeActionReportRead,
	}) {
		t.Fatal("expected CanPerform false for missing report read")
	}
}

func TestPluginPermissionListContainsIsCaseInsensitive(t *testing.T) {
	permissions := []string{"ERP:READ", "webhook:emit"}
	if !PluginPermissionListContains(permissions, "erp:read") {
		t.Fatal("expected case-insensitive permission match")
	}
	if PluginPermissionListContains(permissions, "report:read") {
		t.Fatal("expected report:read not found")
	}
}

func TestPluginPermissionEnforcementRuntimeDeniesMissingAction(t *testing.T) {
	runtime := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())
	install := enabledPermissionTestInstall(t)

	decision, err := runtime.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_7",
		Install:  install,
	})
	if err != ErrPluginPermissionMissingAction {
		t.Fatalf("expected missing action error, got %v", err)
	}
	if decision.Reason != PluginPermissionReasonMissingAction {
		t.Fatalf("expected missing action reason, got %s", decision.Reason)
	}
}
