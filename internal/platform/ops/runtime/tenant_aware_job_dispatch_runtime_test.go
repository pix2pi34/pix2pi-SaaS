package opsruntime

import (
	"strings"
	"testing"
)

func TestTenantAwareJobDispatchRuntimeDispatchesJob(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	job, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:      "tenant_7",
		JobType:       JobDispatchTypeWebhookDelivery,
		Queue:         "webhooks",
		Priority:      JobDispatchPriorityHigh,
		Payload:       map[string]string{"delivery_id": "delivery_1"},
		DedupeKey:     "delivery_1",
		RequestedBy:   "system",
		CorrelationID: "corr-job-1",
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected dispatch allowed, got reason=%s", decision.Reason)
	}
	if job.JobID == "" {
		t.Fatal("expected job id")
	}
	if job.State != JobDispatchStateQueued {
		t.Fatalf("expected QUEUED state, got %s", job.State)
	}
	if job.Queue != "webhooks" {
		t.Fatalf("expected webhooks queue, got %s", job.Queue)
	}
	if job.Payload["delivery_id"] != "delivery_1" {
		t.Fatalf("expected payload delivery_1, got %s", job.Payload["delivery_id"])
	}
}

func TestTenantAwareJobDispatchRuntimeUsesDefaults(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	job, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeCleanup,
		Payload:  map[string]string{"target": "stale_instances"},
	})
	if err != nil {
		t.Fatalf("dispatch default job failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected dispatch allowed, got reason=%s", decision.Reason)
	}
	if job.Queue != "default" {
		t.Fatalf("expected default queue, got %s", job.Queue)
	}
	if job.Priority != JobDispatchPriorityNormal {
		t.Fatalf("expected NORMAL priority, got %s", job.Priority)
	}
}

func TestTenantAwareJobDispatchRuntimeMarksDispatched(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	job, _, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeEmailDelivery,
		Payload:  map[string]string{"email_id": "email_1"},
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}

	updated, decision, err := runtime.MarkDispatched("tenant_7", job.JobID)
	if err != nil {
		t.Fatalf("mark dispatched failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected mark dispatched allowed, got reason=%s", decision.Reason)
	}
	if updated.State != JobDispatchStateDispatched {
		t.Fatalf("expected DISPATCHED, got %s", updated.State)
	}
}

func TestTenantAwareJobDispatchRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		JobType: JobDispatchTypeCleanup,
		Payload: map[string]string{"target": "x"},
	})
	if err != ErrJobDispatchMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestTenantAwareJobDispatchRuntimeRejectsInvalidJobType(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  "DROP_DATABASE",
		Payload:  map[string]string{"target": "x"},
	})
	if err != ErrJobDispatchInvalidJobType {
		t.Fatalf("expected invalid job type error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonInvalidJobType {
		t.Fatalf("expected invalid job type reason, got %s", decision.Reason)
	}
}

func TestTenantAwareJobDispatchRuntimeRejectsInvalidPriority(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeCleanup,
		Priority: "URGENT",
		Payload:  map[string]string{"target": "x"},
	})
	if err != ErrJobDispatchInvalidPriority {
		t.Fatalf("expected invalid priority error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonInvalidPriority {
		t.Fatalf("expected invalid priority reason, got %s", decision.Reason)
	}
}

func TestTenantAwareJobDispatchRuntimeRejectsMissingPayload(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeCleanup,
	})
	if err != ErrJobDispatchMissingPayload {
		t.Fatalf("expected missing payload error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonMissingPayload {
		t.Fatalf("expected missing payload reason, got %s", decision.Reason)
	}
}

func TestTenantAwareJobDispatchRuntimeRejectsDuplicateDedupeKey(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, _, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_1"},
		DedupeKey: "delivery_1",
	})
	if err != nil {
		t.Fatalf("first dispatch failed: %v", err)
	}

	_, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_1"},
		DedupeKey: "delivery_1",
	})
	if err != ErrJobDispatchDuplicateDedupe {
		t.Fatalf("expected duplicate dedupe error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonDuplicateDedupe {
		t.Fatalf("expected duplicate dedupe reason, got %s", decision.Reason)
	}
	if decision.JobID == "" {
		t.Fatal("expected existing job id in duplicate decision")
	}
}

func TestTenantAwareJobDispatchRuntimeDedupeIsTenantScoped(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	_, _, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_7",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_1"},
		DedupeKey: "delivery_1",
	})
	if err != nil {
		t.Fatalf("tenant_7 dispatch failed: %v", err)
	}

	job, decision, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID:  "tenant_8",
		JobType:   JobDispatchTypeWebhookDelivery,
		Payload:   map[string]string{"delivery_id": "delivery_1"},
		DedupeKey: "delivery_1",
	})
	if err != nil {
		t.Fatalf("tenant_8 dispatch should be allowed, got %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected tenant_8 dispatch allowed, got reason=%s", decision.Reason)
	}
	if job.TenantID != "tenant_8" {
		t.Fatalf("expected tenant_8 job, got %s", job.TenantID)
	}
}

func TestTenantAwareJobDispatchRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	job, _, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeReportBuild,
		Queue:    "reports",
		Payload:  map[string]string{"report_id": "report_1"},
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}

	got, err := runtime.GetJob("tenant_7", job.JobID)
	if err != nil {
		t.Fatalf("get job failed: %v", err)
	}
	if got.JobID != job.JobID {
		t.Fatalf("expected job id %s, got %s", job.JobID, got.JobID)
	}

	_, err = runtime.GetJob("tenant_8", job.JobID)
	if err != ErrJobDispatchCrossTenant {
		t.Fatalf("expected cross tenant get job error, got %v", err)
	}

	tenantJobs, err := runtime.ListTenantJobs("tenant_7")
	if err != nil {
		t.Fatalf("list tenant jobs failed: %v", err)
	}
	if len(tenantJobs) != 1 {
		t.Fatalf("expected tenant job count 1, got %d", len(tenantJobs))
	}

	queueJobs, err := runtime.ListTenantQueueJobs("tenant_7", "reports")
	if err != nil {
		t.Fatalf("list tenant queue jobs failed: %v", err)
	}
	if len(queueJobs) != 1 {
		t.Fatalf("expected queue job count 1, got %d", len(queueJobs))
	}

	tenant8Jobs, err := runtime.ListTenantJobs("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 jobs failed: %v", err)
	}
	if len(tenant8Jobs) != 0 {
		t.Fatalf("expected tenant_8 job count 0, got %d", len(tenant8Jobs))
	}
}

func TestTenantAwareJobDispatchRuntimeMarkDispatchedCrossTenantDenied(t *testing.T) {
	runtime := NewTenantAwareJobDispatchRuntime(DefaultTenantAwareJobDispatchRuntimeConfig())

	job, _, err := runtime.DispatchJob(TenantAwareJobDispatchRequest{
		TenantID: "tenant_7",
		JobType:  JobDispatchTypeCleanup,
		Payload:  map[string]string{"target": "x"},
	})
	if err != nil {
		t.Fatalf("dispatch job failed: %v", err)
	}

	_, decision, err := runtime.MarkDispatched("tenant_8", job.JobID)
	if err != ErrJobDispatchCrossTenant {
		t.Fatalf("expected cross tenant mark dispatched error, got %v", err)
	}
	if decision.Reason != JobDispatchReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestTenantAwareJobDispatchRuntimeIDGenerator(t *testing.T) {
	jobID := NewTenantAwareJobID()
	if !strings.HasPrefix(jobID, "tenant_job_") {
		t.Fatalf("unexpected job id %s", jobID)
	}
}
