package opsruntime

import (
	"strings"
	"testing"
)

func restartActionTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord) {
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

func TestRestartActionRuntimeRequestsRestart(t *testing.T) {
	registry, instance := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	action, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:      "tenant_7",
		InstanceID:    instance.InstanceID,
		OperatorID:    "ops_1",
		OperatorRole:  OperatorRoleOpsAdmin,
		Reason:        "deploy refresh",
		CorrelationID: "corr-restart-1",
	})
	if err != nil {
		t.Fatalf("request restart failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected restart allowed, got reason=%s", decision.Reason)
	}
	if action.ActionID == "" {
		t.Fatal("expected action id")
	}
	if action.ActionState != RestartActionStateRequested {
		t.Fatalf("expected RESTART_REQUESTED, got %s", action.ActionState)
	}
	if action.PreviousStatus != ServiceInstanceStatusHealthy {
		t.Fatalf("expected previous status HEALTHY, got %s", action.PreviousStatus)
	}

	metadata, err := registry.GetMetadata("tenant_7", instance.InstanceID, "restart_action_id")
	if err != nil {
		t.Fatalf("expected restart_action_id metadata: %v", err)
	}
	if metadata.Value != action.ActionID {
		t.Fatalf("expected metadata action id %s, got %s", action.ActionID, metadata.Value)
	}

	events, err := runtime.ListTenantAuditEvents("tenant_7")
	if err != nil {
		t.Fatalf("list audit failed: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected audit event count 1, got %d", len(events))
	}
	if events[0].EventType != RestartActionAuditEventRequested {
		t.Fatalf("expected requested audit event, got %s", events[0].EventType)
	}
}

func TestRestartActionRuntimeRejectsMissingTenant(t *testing.T) {
	registry, instance := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != RestartActionReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), nil)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   "instance_1",
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != RestartActionReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeRejectsUnauthorizedOperator(t *testing.T) {
	registry, instance := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrRestartActionUnauthorizedOperator {
		t.Fatalf("expected unauthorized operator error, got %v", err)
	}
	if decision.Reason != RestartActionReasonUnauthorizedOperator {
		t.Fatalf("expected unauthorized reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeRejectsCrossTenantInstance(t *testing.T) {
	registry, instance := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_8",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != RestartActionReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeRejectsInstanceNotFound(t *testing.T) {
	registry, _ := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   "instance_missing",
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionInstanceNotFound {
		t.Fatalf("expected instance not found error, got %v", err)
	}
	if decision.Reason != RestartActionReasonInstanceNotFound {
		t.Fatalf("expected instance not found reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeRejectsNonRestartableStatus(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Status:      ServiceInstanceStatusRegistered,
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionStatusNotRestartable {
		t.Fatalf("expected status not restartable error, got %v", err)
	}
	if decision.Reason != RestartActionReasonStatusNotRestartable {
		t.Fatalf("expected status not restartable reason, got %s", decision.Reason)
	}
}

func TestRestartActionRuntimeTenantSafeActionAccess(t *testing.T) {
	registry, instance := restartActionTestRegistry(t)
	runtime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)

	action, _, err := runtime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleSRE,
	})
	if err != nil {
		t.Fatalf("request restart failed: %v", err)
	}

	got, err := runtime.GetAction("tenant_7", action.ActionID)
	if err != nil {
		t.Fatalf("get action failed: %v", err)
	}
	if got.ActionID != action.ActionID {
		t.Fatalf("expected action id %s, got %s", action.ActionID, got.ActionID)
	}

	_, err = runtime.GetAction("tenant_8", action.ActionID)
	if err != ErrRestartActionCrossTenant {
		t.Fatalf("expected cross tenant get action error, got %v", err)
	}

	tenant7Actions, err := runtime.ListTenantActions("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 actions failed: %v", err)
	}
	if len(tenant7Actions) != 1 {
		t.Fatalf("expected tenant_7 action count 1, got %d", len(tenant7Actions))
	}

	tenant8Actions, err := runtime.ListTenantActions("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 actions failed: %v", err)
	}
	if len(tenant8Actions) != 0 {
		t.Fatalf("expected tenant_8 action count 0, got %d", len(tenant8Actions))
	}
}

func TestRestartActionRuntimeIDGenerators(t *testing.T) {
	actionID := NewRestartActionID()
	auditID := NewRestartActionAuditEventID()

	if !strings.HasPrefix(actionID, "restart_action_") {
		t.Fatalf("unexpected action id %s", actionID)
	}
	if !strings.HasPrefix(auditID, "restart_audit_") {
		t.Fatalf("unexpected audit id %s", auditID)
	}
}
