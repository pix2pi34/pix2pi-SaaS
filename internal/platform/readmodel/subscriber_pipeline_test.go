package readmodel

import (
	"context"
	"errors"
	"testing"
	"time"
)

type fakeProcessedStore struct {
	items     map[string]bool
	existsErr error
	markErr   error
	markCalls int
}

func newFakeProcessedStore() *fakeProcessedStore {
	return &fakeProcessedStore{
		items: make(map[string]bool),
	}
}

func (f *fakeProcessedStore) Exists(_ context.Context, eventID string) (bool, error) {
	if f.existsErr != nil {
		return false, f.existsErr
	}
	return f.items[eventID], nil
}

func (f *fakeProcessedStore) Mark(_ context.Context, eventID string) error {
	if f.markErr != nil {
		return f.markErr
	}
	f.items[eventID] = true
	f.markCalls++
	return nil
}

func sampleEvent() ReadModelEvent {
	return ReadModelEvent{
		EventID:       "evt_1001",
		EventType:     "sale.completed",
		TenantID:      "tenant_42",
		AggregateID:   "sale_500",
		CorrelationID: "corr_1",
		OccurredAt:    time.Now(),
		Payload:       []byte(`{"sale_id":"sale_500"}`),
	}
}

func TestHandlerRegistry_RegisterAndGet(t *testing.T) {
	registry := NewHandlerRegistry()

	err := registry.Register("sale.completed", func(_ context.Context, _ ReadModelEvent) (ProjectionResult, error) {
		return ProjectionResult{
			Writes: []ProjectionWrite{
				{Projection: "sales_summary", RecordsAffected: 1},
			},
		}, nil
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	handler, ok := registry.Get("sale.completed")
	if !ok {
		t.Fatal("expected handler")
	}
	if handler == nil {
		t.Fatal("expected non-nil handler")
	}
}

func TestHandlerRegistry_Duplicate(t *testing.T) {
	registry := NewHandlerRegistry()

	handler := func(_ context.Context, _ ReadModelEvent) (ProjectionResult, error) {
		return ProjectionResult{}, nil
	}

	if err := registry.Register("sale.completed", handler); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	err := registry.Register("sale.completed", handler)
	if err == nil {
		t.Fatal("expected duplicate handler error")
	}
	if err != ErrDuplicateHandler {
		t.Fatalf("expected ErrDuplicateHandler, got %v", err)
	}
}

func TestSubscriberPipeline_HandleSuccess(t *testing.T) {
	registry := NewHandlerRegistry()
	store := newFakeProcessedStore()

	err := registry.Register("sale.completed", func(_ context.Context, event ReadModelEvent) (ProjectionResult, error) {
		if event.TenantID != "tenant_42" {
			t.Fatalf("expected tenant_42, got %s", event.TenantID)
		}

		return ProjectionResult{
			Writes: []ProjectionWrite{
				{Projection: "sales_summary", RecordsAffected: 1},
				{Projection: "dashboard_kpi", RecordsAffected: 1},
			},
		}, nil
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	pipeline, err := NewSubscriberPipeline(registry, store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := pipeline.Handle(context.Background(), sampleEvent())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if result.AlreadyProcessed {
		t.Fatal("expected first event not processed before")
	}
	if result.Retryable {
		t.Fatal("expected retryable false")
	}
	if len(result.ProjectionWrites) != 2 {
		t.Fatalf("expected 2 projection writes, got %d", len(result.ProjectionWrites))
	}
	if store.markCalls != 1 {
		t.Fatalf("expected mark once, got %d", store.markCalls)
	}
}

func TestSubscriberPipeline_AlreadyProcessed(t *testing.T) {
	registry := NewHandlerRegistry()
	store := newFakeProcessedStore()
	store.items["evt_1001"] = true

	err := registry.Register("sale.completed", func(_ context.Context, _ ReadModelEvent) (ProjectionResult, error) {
		t.Fatal("handler should not run for already processed event")
		return ProjectionResult{}, nil
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	pipeline, err := NewSubscriberPipeline(registry, store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := pipeline.Handle(context.Background(), sampleEvent())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !result.AlreadyProcessed {
		t.Fatal("expected already processed")
	}
	if store.markCalls != 0 {
		t.Fatalf("expected no mark call, got %d", store.markCalls)
	}
}

func TestSubscriberPipeline_UnknownHandler(t *testing.T) {
	registry := NewHandlerRegistry()
	store := newFakeProcessedStore()

	pipeline, err := NewSubscriberPipeline(registry, store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = pipeline.Handle(context.Background(), sampleEvent())
	if err == nil {
		t.Fatal("expected unknown handler error")
	}
}

func TestSubscriberPipeline_RetryableError(t *testing.T) {
	registry := NewHandlerRegistry()
	store := newFakeProcessedStore()

	err := registry.Register("sale.completed", func(_ context.Context, _ ReadModelEvent) (ProjectionResult, error) {
		return ProjectionResult{}, NewRetryableError(errors.New("temporary projection db issue"))
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	pipeline, err := NewSubscriberPipeline(registry, store)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := pipeline.Handle(context.Background(), sampleEvent())
	if err == nil {
		t.Fatal("expected retryable error")
	}
	if !result.Retryable {
		t.Fatal("expected retryable true")
	}
	if store.markCalls != 0 {
		t.Fatalf("expected mark not called, got %d", store.markCalls)
	}
}

func TestReadModelEvent_InvalidTenant(t *testing.T) {
	event := sampleEvent()
	event.TenantID = "tenant 42"

	err := event.Validate()
	if err == nil {
		t.Fatal("expected validation error")
	}
}

func TestProjectionResult_InvalidWrite(t *testing.T) {
	result := ProjectionResult{
		Writes: []ProjectionWrite{
			{Projection: "", RecordsAffected: 1},
		},
	}

	err := result.Validate()
	if err == nil {
		t.Fatal("expected invalid projection write error")
	}
}
