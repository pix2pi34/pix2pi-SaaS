package pluginruntime

import (
	"strings"
	"testing"
)

func compatibleManifest() PluginManifest {
	return PluginManifest{
		TenantID:       "tenant_7",
		PluginID:       "stock-sync-plugin",
		Name:           "Stock Sync Plugin",
		Version:        "1.0.0",
		RuntimeVersion: "pix2pi-plugin-runtime/v1.2.0",
		EntryPoint:     "cmd/plugin_stock_sync_main.go",
		Environment:    PluginEnvironmentSandbox,
		Permissions:    []string{"erp:read", "erp:write"},
		Status:         PluginManifestStatusLoaded,
	}
}

func TestPluginVersionCompatibilityRuntimeAllowsCompatibleVersion(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	state, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: compatibleManifest(),
		HostRuntimeVersion: PluginHostRuntimeVersion{
			RuntimeVersion: "pix2pi-plugin-runtime/v1.5.0",
			MinSupported:   "pix2pi-plugin-runtime/v1.0.0",
			MaxSupported:   "pix2pi-plugin-runtime/v1.9.9",
			Environment:    PluginEnvironmentSandbox,
			HostBuild:      "build_20260507",
		},
		ActorRef: "plugin-loader",
	})
	if err != nil {
		t.Fatalf("compatibility check failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected compatibility allowed, got reason=%s", decision.Reason)
	}
	if state.Compatibility != PluginCompatibilityStateCompatible {
		t.Fatalf("expected compatible state, got %s", state.Compatibility)
	}
	if state.StateID == "" {
		t.Fatal("expected state id")
	}
	if decision.StateID != state.StateID {
		t.Fatalf("expected decision state id %s, got %s", state.StateID, decision.StateID)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		Manifest: compatibleManifest(),
	})
	if err != ErrPluginCompatibilityMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsCrossTenant(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_8",
		Manifest: compatibleManifest(),
	})
	if err != ErrPluginCompatibilityCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsBelowMinimum(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())
	manifest := compatibleManifest()
	manifest.RuntimeVersion = "pix2pi-plugin-runtime/v0.9.9"

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
		HostRuntimeVersion: PluginHostRuntimeVersion{
			RuntimeVersion: "pix2pi-plugin-runtime/v1.5.0",
			MinSupported:   "pix2pi-plugin-runtime/v1.0.0",
			MaxSupported:   "pix2pi-plugin-runtime/v1.9.9",
			Environment:    PluginEnvironmentSandbox,
		},
	})
	if err != ErrPluginCompatibilityBelowMinimum {
		t.Fatalf("expected below minimum error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonBelowMinimum {
		t.Fatalf("expected below minimum reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsAboveMaximum(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())
	manifest := compatibleManifest()
	manifest.RuntimeVersion = "pix2pi-plugin-runtime/v2.0.0"

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
		HostRuntimeVersion: PluginHostRuntimeVersion{
			RuntimeVersion: "pix2pi-plugin-runtime/v1.5.0",
			MinSupported:   "pix2pi-plugin-runtime/v1.0.0",
			MaxSupported:   "pix2pi-plugin-runtime/v1.9.9",
			Environment:    PluginEnvironmentSandbox,
		},
	})
	if err != ErrPluginCompatibilityAboveMaximum {
		t.Fatalf("expected above maximum error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonAboveMaximum {
		t.Fatalf("expected above maximum reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsEnvironmentMismatch(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: compatibleManifest(),
		HostRuntimeVersion: PluginHostRuntimeVersion{
			RuntimeVersion: "pix2pi-plugin-runtime/v1.5.0",
			MinSupported:   "pix2pi-plugin-runtime/v1.0.0",
			MaxSupported:   "pix2pi-plugin-runtime/v1.9.9",
			Environment:    PluginEnvironmentProduction,
		},
	})
	if err != ErrPluginCompatibilityEnvironmentMismatch {
		t.Fatalf("expected environment mismatch error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonEnvironmentMismatch {
		t.Fatalf("expected environment mismatch reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeRejectsInvalidRuntimePrefix(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())
	manifest := compatibleManifest()
	manifest.RuntimeVersion = "unknown-runtime/v1.0.0"

	_, decision, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != ErrPluginCompatibilityInvalidRuntime {
		t.Fatalf("expected invalid runtime error, got %v", err)
	}
	if decision.Reason != PluginCompatibilityReasonInvalidRuntime {
		t.Fatalf("expected invalid runtime reason, got %s", decision.Reason)
	}
}

func TestPluginVersionCompatibilityRuntimeTenantSafeStateAccess(t *testing.T) {
	runtime := NewPluginVersionCompatibilityRuntime(DefaultPluginVersionCompatibilityRuntimeConfig())
	manifest := compatibleManifest()

	state, _, err := runtime.CheckCompatibility(PluginCompatibilityCheckRequest{
		TenantID: "tenant_7",
		Manifest: manifest,
	})
	if err != nil {
		t.Fatalf("compatibility check failed: %v", err)
	}

	got, err := runtime.GetCompatibilityState("tenant_7", manifest.PluginID, manifest.Version)
	if err != nil {
		t.Fatalf("get compatibility state failed: %v", err)
	}
	if got.StateID != state.StateID {
		t.Fatalf("expected state id %s, got %s", state.StateID, got.StateID)
	}

	_, err = runtime.GetCompatibilityState("tenant_8", manifest.PluginID, manifest.Version)
	if err != ErrPluginCompatibilityMissingManifest {
		t.Fatalf("expected missing manifest for other tenant, got %v", err)
	}

	tenant7, err := runtime.ListTenantCompatibilityStates("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 states failed: %v", err)
	}
	if len(tenant7) != 1 {
		t.Fatalf("expected tenant_7 state count 1, got %d", len(tenant7))
	}

	tenant8, err := runtime.ListTenantCompatibilityStates("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 states failed: %v", err)
	}
	if len(tenant8) != 0 {
		t.Fatalf("expected tenant_8 state count 0, got %d", len(tenant8))
	}
}

func TestParseAndComparePluginRuntimeVersion(t *testing.T) {
	v120, err := ParsePluginRuntimeVersion("pix2pi-plugin-runtime/v1.2.0", "pix2pi-plugin-runtime/")
	if err != nil {
		t.Fatalf("parse v1.2.0 failed: %v", err)
	}

	v130, err := ParsePluginRuntimeVersion("pix2pi-plugin-runtime/v1.3.0", "pix2pi-plugin-runtime/")
	if err != nil {
		t.Fatalf("parse v1.3.0 failed: %v", err)
	}

	if ComparePluginRuntimeVersion(v120, v130) >= 0 {
		t.Fatal("expected v1.2.0 < v1.3.0")
	}
	if ComparePluginRuntimeVersion(v130, v120) <= 0 {
		t.Fatal("expected v1.3.0 > v1.2.0")
	}
	if ComparePluginRuntimeVersion(v120, v120) != 0 {
		t.Fatal("expected same versions equal")
	}

	id := NewPluginCompatibilityStateID()
	if !strings.HasPrefix(id, "plugin_compat_") {
		t.Fatalf("unexpected compatibility state id %s", id)
	}
}
