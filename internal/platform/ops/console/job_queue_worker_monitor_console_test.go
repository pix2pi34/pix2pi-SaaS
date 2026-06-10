package opsconsole

import (
	"strings"
	"testing"
	"time"
)

func newJobQueueWorkerMonitorRuntimeForTest(t *testing.T) *JobQueueWorkerMonitorConsoleRuntime {
	t.Helper()

	runtime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())

	_, _, err := runtime.UpsertJob(JobMonitorEntry{
		TenantID:      "tenant_7",
		JobID:         "job_queued_1",
		JobType:       "WEBHOOK_DELIVERY",
		Queue:         "webhooks",
		Priority:      "HIGH",
		State:         JobMonitorStateQueued,
		Attempt:       1,
		CorrelationID: "corr-job-1",
		Metadata:      map[string]string{"delivery_id": "delivery_1"},
	})
	if err != nil {
		t.Fatalf("upsert queued job failed: %v", err)
	}

	_, _, err = runtime.UpsertJob(JobMonitorEntry{
		TenantID:  "tenant_7",
		JobID:     "job_failed_1",
		JobType:   "EMAIL_DELIVERY",
		Queue:     "notifications",
		Priority:  "NORMAL",
		State:     JobMonitorStateFailed,
		Attempt:   2,
		LastError: "smtp timeout",
	})
	if err != nil {
		t.Fatalf("upsert failed job failed: %v", err)
	}

	_, _, err = runtime.UpsertWorker(WorkerMonitorEntry{
		TenantID:       "tenant_7",
		WorkerID:       "worker_1",
		Queue:          "webhooks",
		Status:         WorkerMonitorStatusActive,
		Concurrency:    4,
		ProcessedCount: 20,
		FailedCount:    1,
		HeartbeatAt:    time.Now().UTC().Format(time.RFC3339Nano),
		Metadata:       map[string]string{"node": "node-a"},
	})
	if err != nil {
		t.Fatalf("upsert worker failed: %v", err)
	}

	return runtime
}

func TestJobQueueWorkerMonitorConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newJobQueueWorkerMonitorRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:          "tenant_7",
		ViewerTenantID:    "platform",
		IncludeWorkers:    true,
		IncludeFailedJobs: true,
		CorrelationID:     "corr-snapshot-1",
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
	if snapshot.JobCount != 2 {
		t.Fatalf("expected job count 2, got %d", snapshot.JobCount)
	}
	if snapshot.WorkerCount != 1 {
		t.Fatalf("expected worker count 1, got %d", snapshot.WorkerCount)
	}
	if snapshot.QueuedCount != 1 {
		t.Fatalf("expected queued count 1, got %d", snapshot.QueuedCount)
	}
	if snapshot.FailedCount != 1 {
		t.Fatalf("expected failed count 1, got %d", snapshot.FailedCount)
	}
	if snapshot.ActiveWorkerCount != 1 {
		t.Fatalf("expected active worker count 1, got %d", snapshot.ActiveWorkerCount)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeQueueFilter(t *testing.T) {
	runtime := newJobQueueWorkerMonitorRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:          "tenant_7",
		QueueFilter:       "webhooks",
		IncludeWorkers:    true,
		IncludeFailedJobs: true,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if snapshot.JobCount != 1 {
		t.Fatalf("expected filtered job count 1, got %d", snapshot.JobCount)
	}
	if snapshot.WorkerCount != 1 {
		t.Fatalf("expected filtered worker count 1, got %d", snapshot.WorkerCount)
	}
	if snapshot.Jobs[0].Queue != "WEBHOOKS" {
		t.Fatalf("expected WEBHOOKS queue, got %s", snapshot.Jobs[0].Queue)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeHidesFailedJobsWhenDisabled(t *testing.T) {
	runtime := newJobQueueWorkerMonitorRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:          "tenant_7",
		IncludeWorkers:    false,
		IncludeFailedJobs: false,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.JobCount != 1 {
		t.Fatalf("expected only non-failed jobs, got %d", snapshot.JobCount)
	}
	if snapshot.FailedCount != 0 {
		t.Fatalf("expected failed count hidden as 0, got %d", snapshot.FailedCount)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{})
	if err != ErrJobMonitorMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != JobMonitorReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newJobQueueWorkerMonitorRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrJobMonitorCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != JobMonitorReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeRejectsInvalidJobState(t *testing.T) {
	runtime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())

	_, decision, err := runtime.UpsertJob(JobMonitorEntry{
		TenantID: "tenant_7",
		JobID:    "job_1",
		Queue:    "webhooks",
		State:    "UNKNOWN",
	})
	if err != ErrJobMonitorInvalidJobState {
		t.Fatalf("expected invalid job state error, got %v", err)
	}
	if decision.Reason != JobMonitorReasonInvalidJobState {
		t.Fatalf("expected invalid job state reason, got %s", decision.Reason)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeRejectsInvalidWorkerStatus(t *testing.T) {
	runtime := NewJobQueueWorkerMonitorConsoleRuntime(DefaultJobQueueWorkerMonitorConsoleConfig())

	_, decision, err := runtime.UpsertWorker(WorkerMonitorEntry{
		TenantID: "tenant_7",
		WorkerID: "worker_1",
		Queue:    "webhooks",
		Status:   "BROKEN",
	})
	if err != ErrJobMonitorInvalidWorkerStatus {
		t.Fatalf("expected invalid worker status error, got %v", err)
	}
	if decision.Reason != JobMonitorReasonInvalidWorkerStatus {
		t.Fatalf("expected invalid worker status reason, got %s", decision.Reason)
	}
}

func TestJobQueueWorkerMonitorConsoleRuntimeDetectsStaleWorker(t *testing.T) {
	config := DefaultJobQueueWorkerMonitorConsoleConfig()
	config.WorkerStaleSeconds = 1
	runtime := NewJobQueueWorkerMonitorConsoleRuntime(config)

	_, _, err := runtime.UpsertWorker(WorkerMonitorEntry{
		TenantID:    "tenant_7",
		WorkerID:    "worker_stale",
		Queue:       "webhooks",
		Status:      WorkerMonitorStatusActive,
		HeartbeatAt: time.Now().UTC().Add(-5 * time.Minute).Format(time.RFC3339Nano),
	})
	if err != nil {
		t.Fatalf("upsert stale worker failed: %v", err)
	}

	snapshot, _, err := runtime.BuildSnapshot(JobQueueWorkerMonitorRequest{
		TenantID:       "tenant_7",
		IncludeWorkers: true,
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.StaleWorkerCount != 1 {
		t.Fatalf("expected stale worker count 1, got %d", snapshot.StaleWorkerCount)
	}
	if snapshot.Workers[0].Status != WorkerMonitorStatusStale {
		t.Fatalf("expected worker status STALE, got %s", snapshot.Workers[0].Status)
	}
}

func TestNewOpsConsoleRuntimeID(t *testing.T) {
	id := NewOpsConsoleRuntimeID("ops_console_")
	if !strings.HasPrefix(id, "ops_console_") {
		t.Fatalf("unexpected id %s", id)
	}
}
