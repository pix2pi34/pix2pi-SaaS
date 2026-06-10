package opsruntime

import (
	"testing"
	"time"
)

func TestRegistryRuntimeFinalIntegrationFlow(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, metadataDecision, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:      "tenant_final",
		ServiceName:   "identity-api",
		Host:          "10.0.0.11",
		Port:          9001,
		Zone:          "tr-istanbul-1",
		NodeID:        "node-final-a",
		Runtime:       "go",
		Version:       "1.0.0",
		Status:        ServiceInstanceStatusHealthy,
		CorrelationID: "corr_final_register",
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}
	if !metadataDecision.Allowed {
		t.Fatalf("expected register decision allowed, got reason=%s", metadataDecision.Reason)
	}
	if instance.InstanceID == "" {
		t.Fatal("expected instance id")
	}

	_, _, err = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:      "tenant_final",
		InstanceID:    instance.InstanceID,
		Key:           "build_sha",
		Value:         "abc-final",
		Visibility:    InstanceMetadataVisibilityTenant,
		Source:        "deploy",
		CorrelationID: "corr_final_meta_tenant",
	})
	if err != nil {
		t.Fatalf("upsert tenant metadata failed: %v", err)
	}

	_, _, err = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:      "tenant_final",
		InstanceID:    instance.InstanceID,
		Key:           "node_pool",
		Value:         "pool-a",
		Visibility:    InstanceMetadataVisibilityPlatform,
		Source:        "orchestrator",
		CorrelationID: "corr_final_meta_platform",
	})
	if err != nil {
		t.Fatalf("upsert platform metadata failed: %v", err)
	}

	_, _, err = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:      "tenant_final",
		InstanceID:    instance.InstanceID,
		Key:           "internal_note",
		Value:         "cleanup-target",
		Visibility:    InstanceMetadataVisibilityInternal,
		Source:        "ops",
		CorrelationID: "corr_final_meta_internal",
	})
	if err != nil {
		t.Fatalf("upsert internal metadata failed: %v", err)
	}

	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	tenantView, visibilityDecision, err := visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_final",
		ViewerTenantID: "tenant_final",
		Scope:          RegistryVisibilityScopeTenant,
		ActorRef:       "tenant-user",
		CorrelationID:  "corr_final_visibility_tenant",
	})
	if err != nil {
		t.Fatalf("tenant registry visibility failed: %v", err)
	}
	if !visibilityDecision.Allowed {
		t.Fatalf("expected tenant visibility allowed, got reason=%s", visibilityDecision.Reason)
	}
	if tenantView.EntryCount != 1 {
		t.Fatalf("expected tenant view entry count 1, got %d", tenantView.EntryCount)
	}
	if tenantView.MetadataCount != 1 {
		t.Fatalf("expected tenant metadata count 1, got %d", tenantView.MetadataCount)
	}

	now := time.Date(2026, 5, 7, 7, 10, 0, 0, time.UTC)

	registry.mu.Lock()
	staleRecord := registry.instances[serviceInstanceKey("tenant_final", instance.InstanceID)]
	staleRecord.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_final", instance.InstanceID)] = staleRecord
	registry.mu.Unlock()

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	cleanupResult, cleanupDecision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID:      "tenant_final",
		Now:           now,
		ActorRef:      "ops-cleanup",
		CorrelationID: "corr_final_cleanup",
	})
	if err != nil {
		t.Fatalf("run cleanup failed: %v", err)
	}
	if !cleanupDecision.Allowed {
		t.Fatalf("expected cleanup allowed, got reason=%s", cleanupDecision.Reason)
	}
	if cleanupResult.CheckedCount != 1 {
		t.Fatalf("expected checked count 1, got %d", cleanupResult.CheckedCount)
	}
	if cleanupResult.StaleCandidateCount != 1 {
		t.Fatalf("expected stale candidate count 1, got %d", cleanupResult.StaleCandidateCount)
	}
	if cleanupResult.MarkedStaleCount != 1 {
		t.Fatalf("expected marked stale count 1, got %d", cleanupResult.MarkedStaleCount)
	}
	if cleanupResult.DeletedMetadataCount != 1 {
		t.Fatalf("expected deleted internal metadata count 1, got %d", cleanupResult.DeletedMetadataCount)
	}

	instances, err := registry.ListTenantInstances("tenant_final")
	if err != nil {
		t.Fatalf("list tenant instances failed: %v", err)
	}
	if len(instances) != 1 {
		t.Fatalf("expected tenant instance count 1, got %d", len(instances))
	}
	if instances[0].Status != ServiceInstanceStatusStale {
		t.Fatalf("expected instance status STALE, got %s", instances[0].Status)
	}

	internalView, internalDecision, err := visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_final",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopeInternal,
		ActorRef:       "ops-panel",
		CorrelationID:  "corr_final_visibility_internal",
	})
	if err != nil {
		t.Fatalf("internal registry visibility failed: %v", err)
	}
	if !internalDecision.Allowed {
		t.Fatalf("expected internal visibility allowed, got reason=%s", internalDecision.Reason)
	}
	if internalView.EntryCount != 1 {
		t.Fatalf("expected internal view entry count 1, got %d", internalView.EntryCount)
	}
	if internalView.MetadataCount != 2 {
		t.Fatalf("expected metadata count 2 after internal cleanup, got %d", internalView.MetadataCount)
	}
	if internalView.Entries[0].Status != ServiceInstanceStatusStale {
		t.Fatalf("expected visible status STALE, got %s", internalView.Entries[0].Status)
	}
}

func TestRegistryRuntimeFinalCrossTenantDenyFlow(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	tenantFinalInstance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_final",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_final instance failed: %v", err)
	}

	tenantOtherInstance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_other",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_other instance failed: %v", err)
	}

	_, metadataDecision, err := registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_other",
		InstanceID: tenantFinalInstance.InstanceID,
		Key:        "build_sha",
		Value:      "cross-tenant-write",
	})
	if err != ErrInstanceMetadataCrossTenant {
		t.Fatalf("expected cross tenant metadata write error, got %v", err)
	}
	if metadataDecision.Reason != InstanceMetadataReasonCrossTenant {
		t.Fatalf("expected cross tenant metadata reason, got %s", metadataDecision.Reason)
	}

	_, err = registry.GetMetadata("tenant_other", tenantFinalInstance.InstanceID, "build_sha")
	if err != ErrInstanceMetadataCrossTenant {
		t.Fatalf("expected cross tenant metadata read error, got %v", err)
	}

	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, visibilityDecision, err := visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_final",
		ViewerTenantID: "tenant_other",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != ErrRegistryVisibilityCrossTenantDenied {
		t.Fatalf("expected cross tenant visibility denied, got %v", err)
	}
	if visibilityDecision.Reason != RegistryVisibilityReasonCrossTenantDenied {
		t.Fatalf("expected visibility cross tenant reason, got %s", visibilityDecision.Reason)
	}

	now := time.Date(2026, 5, 7, 7, 10, 0, 0, time.UTC)

	registry.mu.Lock()
	recordFinal := registry.instances[serviceInstanceKey("tenant_final", tenantFinalInstance.InstanceID)]
	recordFinal.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_final", tenantFinalInstance.InstanceID)] = recordFinal

	recordOther := registry.instances[serviceInstanceKey("tenant_other", tenantOtherInstance.InstanceID)]
	recordOther.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_other", tenantOtherInstance.InstanceID)] = recordOther
	registry.mu.Unlock()

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	result, cleanupDecision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID:      "tenant_final",
		Now:           now,
		CorrelationID: "corr_cross_tenant_cleanup",
	})
	if err != nil {
		t.Fatalf("tenant_final cleanup failed: %v", err)
	}
	if !cleanupDecision.Allowed {
		t.Fatalf("expected tenant_final cleanup allowed, got reason=%s", cleanupDecision.Reason)
	}
	if result.CheckedCount != 1 {
		t.Fatalf("expected cleanup checked count 1, got %d", result.CheckedCount)
	}
	if result.MarkedStaleCount != 1 {
		t.Fatalf("expected tenant_final marked stale count 1, got %d", result.MarkedStaleCount)
	}

	tenantOtherInstances, err := registry.ListTenantInstances("tenant_other")
	if err != nil {
		t.Fatalf("list tenant_other instances failed: %v", err)
	}
	if len(tenantOtherInstances) != 1 {
		t.Fatalf("expected tenant_other instance count 1, got %d", len(tenantOtherInstances))
	}
	if tenantOtherInstances[0].Status != ServiceInstanceStatusHealthy {
		t.Fatalf("tenant_other should remain HEALTHY, got %s", tenantOtherInstances[0].Status)
	}
}

func TestRegistryRuntimeFinalDenyCases(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	_, registerDecision, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID: "tenant_final",
	})
	if err != ErrInstanceMetadataMissingService {
		t.Fatalf("expected missing service error, got %v", err)
	}
	if registerDecision.Reason != InstanceMetadataReasonMissingService {
		t.Fatalf("expected missing service reason, got %s", registerDecision.Reason)
	}

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), nil)

	_, cleanupDecision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID: "tenant_final",
	})
	if err != ErrStaleInstanceCleanupMissingRegistry {
		t.Fatalf("expected missing registry cleanup error, got %v", err)
	}
	if cleanupDecision.Reason != StaleInstanceCleanupReasonMissingRegistry {
		t.Fatalf("expected missing registry cleanup reason, got %s", cleanupDecision.Reason)
	}

	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)

	_, visibilityDecision, err := visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       "tenant_final",
		ViewerTenantID: "tenant_final",
		Scope:          "PUBLIC",
	})
	if err != ErrRegistryVisibilityInvalidScope {
		t.Fatalf("expected invalid visibility scope error, got %v", err)
	}
	if visibilityDecision.Reason != RegistryVisibilityReasonInvalidScope {
		t.Fatalf("expected invalid visibility scope reason, got %s", visibilityDecision.Reason)
	}
}
