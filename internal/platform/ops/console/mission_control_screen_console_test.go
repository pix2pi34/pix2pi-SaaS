package opsconsole

import "testing"

func newMissionControlScreenRuntimeForTest(t *testing.T) *MissionControlScreenConsoleRuntime {
	t.Helper()

	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, _, err := runtime.RecordAction(MissionControlActionEntry{
		TenantID:      "tenant_7",
		ActionID:      "restart_1",
		ActionType:    MissionControlActionRestart,
		Status:        MissionControlActionStatusRequested,
		InstanceID:    "api_gateway_1",
		ServiceID:     "api_gateway",
		OperatorID:    "operator_1",
		OperatorRole:  MissionControlOperatorRoleOperator,
		Message:       "Restart requested after degraded health",
		Reason:        "health_degraded",
		CorrelationID: "corr-restart-1",
		Metadata:      map[string]string{"source": "mission_control"},
	})
	if err != nil {
		t.Fatalf("record restart action failed: %v", err)
	}

	_, _, err = runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "quarantine_1",
		ActionType:   MissionControlActionQuarantine,
		Status:       MissionControlActionStatusApproved,
		InstanceID:   "worker_1",
		ServiceID:    "worker",
		OperatorID:   "admin_1",
		OperatorRole: MissionControlOperatorRoleAdmin,
		Message:      "Quarantine approved for suspicious worker behavior",
		Reason:       "security_review",
	})
	if err != nil {
		t.Fatalf("record quarantine action failed: %v", err)
	}

	_, _, err = runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "maintenance_1",
		ActionType:   MissionControlActionMaintenance,
		Status:       MissionControlActionStatusExecuted,
		InstanceID:   "internal_registry_1",
		ServiceID:    "internal_registry",
		OperatorID:   "admin_1",
		OperatorRole: MissionControlOperatorRoleAdmin,
		Message:      "Maintenance executed",
		Reason:       "planned_maintenance",
	})
	if err != nil {
		t.Fatalf("record maintenance action failed: %v", err)
	}

	return runtime
}

func TestMissionControlScreenConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newMissionControlScreenRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(MissionControlScreenRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeExecuted: true,
		CorrelationID:   "corr-snapshot-1",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if !snapshot.OK {
		t.Fatal("expected snapshot OK")
	}
	if snapshot.ActionCount != 3 {
		t.Fatalf("expected action count 3, got %d", snapshot.ActionCount)
	}
	if snapshot.RestartCount != 1 {
		t.Fatalf("expected restart count 1, got %d", snapshot.RestartCount)
	}
	if snapshot.QuarantineCount != 1 {
		t.Fatalf("expected quarantine count 1, got %d", snapshot.QuarantineCount)
	}
	if snapshot.MaintenanceCount != 1 {
		t.Fatalf("expected maintenance count 1, got %d", snapshot.MaintenanceCount)
	}
	if snapshot.RequestedCount != 1 {
		t.Fatalf("expected requested count 1, got %d", snapshot.RequestedCount)
	}
	if snapshot.ApprovedCount != 1 {
		t.Fatalf("expected approved count 1, got %d", snapshot.ApprovedCount)
	}
	if snapshot.ExecutedCount != 1 {
		t.Fatalf("expected executed count 1, got %d", snapshot.ExecutedCount)
	}
}

func TestMissionControlScreenConsoleRuntimeHidesExecutedWhenDisabled(t *testing.T) {
	runtime := newMissionControlScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(MissionControlScreenRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeExecuted: false,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.ActionCount != 2 {
		t.Fatalf("expected executed actions hidden and count 2, got %d", snapshot.ActionCount)
	}
	if snapshot.ExecutedCount != 0 {
		t.Fatalf("expected executed count 0 when hidden, got %d", snapshot.ExecutedCount)
	}
}

func TestMissionControlScreenConsoleRuntimeActionFilter(t *testing.T) {
	runtime := newMissionControlScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(MissionControlScreenRequest{
		TenantID:        "tenant_7",
		ActionFilter:    MissionControlActionQuarantine,
		IncludeExecuted: true,
	})
	if err != nil {
		t.Fatalf("build filtered snapshot failed: %v", err)
	}
	if snapshot.ActionCount != 1 {
		t.Fatalf("expected one quarantine action, got %d", snapshot.ActionCount)
	}
	if snapshot.Actions[0].ActionType != MissionControlActionQuarantine {
		t.Fatalf("expected quarantine action, got %s", snapshot.Actions[0].ActionType)
	}
}

func TestMissionControlScreenConsoleRuntimeStatusFilter(t *testing.T) {
	runtime := newMissionControlScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(MissionControlScreenRequest{
		TenantID:        "tenant_7",
		StatusFilter:    MissionControlActionStatusApproved,
		IncludeExecuted: true,
	})
	if err != nil {
		t.Fatalf("build status filtered snapshot failed: %v", err)
	}
	if snapshot.ActionCount != 1 {
		t.Fatalf("expected one approved action, got %d", snapshot.ActionCount)
	}
	if snapshot.Actions[0].Status != MissionControlActionStatusApproved {
		t.Fatalf("expected approved status, got %s", snapshot.Actions[0].Status)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(MissionControlScreenRequest{})
	if err != ErrMissionControlScreenMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newMissionControlScreenRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(MissionControlScreenRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrMissionControlScreenCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsViewerMutation(t *testing.T) {
	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, decision, err := runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "restart_1",
		ActionType:   MissionControlActionRestart,
		Status:       MissionControlActionStatusRequested,
		InstanceID:   "api_gateway_1",
		OperatorID:   "viewer_1",
		OperatorRole: MissionControlOperatorRoleViewer,
		Message:      "Viewer should not restart",
	})
	if err != ErrMissionControlScreenUnauthorizedRole {
		t.Fatalf("expected unauthorized role error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonUnauthorizedRole {
		t.Fatalf("expected unauthorized role reason, got %s", decision.Reason)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsInvalidActionType(t *testing.T) {
	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, decision, err := runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "bad_action_1",
		ActionType:   "DELETE_CLUSTER",
		Status:       MissionControlActionStatusRequested,
		InstanceID:   "api_gateway_1",
		OperatorID:   "admin_1",
		OperatorRole: MissionControlOperatorRoleAdmin,
		Message:      "bad action",
	})
	if err != ErrMissionControlScreenInvalidActionType {
		t.Fatalf("expected invalid action type error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonInvalidActionType {
		t.Fatalf("expected invalid action type reason, got %s", decision.Reason)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsInvalidStatus(t *testing.T) {
	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, decision, err := runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "bad_status_1",
		ActionType:   MissionControlActionRestart,
		Status:       "BROKEN_STATUS",
		InstanceID:   "api_gateway_1",
		OperatorID:   "admin_1",
		OperatorRole: MissionControlOperatorRoleAdmin,
		Message:      "bad status",
	})
	if err != ErrMissionControlScreenInvalidActionStatus {
		t.Fatalf("expected invalid status error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonInvalidActionStatus {
		t.Fatalf("expected invalid status reason, got %s", decision.Reason)
	}
}

func TestMissionControlScreenConsoleRuntimeRejectsMissingMessage(t *testing.T) {
	runtime := NewMissionControlScreenConsoleRuntime(DefaultMissionControlScreenConsoleConfig())

	_, decision, err := runtime.RecordAction(MissionControlActionEntry{
		TenantID:     "tenant_7",
		ActionID:     "restart_1",
		ActionType:   MissionControlActionRestart,
		Status:       MissionControlActionStatusRequested,
		InstanceID:   "api_gateway_1",
		OperatorID:   "admin_1",
		OperatorRole: MissionControlOperatorRoleAdmin,
	})
	if err != ErrMissionControlScreenMissingMessage {
		t.Fatalf("expected missing message error, got %v", err)
	}
	if decision.Reason != MissionControlScreenReasonMissingMessage {
		t.Fatalf("expected missing message reason, got %s", decision.Reason)
	}
}
