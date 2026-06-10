package jobsqueue

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type jqAuditEventRecord struct {
	AuditID     string
	TenantID    string
	JobID       string
	EventType   string
	ActorRef    string
	Status      string
	AttemptNo   int
	Message     string
	Metadata    map[string]any
	OccurredAt  time.Time
}

type jqDispatchPolicyRecord struct {
	TenantID          string
	QueueKey          string
	PreferredPool     string
	EffectiveQueueKey string
	DispatchMode      string
	TenantAware       bool
}

type extendedJobsQueueIntegrationStore struct {
	mu               sync.Mutex
	nowFn            func() time.Time
	jobSeq           int
	auditSeq         int
	jobs             map[string]*jqRuntimeJobRecord
	auditEvents      []jqAuditEventRecord
	dispatchPolicies map[string]jqDispatchPolicyRecord
}

func newExtendedJobsQueueIntegrationStore() *extendedJobsQueueIntegrationStore {
	return &extendedJobsQueueIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		jobs:             make(map[string]*jqRuntimeJobRecord),
		auditEvents:      make([]jqAuditEventRecord, 0),
		dispatchPolicies: make(map[string]jqDispatchPolicyRecord),
	}
}

func (s *extendedJobsQueueIntegrationStore) setDispatchPolicy(policy jqDispatchPolicyRecord) {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := strings.TrimSpace(policy.TenantID) + "|" + strings.TrimSpace(policy.QueueKey)
	s.dispatchPolicies[key] = policy
}

func (s *extendedJobsQueueIntegrationStore) EnqueueJob(_ context.Context, cmd EnqueueJobCommand) (EnqueueJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	targetTenantID := strings.TrimSpace(cmd.TenantID)
	dedupKey := strings.TrimSpace(cmd.DedupKey)

	if dedupKey != "" {
		for _, job := range s.jobs {
			if job.TenantID == targetTenantID && job.DedupKey == dedupKey {
				return EnqueueJobResult{
					JobID:        job.JobID,
					Status:       job.Status,
					DedupMatched: true,
					ScheduledAt:  cloneTimePtr(job.ScheduledAt),
				}, nil
			}
		}
	}

	s.jobSeq++
	jobID := fmt.Sprintf("job-%03d", s.jobSeq)

	status := "queued"
	if cmd.ScheduledAt != nil {
		status = "scheduled"
	}

	job := &jqRuntimeJobRecord{
		JobID:          jobID,
		TenantID:       targetTenantID,
		QueueKey:       strings.TrimSpace(cmd.QueueKey),
		JobKey:         strings.TrimSpace(cmd.JobKey),
		JobType:        strings.TrimSpace(cmd.JobType),
		Priority:       strings.TrimSpace(cmd.Priority),
		Status:         status,
		DedupKey:       dedupKey,
		Payload:        cloneMap(cmd.Payload),
		ScheduledAt:    cloneTimePtr(cmd.ScheduledAt),
		RequestedBy:    strings.TrimSpace(cmd.RequestedBy),
		MaxAttempts:    cmd.MaxAttempts,
		AttemptNo:      0,
		CreatedAt:      now,
		UpdatedAt:      now,
		OutputPayload:  map[string]any{},
	}
	s.jobs[jobID] = job

	return EnqueueJobResult{
		JobID:        job.JobID,
		Status:       job.Status,
		DedupMatched: false,
		ScheduledAt:  cloneTimePtr(job.ScheduledAt),
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) ClaimNextJob(_ context.Context, cmd ClaimJobCommand) (ClaimJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	targetTenantID := strings.TrimSpace(cmd.TenantID)
	queueKey := strings.TrimSpace(cmd.QueueKey)

	var selected *jqRuntimeJobRecord
	for _, job := range s.jobs {
		if job.TenantID != targetTenantID {
			continue
		}
		if job.QueueKey != queueKey {
			continue
		}
		if job.Status != "queued" && job.Status != "scheduled" {
			continue
		}
		if job.ScheduledAt != nil && job.ScheduledAt.After(now) {
			continue
		}

		if selected == nil || priorityRank(job.Priority) < priorityRank(selected.Priority) ||
			(priorityRank(job.Priority) == priorityRank(selected.Priority) && job.CreatedAt.Before(selected.CreatedAt)) {
			selected = job
		}
	}

	if selected == nil {
		return ClaimJobResult{Claimed: false}, nil
	}

	selected.Status = "processing"
	selected.WorkerID = strings.TrimSpace(cmd.WorkerID)
	selected.AttemptNo++
	leaseExpiresAt := now.Add(time.Duration(cmd.LeaseSeconds) * time.Second)
	selected.LeaseExpiresAt = &leaseExpiresAt
	selected.UpdatedAt = now

	return ClaimJobResult{
		Claimed:        true,
		JobID:          selected.JobID,
		QueueKey:       selected.QueueKey,
		JobKey:         selected.JobKey,
		JobType:        selected.JobType,
		Priority:       selected.Priority,
		Status:         selected.Status,
		AttemptNo:      selected.AttemptNo,
		Payload:        cloneMap(selected.Payload),
		LeaseExpiresAt: cloneTimePtr(selected.LeaseExpiresAt),
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) UpdateJobProgress(_ context.Context, cmd UpdateJobProgressCommand) (UpdateJobProgressResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return UpdateJobProgressResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return UpdateJobProgressResult{}, fmt.Errorf("tenant mismatch")
	}

	if job.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return UpdateJobProgressResult{}, fmt.Errorf("worker mismatch")
	}

	if job.AttemptNo != cmd.AttemptNo {
		return UpdateJobProgressResult{}, fmt.Errorf("attempt mismatch")
	}

	now := s.nowFn().UTC()
	job.Status = strings.TrimSpace(cmd.Status)
	job.ProgressPercent = cmd.ProgressPercent
	job.LastMessage = strings.TrimSpace(cmd.Message)
	job.UpdatedAt = now

	if job.Status == "processing" && cmd.LeaseExtendSeconds > 0 {
		leaseExpiresAt := now.Add(time.Duration(cmd.LeaseExtendSeconds) * time.Second)
		job.LeaseExpiresAt = &leaseExpiresAt
	} else if job.Status != "processing" {
		job.LeaseExpiresAt = nil
	}

	return UpdateJobProgressResult{
		JobID:           job.JobID,
		Status:          job.Status,
		ProgressPercent: job.ProgressPercent,
		AttemptNo:       job.AttemptNo,
		Message:         job.LastMessage,
		LeaseExpiresAt:  cloneTimePtr(job.LeaseExpiresAt),
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) CompleteJob(_ context.Context, cmd CompleteJobCommand) (CompleteJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return CompleteJobResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return CompleteJobResult{}, fmt.Errorf("tenant mismatch")
	}

	if job.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return CompleteJobResult{}, fmt.Errorf("worker mismatch")
	}

	if job.AttemptNo != cmd.AttemptNo {
		return CompleteJobResult{}, fmt.Errorf("attempt mismatch")
	}

	now := s.nowFn().UTC()
	job.Status = strings.TrimSpace(cmd.Status)
	job.LastMessage = strings.TrimSpace(cmd.CompletionNote)
	job.ErrorCode = strings.TrimSpace(cmd.ErrorCode)
	job.OutputPayload = cloneMap(cmd.OutputPayload)
	job.LeaseExpiresAt = nil
	job.UpdatedAt = now

	return CompleteJobResult{
		JobID:          job.JobID,
		Status:         job.Status,
		AttemptNo:      job.AttemptNo,
		CompletionNote: job.LastMessage,
		ErrorCode:      job.ErrorCode,
		OutputPayload:  cloneMap(job.OutputPayload),
		LeaseReleased:  true,
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) RecoverJob(_ context.Context, cmd RecoverJobCommand) (RecoverJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return RecoverJobResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return RecoverJobResult{}, fmt.Errorf("tenant mismatch")
	}

	job.WorkerID = ""
	job.LeaseExpiresAt = nil
	job.UpdatedAt = s.nowFn().UTC()

	switch strings.TrimSpace(cmd.ActionType) {
	case "retry":
		job.Status = "queued"
	case "requeue":
		job.Status = "queued"
		if strings.TrimSpace(cmd.TargetQueueKey) != "" {
			job.QueueKey = strings.TrimSpace(cmd.TargetQueueKey)
		}
	case "dead_letter":
		job.Status = "dead_letter"
	default:
		return RecoverJobResult{}, fmt.Errorf("unsupported action: %s", cmd.ActionType)
	}

	if cmd.ResetAttempts {
		job.AttemptNo = 0
	}

	return RecoverJobResult{
		JobID:         job.JobID,
		Status:        job.Status,
		QueueKey:      job.QueueKey,
		AttemptNo:     job.AttemptNo,
		LeaseReleased: true,
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) RecordJobAuditEvent(_ context.Context, cmd RecordJobAuditEventCommand) (RecordJobAuditEventResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.auditSeq++
	auditID := fmt.Sprintf("audit-%03d", s.auditSeq)

	s.auditEvents = append(s.auditEvents, jqAuditEventRecord{
		AuditID:    auditID,
		TenantID:   strings.TrimSpace(cmd.TenantID),
		JobID:      strings.TrimSpace(cmd.JobID),
		EventType:  strings.TrimSpace(cmd.EventType),
		ActorRef:   strings.TrimSpace(cmd.ActorRef),
		Status:     strings.TrimSpace(cmd.Status),
		AttemptNo:  cmd.AttemptNo,
		Message:    strings.TrimSpace(cmd.Message),
		Metadata:   cloneMap(cmd.Metadata),
		OccurredAt: s.nowFn().UTC(),
	})

	return RecordJobAuditEventResult{AuditID: auditID}, nil
}

func (s *extendedJobsQueueIntegrationStore) ResolveDispatchPolicy(_ context.Context, cmd ResolveDispatchCommand) (ResolveDispatchResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	key := strings.TrimSpace(cmd.TenantID) + "|" + strings.TrimSpace(cmd.QueueKey)
	if policy, ok := s.dispatchPolicies[key]; ok {
		return ResolveDispatchResult{
			EffectiveQueueKey: firstNonEmpty(strings.TrimSpace(policy.EffectiveQueueKey), strings.TrimSpace(cmd.QueueKey)),
			PreferredPool:     strings.TrimSpace(policy.PreferredPool),
			DispatchMode:      strings.TrimSpace(policy.DispatchMode),
			TenantAware:       policy.TenantAware,
		}, nil
	}

	if strings.TrimSpace(cmd.TenantID) != "" {
		return ResolveDispatchResult{
			EffectiveQueueKey: strings.TrimSpace(cmd.QueueKey),
			PreferredPool:     "tenant-default-pool",
			DispatchMode:      "tenant_pinned",
			TenantAware:       true,
		}, nil
	}

	return ResolveDispatchResult{
		EffectiveQueueKey: strings.TrimSpace(cmd.QueueKey),
		PreferredPool:     "shared-default",
		DispatchMode:      "shared_pool",
		TenantAware:       false,
	}, nil
}

func (s *extendedJobsQueueIntegrationStore) snapshotJob(jobID string) (jqRuntimeJobRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[jobID]
	if !ok {
		return jqRuntimeJobRecord{}, false
	}

	out := *job
	out.Payload = cloneMap(job.Payload)
	out.OutputPayload = cloneMap(job.OutputPayload)
	out.ScheduledAt = cloneTimePtr(job.ScheduledAt)
	out.LeaseExpiresAt = cloneTimePtr(job.LeaseExpiresAt)
	return out, true
}

func (s *extendedJobsQueueIntegrationStore) auditCountForJob(jobID string) int {
	s.mu.Lock()
	defer s.mu.Unlock()

	count := 0
	for _, item := range s.auditEvents {
		if item.JobID == jobID {
			count++
		}
	}
	return count
}

func TestJobsQueueExtendedIntegration_DispatchAuditSuccessFlow(t *testing.T) {
	store := newExtendedJobsQueueIntegrationStore()
	store.setDispatchPolicy(jqDispatchPolicyRecord{
		TenantID:          "tenant-a",
		QueueKey:          "notifications-email",
		PreferredPool:     "tenant-a-burst",
		EffectiveQueueKey: "notifications-email",
		DispatchMode:      "tenant_pinned",
		TenantAware:       true,
	})

	enqueueUsecase := NewEnqueueJobUsecase(store)
	dispatchUsecase := NewResolveDispatchUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)
	progressUsecase := NewUpdateJobProgressUsecase(store)
	completeUsecase := NewCompleteJobUsecase(store)
	auditUsecase := NewJobAuditUsecase(store)

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 15, 0, 0, 0, time.UTC) }
	enqueueUsecase.nowFn = store.nowFn
	dispatchUsecase.nowFn = store.nowFn
	claimUsecase.nowFn = store.nowFn
	progressUsecase.nowFn = store.nowFn
	completeUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn

	enqueueResp, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-mail-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("enqueue hatasi: %v", err)
	}

	dispatchResp, err := dispatchUsecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          enqueueResp.JobID,
		Priority:       "high",
		AvailablePools: []string{"tenant-a-burst", "shared-default"},
		FallbackPool:   "fallback-shared",
	})
	if err != nil {
		t.Fatalf("dispatch hatasi: %v", err)
	}

	if dispatchResp.SelectedPool != "tenant-a-burst" {
		t.Fatalf("beklenen selected_pool tenant-a-burst, alinan: %s", dispatchResp.SelectedPool)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     enqueueResp.JobID,
		EventType: "enqueued",
		ActorRef:  "system-api",
		Status:    "queued",
		AttemptNo: 0,
		Message:   "job kuyruğa alındı",
	}); err != nil {
		t.Fatalf("audit enqueued hatasi: %v", err)
	}

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 15, 1, 0, 0, time.UTC) }
	claimUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn

	claimResp, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("claim hatasi: %v", err)
	}

	if !claimResp.Claimed {
		t.Fatalf("job claim edilmeliydi")
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     claimResp.JobID,
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
		Message:   "worker claim etti",
	}); err != nil {
		t.Fatalf("audit claimed hatasi: %v", err)
	}

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 15, 2, 0, 0, time.UTC) }
	progressUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn

	if _, err := progressUsecase.Update(context.Background(), UpdateJobProgressRequest{
		TenantID:           "tenant-a",
		JobID:              claimResp.JobID,
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    50,
		Message:            "yarısı tamamlandı",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}); err != nil {
		t.Fatalf("progress hatasi: %v", err)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     claimResp.JobID,
		EventType: "progressed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
		Message:   "yarısı tamamlandı",
	}); err != nil {
		t.Fatalf("audit progressed hatasi: %v", err)
	}

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 15, 3, 0, 0, time.UTC) }
	completeUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn

	if _, err := completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          claimResp.JobID,
		WorkerID:       "worker-01",
		Status:         "succeeded",
		AttemptNo:      1,
		CompletionNote: "iş tamamlandı",
		OutputPayload:  map[string]any{"sent_count": 10},
	}); err != nil {
		t.Fatalf("complete hatasi: %v", err)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     claimResp.JobID,
		EventType: "completed",
		ActorRef:  "worker-01",
		Status:    "succeeded",
		AttemptNo: 1,
		Message:   "iş tamamlandı",
	}); err != nil {
		t.Fatalf("audit completed hatasi: %v", err)
	}

	job, ok := store.snapshotJob(claimResp.JobID)
	if !ok {
		t.Fatalf("job snapshot bulunamadi")
	}

	if job.Status != "succeeded" {
		t.Fatalf("beklenen final job status succeeded, alinan: %s", job.Status)
	}

	if store.auditCountForJob(claimResp.JobID) != 4 {
		t.Fatalf("beklenen 4 audit kaydi, alinan: %d", store.auditCountForJob(claimResp.JobID))
	}
}

func TestJobsQueueExtendedIntegration_BackoffRetryDispatchFlow(t *testing.T) {
	store := newExtendedJobsQueueIntegrationStore()
	enqueueUsecase := NewEnqueueJobUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)
	completeUsecase := NewCompleteJobUsecase(store)
	backoffUsecase := NewCalculateJobBackoffUsecase()
	recoverUsecase := NewRecoverJobUsecase(store)
	dispatchUsecase := NewResolveDispatchUsecase(store)
	auditUsecase := NewJobAuditUsecase(store)

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 16, 0, 0, 0, time.UTC) }
	enqueueUsecase.nowFn = store.nowFn
	claimUsecase.nowFn = store.nowFn
	completeUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn
	backoffUsecase.nowFn = store.nowFn
	dispatchUsecase.nowFn = store.nowFn

	enqueueResp, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-mail-002",
		JobType:     "email.send",
		Priority:    "normal",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("enqueue hatasi: %v", err)
	}

	claimResp, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("claim hatasi: %v", err)
	}

	if _, err := completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          claimResp.JobID,
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
		CompletionNote: "timeout",
		ErrorCode:      "EMAIL_TIMEOUT",
	}); err != nil {
		t.Fatalf("complete failed hatasi: %v", err)
	}

	backoffResp, err := backoffUsecase.Calculate(context.Background(), CalculateJobBackoffRequest{
		TenantID:         "tenant-a",
		JobID:            enqueueResp.JobID,
		Strategy:         "exponential",
		AttemptNo:        2,
		BaseDelaySeconds: 30,
		MaxDelaySeconds:  600,
		JitterPercent:    0,
		LastErrorCode:    "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("backoff hatasi: %v", err)
	}

	if backoffResp.PlannedDelaySeconds != 60 {
		t.Fatalf("beklenen planned delay 60, alinan: %d", backoffResp.PlannedDelaySeconds)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     enqueueResp.JobID,
		EventType: "failed",
		ActorRef:  "worker-01",
		Status:    "failed",
		AttemptNo: 1,
		Message:   "timeout",
		Metadata:  map[string]any{"planned_delay_seconds": backoffResp.PlannedDelaySeconds},
	}); err != nil {
		t.Fatalf("audit failed hatasi: %v", err)
	}

	if _, err := recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         enqueueResp.JobID,
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "timeout geçici görünüyor",
		ResetAttempts: false,
	}); err != nil {
		t.Fatalf("retry hatasi: %v", err)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     enqueueResp.JobID,
		EventType: "retried",
		ActorRef:  "worker-01",
		Status:    "queued",
		AttemptNo: 1,
		Message:   "retry kuyruğa döndü",
	}); err != nil {
		t.Fatalf("audit retried hatasi: %v", err)
	}

	dispatchResp, err := dispatchUsecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "notifications-email",
		JobID:          enqueueResp.JobID,
		Priority:       "normal",
		AvailablePools: []string{"tenant-default-pool", "shared-default"},
		FallbackPool:   "fallback-shared",
	})
	if err != nil {
		t.Fatalf("dispatch hatasi: %v", err)
	}

	if dispatchResp.SelectedPool == "" {
		t.Fatalf("selected_pool bos olmamaliydi")
	}

	if store.auditCountForJob(enqueueResp.JobID) != 2 {
		t.Fatalf("beklenen 2 audit kaydi, alinan: %d", store.auditCountForJob(enqueueResp.JobID))
	}
}

func TestJobsQueueExtendedIntegration_RequeueDeadLetterTenantIsolationFlow(t *testing.T) {
	store := newExtendedJobsQueueIntegrationStore()
	enqueueUsecase := NewEnqueueJobUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)
	completeUsecase := NewCompleteJobUsecase(store)
	recoverUsecase := NewRecoverJobUsecase(store)
	dispatchUsecase := NewResolveDispatchUsecase(store)
	auditUsecase := NewJobAuditUsecase(store)

	store.nowFn = func() time.Time { return time.Date(2026, 4, 25, 17, 0, 0, 0, time.UTC) }
	enqueueUsecase.nowFn = store.nowFn
	claimUsecase.nowFn = store.nowFn
	completeUsecase.nowFn = store.nowFn
	recoverUsecase.nowFn = store.nowFn
	dispatchUsecase.nowFn = store.nowFn
	auditUsecase.nowFn = store.nowFn

	tenantAJob, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-mail-a",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("tenant-a enqueue hatasi: %v", err)
	}

	if _, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-b",
		QueueKey:    "notifications-email",
		JobKey:      "job-mail-b",
		JobType:     "email.send",
		Priority:    "normal",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	}); err != nil {
		t.Fatalf("tenant-b enqueue hatasi: %v", err)
	}

	claimResp, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-a",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-a claim hatasi: %v", err)
	}

	if _, err := completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          claimResp.JobID,
		WorkerID:       "worker-a",
		Status:         "failed",
		AttemptNo:      1,
		CompletionNote: "kalıcı hata",
		ErrorCode:      "EMAIL_HARD_FAIL",
	}); err != nil {
		t.Fatalf("tenant-a fail hatasi: %v", err)
	}

	requeueResp, err := recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:       "tenant-a",
		JobID:          tenantAJob.JobID,
		ActionType:     "requeue",
		RequestedBy:    "worker-a",
		TargetQueueKey: "priority-critical",
		Reason:         "öncelikli kuyruğa taşı",
		ResetAttempts:  false,
	})
	if err != nil {
		t.Fatalf("requeue hatasi: %v", err)
	}

	if requeueResp.QueueKey != "priority-critical" {
		t.Fatalf("beklenen queue_key priority-critical, alinan: %s", requeueResp.QueueKey)
	}

	dispatchResp, err := dispatchUsecase.Resolve(context.Background(), ResolveDispatchRequest{
		TenantID:       "tenant-a",
		QueueKey:       "priority-critical",
		JobID:          tenantAJob.JobID,
		Priority:       "critical",
		AvailablePools: []string{"priority-critical", "tenant-default-pool"},
		FallbackPool:   "fallback-shared",
	})
	if err != nil {
		t.Fatalf("dispatch hatasi: %v", err)
	}

	if dispatchResp.SelectedPool == "" {
		t.Fatalf("dispatch selected pool bos olmamaliydi")
	}

	deadLetterResp, err := recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         tenantAJob.JobID,
		ActionType:    "dead_letter",
		RequestedBy:   "worker-a",
		Reason:        "kalıcı hata",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("dead-letter hatasi: %v", err)
	}

	if deadLetterResp.Status != "dead_letter" {
		t.Fatalf("beklenen dead_letter status, alinan: %s", deadLetterResp.Status)
	}

	if _, err := auditUsecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     tenantAJob.JobID,
		EventType: "dead_lettered",
		ActorRef:  "worker-a",
		Status:    "dead_letter",
		AttemptNo: 1,
		Message:   "kalıcı hata nedeniyle dead-letter",
	}); err != nil {
		t.Fatalf("audit dead_lettered hatasi: %v", err)
	}

	_, err = recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-b",
		JobID:         tenantAJob.JobID,
		ActionType:    "retry",
		RequestedBy:   "worker-b",
		Reason:        "başka tenant müdahalesi",
		ResetAttempts: false,
	})
	if err == nil {
		t.Fatalf("tenant-b tenant-a job'u uzerinde recover yapamamaliydi")
	}

	job, ok := store.snapshotJob(tenantAJob.JobID)
	if !ok {
		t.Fatalf("job snapshot bulunamadi")
	}

	if job.Status != "dead_letter" {
		t.Fatalf("beklenen final status dead_letter, alinan: %s", job.Status)
	}

	if store.auditCountForJob(tenantAJob.JobID) != 1 {
		t.Fatalf("beklenen 1 audit kaydi, alinan: %d", store.auditCountForJob(tenantAJob.JobID))
	}
}
