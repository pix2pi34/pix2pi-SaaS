package opsruntime

import (
	"strings"
	"testing"
)

func TestJobAuditLogPersistenceRuntimeRecordsAuditLog(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	record, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:      "tenant_7",
		JobID:         "tenant_job_1",
		JobType:       JobDispatchTypeWebhookDelivery,
		Queue:         "webhooks",
		EventType:     JobAuditEventQueued,
		Severity:      JobAuditSeverityInfo,
		State:         JobDispatchStateQueued,
		Message:       "Webhook delivery queued",
		ActorID:       "system",
		CorrelationID: "corr-audit-1",
		Attributes:    map[string]string{"delivery_id": "delivery_1"},
	})
	if err != nil {
		t.Fatalf("record audit log failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected audit allowed, got reason=%s", decision.Reason)
	}
	if record.AuditID == "" {
		t.Fatal("expected audit id")
	}
	if record.EventType != JobAuditEventQueued {
		t.Fatalf("expected JOB_QUEUED, got %s", record.EventType)
	}
	if record.Attributes["delivery_id"] != "delivery_1" {
		t.Fatalf("expected delivery_id attribute, got %s", record.Attributes["delivery_id"])
	}
}

func TestJobAuditLogPersistenceRuntimeRecordsFromJob(t *testing.T) {
	dispatchRuntime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())
	auditRuntime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	job, _, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:      "tenant_7",
		JobType:       JobDispatchTypeEmailDelivery,
		Queue:         "email",
		Priority:      JobDispatchPriorityHigh,
		Payload:       map[string]string{"email_id": "email_1"},
		DedupeKey:     "email_1",
		RequestedBy:   "system",
		CorrelationID: "corr-job-audit-1",
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}

	record, decision, err := auditRuntime.RecordFromJob(job, JobAuditEventQueued, "Email delivery queued")
	if err != nil {
		t.Fatalf("record from job failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected record from job allowed, got reason=%s", decision.Reason)
	}
	if record.JobID != job.JobID {
		t.Fatalf("expected job id %s, got %s", job.JobID, record.JobID)
	}
	if record.Attributes["priority"] != JobDispatchPriorityHigh {
		t.Fatalf("expected priority HIGH, got %s", record.Attributes["priority"])
	}
	if record.Attributes["dedupe_key"] != "email_1" {
		t.Fatalf("expected dedupe key email_1, got %s", record.Attributes["dedupe_key"])
	}
}

func TestJobAuditLogPersistenceRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
		Message:   "queued",
	})
	if err != ErrJobAuditMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != JobAuditReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestJobAuditLogPersistenceRuntimeRejectsMissingJobID(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
		Message:   "queued",
	})
	if err != ErrJobAuditMissingJobID {
		t.Fatalf("expected missing job id error, got %v", err)
	}
	if decision.Reason != JobAuditReasonMissingJobID {
		t.Fatalf("expected missing job id reason, got %s", decision.Reason)
	}
}

func TestJobAuditLogPersistenceRuntimeRejectsInvalidEventType(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: "JOB_EXPLODED",
		Message:   "queued",
	})
	if err != ErrJobAuditInvalidEventType {
		t.Fatalf("expected invalid event type error, got %v", err)
	}
	if decision.Reason != JobAuditReasonInvalidEventType {
		t.Fatalf("expected invalid event type reason, got %s", decision.Reason)
	}
}

func TestJobAuditLogPersistenceRuntimeRejectsInvalidSeverity(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
		Severity:  "PANIC",
		Message:   "queued",
	})
	if err != ErrJobAuditInvalidSeverity {
		t.Fatalf("expected invalid severity error, got %v", err)
	}
	if decision.Reason != JobAuditReasonInvalidSeverity {
		t.Fatalf("expected invalid severity reason, got %s", decision.Reason)
	}
}

func TestJobAuditLogPersistenceRuntimeRejectsMissingMessage(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, decision, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
	})
	if err != ErrJobAuditMissingMessage {
		t.Fatalf("expected missing message error, got %v", err)
	}
	if decision.Reason != JobAuditReasonMissingMessage {
		t.Fatalf("expected missing message reason, got %s", decision.Reason)
	}
}

func TestJobAuditLogPersistenceRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	record, _, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeReportBuild,
		EventType: JobAuditEventQueued,
		Message:   "Report build queued",
	})
	if err != nil {
		t.Fatalf("record audit log failed: %v", err)
	}

	got, err := runtime.GetAuditLog("tenant_7", record.AuditID)
	if err != nil {
		t.Fatalf("get audit log failed: %v", err)
	}
	if got.AuditID != record.AuditID {
		t.Fatalf("expected audit id %s, got %s", record.AuditID, got.AuditID)
	}

	_, err = runtime.GetAuditLog("tenant_8", record.AuditID)
	if err != ErrJobAuditCrossTenant {
		t.Fatalf("expected cross tenant audit get error, got %v", err)
	}

	tenantLogs, err := runtime.ListTenantAuditLogs("tenant_7")
	if err != nil {
		t.Fatalf("list tenant audit logs failed: %v", err)
	}
	if len(tenantLogs) != 1 {
		t.Fatalf("expected tenant audit count 1, got %d", len(tenantLogs))
	}

	jobLogs, err := runtime.ListJobAuditLogs("tenant_7", "tenant_job_1")
	if err != nil {
		t.Fatalf("list job audit logs failed: %v", err)
	}
	if len(jobLogs) != 1 {
		t.Fatalf("expected job audit count 1, got %d", len(jobLogs))
	}

	tenant8Logs, err := runtime.ListTenantAuditLogs("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 audit logs failed: %v", err)
	}
	if len(tenant8Logs) != 0 {
		t.Fatalf("expected tenant_8 audit count 0, got %d", len(tenant8Logs))
	}
}

func TestJobAuditLogPersistenceRuntimeMultipleEventsForJob(t *testing.T) {
	runtime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, _, err := runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
		State:     JobDispatchStateQueued,
		Message:   "Cleanup queued",
	})
	if err != nil {
		t.Fatalf("record queued audit failed: %v", err)
	}

	_, _, err = runtime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventDispatched,
		State:     JobDispatchStateDispatched,
		Message:   "Cleanup dispatched",
	})
	if err != nil {
		t.Fatalf("record dispatched audit failed: %v", err)
	}

	jobLogs, err := runtime.ListJobAuditLogs("tenant_7", "tenant_job_1")
	if err != nil {
		t.Fatalf("list job audit logs failed: %v", err)
	}
	if len(jobLogs) != 2 {
		t.Fatalf("expected 2 job audit logs, got %d", len(jobLogs))
	}
}

func TestJobAuditLogPersistenceRuntimeIDGenerator(t *testing.T) {
	auditID := NewJobAuditLogID()
	if !strings.HasPrefix(auditID, "job_audit_log_") {
		t.Fatalf("unexpected audit id %s", auditID)
	}
}
