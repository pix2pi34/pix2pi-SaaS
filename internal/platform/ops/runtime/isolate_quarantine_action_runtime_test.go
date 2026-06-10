package opsruntime

import (
	"strings"
	"testing"
)

func isolateQuarantineTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord) {
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

func TestIsolateQuarantineActionRuntimeRequestsIsolate(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	action, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:      "tenant_7",
		InstanceID:    instance.InstanceID,
		ActionType:    IsolateQuarantineActionTypeIsolate,
		OperatorID:    "ops_1",
		OperatorRole:  OperatorRoleOpsAdmin,
		Reason:        "suspected noisy instance",
		CorrelationID: "corr-isolate-1",
	})
	if err != nil {
		t.Fatalf("request isolate failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected isolate allowed, got reason=%s", decision.Reason)
	}
	if action.ActionType != IsolateQuarantineActionTypeIsolate {
		t.Fatalf("expected ISOLATE, got %s", action.ActionType)
	}
	if action.ActionState != IsolateQuarantineStateIsolateRequested {
		t.Fatalf("expected ISOLATE_REQUESTED, got %s", action.ActionState)
	}

	metadata, err := registry.GetMetadata("tenant_7", instance.InstanceID, "isolate_quarantine_action_id")
	if err != nil {
		t.Fatalf("expected action metadata: %v", err)
	}
	if metadata.Value != action.ActionID {
		t.Fatalf("expected metadata action id %s, got %s", action.ActionID, metadata.Value)
	}

	events, err := runtime.ListTenantAuditEvents("tenant_7")
	if err != nil {
		t.Fatalf("list audit failed: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("expected audit count 1, got %d", len(events))
	}
	if events[0].EventType != IsolateQuarantineAuditEventRequested {
		t.Fatalf("expected requested event, got %s", events[0].EventType)
	}
}

func TestIsolateQuarantineActionRuntimeRequestsQuarantine(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	action, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeQuarantine,
		OperatorID:   "sre_1",
		OperatorRole: OperatorRoleSRE,
	})
	if err != nil {
		t.Fatalf("request quarantine failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected quarantine allowed, got reason=%s", decision.Reason)
	}
	if action.ActionState != IsolateQuarantineStateQuarantineRequested {
		t.Fatalf("expected QUARANTINE_REQUESTED, got %s", action.ActionState)
	}
}

func TestIsolateQuarantineActionRuntimeRejectsMissingTenant(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeIsolate,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIsolateQuarantineMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != IsolateQuarantineReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestIsolateQuarantineActionRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), nil)

	_, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   "instance_1",
		ActionType:   IsolateQuarantineActionTypeIsolate,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIsolateQuarantineMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != IsolateQuarantineReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestIsolateQuarantineActionRuntimeRejectsInvalidActionType(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		ActionType:   "DELETE",
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIsolateQuarantineInvalidActionType {
		t.Fatalf("expected invalid action type error, got %v", err)
	}
	if decision.Reason != IsolateQuarantineReasonInvalidActionType {
		t.Fatalf("expected invalid action reason, got %s", decision.Reason)
	}
}

func TestIsolateQuarantineActionRuntimeRejectsUnauthorizedOperator(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeIsolate,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrIsolateQuarantineUnauthorizedOperator {
		t.Fatalf("expected unauthorized operator error, got %v", err)
	}
	if decision.Reason != IsolateQuarantineReasonUnauthorizedOperator {
		t.Fatalf("expected unauthorized reason, got %s", decision.Reason)
	}
}

func TestIsolateQuarantineActionRuntimeRejectsCrossTenantInstance(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	_, decision, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_8",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeIsolate,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIsolateQuarantineCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != IsolateQuarantineReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestIsolateQuarantineActionRuntimeTenantSafeActionAccess(t *testing.T) {
	registry, instance := isolateQuarantineTestRegistry(t)
	runtime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)

	action, _, err := runtime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeQuarantine,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != nil {
		t.Fatalf("request quarantine failed: %v", err)
	}

	got, err := runtime.GetAction("tenant_7", action.ActionID)
	if err != nil {
		t.Fatalf("get action failed: %v", err)
	}
	if got.ActionID != action.ActionID {
		t.Fatalf("expected action id %s, got %s", action.ActionID, got.ActionID)
	}

	_, err = runtime.GetAction("tenant_8", action.ActionID)
	if err != ErrIsolateQuarantineCrossTenant {
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

func TestIsolateQuarantineStateForType(t *testing.T) {
	if IsolateQuarantineStateForType(IsolateQuarantineActionTypeIsolate) != IsolateQuarantineStateIsolateRequested {
		t.Fatal("expected isolate state")
	}
	if IsolateQuarantineStateForType(IsolateQuarantineActionTypeQuarantine) != IsolateQuarantineStateQuarantineRequested {
		t.Fatal("expected quarantine state")
	}
	if IsolateQuarantineStateForType("DELETE") != IsolateQuarantineStateDenied {
		t.Fatal("expected denied state")
	}
}

func TestIsolateQuarantineActionRuntimeIDGenerators(t *testing.T) {
	actionID := NewIsolateQuarantineActionID()
	auditID := NewIsolateQuarantineAuditEventID()

	if !strings.HasPrefix(actionID, "isolate_quarantine_action_") {
		t.Fatalf("unexpected action id %s", actionID)
	}
	if !strings.HasPrefix(auditID, "isolate_quarantine_audit_") {
		t.Fatalf("unexpected audit id %s", auditID)
	}
}
