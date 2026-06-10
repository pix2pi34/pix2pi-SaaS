package opsruntime

import (
	"strings"
	"testing"
)

func incidentActionLogTestRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord) {
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

func TestIncidentNoteActionLogRuntimeCreatesIncidentNote(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	record, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:      "tenant_7",
		InstanceID:    instance.InstanceID,
		OperatorID:    "ops_1",
		OperatorRole:  OperatorRoleOpsAdmin,
		Severity:      IncidentActionSeverityWarning,
		Message:       "CPU spike observed",
		CorrelationID: "corr-incident-1",
	})
	if err != nil {
		t.Fatalf("create incident note failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected incident note allowed, got reason=%s", decision.Reason)
	}
	if record.LogID == "" {
		t.Fatal("expected log id")
	}
	if record.ActionType != IncidentActionTypeNote {
		t.Fatalf("expected INCIDENT_NOTE, got %s", record.ActionType)
	}
	if record.Severity != IncidentActionSeverityWarning {
		t.Fatalf("expected WARNING, got %s", record.Severity)
	}

	metadata, err := registry.GetMetadata("tenant_7", instance.InstanceID, "incident_action_log_id")
	if err != nil {
		t.Fatalf("expected incident metadata: %v", err)
	}
	if metadata.Value != record.LogID {
		t.Fatalf("expected metadata log id %s, got %s", record.LogID, metadata.Value)
	}
}

func TestIncidentNoteActionLogRuntimeRecordsOperatorAction(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	record, decision, err := runtime.RecordIncidentAction(IncidentActionLogRequest{
		TenantID:        "tenant_7",
		InstanceID:      instance.InstanceID,
		ActionType:      IncidentActionTypeOperatorAction,
		OperatorID:      "sre_1",
		OperatorRole:    OperatorRoleSRE,
		Severity:        IncidentActionSeverityCritical,
		Message:         "Restart action requested after incident",
		RelatedActionID: "restart_action_1",
	})
	if err != nil {
		t.Fatalf("record operator action failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected operator action allowed, got reason=%s", decision.Reason)
	}
	if record.RelatedActionID != "restart_action_1" {
		t.Fatalf("expected related action id, got %s", record.RelatedActionID)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsMissingTenant(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Message:      "note",
	})
	if err != ErrIncidentActionLogMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), nil)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_7",
		InstanceID:   "instance_1",
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Message:      "note",
	})
	if err != ErrIncidentActionLogMissingRegistry {
		t.Fatalf("expected missing registry error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonMissingRegistry {
		t.Fatalf("expected missing registry reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsMissingMessage(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIncidentActionLogMissingMessage {
		t.Fatalf("expected missing message error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonMissingMessage {
		t.Fatalf("expected missing message reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsInvalidSeverity(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Severity:     "PANIC",
		Message:      "note",
	})
	if err != ErrIncidentActionLogInvalidSeverity {
		t.Fatalf("expected invalid severity error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonInvalidSeverity {
		t.Fatalf("expected invalid severity reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsUnauthorizedOperator(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
		Message:      "note",
	})
	if err != ErrIncidentActionLogUnauthorizedOperator {
		t.Fatalf("expected unauthorized operator error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonUnauthorizedOperator {
		t.Fatalf("expected unauthorized reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeRejectsCrossTenantInstance(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, decision, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_8",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Message:      "note",
	})
	if err != ErrIncidentActionLogCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != IncidentActionLogReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestIncidentNoteActionLogRuntimeTenantSafeLogAccess(t *testing.T) {
	registry, instance := incidentActionLogTestRegistry(t)
	runtime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	record, _, err := runtime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_7",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Message:      "note",
	})
	if err != nil {
		t.Fatalf("create incident note failed: %v", err)
	}

	got, err := runtime.GetIncidentActionLog("tenant_7", record.LogID)
	if err != nil {
		t.Fatalf("get incident log failed: %v", err)
	}
	if got.LogID != record.LogID {
		t.Fatalf("expected log id %s, got %s", record.LogID, got.LogID)
	}

	_, err = runtime.GetIncidentActionLog("tenant_8", record.LogID)
	if err != ErrIncidentActionLogCrossTenant {
		t.Fatalf("expected cross tenant get log error, got %v", err)
	}

	tenant7Logs, err := runtime.ListTenantIncidentActionLogs("tenant_7")
	if err != nil {
		t.Fatalf("list tenant logs failed: %v", err)
	}
	if len(tenant7Logs) != 1 {
		t.Fatalf("expected tenant_7 log count 1, got %d", len(tenant7Logs))
	}

	instanceLogs, err := runtime.ListInstanceIncidentActionLogs("tenant_7", instance.InstanceID)
	if err != nil {
		t.Fatalf("list instance logs failed: %v", err)
	}
	if len(instanceLogs) != 1 {
		t.Fatalf("expected instance log count 1, got %d", len(instanceLogs))
	}
}

func TestIncidentNoteActionLogRuntimeIDGenerator(t *testing.T) {
	logID := NewIncidentActionLogID()

	if !strings.HasPrefix(logID, "incident_action_log_") {
		t.Fatalf("unexpected log id %s", logID)
	}
}
