package opsruntime

import (
	"testing"
	"time"
)

func serviceStatusPanelRuntimeForTest(t *testing.T) (*ServiceStatusPanelConnectionRuntime, *InstanceMetadataRuntime, ServiceInstanceRecord) {
	t.Helper()

	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Host:        "10.0.0.7",
		Port:        9001,
		Zone:        "tr-istanbul-1",
		NodeID:      "node-a",
		Runtime:     "go",
		Version:     "1.0.0",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)
	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)
	panel := NewServiceStatusPanelConnectionRuntime(DefaultServiceStatusPanelConnectionRuntimeConfig(), registry, visibility, cleanup)

	return panel, registry, instance
}

func TestServiceStatusPanelConnectionRuntimeBuildsPanelSnapshot(t *testing.T) {
	panel, registry, instance := serviceStatusPanelRuntimeForTest(t)

	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "last_heartbeat_at",
		Value:      "2026-05-07T07:20:00Z",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "health_status",
		Value:      "ok",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "restart_action_id",
		Value:      "restart_action_1",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "isolate_quarantine_action_state",
		Value:      IsolateQuarantineStateQuarantineRequested,
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "maintenance_mode_state",
		Value:      MaintenanceModeStateEnabled,
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = registry.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "incident_action_log_id",
		Value:      "incident_action_log_1",
		Visibility: InstanceMetadataVisibilityInternal,
	})

	snapshot, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopeInternal,
		CorrelationID:  "corr-panel-1",
	})
	if err != nil {
		t.Fatalf("build panel snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected panel allowed, got reason=%s", decision.Reason)
	}
	if !snapshot.OK {
		t.Fatal("expected snapshot OK")
	}
	if snapshot.EntryCount != 1 {
		t.Fatalf("expected entry count 1, got %d", snapshot.EntryCount)
	}
	if snapshot.HealthyCount != 1 {
		t.Fatalf("expected healthy count 1, got %d", snapshot.HealthyCount)
	}
	if snapshot.RestartRequestedCount != 1 {
		t.Fatalf("expected restart requested count 1, got %d", snapshot.RestartRequestedCount)
	}
	if snapshot.QuarantineCount != 1 {
		t.Fatalf("expected quarantine count 1, got %d", snapshot.QuarantineCount)
	}
	if snapshot.MaintenanceCount != 1 {
		t.Fatalf("expected maintenance count 1, got %d", snapshot.MaintenanceCount)
	}
	if snapshot.IncidentTaggedCount != 1 {
		t.Fatalf("expected incident tagged count 1, got %d", snapshot.IncidentTaggedCount)
	}
	if snapshot.Entries[0].HealthStatus != "ok" {
		t.Fatalf("expected health status ok, got %s", snapshot.Entries[0].HealthStatus)
	}
	if len(snapshot.Entries[0].PanelTags) != 4 {
		t.Fatalf("expected 4 panel tags, got %d", len(snapshot.Entries[0].PanelTags))
	}
}

func TestServiceStatusPanelConnectionRuntimeTenantScopeCrossTenantDenied(t *testing.T) {
	panel, _, _ := serviceStatusPanelRuntimeForTest(t)

	_, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
		Scope:          RegistryVisibilityScopeTenant,
	})
	if err != ErrServiceStatusPanelCrossTenant {
		t.Fatalf("expected cross tenant panel error, got %v", err)
	}
	if decision.Reason != ServiceStatusPanelReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestServiceStatusPanelConnectionRuntimeRejectsMissingTenant(t *testing.T) {
	panel, _, _ := serviceStatusPanelRuntimeForTest(t)

	_, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		Scope: RegistryVisibilityScopeInternal,
	})
	if err != ErrServiceStatusPanelMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != ServiceStatusPanelReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestServiceStatusPanelConnectionRuntimeRejectsMissingRegistry(t *testing.T) {
	panel := NewServiceStatusPanelConnectionRuntime(DefaultServiceStatusPanelConnectionRuntimeConfig(), nil, nil, nil)

	_, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID: "tenant_7",
		Scope:    RegistryVisibilityScopeInternal,
	})
	if err != ErrServiceStatusPanelMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != ServiceStatusPanelReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestServiceStatusPanelConnectionRuntimeRejectsMissingVisibility(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	panel := NewServiceStatusPanelConnectionRuntime(DefaultServiceStatusPanelConnectionRuntimeConfig(), registry, nil, nil)

	_, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID: "tenant_7",
		Scope:    RegistryVisibilityScopeInternal,
	})
	if err != ErrServiceStatusPanelMissingVisibility {
		t.Fatalf("expected missing visibility error, got %v", err)
	}
	if decision.Reason != ServiceStatusPanelReasonMissingVisibility {
		t.Fatalf("expected missing visibility reason, got %s", decision.Reason)
	}
}

func TestServiceStatusPanelConnectionRuntimeRejectsInvalidScope(t *testing.T) {
	panel, _, _ := serviceStatusPanelRuntimeForTest(t)

	_, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID: "tenant_7",
		Scope:    "PUBLIC",
	})
	if err != ErrServiceStatusPanelInvalidScope {
		t.Fatalf("expected invalid scope error, got %v", err)
	}
	if decision.Reason != ServiceStatusPanelReasonInvalidScope {
		t.Fatalf("expected invalid scope reason, got %s", decision.Reason)
	}
}

func TestServiceStatusPanelConnectionRuntimeStaleBridge(t *testing.T) {
	panel, registry, instance := serviceStatusPanelRuntimeForTest(t)

	registry.mu.Lock()
	record := registry.instances[serviceInstanceKey("tenant_7", instance.InstanceID)]
	record.UpdatedAt = time.Now().UTC().Add(-5 * time.Minute).Format(time.RFC3339Nano)
	registry.instances[serviceInstanceKey("tenant_7", instance.InstanceID)] = record
	registry.mu.Unlock()

	snapshot, decision, err := panel.BuildPanelSnapshot(ServiceStatusPanelRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "platform",
		Scope:          RegistryVisibilityScopeInternal,
	})
	if err != nil {
		t.Fatalf("build panel snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected panel allowed, got reason=%s", decision.Reason)
	}
	if snapshot.StaleCandidateCount != 1 {
		t.Fatalf("expected stale candidate count 1, got %d", snapshot.StaleCandidateCount)
	}
}

func TestBuildServiceStatusPanelTags(t *testing.T) {
	tags := buildServiceStatusPanelTags(ServiceStatusPanelEntry{
		RestartActionID:        "restart_action_1",
		IsolateQuarantineState: IsolateQuarantineStateIsolateRequested,
		MaintenanceModeState:   MaintenanceModeStateEnabled,
		IncidentActionLogID:    "incident_action_log_1",
	})
	if len(tags) != 4 {
		t.Fatalf("expected 4 tags, got %d", len(tags))
	}
}

func TestIsServiceStatusPanelScopeValid(t *testing.T) {
	if !isServiceStatusPanelScopeValid(RegistryVisibilityScopeTenant) {
		t.Fatal("expected TENANT scope valid")
	}
	if !isServiceStatusPanelScopeValid(RegistryVisibilityScopePlatform) {
		t.Fatal("expected PLATFORM scope valid")
	}
	if !isServiceStatusPanelScopeValid(RegistryVisibilityScopeInternal) {
		t.Fatal("expected INTERNAL scope valid")
	}
	if isServiceStatusPanelScopeValid("PUBLIC") {
		t.Fatal("expected PUBLIC scope invalid")
	}
}
