package pluginruntime

import "testing"

func finalPluginRuntimeManifestJSON() []byte {
	return []byte(`{
	  "tenant_id": "tenant_final",
	  "plugin_id": "final-stock-sync-plugin",
	  "name": "Final Stock Sync Plugin",
	  "version": "1.0.0",
	  "runtime_version": "pix2pi-plugin-runtime/v1.2.0",
	  "entrypoint": "cmd/plugin_final_stock_sync_main.go",
	  "environment": "SANDBOX",
	  "permissions": ["erp:read", "erp:write", "webhook:emit", "workflow:trigger"],
	  "capabilities": [
	    {"code": "stock.sync", "description": "Final plugin runtime stock sync capability"}
	  ],
	  "metadata": {
	    "owner": "pix2pi",
	    "phase": "FAZ_2_7_7_6"
	  }
	}`)
}

func TestPluginRuntimeFinalEndToEndSandboxExecutionFlow(t *testing.T) {
	loader := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	manifest, loaderDecision, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:      "tenant_final",
		RawManifest:   finalPluginRuntimeManifestJSON(),
		CorrelationID: "corr_final_loader",
	})
	if err != nil {
		t.Fatalf("plugin manifest load failed: %v", err)
	}
	if !loaderDecision.Allowed {
		t.Fatalf("expected loader decision allowed, got reason=%s", loaderDecision.Reason)
	}
	if manifest.Status != PluginManifestStatusLoaded {
		t.Fatalf("expected manifest status LOADED, got %s", manifest.Status)
	}

	lifecycle := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())

	install, installDecision, err := lifecycle.InstallPlugin(PluginLifecycleRequest{
		TenantID:      "tenant_final",
		Manifest:      manifest,
		ActorRef:      "admin_final",
		CorrelationID: "corr_final_install",
	})
	if err != nil {
		t.Fatalf("plugin install failed: %v", err)
	}
	if !installDecision.Allowed {
		t.Fatalf("expected install decision allowed, got reason=%s", installDecision.Reason)
	}
	if install.Status != PluginInstallStatusInstalled {
		t.Fatalf("expected INSTALLED, got %s", install.Status)
	}

	install, enableDecision, err := lifecycle.EnablePlugin(PluginLifecycleRequest{
		TenantID:      "tenant_final",
		InstallID:     install.InstallID,
		ActorRef:      "admin_final",
		CorrelationID: "corr_final_enable",
	})
	if err != nil {
		t.Fatalf("plugin enable failed: %v", err)
	}
	if !enableDecision.Allowed {
		t.Fatalf("expected enable decision allowed, got reason=%s", enableDecision.Reason)
	}
	if install.Status != PluginInstallStatusEnabled {
		t.Fatalf("expected ENABLED, got %s", install.Status)
	}

	compatibility := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	compatState, compatDecision, err := compatibility.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_final",
		Manifest: manifest,
		HostRuntimeVersion: PluginHostRuntimeVersion{
			RuntimeVersion: "pix2pi-plugin-runtime/v1.5.0",
			MinSupported:   "pix2pi-plugin-runtime/v1.0.0",
			MaxSupported:   "pix2pi-plugin-runtime/v1.9.9",
			Environment:    PluginEnvironmentSandbox,
			HostBuild:      "build_faz_2_7_7_6",
		},
		ActorRef:      "plugin-loader",
		CorrelationID: "corr_final_compat",
	})
	if err != nil {
		t.Fatalf("compatibility check failed: %v", err)
	}
	if !compatDecision.Allowed {
		t.Fatalf("expected compatibility decision allowed, got reason=%s", compatDecision.Reason)
	}
	if compatState.Compatibility != PluginCompatibilityStateCompatible {
		t.Fatalf("expected COMPATIBLE, got %s", compatState.Compatibility)
	}

	permission := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())

	permissionDecision, err := permission.CheckPermission(PluginPermissionCheckRequest{
		TenantID:      "tenant_final",
		Install:       install,
		Action:        PluginRuntimeActionERPRead,
		Resource:      "erp.stock",
		ActorRef:      "plugin-worker",
		CorrelationID: "corr_final_permission",
	})
	if err != nil {
		t.Fatalf("permission check failed: %v", err)
	}
	if !permissionDecision.Allowed {
		t.Fatalf("expected permission allowed, got reason=%s", permissionDecision.Reason)
	}
	if permissionDecision.RequiredPermission != "erp:read" {
		t.Fatalf("expected erp:read, got %s", permissionDecision.RequiredPermission)
	}

	sandbox := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permission)

	ctx, sandboxDecision, err := sandbox.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID:      "tenant_final",
		Install:       install,
		Action:        PluginRuntimeActionERPWrite,
		Resource:      "erp.stock",
		PayloadKind:   "json",
		ActorRef:      "plugin-worker",
		CorrelationID: "corr_final_sandbox",
	})
	if err != nil {
		t.Fatalf("sandbox execution context failed: %v", err)
	}
	if !sandboxDecision.Allowed {
		t.Fatalf("expected sandbox decision allowed, got reason=%s", sandboxDecision.Reason)
	}
	if ctx.SandboxNamespace == "" {
		t.Fatal("expected sandbox namespace")
	}
	if ctx.RequiredPermission != "erp:write" {
		t.Fatalf("expected erp:write, got %s", ctx.RequiredPermission)
	}
	if !PluginSandboxContextMatchesTenant(ctx, "tenant_final") {
		t.Fatal("expected sandbox context to match tenant_final")
	}
}

func TestPluginRuntimeFinalCrossTenantDenyAcrossModules(t *testing.T) {
	loader := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, loaderDecision, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_other",
		RawManifest: finalPluginRuntimeManifestJSON(),
	})
	if err != ErrPluginLoaderCrossTenant {
		t.Fatalf("expected loader cross tenant error, got %v", err)
	}
	if loaderDecision.Reason != PluginLoaderReasonCrossTenant {
		t.Fatalf("expected loader cross tenant reason, got %s", loaderDecision.Reason)
	}

	manifest, _, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_final",
		RawManifest: finalPluginRuntimeManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}

	lifecycle := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	install, _, err := lifecycle.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_final",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	install, _, err = lifecycle.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_final",
		InstallID: install.InstallID,
	})
	if err != nil {
		t.Fatalf("enable plugin failed: %v", err)
	}

	_, lifecycleDecision, err := lifecycle.DisablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_other",
		InstallID: install.InstallID,
	})
	if err != ErrPluginLifecycleCrossTenant {
		t.Fatalf("expected lifecycle cross tenant error, got %v", err)
	}
	if lifecycleDecision.Reason != PluginLifecycleReasonCrossTenant {
		t.Fatalf("expected lifecycle cross tenant reason, got %s", lifecycleDecision.Reason)
	}

	permission := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())

	permissionDecision, err := permission.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_other",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginPermissionCrossTenant {
		t.Fatalf("expected permission cross tenant error, got %v", err)
	}
	if permissionDecision.Reason != PluginPermissionReasonCrossTenant {
		t.Fatalf("expected permission cross tenant reason, got %s", permissionDecision.Reason)
	}

	sandbox := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permission)

	_, sandboxDecision, err := sandbox.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID: "tenant_other",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginSandboxCrossTenant {
		t.Fatalf("expected sandbox cross tenant error, got %v", err)
	}
	if sandboxDecision.Reason != PluginSandboxReasonCrossTenant {
		t.Fatalf("expected sandbox cross tenant reason, got %s", sandboxDecision.Reason)
	}

	compatibility := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	_, compatDecision, err := compatibility.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_other",
		Manifest: manifest,
	})
	if err != ErrPluginCompatibilityCrossTenant {
		t.Fatalf("expected compatibility cross tenant error, got %v", err)
	}
	if compatDecision.Reason != PluginCompatibilityReasonCrossTenant {
		t.Fatalf("expected compatibility cross tenant reason, got %s", compatDecision.Reason)
	}
}

func TestPluginRuntimeFinalDenyCases(t *testing.T) {
	loader := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	manifest, _, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_final",
		RawManifest: finalPluginRuntimeManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}

	lifecycle := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	install, _, err := lifecycle.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_final",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	permission := NewPluginPermissionEnforcementRuntime(DefaultPluginPermissionEnforcementRuntimeConfig())

	permissionDecision, err := permission.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_final",
		Install:  install,
		Action:   PluginRuntimeActionERPRead,
	})
	if err != ErrPluginPermissionInstallNotEnabled {
		t.Fatalf("expected install not enabled permission error, got %v", err)
	}
	if permissionDecision.Reason != PluginPermissionReasonInstallNotEnabled {
		t.Fatalf("expected install not enabled reason, got %s", permissionDecision.Reason)
	}

	install, _, err = lifecycle.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_final",
		InstallID: install.InstallID,
	})
	if err != nil {
		t.Fatalf("enable plugin failed: %v", err)
	}

	permissionDecision, err = permission.CheckPermission(PluginPermissionCheckRequest{
		TenantID: "tenant_final",
		Install:  install,
		Action:   PluginRuntimeActionReportRead,
	})
	if err != ErrPluginPermissionDenied {
		t.Fatalf("expected permission denied error, got %v", err)
	}
	if permissionDecision.Reason != PluginPermissionReasonPermissionDenied {
		t.Fatalf("expected permission denied reason, got %s", permissionDecision.Reason)
	}

	sandbox := NewPluginSandboxRuntime(DefaultPluginSandboxRuntimeConfig(), permission)
	productionInstall := install
	productionInstall.Environment = PluginEnvironmentProduction

	_, sandboxDecision, err := sandbox.BuildExecutionContext(PluginSandboxExecutionRequest{
		TenantID:    "tenant_final",
		Install:     productionInstall,
		Action:      PluginRuntimeActionERPRead,
		Environment: PluginEnvironmentProduction,
	})
	if err != ErrPluginSandboxProductionDenied {
		t.Fatalf("expected sandbox production denied error, got %v", err)
	}
	if sandboxDecision.Reason != PluginSandboxReasonProductionDenied {
		t.Fatalf("expected sandbox production denied reason, got %s", sandboxDecision.Reason)
	}

	compatibility := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())
	tooNewManifest := manifest
	tooNewManifest.RuntimeVersion = "pix2pi-plugin-runtime/v2.0.0"

	_, compatDecision, err := compatibility.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_final",
		Manifest: tooNewManifest,
	})
	if err != ErrPluginCompatibilityAboveMaximum {
		t.Fatalf("expected compatibility above maximum error, got %v", err)
	}
	if compatDecision.Reason != PluginCompatibilityReasonAboveMaximum {
		t.Fatalf("expected above maximum reason, got %s", compatDecision.Reason)
	}
}
