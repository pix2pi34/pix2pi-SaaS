package opsruntime

import "testing"

func registryVisibilityTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord, ServiceInstanceRecord) {
	t.Helper()

	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	tenant7Instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Host:        "10.0.0.7",
		Port:        9001,
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_7 instance failed: %v", err)
	}

	tenant8Instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_8",
		ServiceName: "api-gateway",
		Host:        "10.0.0.8",
		Port:        9010,
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_8 instance failed: %v", err)
	}

	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: tenant7Instance.InstanceID,
		Key:        "tenant_key",
		Value:      "tenant-visible",
		Visibility: InstanceMetadataVisibilityTenant,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: tenant7Instance.InstanceID,
		Key:        "platform_key",
		Value:      "platform-visible",
		Visibility: InstanceMetadataVisibilityPlatform,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: tenant7Instance.InstanceID,
		Key:        "internal_key",
		Value:      "internal-visible",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_8",
		InstanceID: tenant8Instance.InstanceID,
		Key:        "tenant_key",
		Value:      "other-tenant",
		Visibility: InstanceMetadataVisibilityTenant,
	})

	return registry, tenant7Instance, tenant8Instance
}

func TestRegistryVisibilityRuntimeTenantScopeFiltersTenantMetadata(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	result, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_7",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != nil {
		t.Fatalf("tenant visibility failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected tenant visibility allowed, got reason=%s", decision.Reason)
	}
	if result.EntryCount != 1 {
		t.Fatalf("expected entry count 1, got %d", result.EntryCount)
	}
	if result.MetadataCount != 1 {
		t.Fatalf("expected tenant metadata count 1, got %d", result.MetadataCount)
	}
	if result.Entries[0].Metadata[0].Visibility != InstanceMetadataVisibilityTenant {
		t.Fatalf("expected TENANT visibility, got %s", result.Entries[0].Metadata[0].Visibility)
	}
}

func TestRegistryVisibilityRuntimePlatformScopeIncludesPlatformMetadata(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	result, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopePlatform,
		ActorRef:       "ops-panel",
	})
	if err != nil {
		t.Fatalf("platform visibility failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected platform visibility allowed, got reason=%s", decision.Reason)
	}
	if result.EntryCount != 1 {
		t.Fatalf("expected entry count 1, got %d", result.EntryCount)
	}
	if result.MetadataCount != 2 {
		t.Fatalf("expected platform metadata count 2, got %d", result.MetadataCount)
	}
}

func TestRegistryVisibilityRuntimeInternalScopeIncludesInternalMetadata(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	result, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopeInternal,
	})
	if err != nil {
		t.Fatalf("internal visibility failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected internal visibility allowed, got reason=%s", decision.Reason)
	}
	if result.MetadataCount != 3 {
		t.Fatalf("expected internal metadata count 3, got %d", result.MetadataCount)
	}
}

func TestRegistryVisibilityRuntimeRejectsCrossTenantTenantScope(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != ErrRegistryVisibilityCrossTenantDenied {
		t.Fatalf("expected cross tenant denied, got %v", err)
	}
	if decision.Reason != RegistryVisibilityReasonCrossTenantDenied {
		t.Fatalf("expected cross tenant denied reason, got %s", decision.Reason)
	}
}

func TestRegistryVisibilityRuntimeRejectsMissingTenant(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		ViewerTenantID: "tenant_7",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != ErrRegistryVisibilityMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != RegistryVisibilityReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestRegistryVisibilityRuntimeRejectsMissingViewer(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID: "tenant_7",
		Scope:    RegistryVisibilityScopeTenant,
	})
	if err != ErrRegistryVisibilityMissingViewer {
		t.Fatalf("expected missing viewer error, got %v", err)
	}
	if decision.Reason != RegistryVisibilityReasonMissingViewer {
		t.Fatalf("expected missing viewer reason, got %s", decision.Reason)
	}
}

func TestRegistryVisibilityRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), nil)

	_, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_7",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != ErrRegistryVisibilityMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != RegistryVisibilityReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestRegistryVisibilityRuntimeRejectsInvalidScope(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, decision, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_7",
		Scope:          "PUBLIC",
	})
	if err != ErrRegistryVisibilityInvalidScope {
		t.Fatalf("expected invalid scope error, got %v", err)
	}
	if decision.Reason != RegistryVisibilityReasonInvalidScope {
		t.Fatalf("expected invalid scope reason, got %s", decision.Reason)
	}
}

func TestRegistryVisibilityRuntimeDoesNotLeakOtherTenantInstances(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	result, _, err := runtime.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopeInternal,
	})
	if err != nil {
		t.Fatalf("internal visibility failed: %v", err)
	}
	if result.EntryCount != 1 {
		t.Fatalf("expected only tenant_7 entry count 1, got %d", result.EntryCount)
	}
	if result.Entries[0].TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 entry, got %s", result.Entries[0].TenantID)
	}
}

func TestRegistryVisibilityRuntimeCanView(t *testing.T) {
	registry, _, _ := registryVisibilityTestRegistry(t)
	runtime := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	if !runtime.CanView(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_7",
		Scope:          RegistryVisibilityScopeTenant,
	}) {
		t.Fatal("expected CanView true for same tenant")
	}

	if runtime.CanView(RegistryVisibilityRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
		Scope:          RegistryVisibilityScopeTenant,
	}) {
		t.Fatal("expected CanView false for cross tenant tenant scope")
	}
}

func TestRegistryVisibilityMetadataAllowed(t *testing.T) {
	if !registryVisibilityMetadataAllowed(InstanceMetadataVisibilityTenant, []string{InstanceMetadataVisibilityTenant}) {
		t.Fatal("expected tenant metadata allowed")
	}
	if registryVisibilityMetadataAllowed(InstanceMetadataVisibilityInternal, []string{InstanceMetadataVisibilityTenant}) {
		t.Fatal("expected internal metadata denied for tenant-only visibility")
	}
}
