package opsconsole

import (
	"strings"
	"testing"
)

func newIncidentAuditCenterRuntimeForTest(t *testing.T) *IncidentAuditCenterConsoleRuntime {
	t.Helper()

	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, _, err := runtime.UpsertIncident(IncidentCenterRecord{
		TenantID:      "tenant_7",
		IncidentID:    "incident_critical_1",
		Source:        "webhook_runtime",
		Severity:      IncidentAuditSeverityCritical,
		Status:        IncidentStatusOpen,
		Title:         "Webhook DLQ spike",
		Message:       "Webhook DLQ count exceeded threshold",
		Owner:         "ops",
		CorrelationID: "corr-incident-1",
		Metadata:      map[string]string{"dlq_count": "12"},
	})
	if err != nil {
		t.Fatalf("upsert critical incident failed: %v", err)
	}

	_, _, err = runtime.UpsertIncident(IncidentCenterRecord{
		TenantID:   "tenant_7",
		IncidentID: "incident_warning_1",
		Source:     "job_runtime",
		Severity:   IncidentAuditSeverityWarning,
		Status:     IncidentStatusResolved,
		Title:      "Worker stale",
		Message:    "Worker heartbeat stale",
		Owner:      "ops",
	})
	if err != nil {
		t.Fatalf("upsert warning incident failed: %v", err)
	}

	_, _, err = runtime.RecordAuditEvent(AuditCenterRecord{
		TenantID:   "tenant_7",
		AuditID:    "audit_security_1",
		ActorID:    "system",
		ActionType: AuditActionSecurityEvent,
		TargetType: "TENANT",
		TargetID:   "tenant_7",
		Severity:   IncidentAuditSeverityCritical,
		Message:    "Cross tenant access denied",
	})
	if err != nil {
		t.Fatalf("record security audit failed: %v", err)
	}

	_, _, err = runtime.RecordAuditEvent(AuditCenterRecord{
		TenantID:   "tenant_7",
		AuditID:    "audit_operator_1",
		ActorID:    "operator_1",
		ActionType: AuditActionOperatorAction,
		TargetType: "INCIDENT",
		TargetID:   "incident_critical_1",
		Severity:   IncidentAuditSeverityInfo,
		Message:    "Operator opened incident detail",
	})
	if err != nil {
		t.Fatalf("record operator audit failed: %v", err)
	}

	return runtime
}

func TestIncidentAuditCenterConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeResolved: true,
		IncludeAudit:    true,
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
	if snapshot.IncidentCount != 2 {
		t.Fatalf("expected incident count 2, got %d", snapshot.IncidentCount)
	}
	if snapshot.AuditCount != 2 {
		t.Fatalf("expected audit count 2, got %d", snapshot.AuditCount)
	}
	if snapshot.OpenCount != 1 {
		t.Fatalf("expected open count 1, got %d", snapshot.OpenCount)
	}
	if snapshot.ResolvedCount != 1 {
		t.Fatalf("expected resolved count 1, got %d", snapshot.ResolvedCount)
	}
	if snapshot.CriticalCount != 1 {
		t.Fatalf("expected critical incident count 1, got %d", snapshot.CriticalCount)
	}
	if snapshot.SecurityEventCount != 1 {
		t.Fatalf("expected security event count 1, got %d", snapshot.SecurityEventCount)
	}
	if snapshot.OperatorActionCount != 1 {
		t.Fatalf("expected operator action count 1, got %d", snapshot.OperatorActionCount)
	}
}

func TestIncidentAuditCenterConsoleRuntimeFiltersSeverity(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		SeverityFilter:  IncidentAuditSeverityCritical,
		IncludeResolved: true,
		IncludeAudit:    true,
	})
	if err != nil {
		t.Fatalf("build severity filtered snapshot failed: %v", err)
	}
	if snapshot.IncidentCount != 1 {
		t.Fatalf("expected critical incident count 1, got %d", snapshot.IncidentCount)
	}
	if snapshot.AuditCount != 1 {
		t.Fatalf("expected critical audit count 1, got %d", snapshot.AuditCount)
	}
}

func TestIncidentAuditCenterConsoleRuntimeFiltersStatus(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		StatusFilter:    IncidentStatusResolved,
		IncludeResolved: true,
	})
	if err != nil {
		t.Fatalf("build status filtered snapshot failed: %v", err)
	}
	if snapshot.IncidentCount != 1 {
		t.Fatalf("expected resolved incident count 1, got %d", snapshot.IncidentCount)
	}
	if snapshot.Incidents[0].Status != IncidentStatusResolved {
		t.Fatalf("expected resolved status, got %s", snapshot.Incidents[0].Status)
	}
}

func TestIncidentAuditCenterConsoleRuntimeHidesResolvedWhenDisabled(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		IncludeResolved: false,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.IncidentCount != 1 {
		t.Fatalf("expected only open incidents, got %d", snapshot.IncidentCount)
	}
	if snapshot.ResolvedCount != 0 {
		t.Fatalf("expected resolved count 0 when hidden, got %d", snapshot.ResolvedCount)
	}
}

func TestIncidentAuditCenterConsoleRuntimeResolveIncident(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	record, decision, err := runtime.ResolveIncident("tenant_7", "incident_critical_1", "operator_1", "Resolved after retry drain")
	if err != nil {
		t.Fatalf("resolve incident failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected resolve allowed, got reason=%s", decision.Reason)
	}
	if record.Status != IncidentStatusResolved {
		t.Fatalf("expected resolved status, got %s", record.Status)
	}
	if record.ResolvedAt == "" {
		t.Fatal("expected resolved_at timestamp")
	}

	snapshot, _, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:        "tenant_7",
		IncludeResolved: true,
		IncludeAudit:    true,
		ActionFilter:    AuditActionIncidentResolved,
	})
	if err != nil {
		t.Fatalf("build snapshot after resolve failed: %v", err)
	}
	if snapshot.AuditCount != 1 {
		t.Fatalf("expected one incident resolved audit, got %d", snapshot.AuditCount)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{})
	if err != ErrIncidentAuditMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newIncidentAuditCenterRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(IncidentAuditCenterRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrIncidentAuditCrossTenant {
		t.Fatalf("expected cross tenant viewer error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsInvalidSeverity(t *testing.T) {
	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, decision, err := runtime.UpsertIncident(IncidentCenterRecord{
		TenantID:   "tenant_7",
		IncidentID: "incident_1",
		Severity:   "PANIC",
		Status:     IncidentStatusOpen,
		Title:      "Bad severity",
		Message:    "Bad severity",
	})
	if err != ErrIncidentAuditInvalidSeverity {
		t.Fatalf("expected invalid severity error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonInvalidSeverity {
		t.Fatalf("expected invalid severity reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsInvalidStatus(t *testing.T) {
	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, decision, err := runtime.UpsertIncident(IncidentCenterRecord{
		TenantID:   "tenant_7",
		IncidentID: "incident_1",
		Severity:   IncidentAuditSeverityWarning,
		Status:     "BROKEN",
		Title:      "Bad status",
		Message:    "Bad status",
	})
	if err != ErrIncidentAuditInvalidStatus {
		t.Fatalf("expected invalid status error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonInvalidStatus {
		t.Fatalf("expected invalid status reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsInvalidActionType(t *testing.T) {
	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, decision, err := runtime.RecordAuditEvent(AuditCenterRecord{
		TenantID:   "tenant_7",
		ActorID:    "operator_1",
		ActionType: "DELETE_WORLD",
		TargetType: "INCIDENT",
		TargetID:   "incident_1",
		Severity:   IncidentAuditSeverityInfo,
		Message:    "bad action",
	})
	if err != ErrIncidentAuditInvalidActionType {
		t.Fatalf("expected invalid action type error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonInvalidActionType {
		t.Fatalf("expected invalid action type reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterConsoleRuntimeRejectsMissingAuditActor(t *testing.T) {
	runtime := NewIncidentAuditCenterConsoleRuntime(DefaultIncidentAuditCenterConsoleConfig())

	_, decision, err := runtime.RecordAuditEvent(AuditCenterRecord{
		TenantID:   "tenant_7",
		ActionType: AuditActionOperatorAction,
		TargetType: "INCIDENT",
		TargetID:   "incident_1",
		Severity:   IncidentAuditSeverityInfo,
		Message:    "missing actor",
	})
	if err != ErrIncidentAuditMissingActor {
		t.Fatalf("expected missing actor error, got %v", err)
	}
	if decision.Reason != IncidentAuditReasonMissingActor {
		t.Fatalf("expected missing actor reason, got %s", decision.Reason)
	}
}

func TestIncidentAuditCenterIDs(t *testing.T) {
	incidentID := NewIncidentCenterID()
	auditID := NewAuditCenterID()

	if !strings.HasPrefix(incidentID, "incident_") {
		t.Fatalf("unexpected incident id %s", incidentID)
	}
	if !strings.HasPrefix(auditID, "audit_") {
		t.Fatalf("unexpected audit id %s", auditID)
	}
}
