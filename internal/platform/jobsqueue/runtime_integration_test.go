package jobsqueue

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

type jqRuntimeJobRecord struct {
	JobID            string
	TenantID         string
	QueueKey         string
	JobKey           string
	JobType          string
	Priority         string
	Status           string
	DedupKey         string
	Payload          map[string]any
	ScheduledAt      *time.Time
	RequestedBy      string
	MaxAttempts      int
	AttemptNo        int
	WorkerID         string
	LeaseExpiresAt   *time.Time
	ProgressPercent  int
	LastMessage      string
	ErrorCode        string
	OutputPayload    map[string]any
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type jobsQueueRuntimeIntegrationStore struct {
	mu     sync.Mutex
	nowFn  func() time.Time
	seq    int
	jobs   map[string]*jqRuntimeJobRecord
}

func newJobsQueueRuntimeIntegrationStore() *jobsQueueRuntimeIntegrationStore {
	return &jobsQueueRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		jobs: make(map[string]*jqRuntimeJobRecord),
	}
}

func (s *jobsQueueRuntimeIntegrationStore) EnqueueJob(_ context.Context, cmd EnqueueJobCommand) (EnqueueJobResult, error) {
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

	s.seq++
	jobID := fmt.Sprintf("job-%03d", s.seq)

	status := "queued"
	if cmd.ScheduledAt != nil {
		status = "scheduled"
	}

	job := &jqRuntimeJobRecord{
		JobID:           jobID,
		TenantID:        targetTenantID,
		QueueKey:        strings.TrimSpace(cmd.QueueKey),
		JobKey:          strings.TrimSpace(cmd.JobKey),
		JobType:         strings.TrimSpace(cmd.JobType),
		Priority:        strings.TrimSpace(cmd.Priority),
		Status:          status,
		DedupKey:        dedupKey,
		Payload:         cloneMap(cmd.Payload),
		ScheduledAt:     cloneTimePtr(cmd.ScheduledAt),
		RequestedBy:     strings.TrimSpace(cmd.RequestedBy),
		MaxAttempts:     cmd.MaxAttempts,
		AttemptNo:       0,
		CreatedAt:       now,
		UpdatedAt:       now,
		OutputPayload:   map[string]any{},
	}
	s.jobs[jobID] = job

	return EnqueueJobResult{
		JobID:        job.JobID,
		Status:       job.Status,
		DedupMatched: false,
		ScheduledAt:  cloneTimePtr(job.ScheduledAt),
	}, nil
}

func (s *jobsQueueRuntimeIntegrationStore) ClaimNextJob(_ context.Context, cmd ClaimJobCommand) (ClaimJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	targetTenantID := strings.TrimSpace(cmd.TenantID)
	queueKey := strings.TrimSpace(cmd.QueueKey)

	candidates := make([]*jqRuntimeJobRecord, 0)
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
		candidates = append(candidates, job)
	}

	sort.Slice(candidates, func(i, j int) bool {
		pi := priorityRank(candidates[i].Priority)
		pj := priorityRank(candidates[j].Priority)
		if pi == pj {
			if candidates[i].CreatedAt.Equal(candidates[j].CreatedAt) {
				return candidates[i].JobID < candidates[j].JobID
			}
			return candidates[i].CreatedAt.Before(candidates[j].CreatedAt)
		}
		return pi < pj
	})

	if len(candidates) == 0 {
		return ClaimJobResult{
			Claimed: false,
		}, nil
	}

	job := candidates[0]
	job.Status = "processing"
	job.WorkerID = strings.TrimSpace(cmd.WorkerID)
	job.AttemptNo++
	leaseExpiresAt := now.Add(time.Duration(cmd.LeaseSeconds) * time.Second)
	job.LeaseExpiresAt = &leaseExpiresAt
	job.UpdatedAt = now

	return ClaimJobResult{
		Claimed:        true,
		JobID:          job.JobID,
		QueueKey:       job.QueueKey,
		JobKey:         job.JobKey,
		JobType:        job.JobType,
		Priority:       job.Priority,
		Status:         "processing",
		AttemptNo:      job.AttemptNo,
		Payload:        cloneMap(job.Payload),
		LeaseExpiresAt: cloneTimePtr(job.LeaseExpiresAt),
	}, nil
}

func (s *jobsQueueRuntimeIntegrationStore) UpdateJobProgress(_ context.Context, cmd UpdateJobProgressCommand) (UpdateJobProgressResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return UpdateJobProgressResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return UpdateJobProgressResult{}, fmt.Errorf("tenant mismatch: %s", cmd.TenantID)
	}

	if job.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return UpdateJobProgressResult{}, fmt.Errorf("worker mismatch: %s", cmd.WorkerID)
	}

	if job.AttemptNo != cmd.AttemptNo {
		return UpdateJobProgressResult{}, fmt.Errorf("attempt mismatch: %d", cmd.AttemptNo)
	}

	now := s.nowFn().UTC()
	job.Status = strings.TrimSpace(cmd.Status)
	job.ProgressPercent = cmd.ProgressPercent
	job.LastMessage = strings.TrimSpace(cmd.Message)
	job.UpdatedAt = now

	if job.Status == "processing" && cmd.LeaseExtendSeconds > 0 {
		leaseExpiresAt := now.Add(time.Duration(cmd.LeaseExtendSeconds) * time.Second)
		job.LeaseExpiresAt = &leaseExpiresAt
	}

	if job.Status != "processing" {
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

func (s *jobsQueueRuntimeIntegrationStore) CompleteJob(_ context.Context, cmd CompleteJobCommand) (CompleteJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return CompleteJobResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return CompleteJobResult{}, fmt.Errorf("tenant mismatch: %s", cmd.TenantID)
	}

	if job.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return CompleteJobResult{}, fmt.Errorf("worker mismatch: %s", cmd.WorkerID)
	}

	if job.AttemptNo != cmd.AttemptNo {
		return CompleteJobResult{}, fmt.Errorf("attempt mismatch: %d", cmd.AttemptNo)
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

func (s *jobsQueueRuntimeIntegrationStore) RecoverJob(_ context.Context, cmd RecoverJobCommand) (RecoverJobResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	job, ok := s.jobs[strings.TrimSpace(cmd.JobID)]
	if !ok {
		return RecoverJobResult{}, fmt.Errorf("job not found: %s", cmd.JobID)
	}

	if job.TenantID != strings.TrimSpace(cmd.TenantID) {
		return RecoverJobResult{}, fmt.Errorf("tenant mismatch: %s", cmd.TenantID)
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

func (s *jobsQueueRuntimeIntegrationStore) snapshotJob(jobID string) (jqRuntimeJobRecord, bool) {
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

func priorityRank(priority string) int {
	switch strings.TrimSpace(priority) {
	case "critical":
		return 1
	case "high":
		return 2
	case "normal":
		return 3
	case "low":
		return 4
	default:
		return 5
	}
}

func TestJobsQueueRuntimeIntegration_EnqueueClaimProgressCompleteFlow(t *testing.T) {
	store := newJobsQueueRuntimeIntegrationStore()

	enqueueUsecase := NewEnqueueJobUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)
	progressUsecase := NewUpdateJobProgressUsecase(store)
	completeUsecase := NewCompleteJobUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 9, 0, 0, 0, time.UTC)
	}
	enqueueUsecase.nowFn = store.nowFn

	enqueueResp, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		Payload:     map[string]any{"template": "welcome"},
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("enqueue hatasi: %v", err)
	}

	if enqueueResp.Status != "queued" {
		t.Fatalf("beklenen enqueue status queued, alinan: %s", enqueueResp.Status)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 9, 1, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

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
		t.Fatalf("beklenen claimed true")
	}

	if claimResp.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", claimResp.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 9, 2, 0, 0, time.UTC)
	}
	progressUsecase.nowFn = store.nowFn

	progressResp, err := progressUsecase.Update(context.Background(), UpdateJobProgressRequest{
		TenantID:           "tenant-a",
		JobID:              claimResp.JobID,
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    50,
		Message:            "ilk batch tamamlandi",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	})
	if err != nil {
		t.Fatalf("progress hatasi: %v", err)
	}

	if progressResp.ProgressPercent != 50 {
		t.Fatalf("beklenen progress 50, alinan: %d", progressResp.ProgressPercent)
	}

	if progressResp.LeaseExpiresAt == nil {
		t.Fatalf("beklenen lease_expires_at dolu olmaliydi")
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 9, 3, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	completeResp, err := completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          claimResp.JobID,
		WorkerID:       "worker-01",
		Status:         "succeeded",
		AttemptNo:      1,
		CompletionNote: "tamamlandi",
		OutputPayload:  map[string]any{"sent_count": 10},
	})
	if err != nil {
		t.Fatalf("complete hatasi: %v", err)
	}

	if completeResp.Status != "succeeded" {
		t.Fatalf("beklenen complete status succeeded, alinan: %s", completeResp.Status)
	}

	job, ok := store.snapshotJob(claimResp.JobID)
	if !ok {
		t.Fatalf("job snapshot bulunamadi")
	}

	if job.Status != "succeeded" {
		t.Fatalf("beklenen final job status succeeded, alinan: %s", job.Status)
	}

	if job.AttemptNo != 1 {
		t.Fatalf("beklenen final attempt_no 1, alinan: %d", job.AttemptNo)
	}
}

func TestJobsQueueRuntimeIntegration_TenantIsolationAndScheduledClaimFlow(t *testing.T) {
	store := newJobsQueueRuntimeIntegrationStore()

	enqueueUsecase := NewEnqueueJobUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)

	now := time.Date(2026, 4, 25, 10, 0, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return now }
	enqueueUsecase.nowFn = store.nowFn
	claimUsecase.nowFn = store.nowFn

	scheduledAt := time.Date(2026, 4, 25, 11, 0, 0, 0, time.UTC)

	_, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-a",
		JobType:     "email.send",
		Priority:    "normal",
		ScheduledAt: &scheduledAt,
		RequestedBy: "system-api",
		MaxAttempts: 3,
	})
	if err != nil {
		t.Fatalf("tenant-a scheduled enqueue hatasi: %v", err)
	}

	_, err = enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-b",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-b",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 3,
	})
	if err != nil {
		t.Fatalf("tenant-b enqueue hatasi: %v", err)
	}

	tenantAClaimBeforeDue, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-a",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-a early claim hatasi: %v", err)
	}

	if tenantAClaimBeforeDue.Claimed {
		t.Fatalf("tenant-a scheduled job due olmadan claim edilmemeliydi")
	}

	tenantBClaim, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-b",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-b",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-b claim hatasi: %v", err)
	}

	if !tenantBClaim.Claimed {
		t.Fatalf("tenant-b job claim edilmeliydi")
	}

	now = time.Date(2026, 4, 25, 11, 1, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return now }
	claimUsecase.nowFn = store.nowFn

	tenantAClaimAfterDue, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-a",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("tenant-a due sonrasi claim hatasi: %v", err)
	}

	if !tenantAClaimAfterDue.Claimed {
		t.Fatalf("tenant-a scheduled job due sonrasi claim edilmeliydi")
	}
}

func TestJobsQueueRuntimeIntegration_FailRetryDeadLetterFlow(t *testing.T) {
	store := newJobsQueueRuntimeIntegrationStore()

	enqueueUsecase := NewEnqueueJobUsecase(store)
	claimUsecase := NewClaimJobUsecase(store)
	completeUsecase := NewCompleteJobUsecase(store)
	recoverUsecase := NewRecoverJobUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 0, 0, 0, time.UTC)
	}
	enqueueUsecase.nowFn = store.nowFn

	enqueueResp, err := enqueueUsecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-retry",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("enqueue hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 1, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	firstClaim, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("ilk claim hatasi: %v", err)
	}

	if !firstClaim.Claimed {
		t.Fatalf("ilk claim basarili olmaliydi")
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 2, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	_, err = completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          enqueueResp.JobID,
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
		CompletionNote: "provider timeout",
		ErrorCode:      "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("ilk fail hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 3, 0, 0, time.UTC)
	}
	recoverUsecase.nowFn = store.nowFn

	retryResp, err := recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         enqueueResp.JobID,
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "transient error temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("retry hatasi: %v", err)
	}

	if retryResp.Status != "queued" {
		t.Fatalf("beklenen retry sonrasi status queued, alinan: %s", retryResp.Status)
	}

	if retryResp.AttemptNo != 0 {
		t.Fatalf("beklenen retry sonrasi attempt_no 0, alinan: %d", retryResp.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 4, 0, 0, time.UTC)
	}
	claimUsecase.nowFn = store.nowFn

	secondClaim, err := claimUsecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-02",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("ikinci claim hatasi: %v", err)
	}

	if !secondClaim.Claimed {
		t.Fatalf("ikinci claim basarili olmaliydi")
	}

	if secondClaim.AttemptNo != 1 {
		t.Fatalf("beklenen ikinci claim attempt_no 1, alinan: %d", secondClaim.AttemptNo)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 5, 0, 0, time.UTC)
	}
	completeUsecase.nowFn = store.nowFn

	_, err = completeUsecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          enqueueResp.JobID,
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      1,
		CompletionNote: "kalici hata",
		ErrorCode:      "EMAIL_HARD_FAIL",
	})
	if err != nil {
		t.Fatalf("ikinci fail hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 6, 0, 0, time.UTC)
	}
	recoverUsecase.nowFn = store.nowFn

	deadLetterResp, err := recoverUsecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         enqueueResp.JobID,
		ActionType:    "dead_letter",
		RequestedBy:   "worker-02",
		Reason:        "kalici hata",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("dead-letter hatasi: %v", err)
	}

	if deadLetterResp.Status != "dead_letter" {
		t.Fatalf("beklenen dead_letter status, alinan: %s", deadLetterResp.Status)
	}

	job, ok := store.snapshotJob(enqueueResp.JobID)
	if !ok {
		t.Fatalf("job snapshot bulunamadi")
	}

	if job.Status != "dead_letter" {
		t.Fatalf("beklenen final job status dead_letter, alinan: %s", job.Status)
	}
}
