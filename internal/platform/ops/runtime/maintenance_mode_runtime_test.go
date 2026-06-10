package opsruntime

import (
	"strings"
	"testing"
)

func maintenanceModeTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord) {
	t.Helper()

	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Host:        "10.0.0.7",
		Port:        9001,
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	return registry, instance
}

func TestMaintenanceModeRuntimeEnablesMaintenanceMode(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	record, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:      "tenant_7",
		InstanceID:    instance.InstanceID,
		Action:        MaintenanceModeActionEnable,
		OperatorID:    "ops_1",
		OperatorRole:  OperatorRoleOpsAdmin,
		Reason:        "planned deploy",
		CorrelationID: "corr-maintenance-1",
	})
	if err != nil {
		t.Fatalf("enable maintenance failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected maintenance allowed, got reason=%s", decision.Reason)
	}
	if record.ModeState != MaintenanceModeStateEnabled {
		t.Fatalf("expected MAINTENANCE_ENABLED, got %s", record.ModeState)
	}
	if record.MaintenanceID == "" {
		t.Fatal("expected maintenance id")
	}

	metadata, err := registry.GetMetadata("tenant_7", instance.InstanceID, "maintenance_mode_state")
	if err != nil {
		t.Fatalf("expected maintenance metadata: %v", err)
	}
	if metadata.Value != MaintenanceModeStateEnabled {
		t.Fatalf("expected metadata state enabled, got %s", metadata.Value)
	}

	events, err := runtime.ListTenantMaintenanceAuditEvents("tenant_7")
	if err != nil {
		t.Fatalf("list audit failed: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected audit count 1, got %d", len(events))
	}
	if events[0].EventType != MaintenanceModeAuditEventEnabled {
		t.Fatalf("expected enabled event, got %s", events[0].EventType)
	}
}

func TestMaintenanceModeRuntimeDisablesMaintenanceMode(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	record, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionDisable,
		OperatorID:   "sre_1",
		OperatorRole: OperatorRoleSRE,
	})
	if err != nil {
		t.Fatalf("disable maintenance failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected maintenance disable allowed, got reason=%s", decision.Reason)
	}
	if record.ModeState != MaintenanceModeStateDisabled {
		t.Fatalf("expected MAINTENANCE_DISABLED, got %s", record.ModeState)
	}
}

func TestMaintenanceModeRuntimeRejectsMissingTenant(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	_, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrMaintenanceModeMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != MaintenanceModeReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestMaintenanceModeRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), nil)

	_, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_7",
		InstanceID:   "instance_1",
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrMaintenanceModeMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != MaintenanceModeReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestMaintenanceModeRuntimeRejectsInvalidAction(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	_, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		Action:       "PAUSE",
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrMaintenanceModeInvalidAction {
		t.Fatalf("expected invalid action error, got %v", err)
	}
	if decision.Reason != MaintenanceModeReasonInvalidAction {
		t.Fatalf("expected invalid action reason, got %s", decision.Reason)
	}
}

func TestMaintenanceModeRuntimeRejectsUnauthorizedOperator(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	_, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrMaintenanceModeUnauthorizedOperator {
		t.Fatalf("expected unauthorized operator error, got %v", err)
	}
	if decision.Reason != MaintenanceModeReasonUnauthorizedOperator {
		t.Fatalf("expected unauthorized reason, got %s", decision.Reason)
	}
}

func TestMaintenanceModeRuntimeRejectsCrossTenantInstance(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	_, decision, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_8",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrMaintenanceModeCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != MaintenanceModeReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestMaintenanceModeRuntimeTenantSafeRecordAccess(t *testing.T) {
	registry, instance := maintenanceModeTestRegistry(t)
	runtime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)

	record, _, err := runtime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != nil {
		t.Fatalf("enable maintenance failed: %v", err)
	}

	got, err := runtime.GetMaintenanceRecord("tenant_7", record.MaintenanceID)
	if err != nil {
		t.Fatalf("get maintenance record failed: %v", err)
	}
	if got.MaintenanceID != record.MaintenanceID {
		t.Fatalf("expected maintenance id %s, got %s", record.MaintenanceID, got.MaintenanceID)
	}

	_, err = runtime.GetMaintenanceRecord("tenant_8", record.MaintenanceID)
	if err != ErrMaintenanceModeCrossTenant {
		t.Fatalf("expected cross tenant get record error, got %v", err)
	}

	tenant7Records, err := runtime.ListTenantMaintenanceRecords("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 records failed: %v", err)
	}
	if len(tenant7Records) != 1 {
		t.Fatalf("expected tenant_7 record count 1, got %d", len(tenant7Records))
	}

	tenant8Records, err := runtime.ListTenantMaintenanceRecords("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 records failed: %v", err)
	}
	if len(tenant8Records) != 0 {
		t.Fatalf("expected tenant_8 record count 0, got %d", len(tenant8Records))
	}
}

func TestMaintenanceModeStateForAction(t *testing.T) {
	if MaintenanceModeStateForAction(MaintenanceModeActionEnable) != MaintenanceModeStateEnabled {
		t.Fatal("expected enabled state")
	}
	if MaintenanceModeStateForAction(MaintenanceModeActionDisable) != MaintenanceModeStateDisabled {
		t.Fatal("expected disabled state")
	}
	if MaintenanceModeStateForAction("PAUSE") != MaintenanceModeStateDenied {
		t.Fatal("expected denied state")
	}
}

func TestMaintenanceModeRuntimeIDGenerators(t *testing.T) {
	maintenanceID := NewMaintenanceModeID()
	auditID := NewMaintenanceModeAuditEventID()

	if !strings.HasPrefix(maintenanceID, "maintenance_mode_") {
		t.Fatalf("unexpected maintenance id %s", maintenanceID)
	}
	if !strings.HasPrefix(auditID, "maintenance_audit_") {
		t.Fatalf("unexpected audit id %s", auditID)
	}
}
