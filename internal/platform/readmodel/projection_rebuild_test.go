package readmodel

import (
	"context"
	"testing"
)

type fakeRebuildTracker struct {
	callCount int
	lastPlan  ProjectionRebuildPlan
	lastState RebuildState
	lastDetail string
	err       error
}

func (f *fakeRebuildTracker) Mark(_ context.Context, plan ProjectionRebuildPlan, state RebuildState, detail string) error {
	if f.err != nil {
		return f.err
	}
	f.callCount++
	f.lastPlan = plan
	f.lastState = state
	f.lastDetail = detail
	return nil
}

func TestNewProjectionRebuildCoordinator(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	coord, err := NewProjectionRebuildCoordinator(store, &fakeRebuildTracker{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if coord == nil {
		t.Fatal("expected rebuild coordinator")
	}
}

func TestProjectionRebuildRequest_Validate(t *testing.T) {
	req := ProjectionRebuildRequest{
		TenantID:   "tenant_42",
		Projection: "sales_summary",
		Mode:       RebuildModeTruncateReplay,
		Reason:     "full rebuild",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestProjectionRebuildCoordinator_PlanTruncateReplay(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	coord, err := NewProjectionRebuildCoordinator(store, &fakeRebuildTracker{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := coord.Plan(ProjectionRebuildRequest{
		TenantID:   "tenant_42",
		Projection: "sales_summary",
		Mode:       RebuildModeTruncateReplay,
		Reason:     "full rebuild",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.Projection != "sales_summary" {
		t.Fatalf("expected sales_summary, got %s", plan.Projection)
	}
	if plan.FullTableName != "readmodel.rm_sales_summary" {
		t.Fatalf("expected readmodel.rm_sales_summary, got %s", plan.FullTableName)
	}
	if !plan.TruncateBeforeReplay {
		t.Fatal("expected truncate before replay")
	}
	if !plan.RequiresReplay {
		t.Fatal("expected requires replay")
	}
}

func TestProjectionRebuildCoordinator_PlanReplayFromEvent(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	coord, err := NewProjectionRebuildCoordinator(store, &fakeRebuildTracker{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := coord.Plan(ProjectionRebuildRequest{
		TenantID:          "tenant_42",
		Projection:        "dashboard_kpi",
		Mode:              RebuildModeReplayFromEvent,
		ReplayFromEventID: "evt_9001",
		Reason:            "partial replay",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if plan.TruncateBeforeReplay {
		t.Fatal("expected no truncate on replay_from_event")
	}
	if plan.ReplayFromEventID != "evt_9001" {
		t.Fatalf("expected evt_9001, got %s", plan.ReplayFromEventID)
	}
}

func TestProjectionRebuildCoordinator_UnknownProjection(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	coord, err := NewProjectionRebuildCoordinator(store, &fakeRebuildTracker{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = coord.Plan(ProjectionRebuildRequest{
		TenantID:   "tenant_42",
		Projection: "unknown_projection",
		Mode:       RebuildModeTruncateReplay,
	})
	if err == nil {
		t.Fatal("expected unknown projection error")
	}
}

func TestProjectionRebuildCoordinator_RebuildNotSupported(t *testing.T) {
	registry := NewProjectionContractRegistry()
	registry.MustRegister(ProjectionSchema{
		Name:              "non_rebuild_projection",
		TableName:         "rm_non_rebuild_projection",
		TenantColumn:      "tenant_id",
		PrimaryKeyColumns: []string{"tenant_id", "row_id"},
		VersionColumn:     "projection_version",
		UpdatedAtColumn:   "updated_at",
		SupportsRebuild:   false,
		Description:       "non rebuild projection",
	})

	store, err := NewReportingStore(sampleReportingConfig(), registry)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	coord, err := NewProjectionRebuildCoordinator(store, &fakeRebuildTracker{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = coord.Plan(ProjectionRebuildRequest{
		TenantID:   "tenant_42",
		Projection: "non_rebuild_projection",
		Mode:       RebuildModeTruncateReplay,
	})
	if err == nil {
		t.Fatal("expected rebuild not supported error")
	}
}

func TestProjectionRebuildCoordinator_MarkLifecycle(t *testing.T) {
	store, err := NewReportingStore(sampleReportingConfig(), DefaultProjectionContracts())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	tracker := &fakeRebuildTracker{}
	coord, err := NewProjectionRebuildCoordinator(store, tracker)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	plan, err := coord.Plan(ProjectionRebuildRequest{
		TenantID:   "tenant_42",
		Projection: "sales_reports",
		Mode:       RebuildModeTruncateReplay,
		Reason:     "rebuild run",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if err := coord.MarkPlanned(context.Background(), plan, "queued"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != RebuildStatePlanned {
		t.Fatalf("expected planned, got %s", tracker.lastState)
	}

	if err := coord.MarkRunning(context.Background(), plan, "running"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != RebuildStateRunning {
		t.Fatalf("expected running, got %s", tracker.lastState)
	}

	if err := coord.MarkCompleted(context.Background(), plan, "done"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != RebuildStateCompleted {
		t.Fatalf("expected completed, got %s", tracker.lastState)
	}

	if err := coord.MarkFailed(context.Background(), plan, "failed"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if tracker.lastState != RebuildStateFailed {
		t.Fatalf("expected failed, got %s", tracker.lastState)
	}

	if tracker.callCount != 4 {
		t.Fatalf("expected 4 tracker calls, got %d", tracker.callCount)
	}
}
