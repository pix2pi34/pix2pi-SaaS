package pluginruntime

import (
	"strings"
	"testing"
)

func loadedLifecyclePluginManifest(t *testing.T) PluginManifest {
	t.Helper()

	loader := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())
	manifest, decision, err := loader.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_7",
		RawManifest: validPluginManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected loader decision allowed, got reason=%s", decision.Reason)
	}
	return manifest
}

func TestPluginLifecycleRuntimeInstallsLoadedPlugin(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	install, decision, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
		ActorRef: "admin_1",
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected install allowed, got reason=%s", decision.Reason)
	}
	if install.InstallID == "" {
		t.Fatal("expected install id")
	}
	if install.Status != PluginInstallStatusInstalled {
		t.Fatalf("expected INSTALLED, got %s", install.Status)
	}
	if install.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", install.TenantID)
	}
	if install.PluginID != manifest.PluginID {
		t.Fatalf("expected plugin id %s, got %s", manifest.PluginID, install.PluginID)
	}
}

func TestPluginLifecycleRuntimeRejectsManifestNotLoaded(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)
	manifest.Status = ""

	_, decision, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != ErrPluginLifecycleManifestNotLoaded {
		t.Fatalf("expected manifest not loaded error, got %v", err)
	}
	if decision.Reason != PluginLifecycleReasonManifestNotLoaded {
		t.Fatalf("expected manifest not loaded reason, got %s", decision.Reason)
	}
}

func TestPluginLifecycleRuntimeRejectsCrossTenantInstall(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	_, decision, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_8",
		Manifest: manifest,
	})
	if err != ErrPluginLifecycleCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginLifecycleReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPluginLifecycleRuntimeEnableDisableSuspendUninstallFlow(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	install, _, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	install, decision, err := runtime.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
		ActorRef:  "admin_1",
	})
	if err != nil {
		t.Fatalf("enable plugin failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected enable allowed, got reason=%s", decision.Reason)
	}
	if install.Status != PluginInstallStatusEnabled {
		t.Fatalf("expected ENABLED, got %s", install.Status)
	}
	if install.EnabledAt == "" {
		t.Fatal("expected enabled_at")
	}

	install, _, err = runtime.DisablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
		ActorRef:  "admin_1",
	})
	if err != nil {
		t.Fatalf("disable plugin failed: %v", err)
	}
	if install.Status != PluginInstallStatusDisabled {
		t.Fatalf("expected DISABLED, got %s", install.Status)
	}
	if install.DisabledAt == "" {
		t.Fatal("expected disabled_at")
	}

	install, _, err = runtime.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
		ActorRef:  "admin_1",
	})
	if err != nil {
		t.Fatalf("re-enable plugin failed: %v", err)
	}

	install, _, err = runtime.SuspendPlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
		ActorRef:  "ops_1",
	})
	if err != nil {
		t.Fatalf("suspend plugin failed: %v", err)
	}
	if install.Status != PluginInstallStatusSuspended {
		t.Fatalf("expected SUSPENDED, got %s", install.Status)
	}
	if install.SuspendedAt == "" {
		t.Fatal("expected suspended_at")
	}

	install, _, err = runtime.UninstallPlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
		ActorRef:  "admin_1",
	})
	if err != nil {
		t.Fatalf("uninstall plugin failed: %v", err)
	}
	if install.Status != PluginInstallStatusUninstalled {
		t.Fatalf("expected UNINSTALLED, got %s", install.Status)
	}
	if install.UninstalledAt == "" {
		t.Fatal("expected uninstalled_at")
	}
}

func TestPluginLifecycleRuntimeRejectsInvalidTransition(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	install, _, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	_, decision, err := runtime.DisablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
	})
	if err != ErrPluginLifecycleInvalidTransition {
		t.Fatalf("expected invalid transition error, got %v", err)
	}
	if decision.Reason != PluginLifecycleReasonInvalidTransition {
		t.Fatalf("expected invalid transition reason, got %s", decision.Reason)
	}
}

func TestPluginLifecycleRuntimeRejectsTerminalTransition(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	install, _, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	install, _, err = runtime.UninstallPlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
	})
	if err != nil {
		t.Fatalf("uninstall plugin failed: %v", err)
	}

	_, decision, err := runtime.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_7",
		InstallID: install.InstallID,
	})
	if err != ErrPluginLifecycleTerminalInstall {
		t.Fatalf("expected terminal install error, got %v", err)
	}
	if decision.Reason != PluginLifecycleReasonTerminalInstall {
		t.Fatalf("expected terminal reason, got %s", decision.Reason)
	}
}

func TestPluginLifecycleRuntimeRejectsCrossTenantAccess(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	install, _, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	_, decision, err := runtime.EnablePlugin(PluginLifecycleRequest{
		TenantID:  "tenant_8",
		InstallID: install.InstallID,
	})
	if err != ErrPluginLifecycleCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginLifecycleReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}

	_, err = runtime.GetInstall("tenant_8", install.InstallID)
	if err != ErrPluginLifecycleCrossTenant {
		t.Fatalf("expected cross tenant get error, got %v", err)
	}
}

func TestPluginLifecycleRuntimeTenantSafeList(t *testing.T) {
	runtime := NewPluginLifecycleRuntime(DefaultPluginLifecycleRuntimeConfig())
	manifest := loadedLifecyclePluginManifest(t)

	_, _, err := runtime.InstallPlugin(PluginLifecycleRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("install plugin failed: %v", err)
	}

	tenant7, err := runtime.ListTenantInstalls("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 failed: %v", err)
	}
	if len(tenant7) != 1 {
		t.Fatalf("expected tenant_7 install count 1, got %d", len(tenant7))
	}

	tenant8, err := runtime.ListTenantInstalls("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 failed: %v", err)
	}
	if len(tenant8) != 0 {
		t.Fatalf("expected tenant_8 install count 0, got %d", len(tenant8))
	}
}

func TestTenantPluginInstallID(t *testing.T) {
	id := NewTenantPluginInstallID()
	if !strings.HasPrefix(id, "plugin_install_") {
		t.Fatalf("unexpected install id %s", id)
	}
}
