package opsruntime

import "testing"

func TestJobEngineIntegrationFinalDispatchAuditLifecycle(t *testing.T) {
	dispatchRuntime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())
	auditRuntime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	job, dispatchDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:      "tenant_job_final",
		JobType:       JobDispatchTypeWebhookDelivery,
		Queue:         "webhooks",
		Priority:      JobDispatchPriorityHigh,
		Payload:       map[string]string{"delivery_id": "delivery_final_1"},
		DedupeKey:     "delivery_final_1",
		RequestedBy:   "system",
		CorrelationID: "corr-job-final-dispatch",
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}
	if !dispatchDecision.Allowed {
		t.Fatalf("expected dispatch allowed, got reason=%s", dispatchDecision.Reason)
	}
	if job.State != JobDispatchStateQueued {
		t.Fatalf("expected QUEUED state, got %s", job.State)
	}

	queuedAudit, queuedDecision, err := auditRuntime.RecordFromJob(job, JobAuditEventQueued, "Webhook delivery queued")
	if err != nil {
		t.Fatalf("queued audit failed: %v", err)
	}
	if !queuedDecision.Allowed {
		t.Fatalf("expected queued audit allowed, got reason=%s", queuedDecision.Reason)
	}
	if queuedAudit.JobID != job.JobID {
		t.Fatalf("expected queued audit job id %s, got %s", job.JobID, queuedAudit.JobID)
	}

	dispatchedJob, markDecision, err := dispatchRuntime.MarkDispatched("tenant_job_final", job.JobID)
	if err != nil {
		t.Fatalf("mark dispatched failed: %v", err)
	}
	if !markDecision.Allowed {
		t.Fatalf("expected mark dispatched allowed, got reason=%s", markDecision.Reason)
	}
	if dispatchedJob.State != JobDispatchStateDispatched {
		t.Fatalf("expected DISPATCHED state, got %s", dispatchedJob.State)
	}

	dispatchedAudit, dispatchedDecision, err := auditRuntime.RecordFromJob(dispatchedJob, JobAuditEventDispatched, "Webhook delivery dispatched")
	if err != nil {
		t.Fatalf("dispatched audit failed: %v", err)
	}
	if !dispatchedDecision.Allowed {
		t.Fatalf("expected dispatched audit allowed, got reason=%s", dispatchedDecision.Reason)
	}
	if dispatchedAudit.State != JobDispatchStateDispatched {
		t.Fatalf("expected dispatched audit state DISPATCHED, got %s", dispatchedAudit.State)
	}

	jobAuditLogs, err := auditRuntime.ListJobAuditLogs("tenant_job_final", job.JobID)
	if err != nil {
		t.Fatalf("list job audit logs failed: %v", err)
	}
	if len(jobAuditLogs) != 2 {
		t.Fatalf("expected 2 job audit logs, got %d", len(jobAuditLogs))
	}

	tenantJobs, err := dispatchRuntime.ListTenantJobs("tenant_job_final")
	if err != nil {
		t.Fatalf("list tenant jobs failed: %v", err)
	}
	if len(tenantJobs) != 1 {
		t.Fatalf("expected tenant job count 1, got %d", len(tenantJobs))
	}

	queueJobs, err := dispatchRuntime.ListTenantQueueJobs("tenant_job_final", "webhooks")
	if err != nil {
		t.Fatalf("list queue jobs failed: %v", err)
	}
	if len(queueJobs) != 1 {
		t.Fatalf("expected queue job count 1, got %d", len(queueJobs))
	}
}

func TestJobEngineIntegrationFinalTenantDedupeBoundary(t *testing.T) {
	dispatchRuntime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	firstJob, firstDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_shared"},
		DedupeKey: "delivery_shared",
	})
	if err != nil {
		t.Fatalf("first tenant dispatch failed: %v", err)
	}
	if !firstDecision.Allowed {
		t.Fatalf("expected first tenant dispatch allowed, got reason=%s", firstDecision.Reason)
	}

	_, duplicateDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_shared"},
		DedupeKey: "delivery_shared",
	})
	if err != ErrJobDispatchDuplicateDedupe {
		t.Fatalf("expected duplicate dedupe error, got %v", err)
	}
	if duplicateDecision.JobID != firstJob.JobID {
		t.Fatalf("expected duplicate decision existing job id %s, got %s", firstJob.JobID, duplicateDecision.JobID)
	}
	if duplicateDecision.Reason != JobDispatchReasonDuplicateDedupe {
		t.Fatalf("expected duplicate dedupe reason, got %s", duplicateDecision.Reason)
	}

	secondTenantJob, secondTenantDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_8",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_shared"},
		DedupeKey: "delivery_shared",
	})
	if err != nil {
		t.Fatalf("second tenant same dedupe should be allowed, got %v", err)
	}
	if !secondTenantDecision.Allowed {
		t.Fatalf("expected second tenant dispatch allowed, got reason=%s", secondTenantDecision.Reason)
	}
	if secondTenantJob.TenantID != "tenant_8" {
		t.Fatalf("expected tenant_8 job, got %s", secondTenantJob.TenantID)
	}
}

func TestJobEngineIntegrationFinalCrossTenantAccessDenied(t *testing.T) {
	dispatchRuntime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())
	auditRuntime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	job, _, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeReportBuild,
		Queue:    "reports",
		Payload:  map[string]string{"report_id": "report_1"},
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}

	auditLog, _, err := auditRuntime.RecordFromJob(job, JobAuditEventQueued, "Report build queued")
	if err != nil {
		t.Fatalf("record audit failed: %v", err)
	}

	_, err = dispatchRuntime.GetJob("tenant_8", job.JobID)
	if err != ErrJobDispatchCrossTenant {
		t.Fatalf("expected cross tenant get job error, got %v", err)
	}

	_, decision, err := dispatchRuntime.MarkDispatched("tenant_8", job.JobID)
	if err != ErrJobDispatchCrossTenant {
		t.Fatalf("expected cross tenant mark dispatched error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonCrossTenant {
		t.Fatalf("expected cross tenant mark dispatched reason, got %s", decision.Reason)
	}

	_, err = auditRuntime.GetAuditLog("tenant_8", auditLog.AuditID)
	if err != ErrJobAuditCrossTenant {
		t.Fatalf("expected cross tenant get audit error, got %v", err)
	}

	tenant8Jobs, err := dispatchRuntime.ListTenantJobs("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 jobs failed: %v", err)
	}
	if len(tenant8Jobs) != 0 {
		t.Fatalf("expected tenant_8 job count 0, got %d", len(tenant8Jobs))
	}

	tenant8Audits, err := auditRuntime.ListTenantAuditLogs("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 audit logs failed: %v", err)
	}
	if len(tenant8Audits) != 0 {
		t.Fatalf("expected tenant_8 audit count 0, got %d", len(tenant8Audits))
	}
}

func TestJobEngineIntegrationFinalDenyCases(t *testing.T) {
	dispatchRuntime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())
	auditRuntime := NewJobAuditLogPersistenceRuntime(DefaultJobAuditLogPersistenceRuntimeConfig())

	_, missingTenantDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		JobType: JobDispatchTypeCleanup,
		Payload: map[string]string{"target": "stale_instances"},
	})
	if err != ErrJobDispatchMissingTenant {
		t.Fatalf("expected missing tenant dispatch error, got %v", err)
	}
	if missingTenantDecision.Reason != JobDispatchReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", missingTenantDecision.Reason)
	}

	_, invalidJobDecision, err := dispatchRuntime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  "DROP_DATABASE",
		Payload:  map[string]string{"target": "x"},
	})
	if err != ErrJobDispatchInvalidJobType {
		t.Fatalf("expected invalid job type error, got %v", err)
	}
	if invalidJobDecision.Reason != JobDispatchReasonInvalidJobType {
		t.Fatalf("expected invalid job type reason, got %s", invalidJobDecision.Reason)
	}

	_, invalidAuditDecision, err := auditRuntime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: "JOB_UNKNOWN",
		Message:   "unknown event",
	})
	if err != ErrJobAuditInvalidEventType {
		t.Fatalf("expected invalid audit event error, got %v", err)
	}
	if invalidAuditDecision.Reason != JobAuditReasonInvalidEventType {
		t.Fatalf("expected invalid audit event reason, got %s", invalidAuditDecision.Reason)
	}

	_, missingMessageDecision, err := auditRuntime.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:  "tenant_7",
		JobID:     "tenant_job_1",
		JobType:   JobDispatchTypeCleanup,
		EventType: JobAuditEventQueued,
	})
	if err != ErrJobAuditMissingMessage {
		t.Fatalf("expected missing audit message error, got %v", err)
	}
	if missingMessageDecision.Reason != JobAuditReasonMissingMessage {
		t.Fatalf("expected missing audit message reason, got %s", missingMessageDecision.Reason)
	}
}
