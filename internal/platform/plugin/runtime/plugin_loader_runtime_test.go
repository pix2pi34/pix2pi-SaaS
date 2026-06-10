package pluginruntime

import (
	"strings"
	"testing"
)

func validPluginManifestJSON() []byte {
	return []byte(`{
	  "tenant_id": "tenant_7",
	  "plugin_id": "stock-sync-plugin",
	  "name": "Stock Sync Plugin",
	  "version": "1.0.0",
	  "runtime_version": "pix2pi-plugin-runtime/v1",
	  "entrypoint": "cmd/plugin_stock_sync_main.go",
	  "environment": "SANDBOX",
	  "permissions": ["erp:read", "erp:write", "webhook:emit", "erp:read"],
	  "capabilities": [
	    {"code": "stock.sync", "description": "Stock sync capability"}
	  ],
	  "metadata": {
	    "owner": "pix2pi"
	  }
	}`)
}

func TestPluginLoaderRuntimeLoadsValidManifest(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	manifest, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_7",
		RawManifest: validPluginManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected load allowed, got reason=%s", decision.Reason)
	}
	if manifest.Status != PluginManifestStatusLoaded {
		t.Fatalf("expected LOADED status, got %s", manifest.Status)
	}
	if manifest.LoadedAt == "" {
		t.Fatal("expected loaded_at")
	}
	if len(manifest.Permissions) != 3 {
		t.Fatalf("expected deduplicated permission count 3, got %d", len(manifest.Permissions))
	}
	if manifest.PluginID != "stock-sync-plugin" {
		t.Fatalf("unexpected plugin id %s", manifest.PluginID)
	}
}

func TestPluginLoaderRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		RawManifest: validPluginManifestJSON(),
	})
	if err != ErrPluginLoaderMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestPluginLoaderRuntimeRejectsCrossTenantManifest(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_8",
		RawManifest: validPluginManifestJSON(),
	})
	if err != ErrPluginLoaderCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPluginLoaderRuntimeRejectsMissingRequiredFields(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID: "tenant_7",
		RawManifest: []byte(`{
		  "tenant_id": "tenant_7",
		  "name": "Missing Plugin ID",
		  "version": "1.0.0",
		  "runtime_version": "pix2pi-plugin-runtime/v1",
		  "entrypoint": "cmd/plugin_main.go",
		  "permissions": ["erp:read"]
		}`),
	})
	if err != ErrPluginLoaderMissingPluginID {
		t.Fatalf("expected missing plugin id, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonMissingPluginID {
		t.Fatalf("expected missing plugin id reason, got %s", decision.Reason)
	}

	_, decision, err = runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID: "tenant_7",
		RawManifest: []byte(`{
		  "tenant_id": "tenant_7",
		  "plugin_id": "plugin-a",
		  "name": "Missing Entry",
		  "version": "1.0.0",
		  "runtime_version": "pix2pi-plugin-runtime/v1",
		  "permissions": ["erp:read"]
		}`),
	})
	if err != ErrPluginLoaderMissingEntryPoint {
		t.Fatalf("expected missing entrypoint, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonMissingEntryPoint {
		t.Fatalf("expected missing entrypoint reason, got %s", decision.Reason)
	}
}

func TestPluginLoaderRuntimeRejectsInvalidPermission(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID: "tenant_7",
		RawManifest: []byte(`{
		  "tenant_id": "tenant_7",
		  "plugin_id": "unsafe-plugin",
		  "name": "Unsafe Plugin",
		  "version": "1.0.0",
		  "runtime_version": "pix2pi-plugin-runtime/v1",
		  "entrypoint": "cmd/plugin_unsafe_main.go",
		  "environment": "SANDBOX",
		  "permissions": ["root:all"]
		}`),
	})
	if err != ErrPluginLoaderInvalidPermission {
		t.Fatalf("expected invalid permission, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonInvalidPermission {
		t.Fatalf("expected invalid permission reason, got %s", decision.Reason)
	}
}

func TestPluginLoaderRuntimeRejectsInvalidEnvironment(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	_, decision, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID: "tenant_7",
		RawManifest: []byte(`{
		  "tenant_id": "tenant_7",
		  "plugin_id": "bad-env-plugin",
		  "name": "Bad Env Plugin",
		  "version": "1.0.0",
		  "runtime_version": "pix2pi-plugin-runtime/v1",
		  "entrypoint": "cmd/plugin_bad_env_main.go",
		  "environment": "LOCAL",
		  "permissions": ["erp:read"]
		}`),
	})
	if err != ErrPluginLoaderInvalidEnvironment {
		t.Fatalf("expected invalid environment, got %v", err)
	}
	if decision.Reason != PluginLoaderReasonInvalidEnvironment {
		t.Fatalf("expected invalid environment reason, got %s", decision.Reason)
	}
}

func TestPluginLoaderRuntimeTenantSafeRegistry(t *testing.T) {
	runtime := NewPluginLoaderRuntime(DefaultPluginLoaderRuntimeConfig())

	manifest, _, err := runtime.LoadManifestJSON(PluginLoadRequest{
		TenantID:    "tenant_7",
		RawManifest: validPluginManifestJSON(),
	})
	if err != nil {
		t.Fatalf("load manifest failed: %v", err)
	}

	loaded, err := runtime.GetLoadedPlugin("tenant_7", manifest.PluginID, manifest.Version)
	if err != nil {
		t.Fatalf("get loaded plugin failed: %v", err)
	}
	if loaded.PluginID != manifest.PluginID {
		t.Fatalf("expected plugin id %s, got %s", manifest.PluginID, loaded.PluginID)
	}

	_, err = runtime.GetLoadedPlugin("tenant_8", manifest.PluginID, manifest.Version)
	if err != ErrPluginLoaderMissingManifest {
		t.Fatalf("expected missing manifest for other tenant, got %v", err)
	}

	tenant7Plugins, err := runtime.ListTenantPlugins("tenant_7")
	if err != nil {
		t.Fatalf("list tenant plugins failed: %v", err)
	}
	if len(tenant7Plugins) != 1 {
		t.Fatalf("expected tenant_7 plugin count 1, got %d", len(tenant7Plugins))
	}

	tenant8Plugins, err := runtime.ListTenantPlugins("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 plugins failed: %v", err)
	}
	if len(tenant8Plugins) != 0 {
		t.Fatalf("expected tenant_8 plugin count 0, got %d", len(tenant8Plugins))
	}
}

func TestPluginManifestKeyAndRuntimeLoadID(t *testing.T) {
	key := PluginManifestKey("tenant_7", "plugin-a", "1.0.0")
	if key != "tenant_7:plugin-a:1.0.0" {
		t.Fatalf("unexpected manifest key %s", key)
	}

	loadID := NewPluginRuntimeLoadID()
	if !strings.HasPrefix(loadID, "plugin_load_") {
		t.Fatalf("unexpected load id %s", loadID)
	}
}
