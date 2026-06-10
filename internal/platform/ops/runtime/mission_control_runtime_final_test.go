package opsruntime

import "testing"

func missionControlFinalRegistry(t *testing.T) (*InstanceMetadataRuntime, ServiceInstanceRecord) {
	t.Helper()

	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_mission",
		ServiceName: "identity-api",
		Host:        "10.0.0.7",
		Port:        9001,
		Zone:        "tr-istanbul-1",
		NodeID:      "node-mission-a",
		Runtime:     "go",
		Version:     "1.0.0",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register mission control instance failed: %v", err)
	}

	return registry, instance
}

func TestMissionControlRuntimeFinalActionLifecycle(t *testing.T) {
	registry, instance := missionControlFinalRegistry(t)

	restartRuntime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)
	quarantineRuntime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)
	maintenanceRuntime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)
	incidentRuntime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	restartAction, restartDecision, err := restartRuntime.RequestRestart(RestartActionRequest{
		TenantID:      "tenant_mission",
		InstanceID:    instance.InstanceID,
		OperatorID:    "ops_1",
		OperatorRole:  OperatorRoleOpsAdmin,
		Reason:        "final runtime restart check",
		CorrelationID: "corr-mission-restart",
	})
	if err != nil {
		t.Fatalf("restart action failed: %v", err)
	}
	if !restartDecision.Allowed {
		t.Fatalf("restart decision denied: %s", restartDecision.Reason)
	}
	if restartAction.ActionState != RestartActionStateRequested {
		t.Fatalf("expected restart requested, got %s", restartAction.ActionState)
	}

	restartMetadata, err := registry.GetMetadata("tenant_mission", instance.InstanceID, "restart_action_id")
	if err != nil {
		t.Fatalf("restart metadata missing: %v", err)
	}
	if restartMetadata.Value != restartAction.ActionID {
		t.Fatalf("expected restart metadata %s, got %s", restartAction.ActionID, restartMetadata.Value)
	}

	quarantineAction, quarantineDecision, err := quarantineRuntime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:      "tenant_mission",
		InstanceID:    instance.InstanceID,
		ActionType:    IsolateQuarantineActionTypeQuarantine,
		OperatorID:    "sre_1",
		OperatorRole:  OperatorRoleSRE,
		Reason:        "final runtime quarantine check",
		CorrelationID: "corr-mission-quarantine",
	})
	if err != nil {
		t.Fatalf("quarantine action failed: %v", err)
	}
	if !quarantineDecision.Allowed {
		t.Fatalf("quarantine decision denied: %s", quarantineDecision.Reason)
	}
	if quarantineAction.ActionState != IsolateQuarantineStateQuarantineRequested {
		t.Fatalf("expected quarantine requested, got %s", quarantineAction.ActionState)
	}

	quarantineMetadata, err := registry.GetMetadata("tenant_mission", instance.InstanceID, "isolate_quarantine_action_state")
	if err != nil {
		t.Fatalf("quarantine metadata missing: %v", err)
	}
	if quarantineMetadata.Value != IsolateQuarantineStateQuarantineRequested {
		t.Fatalf("expected quarantine metadata state %s, got %s", IsolateQuarantineStateQuarantineRequested, quarantineMetadata.Value)
	}

	maintenanceRecord, maintenanceDecision, err := maintenanceRuntime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:      "tenant_mission",
		InstanceID:    instance.InstanceID,
		Action:        MaintenanceModeActionEnable,
		OperatorID:    "ops_2",
		OperatorRole:  OperatorRoleOpsAdmin,
		Reason:        "final runtime maintenance check",
		CorrelationID: "corr-mission-maintenance",
	})
	if err != nil {
		t.Fatalf("maintenance mode failed: %v", err)
	}
	if !maintenanceDecision.Allowed {
		t.Fatalf("maintenance decision denied: %s", maintenanceDecision.Reason)
	}
	if maintenanceRecord.ModeState != MaintenanceModeStateEnabled {
		t.Fatalf("expected maintenance enabled, got %s", maintenanceRecord.ModeState)
	}

	maintenanceMetadata, err := registry.GetMetadata("tenant_mission", instance.InstanceID, "maintenance_mode_state")
	if err != nil {
		t.Fatalf("maintenance metadata missing: %v", err)
	}
	if maintenanceMetadata.Value != MaintenanceModeStateEnabled {
		t.Fatalf("expected maintenance metadata state %s, got %s", MaintenanceModeStateEnabled, maintenanceMetadata.Value)
	}

	note, noteDecision, err := incidentRuntime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:      "tenant_mission",
		InstanceID:    instance.InstanceID,
		OperatorID:    "ops_3",
		OperatorRole:  OperatorRoleOpsAdmin,
		Severity:      IncidentActionSeverityWarning,
		Message:       "Final mission control note",
		CorrelationID: "corr-mission-note",
	})
	if err != nil {
		t.Fatalf("incident note failed: %v", err)
	}
	if !noteDecision.Allowed {
		t.Fatalf("incident note decision denied: %s", noteDecision.Reason)
	}
	if note.ActionType != IncidentActionTypeNote {
		t.Fatalf("expected incident note action type, got %s", note.ActionType)
	}

	actionLog, actionLogDecision, err := incidentRuntime.RecordIncidentAction(IncidentActionLogRequest{
		TenantID:        "tenant_mission",
		InstanceID:      instance.InstanceID,
		ActionType:      IncidentActionTypeOperatorAction,
		OperatorID:      "sre_2",
		OperatorRole:    OperatorRoleSRE,
		Severity:        IncidentActionSeverityCritical,
		Message:         "Restart and quarantine actions reviewed",
		RelatedActionID: restartAction.ActionID,
		CorrelationID:   "corr-mission-action-log",
	})
	if err != nil {
		t.Fatalf("incident action log failed: %v", err)
	}
	if !actionLogDecision.Allowed {
		t.Fatalf("action log decision denied: %s", actionLogDecision.Reason)
	}
	if actionLog.RelatedActionID != restartAction.ActionID {
		t.Fatalf("expected related action id %s, got %s", restartAction.ActionID, actionLog.RelatedActionID)
	}

	restartEvents, err := restartRuntime.ListTenantAuditEvents("tenant_mission")
	if err != nil {
		t.Fatalf("restart audit list failed: %v", err)
	}
	if len(restartEvents) != 1 {
		t.Fatalf("expected restart audit count 1, got %d", len(restartEvents))
	}

	quarantineEvents, err := quarantineRuntime.ListTenantAuditEvents("tenant_mission")
	if err != nil {
		t.Fatalf("quarantine audit list failed: %v", err)
	}
	if len(quarantineEvents) != 1 {
		t.Fatalf("expected quarantine audit count 1, got %d", len(quarantineEvents))
	}

	maintenanceEvents, err := maintenanceRuntime.ListTenantMaintenanceAuditEvents("tenant_mission")
	if err != nil {
		t.Fatalf("maintenance audit list failed: %v", err)
	}
	if len(maintenanceEvents) != 1 {
		t.Fatalf("expected maintenance audit count 1, got %d", len(maintenanceEvents))
	}

	incidentLogs, err := incidentRuntime.ListInstanceIncidentActionLogs("tenant_mission", instance.InstanceID)
	if err != nil {
		t.Fatalf("incident log list failed: %v", err)
	}
	if len(incidentLogs) != 2 {
		t.Fatalf("expected incident/action log count 2, got %d", len(incidentLogs))
	}
}

func TestMissionControlRuntimeFinalCrossTenantDenyFlow(t *testing.T) {
	registry, instance := missionControlFinalRegistry(t)

	restartRuntime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)
	quarantineRuntime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)
	maintenanceRuntime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)
	incidentRuntime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, restartDecision, err := restartRuntime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_other",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrRestartActionCrossTenant {
		t.Fatalf("expected restart cross tenant error, got %v", err)
	}
	if restartDecision.Reason != RestartActionReasonCrossTenant {
		t.Fatalf("expected restart cross tenant reason, got %s", restartDecision.Reason)
	}

	_, quarantineDecision, err := quarantineRuntime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_other",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeIsolate,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrIsolateQuarantineCrossTenant {
		t.Fatalf("expected isolate cross tenant error, got %v", err)
	}
	if quarantineDecision.Reason != IsolateQuarantineReasonCrossTenant {
		t.Fatalf("expected isolate cross tenant reason, got %s", quarantineDecision.Reason)
	}

	_, maintenanceDecision, err := maintenanceRuntime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_other",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
	})
	if err != ErrMaintenanceModeCrossTenant {
		t.Fatalf("expected maintenance cross tenant error, got %v", err)
	}
	if maintenanceDecision.Reason != MaintenanceModeReasonCrossTenant {
		t.Fatalf("expected maintenance cross tenant reason, got %s", maintenanceDecision.Reason)
	}

	_, incidentDecision, err := incidentRuntime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_other",
		InstanceID:   instance.InstanceID,
		OperatorID:   "ops_1",
		OperatorRole: OperatorRoleOpsAdmin,
		Message:      "cross tenant note",
	})
	if err != ErrIncidentActionLogCrossTenant {
		t.Fatalf("expected incident cross tenant error, got %v", err)
	}
	if incidentDecision.Reason != IncidentActionLogReasonCrossTenant {
		t.Fatalf("expected incident cross tenant reason, got %s", incidentDecision.Reason)
	}
}

func TestMissionControlRuntimeFinalUnauthorizedDenyFlow(t *testing.T) {
	registry, instance := missionControlFinalRegistry(t)

	restartRuntime := NewRestartActionRuntime(DefaultRestartActionRuntimeConfig(), registry)
	quarantineRuntime := NewIsolateQuarantineActionRuntime(DefaultIsolateQuarantineActionRuntimeConfig(), registry)
	maintenanceRuntime := NewMaintenanceModeRuntime(DefaultMaintenanceModeRuntimeConfig(), registry)
	incidentRuntime := NewIncidentNoteActionLogRuntime(DefaultIncidentNoteActionLogRuntimeConfig(), registry)

	_, restartDecision, err := restartRuntime.RequestRestart(RestartActionRequest{
		TenantID:     "tenant_mission",
		InstanceID:   instance.InstanceID,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrRestartActionUnauthorizedOperator {
		t.Fatalf("expected restart unauthorized error, got %v", err)
	}
	if restartDecision.Reason != RestartActionReasonUnauthorizedOperator {
		t.Fatalf("expected restart unauthorized reason, got %s", restartDecision.Reason)
	}

	_, quarantineDecision, err := quarantineRuntime.RequestIsolateOrQuarantine(IsolateQuarantineActionRequest{
		TenantID:     "tenant_mission",
		InstanceID:   instance.InstanceID,
		ActionType:   IsolateQuarantineActionTypeQuarantine,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrIsolateQuarantineUnauthorizedOperator {
		t.Fatalf("expected quarantine unauthorized error, got %v", err)
	}
	if quarantineDecision.Reason != IsolateQuarantineReasonUnauthorizedOperator {
		t.Fatalf("expected quarantine unauthorized reason, got %s", quarantineDecision.Reason)
	}

	_, maintenanceDecision, err := maintenanceRuntime.ApplyMaintenanceMode(MaintenanceModeRequest{
		TenantID:     "tenant_mission",
		InstanceID:   instance.InstanceID,
		Action:       MaintenanceModeActionEnable,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
	})
	if err != ErrMaintenanceModeUnauthorizedOperator {
		t.Fatalf("expected maintenance unauthorized error, got %v", err)
	}
	if maintenanceDecision.Reason != MaintenanceModeReasonUnauthorizedOperator {
		t.Fatalf("expected maintenance unauthorized reason, got %s", maintenanceDecision.Reason)
	}

	_, incidentDecision, err := incidentRuntime.CreateIncidentNote(IncidentNoteRequest{
		TenantID:     "tenant_mission",
		InstanceID:   instance.InstanceID,
		OperatorID:   "viewer_1",
		OperatorRole: OperatorRoleViewer,
		Message:      "unauthorized note",
	})
	if err != ErrIncidentActionLogUnauthorizedOperator {
		t.Fatalf("expected incident unauthorized error, got %v", err)
	}
	if incidentDecision.Reason != IncidentActionLogReasonUnauthorizedOperator {
		t.Fatalf("expected incident unauthorized reason, got %s", incidentDecision.Reason)
	}
}
