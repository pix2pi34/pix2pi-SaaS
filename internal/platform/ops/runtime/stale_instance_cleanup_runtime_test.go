package opsruntime

import (
	"testing"
	"time"
)

func staleCleanupTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord, ServiceInstanceRecord) {
	t.Helper()

	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	staleInstance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register stale instance failed: %v", err)
	}

	freshInstance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "api-gateway",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register fresh instance failed: %v", err)
	}

	return registry, staleInstance, freshInstance
}

func TestStaleInstanceCleanupRuntimeDetectsStaleInstances(t *testing.T) {
	registry, staleInstance, freshInstance := staleCleanupTestRegistry(t)

	now := time.Date(2026, 5, 7, 1, 30, 0, 0, time.UTC)

	registry.mu.Lock()
	staleRecord := registry.instances[serviceInstanceKey("tenant_7", staleInstance.InstanceID)]
	staleRecord.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_7", staleInstance.InstanceID)] = staleRecord

	freshRecord := registry.instances[serviceInstanceKey("tenant_7", freshInstance.InstanceID)]
	freshRecord.UpdatedAt = now.Add(-30 * time.Second).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_7", freshInstance.InstanceID)] = freshRecord
	registry.mu.Unlock()

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	result, decision, err := cleanup.DetectStaleInstances(StaleInstanceCleanupRequest{
		TenantID: "tenant_7",
		Now:      now,
	})
	if err != nil {
		t.Fatalf("detect stale failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected detect allowed, got reason=%s", decision.Reason)
	}
	if result.CheckedCount != 2 {
		t.Fatalf("expected checked count 2, got %d", result.CheckedCount)
	}
	if result.StaleCandidateCount != 1 {
		t.Fatalf("expected stale candidate count 1, got %d", result.StaleCandidateCount)
	}
	if result.MarkedStaleCount != 0 {
		t.Fatalf("detect should not mutate, got marked stale count %d", result.MarkedStaleCount)
	}
}

func TestStaleInstanceCleanupRuntimeMarksStaleAndDeletesInternalMetadata(t *testing.T) {
	registry, staleInstance, _ := staleCleanupTestRegistry(t)

	now := time.Date(2026, 5, 7, 1, 30, 0, 0, time.UTC)

	registry.mu.Lock()
	staleRecord := registry.instances[serviceInstanceKey("tenant_7", staleInstance.InstanceID)]
	staleRecord.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_7", staleInstance.InstanceID)] = staleRecord
	registry.mu.Unlock()

	_, _, err := registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: staleInstance.InstanceID,
		Key:        "internal_note",
		Value:      "delete-me",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	if err != nil {
		t.Fatalf("upsert internal metadata failed: %v", err)
	}

	_, _, err = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: staleInstance.InstanceID,
		Key:        "build_sha",
		Value:      "keep-me",
		Visibility: InstanceMetadataVisibilityTenant,
	})
	if err != nil {
		t.Fatalf("upsert tenant metadata failed: %v", err)
	}

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	result, decision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID:      "tenant_7",
		Now:           now,
		ActorRef:      "ops-cleanup",
		CorrelationID: "cleanup-1",
	})
	if err != nil {
		t.Fatalf("run cleanup failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected cleanup allowed, got reason=%s", decision.Reason)
	}
	if result.MarkedStaleCount != 1 {
		t.Fatalf("expected marked stale count 1, got %d", result.MarkedStaleCount)
	}
	if result.DeletedMetadataCount != 1 {
		t.Fatalf("expected deleted metadata count 1, got %d", result.DeletedMetadataCount)
	}

	updated, err := registry.GetMetadata("tenant_7", staleInstance.InstanceID, "build_sha")
	if err != nil {
		t.Fatalf("tenant metadata should remain: %v", err)
	}
	if updated.Value != "keep-me" {
		t.Fatalf("expected tenant metadata keep-me, got %s", updated.Value)
	}

	_, err = registry.GetMetadata("tenant_7", staleInstance.InstanceID, "internal_note")
	if err != ErrInstanceMetadataMissingKey {
		t.Fatalf("expected internal metadata deleted, got %v", err)
	}

	instances, err := registry.ListTenantInstances("tenant_7")
	if err != nil {
		t.Fatalf("list tenant instances failed: %v", err)
	}

	foundStale := false
	for _, instance := range instances {
		if instance.InstanceID == staleInstance.InstanceID && instance.Status == ServiceInstanceStatusStale {
			foundStale = true
		}
	}
	if !foundStale {
		t.Fatal("expected stale instance status to be STALE")
	}
}

func TestStaleInstanceCleanupRuntimeRejectsMissingTenant(t *testing.T) {
	registry, _, _ := staleCleanupTestRegistry(t)
	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	_, decision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{})
	if err != ErrStaleInstanceCleanupMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != StaleInstanceCleanupReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestStaleInstanceCleanupRuntimeRejectsMissingRegistry(t *testing.T) {
	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), nil)

	_, decision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID: "tenant_7",
	})
	if err != ErrStaleInstanceCleanupMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != StaleInstanceCleanupReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestStaleInstanceCleanupRuntimeRejectsInvalidThreshold(t *testing.T) {
	registry, _, _ := staleCleanupTestRegistry(t)

	config := DefaultStaleInstanceCleanupRuntimeConfig()
	config.StaleAfterSeconds = -1

	cleanup := NewStaleInstanceCleanupRuntime(config, registry)

	_, decision, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID: "tenant_7",
	})
	if err != ErrStaleInstanceCleanupInvalidThreshold {
		t.Fatalf("expected invalid threshold error, got %v", err)
	}
	if decision.Reason != StaleInstanceCleanupReasonInvalidThreshold {
		t.Fatalf("expected invalid threshold reason, got %s", decision.Reason)
	}
}

func TestStaleInstanceCleanupRuntimeTenantSafeCleanup(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	tenant7Instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_7 failed: %v", err)
	}

	tenant8Instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_8",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register tenant_8 failed: %v", err)
	}

	now := time.Date(2026, 5, 7, 1, 30, 0, 0, time.UTC)

	registry.mu.Lock()
	record7 := registry.instances[serviceInstanceKey("tenant_7", tenant7Instance.InstanceID)]
	record7.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_7", tenant7Instance.InstanceID)] = record7

	record8 := registry.instances[serviceInstanceKey("tenant_8", tenant8Instance.InstanceID)]
	record8.UpdatedAt = now.Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_8", tenant8Instance.InstanceID)] = record8
	registry.mu.Unlock()

	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	result, _, err := cleanup.RunCleanup(StaleInstanceCleanupRequest{
		TenantID: "tenant_7",
		Now:      now,
	})
	if err != nil {
		t.Fatalf("tenant_7 cleanup failed: %v", err)
	}
	if result.CheckedCount != 1 {
		t.Fatalf("expected tenant_7 checked count 1, got %d", result.CheckedCount)
	}
	if result.MarkedStaleCount != 1 {
		t.Fatalf("expected tenant_7 marked stale count 1, got %d", result.MarkedStaleCount)
	}

	tenant8Instances, err := registry.ListTenantInstances("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 failed: %v", err)
	}
	if len(tenant8Instances) != 1 {
		t.Fatalf("expected tenant_8 instance count 1, got %d", len(tenant8Instances))
	}
	if tenant8Instances[0].Status != ServiceInstanceStatusHealthy {
		t.Fatalf("expected tenant_8 to remain HEALTHY, got %s", tenant8Instances[0].Status)
	}
}

func TestCleanupVisibilityAllowed(t *testing.T) {
	if !cleanupVisibilityAllowed(InstanceMetadataVisibilityInternal, []string{InstanceMetadataVisibilityInternal}) {
		t.Fatal("expected internal cleanup visibility allowed")
	}
	if cleanupVisibilityAllowed(InstanceMetadataVisibilityTenant, []string{InstanceMetadataVisibilityInternal}) {
		t.Fatal("expected tenant visibility not allowed for cleanup")
	}
}
