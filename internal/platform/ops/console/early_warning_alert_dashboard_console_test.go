package opsconsole

import "testing"

func newEarlyWarningAlertDashboardRuntimeForTest(t *testing.T) *EarlyWarningAlertDashboardConsoleRuntime {
	t.Helper()

	runtime := NewEarlyWarningAlertDashboardConsoleRuntime(DefaultEarlyWarningAlertDashboardConsoleConfig())

	_, _, err := runtime.UpsertRule(EarlyWarningRuleEntry{
		TenantID:  "tenant_7",
		RuleID:    "rule_webhook_dlq",
		Name:      "Webhook DLQ spike",
		Source:    EarlyWarningSourceWebhook,
		Metric:    "webhook_dlq_count",
		Operator:  EarlyWarningRuleOperatorGreaterThan,
		Threshold: 5,
		Severity:  EarlyWarningSeverityCritical,
		Enabled:   true,
		Metadata:  map[string]string{"window": "5m"},
	})
	if err != nil {
		t.Fatalf("upsert webhook rule failed: %v", err)
	}

	_, _, err = runtime.UpsertRule(EarlyWarningRuleEntry{
		TenantID:  "tenant_7",
		RuleID:    "rule_job_queue",
		Name:      "Job queue backlog",
		Source:    EarlyWarningSourceJobQueue,
		Metric:    "queued_jobs",
		Operator:  EarlyWarningRuleOperatorGreaterThan,
		Threshold: 100,
		Severity:  EarlyWarningSeverityWarning,
		Enabled:   true,
	})
	if err != nil {
		t.Fatalf("upsert job queue rule failed: %v", err)
	}

	_, _, err = runtime.RaiseAlert(EarlyWarningAlertEntry{
		TenantID:      "tenant_7",
		AlertID:       "alert_webhook_dlq_1",
		RuleID:        "rule_webhook_dlq",
		Source:        EarlyWarningSourceWebhook,
		Metric:        "webhook_dlq_count",
		ObservedValue: 12,
		Threshold:     5,
		Severity:      EarlyWarningSeverityCritical,
		Status:        EarlyWarningStatusOpen,
		Message:       "Webhook DLQ count exceeded threshold",
		CorrelationID: "corr-alert-1",
	})
	if err != nil {
		t.Fatalf("raise webhook alert failed: %v", err)
	}

	_, _, err = runtime.RaiseAlert(EarlyWarningAlertEntry{
		TenantID:      "tenant_7",
		AlertID:       "alert_job_queue_1",
		RuleID:        "rule_job_queue",
		Source:        EarlyWarningSourceJobQueue,
		Metric:        "queued_jobs",
		ObservedValue: 145,
		Threshold:     100,
		Severity:      EarlyWarningSeverityWarning,
		Status:        EarlyWarningStatusAcknowledged,
		Message:       "Job queue backlog is above threshold",
		OperatorID:    "operator_1",
	})
	if err != nil {
		t.Fatalf("raise job queue alert failed: %v", err)
	}

	_, _, err = runtime.RaiseAlert(EarlyWarningAlertEntry{
		TenantID:      "tenant_7",
		AlertID:       "alert_db_resolved_1",
		RuleID:        "rule_db_latency",
		Source:        EarlyWarningSourceDatabase,
		Metric:        "db_latency_ms",
		ObservedValue: 80,
		Threshold:     50,
		Severity:      EarlyWarningSeverityWarning,
		Status:        EarlyWarningStatusResolved,
		Message:       "Database latency resolved",
		OperatorID:    "operator_1",
	})
	if err != nil {
		t.Fatalf("raise resolved db alert failed: %v", err)
	}

	return runtime
}

func TestEarlyWarningAlertDashboardConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeResolved: true,
		IncludeRules:    true,
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
	if snapshot.RuleCount != 2 {
		t.Fatalf("expected rule count 2, got %d", snapshot.RuleCount)
	}
	if snapshot.AlertCount != 3 {
		t.Fatalf("expected alert count 3, got %d", snapshot.AlertCount)
	}
	if snapshot.OpenCount != 1 {
		t.Fatalf("expected open count 1, got %d", snapshot.OpenCount)
	}
	if snapshot.AcknowledgedCount != 1 {
		t.Fatalf("expected acknowledged count 1, got %d", snapshot.AcknowledgedCount)
	}
	if snapshot.ResolvedCount != 1 {
		t.Fatalf("expected resolved count 1, got %d", snapshot.ResolvedCount)
	}
	if snapshot.CriticalCount != 1 {
		t.Fatalf("expected critical count 1, got %d", snapshot.CriticalCount)
	}
	if snapshot.WarningCount != 2 {
		t.Fatalf("expected warning count 2, got %d", snapshot.WarningCount)
	}
	if snapshot.WebhookCount != 1 {
		t.Fatalf("expected webhook count 1, got %d", snapshot.WebhookCount)
	}
	if snapshot.JobQueueCount != 1 {
		t.Fatalf("expected job queue count 1, got %d", snapshot.JobQueueCount)
	}
	if snapshot.DatabaseCount != 1 {
		t.Fatalf("expected database count 1, got %d", snapshot.DatabaseCount)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeHidesResolvedWhenDisabled(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{
		TenantID:        "tenant_7",
		IncludeResolved: false,
		IncludeRules:    true,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.AlertCount != 2 {
		t.Fatalf("expected resolved hidden and alert count 2, got %d", snapshot.AlertCount)
	}
	if snapshot.ResolvedCount != 0 {
		t.Fatalf("expected resolved count 0 when hidden, got %d", snapshot.ResolvedCount)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeFiltersSource(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{
		TenantID:        "tenant_7",
		SourceFilter:    EarlyWarningSourceWebhook,
		IncludeResolved: true,
		IncludeRules:    true,
	})
	if err != nil {
		t.Fatalf("build source filtered snapshot failed: %v", err)
	}
	if snapshot.RuleCount != 1 {
		t.Fatalf("expected webhook rule count 1, got %d", snapshot.RuleCount)
	}
	if snapshot.AlertCount != 1 {
		t.Fatalf("expected webhook alert count 1, got %d", snapshot.AlertCount)
	}
	if snapshot.Alerts[0].Source != EarlyWarningSourceWebhook {
		t.Fatalf("expected webhook source, got %s", snapshot.Alerts[0].Source)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeFiltersSeverity(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{
		TenantID:        "tenant_7",
		SeverityFilter:  EarlyWarningSeverityCritical,
		IncludeResolved: true,
		IncludeRules:    true,
	})
	if err != nil {
		t.Fatalf("build severity filtered snapshot failed: %v", err)
	}
	if snapshot.RuleCount != 1 {
		t.Fatalf("expected critical rule count 1, got %d", snapshot.RuleCount)
	}
	if snapshot.AlertCount != 1 {
		t.Fatalf("expected critical alert count 1, got %d", snapshot.AlertCount)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeAcknowledgeAndResolve(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	ack, decision, err := runtime.AcknowledgeAlert("tenant_7", "alert_webhook_dlq_1", "operator_1")
	if err != nil {
		t.Fatalf("acknowledge alert failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected acknowledge allowed, got reason=%s", decision.Reason)
	}
	if ack.Status != EarlyWarningStatusAcknowledged {
		t.Fatalf("expected acknowledged status, got %s", ack.Status)
	}
	if ack.AcknowledgedAt == "" {
		t.Fatal("expected acknowledged timestamp")
	}

	resolved, decision, err := runtime.ResolveAlert("tenant_7", "alert_webhook_dlq_1", "operator_1")
	if err != nil {
		t.Fatalf("resolve alert failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected resolve allowed, got reason=%s", decision.Reason)
	}
	if resolved.Status != EarlyWarningStatusResolved {
		t.Fatalf("expected resolved status, got %s", resolved.Status)
	}
	if resolved.ResolvedAt == "" {
		t.Fatal("expected resolved timestamp")
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewEarlyWarningAlertDashboardConsoleRuntime(DefaultEarlyWarningAlertDashboardConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{})
	if err != ErrEarlyWarningDashboardMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(EarlyWarningDashboardRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrEarlyWarningDashboardCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidSource(t *testing.T) {
	runtime := NewEarlyWarningAlertDashboardConsoleRuntime(DefaultEarlyWarningAlertDashboardConsoleConfig())

	_, decision, err := runtime.UpsertRule(EarlyWarningRuleEntry{
		TenantID:  "tenant_7",
		RuleID:    "rule_bad",
		Name:      "Bad source",
		Source:    "MOON",
		Metric:    "moon_metric",
		Operator:  EarlyWarningRuleOperatorGreaterThan,
		Threshold: 1,
		Severity:  EarlyWarningSeverityWarning,
		Enabled:   true,
	})
	if err != ErrEarlyWarningDashboardInvalidSource {
		t.Fatalf("expected invalid source error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonInvalidSource {
		t.Fatalf("expected invalid source reason, got %s", decision.Reason)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidSeverity(t *testing.T) {
	runtime := NewEarlyWarningAlertDashboardConsoleRuntime(DefaultEarlyWarningAlertDashboardConsoleConfig())

	_, decision, err := runtime.RaiseAlert(EarlyWarningAlertEntry{
		TenantID:      "tenant_7",
		AlertID:       "alert_bad",
		Source:        EarlyWarningSourceWebhook,
		Metric:        "webhook_dlq_count",
		ObservedValue: 10,
		Threshold:     5,
		Severity:      "PANIC",
		Status:        EarlyWarningStatusOpen,
		Message:       "bad severity",
	})
	if err != ErrEarlyWarningDashboardInvalidSeverity {
		t.Fatalf("expected invalid severity error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonInvalidSeverity {
		t.Fatalf("expected invalid severity reason, got %s", decision.Reason)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidStatus(t *testing.T) {
	runtime := NewEarlyWarningAlertDashboardConsoleRuntime(DefaultEarlyWarningAlertDashboardConsoleConfig())

	_, decision, err := runtime.RaiseAlert(EarlyWarningAlertEntry{
		TenantID:      "tenant_7",
		AlertID:       "alert_bad",
		Source:        EarlyWarningSourceWebhook,
		Metric:        "webhook_dlq_count",
		ObservedValue: 10,
		Threshold:     5,
		Severity:      EarlyWarningSeverityWarning,
		Status:        "BROKEN",
		Message:       "bad status",
	})
	if err != ErrEarlyWarningDashboardInvalidStatus {
		t.Fatalf("expected invalid status error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonInvalidStatus {
		t.Fatalf("expected invalid status reason, got %s", decision.Reason)
	}
}

func TestEarlyWarningAlertDashboardConsoleRuntimeRejectsMissingOperatorForTransition(t *testing.T) {
	runtime := newEarlyWarningAlertDashboardRuntimeForTest(t)

	_, decision, err := runtime.AcknowledgeAlert("tenant_7", "alert_webhook_dlq_1", "")
	if err != ErrEarlyWarningDashboardMissingOperatorID {
		t.Fatalf("expected missing operator id error, got %v", err)
	}
	if decision.Reason != EarlyWarningDashboardReasonMissingOperatorID {
		t.Fatalf("expected missing operator id reason, got %s", decision.Reason)
	}
}
