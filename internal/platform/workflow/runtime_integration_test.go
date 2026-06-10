package workflow

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

type workflowRuntimeDefinition struct {
	DefinitionKey string
	Version       int
	InitialState  string
	Steps         []WorkflowDefinitionStep
}

type workflowRuntimeStepRecord struct {
	StepKey         string
	StepType        string
	Status          string
	AttemptNo       int
	WorkerID        string
	LeaseExpiresAt  *time.Time
	LastErrorCode   string
	OutputRef       string
	CompletionNote  string
	CompensationRef string
}

type workflowRuntimeApprovalRecord struct {
	ApprovalID      string
	StepKey         string
	ApproverRef     string
	ApprovalStatus  string
	Comment         string
	Completed       bool
}

type workflowRuntimeRunRecord struct {
	WorkflowRunID string
	TenantID      string
	DefinitionKey string
	CurrentState  string
	Steps         map[string]*workflowRuntimeStepRecord
	Approvals     map[string]*workflowRuntimeApprovalRecord
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type workflowRuntimeIntegrationStore struct {
	mu          sync.Mutex
	nowFn       func() time.Time
	definitions map[string]workflowRuntimeDefinition
	runs        map[string]*workflowRuntimeRunRecord
}

func newWorkflowRuntimeIntegrationStore() *workflowRuntimeIntegrationStore {
	return &workflowRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		definitions: make(map[string]workflowRuntimeDefinition),
		runs:        make(map[string]*workflowRuntimeRunRecord),
	}
}

func (s *workflowRuntimeIntegrationStore) seedDefinition(def workflowRuntimeDefinition) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.definitions[def.DefinitionKey] = def
}

func (s *workflowRuntimeIntegrationStore) seedRun(runID, tenantID, definitionKey, currentState string, stepStatuses map[string]string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	def := s.definitions[definitionKey]
	now := s.nowFn().UTC()

	run := &workflowRuntimeRunRecord{
		WorkflowRunID: runID,
		TenantID:      strings.TrimSpace(tenantID),
		DefinitionKey: definitionKey,
		CurrentState:  currentState,
		Steps:         make(map[string]*workflowRuntimeStepRecord),
		Approvals:     make(map[string]*workflowRuntimeApprovalRecord),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	for _, step := range def.Steps {
		status := strings.TrimSpace(stepStatuses[step.StepKey])
		if status == "" {
			status = "waiting"
		}

		run.Steps[step.StepKey] = &workflowRuntimeStepRecord{
			StepKey:        step.StepKey,
			StepType:       step.StepType,
			Status:         status,
			AttemptNo:      0,
			WorkerID:       "",
			LeaseExpiresAt: nil,
			LastErrorCode:  "",
		}

		if step.StepType == "approval" {
			approvalID := "approval-" + step.StepKey
			run.Approvals[approvalID] = &workflowRuntimeApprovalRecord{
				ApprovalID:     approvalID,
				StepKey:        step.StepKey,
				ApproverRef:    "",
				ApprovalStatus: "pending",
				Comment:        "",
				Completed:      false,
			}
		}
	}

	s.runs[runID] = run
}

func (s *workflowRuntimeIntegrationStore) LoadDefinition(_ context.Context, cmd LoadWorkflowDefinitionCommand) (LoadWorkflowDefinitionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	def, ok := s.definitions[strings.TrimSpace(cmd.DefinitionKey)]
	if !ok {
		return LoadWorkflowDefinitionResult{
			DefinitionKey: strings.TrimSpace(cmd.DefinitionKey),
			Loaded:        false,
		}, nil
	}

	return LoadWorkflowDefinitionResult{
		DefinitionKey: def.DefinitionKey,
		Version:       def.Version,
		InitialState:  def.InitialState,
		Loaded:        true,
		Steps:         cloneWorkflowDefinitionSteps(def.Steps),
	}, nil
}

func (s *workflowRuntimeIntegrationStore) ApplyTransition(_ context.Context, cmd ApplyWorkflowTransitionCommand) (ApplyWorkflowTransitionResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return ApplyWorkflowTransitionResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return ApplyWorkflowTransitionResult{}, fmt.Errorf("tenant mismatch")
	}

	nextState, allowed := resolveFallbackWorkflowTransition(cmd.CurrentState, cmd.Action)
	reason := ""
	if !allowed {
		reason = "transition not allowed"
	}

	if allowed {
		run.CurrentState = nextState
		run.UpdatedAt = s.nowFn().UTC()
	}

	return ApplyWorkflowTransitionResult{
		WorkflowRunID:     run.WorkflowRunID,
		DefinitionKey:     run.DefinitionKey,
		PreviousState:     strings.TrimSpace(cmd.CurrentState),
		Action:            strings.TrimSpace(cmd.Action),
		NextState:         nextState,
		TransitionAllowed: allowed,
		Reason:            reason,
		ContextVars:       cloneMap(cmd.ContextVars),
	}, nil
}

func (s *workflowRuntimeIntegrationStore) ClaimStep(_ context.Context, cmd ClaimWorkflowStepCommand) (ClaimWorkflowStepResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return ClaimWorkflowStepResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return ClaimWorkflowStepResult{}, fmt.Errorf("tenant mismatch")
	}

	step, ok := run.Steps[strings.TrimSpace(cmd.StepKey)]
	if !ok {
		return ClaimWorkflowStepResult{}, fmt.Errorf("step not found: %s", cmd.StepKey)
	}

	if step.Status != "pending" && step.Status != "retry_pending" {
		return ClaimWorkflowStepResult{
			Claimed: false,
		}, nil
	}

	now := s.nowFn().UTC()
	lease := now.Add(time.Duration(cmd.LeaseSeconds) * time.Second)

	step.Status = "in_progress"
	step.WorkerID = strings.TrimSpace(cmd.WorkerID)
	step.AttemptNo++
	step.LeaseExpiresAt = &lease
	run.UpdatedAt = now

	return ClaimWorkflowStepResult{
		Claimed:        true,
		WorkflowRunID:  run.WorkflowRunID,
		StepKey:        step.StepKey,
		StepType:       step.StepType,
		Status:         step.Status,
		AttemptNo:      step.AttemptNo,
		LeaseExpiresAt: cloneWorkflowTimePtr(step.LeaseExpiresAt),
	}, nil
}

func (s *workflowRuntimeIntegrationStore) ApplyApprovalDecision(_ context.Context, cmd ApplyManualApprovalCommand) (ApplyManualApprovalResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return ApplyManualApprovalResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return ApplyManualApprovalResult{}, fmt.Errorf("tenant mismatch")
	}

	approval, ok := run.Approvals[strings.TrimSpace(cmd.ApprovalID)]
	if !ok {
		return ApplyManualApprovalResult{}, fmt.Errorf("approval not found: %s", cmd.ApprovalID)
	}

	step, ok := run.Steps[strings.TrimSpace(cmd.StepKey)]
	if !ok {
		return ApplyManualApprovalResult{}, fmt.Errorf("step not found: %s", cmd.StepKey)
	}

	now := s.nowFn().UTC()

	approval.ApproverRef = strings.TrimSpace(cmd.ApproverRef)
	approval.Comment = strings.TrimSpace(cmd.Comment)
	approval.Completed = true

	if strings.TrimSpace(cmd.Decision) == "approve" {
		approval.ApprovalStatus = "approved"
		step.Status = "approved"
		run.CurrentState = "approved"
	} else {
		approval.ApprovalStatus = "rejected"
		step.Status = "rejected"
		run.CurrentState = "rejected"
	}

	step.WorkerID = ""
	step.LeaseExpiresAt = nil
	run.UpdatedAt = now

	nextStepKey := s.nextStepFor(run.DefinitionKey, step.StepKey, strings.TrimSpace(cmd.Decision) == "approve")
	if nextStepKey != "" {
		if nextStep, ok := run.Steps[nextStepKey]; ok && nextStep.Status == "waiting" {
			nextStep.Status = "pending"
		}
	}

	return ApplyManualApprovalResult{
		WorkflowRunID:     run.WorkflowRunID,
		StepKey:           step.StepKey,
		ApprovalID:        approval.ApprovalID,
		ApproverRef:       approval.ApproverRef,
		Decision:          strings.TrimSpace(cmd.Decision),
		ApprovalStatus:    approval.ApprovalStatus,
		WorkflowNextState: run.CurrentState,
		Comment:           approval.Comment,
		Completed:         true,
	}, nil
}

func (s *workflowRuntimeIntegrationStore) CompleteStep(_ context.Context, cmd CompleteWorkflowStepCommand) (CompleteWorkflowStepResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return CompleteWorkflowStepResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return CompleteWorkflowStepResult{}, fmt.Errorf("tenant mismatch")
	}

	step, ok := run.Steps[strings.TrimSpace(cmd.StepKey)]
	if !ok {
		return CompleteWorkflowStepResult{}, fmt.Errorf("step not found: %s", cmd.StepKey)
	}

	if step.WorkerID != strings.TrimSpace(cmd.WorkerID) {
		return CompleteWorkflowStepResult{}, fmt.Errorf("worker mismatch")
	}

	if step.AttemptNo != cmd.AttemptNo {
		return CompleteWorkflowStepResult{}, fmt.Errorf("attempt mismatch")
	}

	now := s.nowFn().UTC()

	step.Status = strings.TrimSpace(cmd.Status)
	step.OutputRef = strings.TrimSpace(cmd.OutputRef)
	step.LastErrorCode = strings.TrimSpace(cmd.ErrorCode)
	step.CompletionNote = strings.TrimSpace(cmd.CompletionNote)
	step.WorkerID = ""
	step.LeaseExpiresAt = nil
	run.UpdatedAt = now

	if step.Status == "completed" {
		nextStepKey := s.nextStepFor(run.DefinitionKey, step.StepKey, true)
		if nextStepKey != "" {
			if nextStep, ok := run.Steps[nextStepKey]; ok && nextStep.Status == "waiting" {
				nextStep.Status = "pending"
			}
		}
	}

	return CompleteWorkflowStepResult{
		WorkflowRunID:  run.WorkflowRunID,
		StepKey:        step.StepKey,
		Status:         step.Status,
		AttemptNo:      step.AttemptNo,
		OutputRef:      step.OutputRef,
		ErrorCode:      step.LastErrorCode,
		CompletionNote: step.CompletionNote,
		LeaseReleased:  true,
	}, nil
}

func (s *workflowRuntimeIntegrationStore) ApplyRecovery(_ context.Context, cmd ApplyWorkflowRecoveryCommand) (ApplyWorkflowRecoveryResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return ApplyWorkflowRecoveryResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return ApplyWorkflowRecoveryResult{}, fmt.Errorf("tenant mismatch")
	}

	step, ok := run.Steps[strings.TrimSpace(cmd.StepKey)]
	if !ok {
		return ApplyWorkflowRecoveryResult{}, fmt.Errorf("step not found: %s", cmd.StepKey)
	}

	now := s.nowFn().UTC()

	switch strings.TrimSpace(cmd.ActionType) {
	case "retry":
		step.Status = "pending"
		run.CurrentState = "pending"
		if cmd.ResetAttempts {
			step.AttemptNo = 0
		}
	case "compensate":
		step.Status = "compensating"
		step.CompensationRef = strings.TrimSpace(cmd.CompensationRef)
		run.CurrentState = "failed"
	default:
		return ApplyWorkflowRecoveryResult{}, fmt.Errorf("unsupported action: %s", cmd.ActionType)
	}

	step.WorkerID = ""
	step.LeaseExpiresAt = nil
	run.UpdatedAt = now

	return ApplyWorkflowRecoveryResult{
		WorkflowRunID:   run.WorkflowRunID,
		StepKey:         step.StepKey,
		ActionType:      strings.TrimSpace(cmd.ActionType),
		StepStatus:      step.Status,
		WorkflowState:   run.CurrentState,
		AttemptNo:       step.AttemptNo,
		CompensationRef: step.CompensationRef,
		LeaseReleased:   true,
	}, nil
}

func (s *workflowRuntimeIntegrationStore) LoadObservability(_ context.Context, cmd LoadWorkflowObservabilityCommand) (LoadWorkflowObservabilityResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[strings.TrimSpace(cmd.WorkflowRunID)]
	if !ok {
		return LoadWorkflowObservabilityResult{}, fmt.Errorf("workflow run not found: %s", cmd.WorkflowRunID)
	}

	if run.TenantID != strings.TrimSpace(cmd.TenantID) {
		return LoadWorkflowObservabilityResult{}, fmt.Errorf("tenant mismatch")
	}

	now := s.nowFn().UTC()
	result := LoadWorkflowObservabilityResult{
		WorkflowRunID: run.WorkflowRunID,
		DefinitionKey: run.DefinitionKey,
		WorkflowState: run.CurrentState,
		Summary: WorkflowObservabilitySummary{
			TotalSteps:        len(run.Steps),
			PendingSteps:      0,
			InProgressSteps:   0,
			CompletedSteps:    0,
			FailedSteps:       0,
			PendingApprovals:  0,
			ActiveLeaseCount:  0,
			ExpiredLeaseCount: 0,
		},
		Steps: make([]WorkflowStepObservation, 0, len(run.Steps)),
	}

	for _, approval := range run.Approvals {
		if approval.ApprovalStatus == "pending" {
			result.Summary.PendingApprovals++
		}
	}

	stepKeys := make([]string, 0, len(run.Steps))
	for key := range run.Steps {
		stepKeys = append(stepKeys, key)
	}
	sort.Strings(stepKeys)

	for _, key := range stepKeys {
		step := run.Steps[key]

		switch step.Status {
		case "pending", "retry_pending":
			result.Summary.PendingSteps++
		case "in_progress":
			result.Summary.InProgressSteps++
		case "completed", "approved":
			result.Summary.CompletedSteps++
		case "failed", "rejected":
			result.Summary.FailedSteps++
		}

		if step.LeaseExpiresAt != nil {
			if step.LeaseExpiresAt.After(now) {
				result.Summary.ActiveLeaseCount++
			} else {
				result.Summary.ExpiredLeaseCount++
			}
		}

		result.Steps = append(result.Steps, WorkflowStepObservation{
			StepKey:        step.StepKey,
			StepType:       step.StepType,
			Status:         step.Status,
			AttemptNo:      step.AttemptNo,
			WorkerID:       step.WorkerID,
			LeaseExpiresAt: cloneWorkflowTimePtr(step.LeaseExpiresAt),
			LastErrorCode:  step.LastErrorCode,
		})
	}

	return result, nil
}

func (s *workflowRuntimeIntegrationStore) nextStepFor(definitionKey, stepKey string, success bool) string {
	def, ok := s.definitions[definitionKey]
	if !ok {
		return ""
	}

	for _, step := range def.Steps {
		if step.StepKey != stepKey {
			continue
		}

		if success {
			return strings.TrimSpace(step.NextOnSuccess)
		}
		return strings.TrimSpace(step.NextOnFailure)
	}

	return ""
}

func (s *workflowRuntimeIntegrationStore) snapshotRun(runID string) (workflowRuntimeRunRecord, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	run, ok := s.runs[runID]
	if !ok {
		return workflowRuntimeRunRecord{}, false
	}

	out := workflowRuntimeRunRecord{
		WorkflowRunID: run.WorkflowRunID,
		TenantID:      run.TenantID,
		DefinitionKey: run.DefinitionKey,
		CurrentState:  run.CurrentState,
		Steps:         make(map[string]*workflowRuntimeStepRecord),
		Approvals:     make(map[string]*workflowRuntimeApprovalRecord),
		CreatedAt:     run.CreatedAt,
		UpdatedAt:     run.UpdatedAt,
	}

	for k, v := range run.Steps {
		stepCopy := *v
		stepCopy.LeaseExpiresAt = cloneWorkflowTimePtr(v.LeaseExpiresAt)
		out.Steps[k] = &stepCopy
	}

	for k, v := range run.Approvals {
		approvalCopy := *v
		out.Approvals[k] = &approvalCopy
	}

	return out, true
}

func TestWorkflowRuntimeIntegration_DefinitionStateStepApprovalCompleteFlow(t *testing.T) {
	store := newWorkflowRuntimeIntegrationStore()

	store.seedDefinition(workflowRuntimeDefinition{
		DefinitionKey: "purchase_approval",
		Version:       3,
		InitialState:  "draft",
		Steps: []WorkflowDefinitionStep{
			{
				StepKey:                "submit-step",
				StepType:               "task",
				NextOnSuccess:          "approval-step-1",
				RequiresManualApproval: false,
			},
			{
				StepKey:                "approval-step-1",
				StepType:               "approval",
				NextOnSuccess:          "complete-step",
				RequiresManualApproval: true,
			},
			{
				StepKey:                "complete-step",
				StepType:               "task",
				RequiresManualApproval: false,
			},
		},
	})

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 3, 0, 0, 0, time.UTC)
	}
	store.seedRun("wf-run-001", "tenant-a", "purchase_approval", "draft", map[string]string{
		"submit-step":     "pending",
		"approval-step-1": "waiting",
		"complete-step":   "waiting",
	})

	loadDefUsecase := NewLoadWorkflowDefinitionUsecase(store)
	transitionUsecase := NewApplyWorkflowTransitionUsecase(store)
	claimStepUsecase := NewClaimWorkflowStepUsecase(store)
	completeStepUsecase := NewCompleteWorkflowStepUsecase(store)
	manualApprovalUsecase := NewApplyManualApprovalUsecase(store)
	observabilityUsecase := NewLoadWorkflowObservabilityUsecase(store)

	loadDefUsecase.nowFn = store.nowFn
	transitionUsecase.nowFn = store.nowFn
	claimStepUsecase.nowFn = store.nowFn
	completeStepUsecase.nowFn = store.nowFn
	manualApprovalUsecase.nowFn = store.nowFn
	observabilityUsecase.nowFn = store.nowFn

	defResp, err := loadDefUsecase.Load(context.Background(), LoadWorkflowDefinitionRequest{
		TenantID:      "tenant-a",
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("definition load hatasi: %v", err)
	}

	if !defResp.Loaded || len(defResp.Steps) != 3 {
		t.Fatalf("definition beklenen sekilde yuklenmedi")
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("draft->pending transition hatasi: %v", err)
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "pending",
		Action:        "start",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("pending->in_progress transition hatasi: %v", err)
	}

	submitClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "submit-step",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("submit-step claim hatasi: %v", err)
	}

	if !submitClaim.Claimed {
		t.Fatalf("submit-step claim edilmeliydi")
	}

	_, err = completeStepUsecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "submit-step",
		WorkerID:       "worker-01",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-001",
		CompletionNote: "submit tamamlandi",
	})
	if err != nil {
		t.Fatalf("submit-step complete hatasi: %v", err)
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "in_progress",
		Action:        "request_approval",
		RequestedBy:   "worker-02",
	})
	if err != nil {
		t.Fatalf("request_approval transition hatasi: %v", err)
	}

	approvalClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-02",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("approval-step claim hatasi: %v", err)
	}

	if !approvalClaim.Claimed {
		t.Fatalf("approval-step claim edilmeliydi")
	}

	approvalResp, err := manualApprovalUsecase.Apply(context.Background(), ApplyManualApprovalRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-approval-step-1",
		ApproverRef:   "approver-01",
		Decision:      "approve",
		Comment:       "uygun bulundu",
	})
	if err != nil {
		t.Fatalf("manual approval hatasi: %v", err)
	}

	if approvalResp.WorkflowNextState != "approved" {
		t.Fatalf("beklenen workflow_next_state approved, alinan: %s", approvalResp.WorkflowNextState)
	}

	finalClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "complete-step",
		WorkerID:      "worker-03",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("complete-step claim hatasi: %v", err)
	}

	if !finalClaim.Claimed {
		t.Fatalf("complete-step claim edilmeliydi")
	}

	_, err = completeStepUsecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "complete-step",
		WorkerID:       "worker-03",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-002",
		CompletionNote: "final step tamamlandi",
	})
	if err != nil {
		t.Fatalf("complete-step complete hatasi: %v", err)
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "approved",
		Action:        "complete",
		RequestedBy:   "worker-03",
	})
	if err != nil {
		t.Fatalf("approved->completed transition hatasi: %v", err)
	}

	obsResp, err := observabilityUsecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("observability load hatasi: %v", err)
	}

	if obsResp.HealthStatus != "healthy" {
		t.Fatalf("beklenen health healthy, alinan: %s", obsResp.HealthStatus)
	}

	runSnapshot, ok := store.snapshotRun("wf-run-001")
	if !ok {
		t.Fatalf("run snapshot bulunamadi")
	}

	if runSnapshot.CurrentState != "completed" {
		t.Fatalf("beklenen final workflow state completed, alinan: %s", runSnapshot.CurrentState)
	}

	if runSnapshot.Steps["complete-step"].Status != "completed" {
		t.Fatalf("beklenen final step completed")
	}
}

func TestWorkflowRuntimeIntegration_RetryAndCompensationFlow(t *testing.T) {
	store := newWorkflowRuntimeIntegrationStore()

	store.seedDefinition(workflowRuntimeDefinition{
		DefinitionKey: "service_recovery",
		Version:       1,
		InitialState:  "pending",
		Steps: []WorkflowDefinitionStep{
			{
				StepKey:   "service-step-1",
				StepType:  "service",
			},
		},
	})

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 4, 0, 0, 0, time.UTC)
	}
	store.seedRun("wf-run-002", "tenant-a", "service_recovery", "pending", map[string]string{
		"service-step-1": "pending",
	})

	transitionUsecase := NewApplyWorkflowTransitionUsecase(store)
	claimStepUsecase := NewClaimWorkflowStepUsecase(store)
	completeStepUsecase := NewCompleteWorkflowStepUsecase(store)
	recoveryUsecase := NewApplyWorkflowRecoveryUsecase(store)
	observabilityUsecase := NewLoadWorkflowObservabilityUsecase(store)

	transitionUsecase.nowFn = store.nowFn
	claimStepUsecase.nowFn = store.nowFn
	completeStepUsecase.nowFn = store.nowFn
	recoveryUsecase.nowFn = store.nowFn
	observabilityUsecase.nowFn = store.nowFn

	_, err := transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		DefinitionKey: "service_recovery",
		CurrentState:  "pending",
		Action:        "start",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("pending->in_progress transition hatasi: %v", err)
	}

	firstClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("ilk claim hatasi: %v", err)
	}

	if !firstClaim.Claimed {
		t.Fatalf("ilk claim basarili olmaliydi")
	}

	_, err = completeStepUsecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-002",
		StepKey:        "service-step-1",
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
		ErrorCode:      "TIMEOUT",
		CompletionNote: "servis timeout verdi",
	})
	if err != nil {
		t.Fatalf("ilk fail hatasi: %v", err)
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		DefinitionKey: "service_recovery",
		CurrentState:  "in_progress",
		Action:        "fail",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("in_progress->failed transition hatasi: %v", err)
	}

	retryResp, err := recoveryUsecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("retry hatasi: %v", err)
	}

	if retryResp.StepStatus != "pending" || retryResp.WorkflowState != "pending" {
		t.Fatalf("retry sonrasi durum beklenen gibi degil")
	}

	_, err = transitionUsecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		DefinitionKey: "service_recovery",
		CurrentState:  "pending",
		Action:        "start",
		RequestedBy:   "worker-02",
	})
	if err != nil {
		t.Fatalf("retry sonrasi start transition hatasi: %v", err)
	}

	secondClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		StepKey:       "service-step-1",
		WorkerID:      "worker-02",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("ikinci claim hatasi: %v", err)
	}

	if !secondClaim.Claimed || secondClaim.AttemptNo != 1 {
		t.Fatalf("ikinci claim beklenen gibi degil")
	}

	_, err = completeStepUsecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-002",
		StepKey:        "service-step-1",
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      1,
		ErrorCode:      "HARD_FAIL",
		CompletionNote: "kalici hata",
	})
	if err != nil {
		t.Fatalf("ikinci fail hatasi: %v", err)
	}

	compResp, err := recoveryUsecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
		TenantID:        "tenant-a",
		WorkflowRunID:   "wf-run-002",
		StepKey:         "service-step-1",
		ActionType:      "compensate",
		RequestedBy:     "worker-02",
		Reason:          "rollback gerekli",
		CompensationRef: "comp-001",
	})
	if err != nil {
		t.Fatalf("compensate hatasi: %v", err)
	}

	if compResp.StepStatus != "compensating" || compResp.WorkflowState != "failed" {
		t.Fatalf("compensation sonrasi durum beklenen gibi degil")
	}

	obsResp, err := observabilityUsecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-002",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("observability load hatasi: %v", err)
	}

	if obsResp.HealthStatus != "healthy" && obsResp.HealthStatus != "failed" {
		t.Fatalf("beklenmeyen health status: %s", obsResp.HealthStatus)
	}

	runSnapshot, ok := store.snapshotRun("wf-run-002")
	if !ok {
		t.Fatalf("run snapshot bulunamadi")
	}

	if runSnapshot.CurrentState != "failed" {
		t.Fatalf("beklenen final workflow state failed, alinan: %s", runSnapshot.CurrentState)
	}

	if runSnapshot.Steps["service-step-1"].Status != "compensating" {
		t.Fatalf("beklenen final step status compensating")
	}
}

func TestWorkflowRuntimeIntegration_ObservabilityAndTenantIsolationFlow(t *testing.T) {
	store := newWorkflowRuntimeIntegrationStore()

	store.seedDefinition(workflowRuntimeDefinition{
		DefinitionKey: "lease_monitor_flow",
		Version:       1,
		InitialState:  "in_progress",
		Steps: []WorkflowDefinitionStep{
			{
				StepKey:  "task-step-1",
				StepType: "task",
			},
		},
	})

	baseTime := time.Date(2026, 4, 26, 5, 0, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return baseTime }

	store.seedRun("wf-run-003", "tenant-a", "lease_monitor_flow", "in_progress", map[string]string{
		"task-step-1": "pending",
	})
	store.seedRun("wf-run-004", "tenant-b", "lease_monitor_flow", "in_progress", map[string]string{
		"task-step-1": "pending",
	})

	claimStepUsecase := NewClaimWorkflowStepUsecase(store)
	observabilityUsecase := NewLoadWorkflowObservabilityUsecase(store)

	claimStepUsecase.nowFn = store.nowFn
	observabilityUsecase.nowFn = store.nowFn

	tenantAClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-003",
		StepKey:       "task-step-1",
		WorkerID:      "worker-a",
		LeaseSeconds:  10,
	})
	if err != nil {
		t.Fatalf("tenant-a claim hatasi: %v", err)
	}

	if !tenantAClaim.Claimed {
		t.Fatalf("tenant-a claim edilmeliydi")
	}

	tenantBClaim, err := claimStepUsecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-b",
		WorkflowRunID: "wf-run-004",
		StepKey:       "task-step-1",
		WorkerID:      "worker-b",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("tenant-b claim hatasi: %v", err)
	}

	if !tenantBClaim.Claimed {
		t.Fatalf("tenant-b claim edilmeliydi")
	}

	baseTime = baseTime.Add(20 * time.Second)
	store.nowFn = func() time.Time { return baseTime }
	observabilityUsecase.nowFn = store.nowFn

	tenantAObs, err := observabilityUsecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-003",
		RequestedBy:   "observer-01",
	})
	if err != nil {
		t.Fatalf("tenant-a observability hatasi: %v", err)
	}

	if tenantAObs.HealthStatus != "stalled" {
		t.Fatalf("beklenen tenant-a health stalled, alinan: %s", tenantAObs.HealthStatus)
	}

	tenantBObs, err := observabilityUsecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-b",
		WorkflowRunID: "wf-run-004",
		RequestedBy:   "observer-01",
	})
	if err != nil {
		t.Fatalf("tenant-b observability hatasi: %v", err)
	}

	if tenantBObs.HealthStatus != "degraded" {
		t.Fatalf("beklenen tenant-b health degraded, alinan: %s", tenantBObs.HealthStatus)
	}

	if tenantAObs.Summary.ExpiredLeaseCount != 1 {
		t.Fatalf("beklenen tenant-a expired lease 1, alinan: %d", tenantAObs.Summary.ExpiredLeaseCount)
	}

	if tenantBObs.Summary.ActiveLeaseCount != 1 {
		t.Fatalf("beklenen tenant-b active lease 1, alinan: %d", tenantBObs.Summary.ActiveLeaseCount)
	}
}
